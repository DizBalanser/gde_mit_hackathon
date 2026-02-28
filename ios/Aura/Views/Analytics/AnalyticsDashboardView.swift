import SwiftUI
import Charts

struct AnalyticsDashboardView: View {
    @Bindable var viewModel: AnalyticsViewModel
    let entries: [HealthEntry]

    private var calorieData: [DailyCalories] { viewModel.calorieData(from: entries) }
    private var moodData: [DailyMood]         { viewModel.moodData(from: entries) }
    private var symptomData: [DailySymptom]   { viewModel.symptomData(from: entries) }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    summaryStatsRow.padding(.horizontal, 16).padding(.top, 8)

                    if !calorieData.isEmpty  { caloriesCard.padding(.horizontal, 16) }
                    if !moodData.isEmpty     { moodCard.padding(.horizontal, 16) }
                    if !symptomData.isEmpty  { symptomCard.padding(.horizontal, 16) }

                    if calorieData.isEmpty && moodData.isEmpty && symptomData.isEmpty {
                        emptyPlaceholder.padding(.horizontal, 16)
                    }

                    insightsSection.padding(.horizontal, 16)
                    Spacer(minLength: 40)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            if viewModel.insights.isEmpty && !entries.isEmpty {
                await viewModel.loadInsights(from: entries)
            }
        }
        .onChange(of: entries.count) { _, _ in
            Task { await viewModel.loadInsights(from: entries) }
        }
    }

    // MARK: - Summary Stats

    private var summaryStatsRow: some View {
        HStack(spacing: 10) {
            statTile("\(entries.filter { !$0.isProcessing }.count)", "Entries", "list.bullet", .purple)
            statTile(avgMoodFormatted, "Avg Mood", "face.smiling", avgMoodColor)
            statTile(avgCalFormatted, "Avg kcal", "flame", .orange)
        }
    }

    // MARK: - Calories

    private var caloriesCard: some View {
        chartCard(title: "Daily Calories", icon: "flame.fill", iconColor: .orange) {
            Chart(calorieData) { item in
                BarMark(x: .value("Date", item.date, unit: .day),
                        y: .value("kcal", item.calories))
                    .foregroundStyle(Color.orange.opacity(0.75))
                    .cornerRadius(5)
            }
            .chartXAxis { dateAxis }
            .chartYAxis { numericAxis }
            .frame(height: 160)
            .animation(.easeInOut(duration: 0.6), value: calorieData.count)
        }
    }

    // MARK: - Mood

    private var moodCard: some View {
        chartCard(title: "Mood Trend", icon: "heart.fill", iconColor: .purple) {
            Chart {
                ForEach(moodData) { item in
                    AreaMark(x: .value("Date", item.date, unit: .day),
                             y: .value("Mood", item.score))
                        .foregroundStyle(Color.purple.opacity(0.15))
                    LineMark(x: .value("Date", item.date, unit: .day),
                             y: .value("Mood", item.score))
                        .foregroundStyle(Color.purple)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                }
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(Color(.tertiaryLabel))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            .chartYScale(domain: -1.0...1.0)
            .chartXAxis { dateAxis }
            .chartYAxis {
                AxisMarks(values: [-1, -0.5, 0, 0.5, 1]) {
                    AxisValueLabel().foregroundStyle(Color(.secondaryLabel))
                    AxisGridLine().foregroundStyle(Color(.separator).opacity(0.5))
                }
            }
            .frame(height: 160)
            .animation(.easeInOut(duration: 0.6), value: moodData.count)
        }
    }

    // MARK: - Symptom

    private var symptomCard: some View {
        chartCard(title: "Symptom Severity", icon: "waveform.path.ecg", iconColor: .red) {
            Chart {
                ForEach(symptomData) { item in
                    LineMark(x: .value("Date", item.date, unit: .day),
                             y: .value("Severity", item.severity))
                        .foregroundStyle(Color.red.opacity(0.8))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                    PointMark(x: .value("Date", item.date, unit: .day),
                              y: .value("Severity", item.severity))
                        .foregroundStyle(Color.red)
                        .symbolSize(36)
                }
            }
            .chartYScale(domain: 0...10)
            .chartXAxis { dateAxis }
            .chartYAxis {
                AxisMarks(values: [0, 2, 4, 6, 8, 10]) {
                    AxisValueLabel().foregroundStyle(Color(.secondaryLabel))
                    AxisGridLine().foregroundStyle(Color(.separator).opacity(0.5))
                }
            }
            .frame(height: 160)
            .animation(.easeInOut(duration: 0.6), value: symptomData.count)
        }
    }

    // MARK: - Shared axis builders

    private var dateAxis: some AxisContent {
        AxisMarks(values: .stride(by: .day, count: 3)) { _ in
            AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: true)
                .foregroundStyle(Color(.secondaryLabel))
        }
    }

    private var numericAxis: some AxisContent {
        AxisMarks {
            AxisValueLabel().foregroundStyle(Color(.secondaryLabel))
            AxisGridLine().foregroundStyle(Color(.separator).opacity(0.5))
        }
    }

    // MARK: - Insights

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("AI Insights", systemImage: "sparkles")
                    .font(.headline).fontWeight(.semibold).foregroundStyle(.primary)
                Spacer()
                if viewModel.isLoadingInsights {
                    ProgressView().scaleEffect(0.8)
                }
            }

            if viewModel.insights.isEmpty && !viewModel.isLoadingInsights {
                Text(entries.isEmpty
                     ? "Add diary entries to see AI health insights."
                     : "Tap to generate insights from your entries.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)

                if !entries.isEmpty {
                    Button {
                        Task { await viewModel.loadInsights(from: entries) }
                    } label: {
                        Label("Generate Insights", systemImage: "arrow.clockwise")
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundStyle(.purple)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(Color.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }

            LazyVStack(spacing: 10) {
                ForEach(viewModel.insights) { InsightCardView(insight: $0) }
            }
        }
    }

    // MARK: - Empty

    private var emptyPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 44))
                .foregroundStyle(Color(.tertiaryLabel))
            Text("No data yet")
                .font(.title3).foregroundStyle(.secondary)
            Text("Log entries in Diary to see your health trends here.")
                .font(.subheadline).foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 48)
    }

    // MARK: - Reusable

    private func statTile(_ value: String, _ label: String, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon).font(.title3).foregroundStyle(color)
            Text(value).font(.title3).fontWeight(.bold).foregroundStyle(.primary).monospacedDigit()
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private func chartCard<Content: View>(
        title: String, icon: String, iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(iconColor)
            content()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Computed

    private var avgMoodFormatted: String {
        let s = entries.compactMap { $0.moodScore }
        guard !s.isEmpty else { return "—" }
        return String(format: "%+.1f", s.reduce(0,+) / Double(s.count))
    }
    private var avgMoodColor: Color {
        let s = entries.compactMap { $0.moodScore }
        guard !s.isEmpty else { return .purple }
        return s.reduce(0,+) / Double(s.count) >= 0 ? .green : .red
    }
    private var avgCalFormatted: String {
        guard !calorieData.isEmpty else { return "—" }
        return "\(calorieData.map { $0.calories }.reduce(0,+) / calorieData.count)"
    }
}
