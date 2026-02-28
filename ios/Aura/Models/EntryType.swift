import SwiftUI

enum EntryType: String, Codable, CaseIterable {
    case food = "food"
    case symptom = "symptom"
    case mood = "mood"

    var displayName: String {
        switch self {
        case .food: return "Food"
        case .symptom: return "Symptom"
        case .mood: return "Mood"
        }
    }

    var iconName: String {
        switch self {
        case .food: return "fork.knife"
        case .symptom: return "waveform.path.ecg"
        case .mood: return "heart.fill"
        }
    }

    var color: Color {
        switch self {
        case .food: return Color(red: 0.2, green: 0.85, blue: 0.5)
        case .symptom: return Color(red: 1.0, green: 0.35, blue: 0.35)
        case .mood: return Color(red: 0.6, green: 0.4, blue: 1.0)
        }
    }
}
