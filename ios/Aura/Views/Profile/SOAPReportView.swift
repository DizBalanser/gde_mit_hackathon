import SwiftUI

struct SOAPReportView: View {
    let note: SOAPNote
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    reportHeader
                    soapSection("S", "Subjective", "person.bubble", .blue, note.subjective)
                    soapSection("O", "Objective", "chart.bar.doc.horizontal", .green, note.objective)
                    soapSection("A", "Assessment", "brain.head.profile", .orange, note.assessment)
                    soapSection("P", "Plan", "checklist", .purple, note.plan)
                    sourcesSection
                    disclaimerSection
                }
                .padding(20)
                .padding(.bottom, 40)
            }
            .background(Color(.systemBackground))
            .navigationTitle("SOAP Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.medium).foregroundStyle(.purple)
                }
                ToolbarItem(placement: .topBarLeading) {
                    ShareLink(item: note.exportText) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.body)
                            .foregroundStyle(.purple)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var reportHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 60, height: 60)
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 26))
                    .foregroundStyle(.purple)
            }

            Text("Clinical SOAP Note")
                .font(.title3).fontWeight(.bold).foregroundStyle(.primary)

            Text(note.formattedPeriod)
                .font(.subheadline).foregroundStyle(.secondary)

            HStack(spacing: 16) {
                headerBadge("AI-Generated", icon: "sparkles", color: .purple)
                headerBadge("FDA Verified", icon: "checkmark.shield", color: .green)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func headerBadge(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2)
            Text(text).font(.caption2).fontWeight(.medium)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(color.opacity(0.08), in: Capsule())
    }

    // MARK: - SOAP Sections

    private func soapSection(
        _ letter: String,
        _ title: String,
        _ icon: String,
        _ color: Color,
        _ content: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(letter)
                    .font(.title2).fontWeight(.heavy)
                    .foregroundStyle(color)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.subheadline).fontWeight(.semibold).foregroundStyle(.primary)
                    Label(sectionSubtitle(letter), systemImage: icon)
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
            }

            Text(content.isEmpty ? "No data available for this section." : content)
                .font(.body).foregroundStyle(content.isEmpty ? .tertiary : .primary)
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }

    private func sectionSubtitle(_ letter: String) -> String {
        switch letter {
        case "S": return "Patient-reported symptoms & history"
        case "O": return "Measured data & metrics"
        case "A": return "AI pattern analysis"
        case "P": return "Recommendations & next steps"
        default: return ""
        }
    }

    // MARK: - Sources

    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Medical Sources", systemImage: "cross.case")
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase).tracking(0.6)

            let uniqueSources = Array(Set(note.medicalSourcesUsed))
            if uniqueSources.isEmpty {
                Text("No external medical databases were referenced.")
                    .font(.caption).foregroundStyle(.tertiary)
            } else {
                HStack(spacing: 6) {
                    ForEach(uniqueSources, id: \.self) { source in
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 8))
                            Text(source)
                                .font(.caption2).fontWeight(.medium)
                        }
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.blue.opacity(0.08), in: Capsule())
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Disclaimer

    private var disclaimerSection: some View {
        VStack(spacing: 6) {
            Text("This SOAP note is AI-generated from patient self-reported diary data, cross-referenced with FDA FAERS and NLM MedlinePlus. It is not a substitute for professional clinical evaluation or diagnosis.")
                .font(.caption2).foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Text("Generated \(note.formattedDate)")
                .font(.caption2).foregroundStyle(.quaternary)
        }
        .padding(.top, 4)
    }
}
