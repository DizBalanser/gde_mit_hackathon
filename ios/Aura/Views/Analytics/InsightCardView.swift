import SwiftUI

struct InsightCardView: View {
    let insight: Insight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(insight.color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: insight.iconName)
                    .font(.system(size: 18))
                    .foregroundStyle(insight.color)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(insight.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)

                // Confidence bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.tertiarySystemFill))
                            .frame(height: 3)
                        Capsule()
                            .fill(insight.color.opacity(0.7))
                            .frame(width: geo.size.width * CGFloat(insight.confidenceScore), height: 3)
                            .animation(.spring(response: 0.8), value: insight.confidenceScore)
                    }
                }
                .frame(height: 3)

                Text("\(insight.confidencePercent)% confidence")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}
