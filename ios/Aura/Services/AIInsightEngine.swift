import Foundation

struct AIInsightEngine {

    static func generateInsights(entries: [HealthEntry]) -> [Insight] {
        var insights: [Insight] = []

        let sorted = entries.sorted { $0.date < $1.date }
        let foodEntries = sorted.filter { $0.entryType == .food }
        let symptomEntries = sorted.filter { $0.entryType == .symptom }
        let moodEntries = sorted.filter { $0.entryType == .mood }

        // 1. Caffeine-Headache Pattern
        if let insight = detectCaffeineHeadachePattern(food: foodEntries, symptoms: symptomEntries) {
            insights.append(insight)
        }

        // 2. FastFood-Stomach Pattern
        if let insight = detectFastFoodStomachPattern(food: foodEntries, symptoms: symptomEntries) {
            insights.append(insight)
        }

        // 3. Exercise-Mood Correlation
        if let insight = detectExerciseMoodPattern(food: foodEntries, mood: moodEntries) {
            insights.append(insight)
        }

        // 4. Low Mood Streak
        if let insight = detectLowMoodStreak(mood: moodEntries) {
            insights.append(insight)
        }

        // 5. Symptom Frequency
        let frequencyInsights = detectSymptomFrequency(symptoms: symptomEntries)
        insights.append(contentsOf: frequencyInsights)

        return insights
    }

    // MARK: - Pattern Detectors

    private static func detectCaffeineHeadachePattern(
        food: [HealthEntry],
        symptoms: [HealthEntry]
    ) -> Insight? {
        let caffeineKeywords = ["coffee", "caffeine", "espresso", "energy drink", "red bull", "monster"]
        let headacheEntries = symptoms.filter {
            let name = ($0.symptomName ?? "").lowercased()
            let text = $0.rawText.lowercased()
            return name.contains("headache") || text.contains("headache")
        }

        guard !headacheEntries.isEmpty else { return nil }

        let caffeineEntries = food.filter { entry in
            let text = entry.rawText.lowercased()
            return caffeineKeywords.contains { text.contains($0) }
        }

        guard !caffeineEntries.isEmpty else { return nil }

        let oneDaySeconds: TimeInterval = 86400

        var correlationCount = 0
        for headache in headacheEntries {
            let priorCaffeine = caffeineEntries.filter { foodEntry in
                let diff = headache.date.timeIntervalSince(foodEntry.date)
                return diff > 0 && diff <= oneDaySeconds
            }
            if !priorCaffeine.isEmpty {
                correlationCount += 1
            }
        }

        guard correlationCount > 0 else { return nil }

        let confidence = min(0.95, 0.5 + Double(correlationCount) * 0.15)

        return Insight(
            title: "Caffeine & Headache Pattern",
            description: "Your headaches often appear within 24 hours after high caffeine intake. This correlation has been observed \(correlationCount) time(s) in your diary. Consider gradually reducing caffeine to identify your personal threshold.",
            confidenceScore: confidence,
            category: .warning
        )
    }

    private static func detectFastFoodStomachPattern(
        food: [HealthEntry],
        symptoms: [HealthEntry]
    ) -> Insight? {
        let fastFoodKeywords = ["fast food", "burger", "pizza", "fried", "mcdonald", "five guys", "taco bell", "kfc", "wendy's", "onion rings", "french fries", "fries"]
        let stomachEntries = symptoms.filter {
            let name = ($0.symptomName ?? "").lowercased()
            let text = $0.rawText.lowercased()
            return name.contains("stomach") || name.contains("nausea") || name.contains("digestive") ||
                   text.contains("stomach") || text.contains("nausea") || text.contains("bloat")
        }

        guard !stomachEntries.isEmpty else { return nil }

        let fastFoodDays = food.filter { entry in
            let text = entry.rawText.lowercased()
            return fastFoodKeywords.contains { text.contains($0) }
        }

        guard !fastFoodDays.isEmpty else { return nil }

        let oneDaySeconds: TimeInterval = 86400
        var correlationCount = 0

        for stomach in stomachEntries {
            let prior = fastFoodDays.filter { foodEntry in
                let diff = stomach.date.timeIntervalSince(foodEntry.date)
                return diff >= 0 && diff <= oneDaySeconds
            }
            if !prior.isEmpty { correlationCount += 1 }
        }

        guard correlationCount > 0 else { return nil }

        let confidence = min(0.90, 0.45 + Double(correlationCount) * 0.15)

        return Insight(
            title: "Diet & Digestive Health",
            description: "Stomach discomfort appears to follow meals containing fast food, fried foods, or highly processed options. This pattern appeared \(correlationCount) time(s). Reducing ultra-processed food intake could significantly improve your digestive comfort.",
            confidenceScore: confidence,
            category: .symptom
        )
    }

    private static func detectExerciseMoodPattern(
        food: [HealthEntry],
        mood: [HealthEntry]
    ) -> Insight? {
        let exerciseKeywords = ["exercise", "gym", "run", "running", "jog", "jogging", "walk", "walking", "workout", "hike", "hiking", "cycling", "swim", "yoga", "5k"]

        let exerciseMentions = (food + mood).filter { entry in
            let text = entry.rawText.lowercased()
            return exerciseKeywords.contains { text.contains($0) }
        }

        guard !exerciseMentions.isEmpty else { return nil }

        let exerciseDates = Set(exerciseMentions.map { Calendar.current.startOfDay(for: $0.date) })

        let moodOnExerciseDays = mood.filter { entry in
            let day = Calendar.current.startOfDay(for: entry.date)
            return exerciseDates.contains(day)
        }

        guard !moodOnExerciseDays.isEmpty else { return nil }

        let avgMood = moodOnExerciseDays.compactMap { $0.moodScore }.reduce(0, +) / Double(moodOnExerciseDays.count)

        guard avgMood > 0.2 else { return nil }

        let confidence = min(0.88, 0.55 + avgMood * 0.3)

        return Insight(
            title: "Exercise Boosts Your Mood",
            description: String(format: "On days you exercise, your average mood score is %.1f/1.0, which is notably positive. Physical activity appears across \(exerciseMentions.count) diary entries and consistently correlates with better emotional wellbeing.", avgMood),
            confidenceScore: confidence,
            category: .positive
        )
    }

    private static func detectLowMoodStreak(mood: [HealthEntry]) -> Insight? {
        guard mood.count >= 3 else { return nil }

        let sorted = mood.sorted { $0.date < $1.date }
        var maxStreak = 0
        var currentStreak = 0

        for entry in sorted {
            if let score = entry.moodScore, score < 0 {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }

        guard maxStreak >= 3 else { return nil }

        let confidence = min(0.85, 0.60 + Double(maxStreak) * 0.05)

        return Insight(
            title: "Mood Support Needed",
            description: "You've experienced \(maxStreak) consecutive days of below-neutral mood scores. Extended periods of low mood can affect energy, appetite, and overall health. Consider stress management techniques, social connection, or speaking with a healthcare provider.",
            confidenceScore: confidence,
            category: .warning
        )
    }

    private static func detectSymptomFrequency(symptoms: [HealthEntry]) -> [Insight] {
        var nameCounts: [String: Int] = [:]

        for entry in symptoms {
            if let name = entry.symptomName, !name.isEmpty {
                let normalized = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                nameCounts[normalized, default: 0] += 1
            }
        }

        var insights: [Insight] = []

        for (name, count) in nameCounts where count >= 3 {
            let displayName = name.prefix(1).uppercased() + name.dropFirst()
            let confidence = min(0.92, 0.55 + Double(count) * 0.08)

            insights.append(Insight(
                title: "Recurring \(displayName)",
                description: "\(displayName) has appeared \(count) times in your health diary. Recurring symptoms at this frequency warrant attention. Track timing, potential triggers, and consider discussing this pattern with a healthcare professional.",
                confidenceScore: confidence,
                category: .warning
            ))
        }

        return insights
    }
}
