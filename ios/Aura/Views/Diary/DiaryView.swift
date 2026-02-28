import SwiftUI
import SwiftData

struct DiaryView: View {
    @Bindable var viewModel: DiaryViewModel
    @Query(sort: \HealthEntry.date, order: .reverse) var entries: [HealthEntry]
    @Environment(\.modelContext) var modelContext

    @FocusState private var isInputFocused: Bool
    @State private var selectedEntry: HealthEntry?
    @State private var showMedicationDetail = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // ── Inline text input (Apple Notes style) ──
                    inputSection
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 16)

                    Divider().padding(.horizontal, 20)

                    // ── Past entries timeline ──
                    if entries.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(entries) { entry in
                                EntryCard(entry: entry) {
                                    selectedEntry = entry
                                    HapticManager.light()
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        viewModel.deleteEntry(entry, context: modelContext)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                Divider().padding(.leading, 20)
                            }
                        }
                    }

                    Spacer(minLength: 16)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemBackground))
            .safeAreaInset(edge: .bottom) {
                bottomToolbar
            }
            .navigationTitle(todayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Aura")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.purple)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !entries.isEmpty {
                        Text("\(entries.count) entries")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .sheet(item: $selectedEntry) { entry in
            InsightSheetView(entry: entry)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { viewModel.showError = false }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onAppear {
            isInputFocused = true
        }
    }

    // MARK: - Input Section (Apple Notes style)

    private var inputSection: some View {
        HStack(alignment: .top, spacing: 12) {
            // Multiline text field — expands as user types
            TextField("What did you eat, feel, or experience?",
                      text: $viewModel.inputText,
                      axis: .vertical)
                .font(.body)
                .lineLimit(1...12)
                .focused($isInputFocused)
                .tint(.purple)
                .onChange(of: viewModel.inputText) { _, new in
                    viewModel.onTextChanged(new)
                }

            // Live AI result badge (right side — like Amy "294 cal")
            if viewModel.isAutoAnalyzing {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(.secondary)
                    .padding(.top, 3)
            } else if let result = viewModel.liveResult {
                liveResultBadge(result)
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.liveResult != nil)
        .animation(.easeInOut(duration: 0.15), value: viewModel.isAutoAnalyzing)
    }

    @ViewBuilder
    private func liveResultBadge(_ result: AIAnalysisResult) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            if let cal = result.calories {
                Text("\(cal) kcal")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            } else if let mood = result.moodScore {
                Text(moodEmoji(mood))
                    .font(.title3)
            } else if let sev = result.symptomSeverity {
                Text("Sev \(sev)/10")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            Text(EntryType(rawValue: result.entryType)?.displayName ?? "")
                .font(.caption2)
                .foregroundStyle(Color.purple.opacity(0.7))
        }
        .padding(.top, 3)
    }

    // MARK: - Bottom Toolbar

    /// Total calories consumed today (from food entries)
    private var todayCalories: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return entries
            .filter { $0.entryType == .food && cal.isDate($0.date, inSameDayAs: today) }
            .compactMap { $0.calories }
            .reduce(0, +)
    }

    private var bottomToolbar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                // Daily calories pill — always visible with bright flame
                dailyCaloriePill

                // Live AI result (mood/symptom) when typing
                if let result = viewModel.liveResult, result.calories == nil {
                    liveResultPill(result)
                }

                Spacer(minLength: 0)

                // Add / save — purple when active
                Button {
                    Task { await viewModel.submitEntry(context: modelContext) }
                } label: {
                    glassButton(
                        icon: "plus",
                        color: viewModel.inputText.isEmpty ? Color.secondary : Color.purple,
                        weight: .semibold
                    )
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .animation(.easeInOut(duration: 0.15), value: viewModel.inputText.isEmpty)

                // Keyboard dismiss
                Button {
                    isInputFocused = false
                } label: {
                    glassButton(icon: "keyboard.chevron.compact.down", color: .secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
    }

    /// Daily calorie total with bright flame — native glassEffect
    private var dailyCaloriePill: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 16))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.orange, Color.yellow],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            Text("\(todayCalories)")
                .font(.callout)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassEffect(.regular.interactive(), in: .capsule)
    }

    @ViewBuilder
    private func liveResultPill(_ result: AIAnalysisResult) -> some View {
        HStack(spacing: 4) {
            if let mood = result.moodScore {
                Text(moodEmoji(mood))
                Text(String(format: "%+.1f", mood))
                    .fontWeight(.semibold)
                    .monospacedDigit()
            } else if let sev = result.symptomSeverity {
                Image(systemName: "waveform.path.ecg")
                Text("\(sev)/10")
                    .fontWeight(.semibold)
            } else {
                Button {
                    showMedicationDetail = true
                    HapticManager.light()
                } label: {
                    Image(systemName: "pill.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.purple)
                }
            }
        }
        .font(.callout)
        .foregroundStyle(.primary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassEffect(.regular.interactive(), in: .capsule)
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: result.aiSummary)
        .sheet(isPresented: $showMedicationDetail) {
            MedicationDetailSheet(result: result)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    /// Native glassEffect button — real Liquid Glass (iOS 26+)
    private func glassButton(
        icon: String,
        color: Color,
        weight: Font.Weight = .regular
    ) -> some View {
        Image(systemName: icon)
            .font(.system(size: 17, weight: weight))
            .foregroundStyle(color)
            .frame(width: 40, height: 40)
            .glassEffect(.regular.interactive(), in: .circle)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 40))
                .foregroundStyle(.purple.opacity(0.4))
                .padding(.top, 48)

            Text("Start logging")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            Text("Type above to log food, symptoms, or mood.\nAura will analyze your entries automatically.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }

    // MARK: - Helpers

    private var todayTitle: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: Date())
    }

    private func moodEmoji(_ score: Double) -> String {
        switch score {
        case 0.6...1.0:   return "😄"
        case 0.2..<0.6:   return "🙂"
        case -0.2..<0.2:  return "😐"
        case -0.6 ..< -0.2: return "😕"
        default:           return "😞"
        }
    }
}

// MARK: - Medication Detail Sheet

private struct MedicationDetailSheet: View {
    let result: AIAnalysisResult
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack(spacing: 12) {
                        Image(systemName: "pill.fill")
                            .font(.title2)
                            .foregroundStyle(.purple)
                            .frame(width: 44, height: 44)
                            .background(.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Medication Detected")
                                .font(.headline)
                            if let name = result.symptomName {
                                Text(name.capitalized)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // AI Summary
                    if !result.aiSummary.isEmpty {
                        infoCard(
                            icon: "brain.head.profile",
                            title: "AI Analysis",
                            text: result.aiSummary,
                            color: .purple
                        )
                    }

                    // Insight
                    if !result.aiInsight.isEmpty {
                        infoCard(
                            icon: "lightbulb.fill",
                            title: "Insight",
                            text: result.aiInsight,
                            color: .orange
                        )
                    }

                    // Suggestion
                    if !result.aiSuggestion.isEmpty {
                        infoCard(
                            icon: "heart.text.clipboard",
                            title: "Recommendation",
                            text: result.aiSuggestion,
                            color: .green
                        )
                    }

                    Text("Source: Azure OpenAI + FDA FAERS")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
                .padding(20)
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func infoCard(icon: String, title: String, text: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
    }
}
