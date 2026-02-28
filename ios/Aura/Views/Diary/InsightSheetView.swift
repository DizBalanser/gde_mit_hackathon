import SwiftUI

struct InsightSheetView: View {
    let entry: HealthEntry
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    entryHeader
                    rawTextCard

                    if !entry.isProcessing {
                        aiSection

                        switch entry.entryType {
                        case .food:    nutritionGrid
                        case .symptom: severityCard
                        case .mood:    moodCard
                        }

                        if entry.hasMedicalReferences {
                            medicalReferencesSection
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 40)
            }
            .background(Color(.systemBackground))
            .navigationTitle(entry.entryType.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.medium)
                        .foregroundStyle(.purple)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var entryHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(entry.entryType.color.opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: entry.entryType.iconName)
                    .font(.system(size: 22))
                    .foregroundStyle(entry.entryType.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.entryType.displayName)
                    .font(.headline).fontWeight(.semibold).foregroundStyle(.primary)
                Text(entry.formattedDate)
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            if entry.hasMedicalReferences {
                HStack(spacing: 4) {
                    Image(systemName: "cross.case.fill")
                        .font(.caption)
                    Text("Evidence")
                        .font(.caption2).fontWeight(.medium)
                }
                .foregroundStyle(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.08), in: Capsule())
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Raw Text

    private var rawTextCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Your Entry", systemImage: "quote.bubble")
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase).tracking(0.6)

            Text(entry.rawText)
                .font(.body).foregroundStyle(.primary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - AI Analysis

    @ViewBuilder
    private var aiSection: some View {
        VStack(spacing: 10) {
            sectionHeader("AI Analysis", icon: "sparkles")

            if !entry.aiSummary.isEmpty {
                infoRow(label: "Summary", icon: "text.alignleft", content: entry.aiSummary)
            }
            if !entry.aiInsight.isEmpty {
                infoRow(label: "Insight", icon: "lightbulb", content: entry.aiInsight)
            }
            if !entry.aiSuggestion.isEmpty {
                infoRow(label: "Suggestion", icon: "arrow.forward.circle", content: entry.aiSuggestion)
            }
        }
    }

    // MARK: - Medical References

    @ViewBuilder
    private var medicalReferencesSection: some View {
        VStack(spacing: 10) {
            sectionHeader("Medical Sources", icon: "cross.case")

            ForEach(entry.medicalReferences) { ref in
                medicalReferenceRow(ref)
            }

            Text("Data sourced from FDA FAERS and NLM MedlinePlus — not a substitute for professional medical advice.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
    }

    private func medicalReferenceRow(_ ref: MedicalReference) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: ref.category.iconName)
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(ref.source)
                        .font(.caption2).fontWeight(.bold)
                        .foregroundStyle(.blue)
                        .textCase(.uppercase).tracking(0.4)
                    Text(ref.title)
                        .font(.caption).fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                Spacer()
                Image(systemName: "checkmark.shield.fill")
                    .font(.caption)
                    .foregroundStyle(.green.opacity(0.7))
            }

            Text(ref.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let urlString = ref.url, let url = URL(string: urlString) {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right.square")
                        Text("View source")
                    }
                    .font(.caption2).fontWeight(.medium)
                    .foregroundStyle(.blue)
                }
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.1), lineWidth: 1))
    }

    // MARK: - Nutrition

    @ViewBuilder
    private var nutritionGrid: some View {
        let hasMacros = entry.calories != nil || entry.protein != nil
        if hasMacros {
            VStack(spacing: 10) {
                sectionHeader("Nutrition", icon: "fork.knife")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    if let c = entry.calories  { macroTile("\(c)", "kcal", "Calories", .orange) }
                    if let p = entry.protein   { macroTile("\(p)g", "", "Protein", .blue) }
                    if let c = entry.carbs     { macroTile("\(c)g", "", "Carbs", Color(red: 0.9, green: 0.7, blue: 0.1)) }
                    if let f = entry.fat       { macroTile("\(f)g", "", "Fat", .red) }
                }
            }
        }
    }

    // MARK: - Severity

    @ViewBuilder
    private var severityCard: some View {
        if let sev = entry.symptomSeverity {
            VStack(spacing: 10) {
                sectionHeader("Severity", icon: "waveform.path.ecg")
                VStack(spacing: 12) {
                    if let name = entry.symptomName {
                        Text(name).font(.headline).foregroundStyle(.primary)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(.tertiarySystemFill)).frame(height: 8)
                            Capsule()
                                .fill(sevColor(sev))
                                .frame(width: geo.size.width * CGFloat(sev) / 10, height: 8)
                                .animation(.spring(response: 0.7), value: sev)
                        }
                    }
                    .frame(height: 8)
                    Text("\(sev) / 10")
                        .font(.title2).fontWeight(.bold).foregroundStyle(sevColor(sev))
                }
                .padding(16)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Mood

    @ViewBuilder
    private var moodCard: some View {
        if let score = entry.moodScore {
            VStack(spacing: 10) {
                sectionHeader("Mood", icon: "heart")
                VStack(spacing: 12) {
                    Text(moodEmoji(score)).font(.system(size: 52))
                    Text(moodLabel(score)).font(.headline).foregroundStyle(.primary)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(.tertiarySystemFill)).frame(height: 8)
                            Capsule()
                                .fill(score >= 0 ? Color.green : Color.red)
                                .frame(width: max(4, geo.size.width * CGFloat((score + 1) / 2)), height: 8)
                                .animation(.spring(response: 0.7), value: score)
                        }
                    }
                    .frame(height: 8)
                    Text(String(format: "%+.2f", score))
                        .font(.caption).foregroundStyle(.secondary).monospacedDigit()
                }
                .padding(16)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Reusable

    private func sectionHeader(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption).fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase).tracking(0.6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func infoRow(label: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon)
                .font(.caption).fontWeight(.semibold).foregroundStyle(.purple)
            Text(content).font(.body).foregroundStyle(.primary).lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private func macroTile(_ value: String, _ unit: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value).font(.title2).fontWeight(.bold).foregroundStyle(.primary)
                if !unit.isEmpty {
                    Text(unit).font(.caption).foregroundStyle(.secondary)
                }
            }
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.2), lineWidth: 1))
    }

    private func sevColor(_ s: Int) -> Color {
        switch s {
        case 1...3: return .green
        case 4...6: return .orange
        default: return .red
        }
    }
    private func moodEmoji(_ s: Double) -> String {
        switch s {
        case 0.6...1.0: return "😄"; case 0.2..<0.6: return "🙂"
        case -0.2..<0.2: return "😐"; case -0.6 ..< -0.2: return "😕"
        default: return "😞"
        }
    }
    private func moodLabel(_ s: Double) -> String {
        switch s {
        case 0.6...1.0: return "Great"; case 0.2..<0.6: return "Good"
        case -0.2..<0.2: return "Neutral"; case -0.6 ..< -0.2: return "Low"
        default: return "Poor"
        }
    }
}
