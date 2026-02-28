import SwiftUI

enum InsightCategory: String, Codable, CaseIterable {
    case nutrition, sleep, mood, symptom, pattern, warning, positive

    var iconName: String {
        switch self {
        case .nutrition: return "fork.knife.circle.fill"
        case .sleep: return "moon.zzz.fill"
        case .mood: return "face.smiling.fill"
        case .symptom: return "bandage.fill"
        case .pattern: return "chart.line.uptrend.xyaxis"
        case .warning: return "exclamationmark.triangle.fill"
        case .positive: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .nutrition: return Color(red: 0.2, green: 0.85, blue: 0.5)
        case .sleep: return Color(red: 0.4, green: 0.5, blue: 1.0)
        case .mood: return Color(red: 0.6, green: 0.4, blue: 1.0)
        case .symptom: return Color(red: 1.0, green: 0.35, blue: 0.35)
        case .pattern: return Color(red: 0.0, green: 0.8, blue: 1.0)
        case .warning: return Color(red: 1.0, green: 0.7, blue: 0.0)
        case .positive: return Color(red: 1.0, green: 0.85, blue: 0.0)
        }
    }
}

struct Insight: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let confidenceScore: Double
    let category: InsightCategory

    var iconName: String { category.iconName }
    var color: Color { category.color }
    var confidencePercent: Int { Int(confidenceScore * 100) }

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        confidenceScore: Double,
        category: InsightCategory
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.confidenceScore = max(0.0, min(1.0, confidenceScore))
        self.category = category
    }
}
