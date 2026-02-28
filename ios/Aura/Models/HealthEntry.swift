import SwiftData
import Foundation

@Model
final class HealthEntry {
    var id: UUID
    var date: Date
    var rawText: String
    var entryType: EntryType
    var calories: Int?
    var protein: Int?
    var carbs: Int?
    var fat: Int?
    var symptomSeverity: Int?
    var symptomName: String?
    var moodScore: Double?
    var aiSummary: String
    var aiInsight: String
    var aiSuggestion: String
    var isProcessing: Bool
    var medicalReferencesJSON: String?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        rawText: String,
        entryType: EntryType = .food,
        calories: Int? = nil,
        protein: Int? = nil,
        carbs: Int? = nil,
        fat: Int? = nil,
        symptomSeverity: Int? = nil,
        symptomName: String? = nil,
        moodScore: Double? = nil,
        aiSummary: String = "",
        aiInsight: String = "",
        aiSuggestion: String = "",
        isProcessing: Bool = false,
        medicalReferencesJSON: String? = nil
    ) {
        self.id = id
        self.date = date
        self.rawText = rawText
        self.entryType = entryType
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.symptomSeverity = symptomSeverity
        self.symptomName = symptomName
        self.moodScore = moodScore
        self.aiSummary = aiSummary
        self.aiInsight = aiInsight
        self.aiSuggestion = aiSuggestion
        self.isProcessing = isProcessing
        self.medicalReferencesJSON = medicalReferencesJSON
    }

    // MARK: - Medical References

    var medicalReferences: [MedicalReference] {
        get {
            guard let json = medicalReferencesJSON,
                  let data = json.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([MedicalReference].self, from: data)) ?? []
        }
        set {
            guard !newValue.isEmpty,
                  let data = try? JSONEncoder().encode(newValue) else {
                medicalReferencesJSON = nil
                return
            }
            medicalReferencesJSON = String(data: data, encoding: .utf8)
        }
    }

    var hasMedicalReferences: Bool {
        medicalReferencesJSON != nil && !medicalReferences.isEmpty
    }

    // MARK: - Computed Properties

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var calorieSummaryTag: String? {
        guard let cal = calories, cal > 0 else { return nil }
        return "\(cal) kcal"
    }

    var moodTag: String? {
        guard let score = moodScore else { return nil }
        switch score {
        case 0.6...1.0: return "Great mood"
        case 0.2..<0.6: return "Good mood"
        case -0.2..<0.2: return "Neutral"
        case -0.6 ..< -0.2: return "Low mood"
        default: return "Poor mood"
        }
    }

    var severityTag: String? {
        guard let severity = symptomSeverity else { return nil }
        return "Severity \(severity)/10"
    }

    var tags: [String] {
        [calorieSummaryTag, moodTag, severityTag, symptomName].compactMap { $0 }
    }
}
