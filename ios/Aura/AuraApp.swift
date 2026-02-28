import SwiftUI
import SwiftData
import FirebaseCore

@main
struct AuraApp: App {
    let container: ModelContainer = {
        let schema = Schema([HealthEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do { return try ModelContainer(for: schema, configurations: [config]) }
        catch { fatalError("ModelContainer failed: \(error)") }
    }()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(container)
                .task {
                    await FirebaseService.shared.signInAnonymously()
                }
        }
    }
}
