import SwiftUI
import SwiftData

@Observable
final class DiaryViewModel {
    var inputText = ""
    var showError = false
    var errorMessage = ""

    var liveResult: AIAnalysisResult? = nil
    var isAutoAnalyzing = false

    private var debounceTask: Task<Void, Never>? = nil

    // MARK: - Debounced Live Analysis

    func onTextChanged(_ text: String) {
        debounceTask?.cancel()
        debounceTask = nil

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            liveResult = nil
            isAutoAnalyzing = false
            return
        }

        debounceTask = Task {
            do { try await Task.sleep(for: .seconds(1.0)) } catch { return }
            guard !Task.isCancelled else { return }
            await runLiveAnalysis(text: trimmed)
        }
    }

    private func runLiveAnalysis(text: String) async {
        isAutoAnalyzing = true
        do {
            let medicalCtx = await MedicalKnowledgeService.shared.fetchMedicalContext(for: text)
            let result = try await OpenAIService.shared.analyzeEntry(text: text, medicalContext: medicalCtx)
            withAnimation(.easeInOut(duration: 0.25)) {
                liveResult = result
            }
        } catch {
            // Silent — no disruption to the user
        }
        isAutoAnalyzing = false
    }

    // MARK: - Submit Entry

    func submitEntry(context: ModelContext) async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        HapticManager.light()
        debounceTask?.cancel()

        let cachedResult = liveResult
        let needsAnalysis = cachedResult == nil

        let entry = HealthEntry(rawText: text, isProcessing: needsAnalysis)
        if let r = cachedResult {
            applyResult(r, to: entry)
        }

        context.insert(entry)
        try? context.save()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            inputText = ""
            liveResult = nil
            isAutoAnalyzing = false
        }

        HapticManager.success()

        // Fetch medical references + AI analysis in parallel
        if needsAnalysis {
            do {
                async let medicalCtx = MedicalKnowledgeService.shared.fetchMedicalContext(for: text)
                let ctx = await medicalCtx
                let result = try await OpenAIService.shared.analyzeEntry(text: text, medicalContext: ctx)

                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    applyResult(result, to: entry)
                    entry.medicalReferences = ctx.references
                    entry.isProcessing = false
                }
                try? context.save()
                Task { await FirebaseService.shared.syncEntry(entry) }
            } catch {
                entry.aiSummary = "Entry logged"
                entry.aiInsight = "Analysis unavailable — check Azure API config."
                entry.aiSuggestion = ""
                entry.isProcessing = false
                try? context.save()
                Task { await FirebaseService.shared.syncEntry(entry) }
                showError = true
                errorMessage = error.localizedDescription
                HapticManager.error()
            }
        } else {
            Task { await FirebaseService.shared.syncEntry(entry) }
            // Even with cached result, fetch medical references in background
            Task {
                let ctx = await MedicalKnowledgeService.shared.fetchMedicalContext(for: text)
                if !ctx.references.isEmpty {
                    entry.medicalReferences = ctx.references
                    try? context.save()
                    await FirebaseService.shared.syncEntry(entry)
                }
            }
        }
    }

    private func applyResult(_ r: AIAnalysisResult, to entry: HealthEntry) {
        entry.entryType        = EntryType(rawValue: r.entryType) ?? .food
        entry.calories         = r.calories
        entry.protein          = r.protein
        entry.carbs            = r.carbs
        entry.fat              = r.fat
        entry.symptomSeverity  = r.symptomSeverity
        entry.symptomName      = r.symptomName
        entry.moodScore        = r.moodScore
        entry.aiSummary        = r.aiSummary
        entry.aiInsight        = r.aiInsight
        entry.aiSuggestion     = r.aiSuggestion
        entry.isProcessing     = false
    }

    // MARK: - Delete

    func deleteEntry(_ entry: HealthEntry, context: ModelContext) {
        let id = entry.id.uuidString
        withAnimation {
            context.delete(entry)
            try? context.save()
        }
        Task { await FirebaseService.shared.deleteEntry(id) }
        HapticManager.medium()
    }
}
