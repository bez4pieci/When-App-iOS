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
    var appSettings = AppSettings()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.font, Font.dNormal)
                .environmentObject(liveActivityManager)
                .environmentObject(appSettings)
                .onAppear {
                    liveActivityManager.stopAllActivities()
                }
        }
        .modelContainer(for: Station.self)
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Station.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    container.mainContext.autosaveEnabled = true

    // Add some sample data
    container.mainContext.insert(
        Station(
            id: "900058101",
            name: "S Südkreuz Bhf (Berlin)",
            latitude: 52.475501,
            longitude: 13.365548,
            products: [.suburban, .bus, .regional, .express],
        ))

    return MainView()
        .modelContainer(container)
        .environment(\.font, Font.dNormal)
        .environmentObject(LiveActivityManager())
        .environmentObject(AppSettings())
}
