import SwiftUI

struct HealthSummarySheet: View {
    let summary: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.purple.opacity(0.1))
                                .frame(width: 56, height: 56)
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 24))
                                .foregroundStyle(.purple)
                        }
                        Text("Health Summary")
                            .font(.title3).fontWeight(.bold).foregroundStyle(.primary)
                        Text("AI-generated overview of your recent entries")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    // Summary text
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Analysis", systemImage: "sparkles")
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase).tracking(0.6)

                        Text(summary)
                            .font(.body).foregroundStyle(.primary)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))

                    // Share
                    ShareLink(item: summary) {
                        Label("Share Summary", systemImage: "square.and.arrow.up")
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundStyle(.purple)
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(Color.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    }

                    Text("AI-generated — not a substitute for professional medical advice.")
                        .font(.caption2).foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .padding(.bottom, 40)
            }
            .background(Color(.systemBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.medium).foregroundStyle(.purple)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
