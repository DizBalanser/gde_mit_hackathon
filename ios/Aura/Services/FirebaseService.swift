// MARK: - Firebase Setup Required
// Before building, add the Firebase iOS SDK via Xcode:
// File → Add Package Dependencies → https://github.com/firebase/firebase-ios-sdk
// Select: FirebaseAuth, FirebaseFirestore
// Then add GoogleService-Info.plist from your Firebase console (project settings → iOS app).

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirebaseService {
    static let shared = FirebaseService()

    private let db = Firestore.firestore()
    private(set) var uid: String?

    private init() {}

    // MARK: - Auth

    func signInAnonymously() async {
        // If already signed in, just grab the UID
        if let current = Auth.auth().currentUser {
            uid = current.uid
            return
        }
        do {
            let result = try await Auth.auth().signInAnonymously()
            uid = result.user.uid
        } catch {
            print("[FirebaseService] Anonymous auth error: \(error.localizedDescription)")
        }
    }

    // MARK: - User Profile

    func saveUserProfile(_ profile: UserProfile) async {
        guard let uid = uid else { return }
        let data: [String: Any] = [
            "uid": uid,
            "name": profile.name,
            "phoneNumber": profile.phoneNumber,
            "preferredCallHour": profile.preferredCallHour,
            "preferredCallMinute": profile.preferredCallMinute,
            "timezone": profile.timezone,
            "preferredCallUTCHour": profile.preferredCallUTCHour,
            "preferredCallUTCMinute": profile.preferredCallUTCMinute,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        do {
            try await db.collection("users").document(uid).setData(data, merge: true)
        } catch {
            print("[FirebaseService] Save user profile error: \(error.localizedDescription)")
        }
    }

    // MARK: - Diary Entries

    func syncEntry(_ entry: HealthEntry) async {
        guard let uid = uid else { return }
        var data: [String: Any] = [
            "id": entry.id.uuidString,
            "date": Timestamp(date: entry.date),
            "rawText": entry.rawText,
            "entryType": entry.entryType.rawValue,
            "aiSummary": entry.aiSummary,
            "aiInsight": entry.aiInsight,
            "aiSuggestion": entry.aiSuggestion,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if let v = entry.calories       { data["calories"]       = v }
        if let v = entry.protein        { data["protein"]        = v }
        if let v = entry.carbs          { data["carbs"]          = v }
        if let v = entry.fat            { data["fat"]            = v }
        if let v = entry.symptomSeverity { data["symptomSeverity"] = v }
        if let v = entry.symptomName    { data["symptomName"]    = v }
        if let v = entry.moodScore      { data["moodScore"]      = v }

        do {
            try await db
                .collection("users").document(uid)
                .collection("entries").document(entry.id.uuidString)
                .setData(data, merge: true)
        } catch {
            print("[FirebaseService] Sync entry error: \(error.localizedDescription)")
        }
    }

    func deleteEntry(_ id: String) async {
        guard let uid = uid else { return }
        do {
            try await db
                .collection("users").document(uid)
                .collection("entries").document(id)
                .delete()
        } catch {
            print("[FirebaseService] Delete entry error: \(error.localizedDescription)")
        }
    }
}
