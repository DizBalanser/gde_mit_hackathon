import SwiftUI
import SwiftData

@Observable
final class ProfileViewModel {
    var healthSummary = ""
    var isGeneratingSummary = false
    var showSummarySheet = false
    var hasDemoData = false
    var showError = false
    var errorMessage = ""
    var soapNote: SOAPNote? = nil
    var isGeneratingSOAP = false
    var showSOAPSheet = false

    // MARK: - Call Settings
    var userName: String = UserDefaults.standard.string(forKey: "aura.userName") ?? ""
    var userPhone: String = UserDefaults.standard.string(forKey: "aura.userPhone") ?? ""
    var preferredCallTime: Date = {
        let hour = UserDefaults.standard.integer(forKey: "aura.callHour")
        let minute = UserDefaults.standard.integer(forKey: "aura.callMinute")
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = (hour == 0 && minute == 0) ? 9 : hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? Date()
    }()
    var isSavingProfile = false
    var profileSaved = false

    func saveCallSettings() async {
        guard let uid = FirebaseService.shared.uid else { return }
        isSavingProfile = true

        // Persist locally
        UserDefaults.standard.set(userName, forKey: "aura.userName")
        UserDefaults.standard.set(userPhone, forKey: "aura.userPhone")
        let cal = Calendar.current
        let hour = cal.component(.hour, from: preferredCallTime)
        let minute = cal.component(.minute, from: preferredCallTime)
        UserDefaults.standard.set(hour, forKey: "aura.callHour")
        UserDefaults.standard.set(minute, forKey: "aura.callMinute")

        // Build and sync profile
        let utc = UserProfile.localToUTC(hour: hour, minute: minute)
        var profile = UserProfile(uid: uid)
        profile.name = userName
        profile.phoneNumber = userPhone
        profile.preferredCallHour = hour
        profile.preferredCallMinute = minute
        profile.preferredCallUTCHour = utc.hour
        profile.preferredCallUTCMinute = utc.minute
        profile.timezone = TimeZone.current.identifier

        await FirebaseService.shared.saveUserProfile(profile)
        isSavingProfile = false
        profileSaved = true
        HapticManager.success()
        try? await Task.sleep(for: .seconds(2))
        profileSaved = false
    }

    func loadDemoData(in context: ModelContext) {
        MockDataGenerator.generate(in: context)
        try? context.save()
        hasDemoData = true
        HapticManager.success()
    }

    func generateHealthSummary(entries: [HealthEntry]) async {
        guard !entries.isEmpty else { return }
        isGeneratingSummary = true
        do {
            healthSummary = try await OpenAIService.shared.generateHealthSummary(entries: entries)
            showSummarySheet = true
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
        isGeneratingSummary = false
    }

    func generateSOAPNote(entries: [HealthEntry]) async {
        guard !entries.isEmpty else { return }
        isGeneratingSOAP = true
        do {
            soapNote = try await OpenAIService.shared.generateSOAPNote(entries: entries)
            showSOAPSheet = true
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
        isGeneratingSOAP = false
    }

    func clearAllData(context: ModelContext) {
        do {
            try context.delete(model: HealthEntry.self)
            try context.save()
        } catch {
            // Fallback: if batch delete isn't available, clear nothing
        }
        hasDemoData = false
        HapticManager.medium()
    }
}
