import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var diaryVM = DiaryViewModel()
    @State private var analyticsVM = AnalyticsViewModel()
    @State private var profileVM = ProfileViewModel()
    @Query(sort: \HealthEntry.date, order: .reverse) private var entries: [HealthEntry]

    var body: some View {
        TabView(selection: $selectedTab) {
            DiaryView(viewModel: diaryVM)
                .tabItem {
                    Label("Diary", systemImage: "book.closed.fill")
                }
                .tag(0)

            AnalyticsDashboardView(viewModel: analyticsVM, entries: entries)
                .tabItem {
                    Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)

            ProfileView(viewModel: profileVM, entries: entries)
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(2)
        }
        .preferredColorScheme(.light)
        .tint(.purple)
        
    }
}
