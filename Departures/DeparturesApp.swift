import FirebaseCore
import SwiftData
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()

        return true
    }
}

@main
struct DeparturesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var liveActivityManager = LiveActivityManager()
    @StateObject private var settings = Settings()

    var appSettings = AppSettings()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Station.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.font, Font.dNormal)
                .environmentObject(liveActivityManager)
                .environmentObject(settings)
                .environmentObject(appSettings)
                .onAppear {
                    liveActivityManager.stopAllActivities()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Station.self, configurations: config)

    // Add some sample data
    let sampleStation = Station(
        id: "900058101", name: "S Südkreuz Bhf (Berlin)",
        latitude: 52.475501,
        longitude: 13.365548)
    container.mainContext.insert(sampleStation)

    return MainView()
        .modelContainer(container)
        .environment(\.font, Font.dNormal)
        .environmentObject(LiveActivityManager())
        .environmentObject(Settings())
        .environmentObject(AppSettings())
}
