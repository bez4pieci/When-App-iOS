import SwiftData
import SwiftUI
import TripKit

struct MainView: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @EnvironmentObject private var liveActivityManager: LiveActivityManager
    @Environment(\.modelContext) private var modelContext
    @Query() private var stations: [Station]

    @State private var showStationSelection = false
    @State private var currentTabIndex = 0

    private var headerHeight = 240.0
    @State private var offset = 0.0
    private var cornerRadius = AppConfig.cornerRadius

    private var currentStation: Station? {
        guard !stations.isEmpty && currentTabIndex < stations.count else { return nil }
        return stations[currentTabIndex]
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                HeaderMap(station: currentStation, offset: offset)
                    .zIndex(1)

                MainHeader(onGearButtonTap: {
                    showStationSelection = true
                })
                .zIndex(5)

                TabView(selection: $currentTabIndex) {
                    ForEach(Array(stations.enumerated()), id: \.element.id) {
                        index, station in
                        StationTab(station: station, offset: $offset)
                    }

                    NoStation(onSelectStation: { showStationSelection = true })
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .zIndex(2)
            }
            .ignoresSafeArea()
            .navigationBarHidden(true)
            .sheet(isPresented: $showStationSelection) {
                StationSettingsView(
                    station: currentStation,
                    onDelete: deleteStation
                )
            }
        }
    }

    private func deleteStation(_ station: Station) {
        modelContext.delete(station)

        do {
            try modelContext.save()
        } catch {
            print("Error deleting station: \(error)")
        }

        // Adjust currentTabIndex if necessary
        if currentTabIndex >= stations.count && !stations.isEmpty {
            currentTabIndex = stations.count - 1
        }
    }

}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Station.self, configurations: config)
    let sampleStation = Station(
        id: "900058101",
        name: "S Südkreuz Bhf (Berlin)",
        latitude: 52.475501,
        longitude: 13.365548,
        products: [.suburbanTrain, .bus, .regionalTrain, .highSpeedTrain],
    )
    container.mainContext.insert(sampleStation)

    return MainView()
        .modelContainer(container)
        .environment(\.font, Font.dNormal)
        .environmentObject(LiveActivityManager())
        .environmentObject(AppSettings())
}
