import SwiftUI
import Charts

struct DailyCalories: Identifiable {
    var id: Date { date }
    var date: Date
    var calories: Int
}

struct DailyMood: Identifiable {
    var id: Date { date }
    var date: Date
    var score: Double
}

struct DailySymptom: Identifiable {
    var id: Date { date }
    var date: Date
    var severity: Double
    var name: String
}

@Observable
final class AnalyticsViewModel {
    var insights: [Insight] = []
    var isLoadingInsights = false
    var healthSummary = ""

    func calorieData(from entries: [HealthEntry]) -> [DailyCalories] {
        let foodEntries = entries.filter { $0.entryType == .food && ($0.calories ?? 0) > 0 }
        let calendar = Calendar.current

        var dayMap: [Date: Int] = [:]
        for entry in foodEntries {
            let day = calendar.startOfDay(for: entry.date)
            dayMap[day, default: 0] += entry.calories ?? 0
        }

        return dayMap
            .map { DailyCalories(date: $0.key, calories: $0.value) }
            .sorted { $0.date < $1.date }
    }

    func moodData(from entries: [HealthEntry]) -> [DailyMood] {
        let moodEntries = entries.filter { $0.entryType == .mood && $0.moodScore != nil }
        let calendar = Calendar.current

        var dayMap: [Date: [Double]] = [:]
        for entry in moodEntries {
            let day = calendar.startOfDay(for: entry.date)
            if let score = entry.moodScore {
                dayMap[day, default: []].append(score)
            }
        }

        return dayMap
            .map { key, scores in
                let avg = scores.reduce(0, +) / Double(scores.count)
                return DailyMood(date: key, score: avg)
            }
            .sorted { $0.date < $1.date }
    }

    func symptomData(from entries: [HealthEntry]) -> [DailySymptom] {
        let symptomEntries = entries.filter { $0.entryType == .symptom && $0.symptomSeverity != nil }
        let calendar = Calendar.current

        var dayMap: [Date: (severities: [Double], name: String)] = [:]
        for entry in symptomEntries {
            let day = calendar.startOfDay(for: entry.date)
            if let sev = entry.symptomSeverity {
                var current = dayMap[day] ?? (severities: [], name: entry.symptomName ?? "Symptom")
                current.severities.append(Double(sev))
                dayMap[day] = current
            }
        }

        return dayMap
            .map { key, value in
                let avg = value.severities.reduce(0, +) / Double(value.severities.count)
                return DailySymptom(date: key, severity: avg, name: value.name)
            }
            .sorted { $0.date < $1.date }
    }

    func loadInsights(from entries: [HealthEntry]) async {
        isLoadingInsights = true

        let localInsights = AIInsightEngine.generateInsights(entries: entries)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            insights = localInsights
        }

        do {
            let aiInsights = try await OpenAIService.shared.generateInsights(entries: entries)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                insights = aiInsights + localInsights
            }
        } catch {
            // Keep local insights on failure — already displayed
        }

        isLoadingInsights = false
    }
}
