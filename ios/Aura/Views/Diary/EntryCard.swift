import SwiftUI

struct EntryCard: View {
    let entry: HealthEntry
    let onTap: () -> Void

    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                // Type icon column
                VStack {
                    ZStack {
                        Circle()
                            .fill(entry.entryType.color.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: entry.entryType.iconName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(entry.entryType.color)
                    }
                    Spacer()
                }

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    // Header row
                    HStack {
                        Text(entry.entryType.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(entry.entryType.color)

                        Spacer()

                        Text(entry.formattedTime)
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.quaternary)
                    }

                    // Body
                    if entry.isProcessing {
                        processingView
                    } else {
                        if !entry.aiSummary.isEmpty {
                            Text(entry.aiSummary)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if !entry.rawText.isEmpty {
                            Text(entry.rawText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // Tags
                    if !entry.isProcessing && (!entry.tags.isEmpty || entry.hasMedicalReferences) {
                        HStack(spacing: 6) {
                            ForEach(entry.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(Color(.tertiarySystemFill))
                                    )
                            }

                            if entry.hasMedicalReferences {
                                HStack(spacing: 3) {
                                    Image(systemName: "cross.case.fill")
                                        .font(.system(size: 8))
                                    Text("Evidence")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                }
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.blue.opacity(0.08)))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Processing shimmer

    private var processingView: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.75)
                .tint(.secondary)
            Text("Analyzing…")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
