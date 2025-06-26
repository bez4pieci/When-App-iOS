import FirebaseAnalytics
import SwiftData
import SwiftUI
import TripKit

struct MainView: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.modelContext) private var modelContext
    @Query() private var stations: [Station]
    @EnvironmentObject private var liveActivityManager: LiveActivityManager

    @State private var showStationSelection = false
    @State private var currentTabIndex = 0
    @State private var scrollOffsets: [String: Double] = [:]
    @State private var departuresViewModel = DeparturesViewModel()

    private var headerHeight = 240.0
    private var cornerRadius = AppConfig.cornerRadius

    private var currentStation: Station? {
        guard !stations.isEmpty && currentTabIndex < stations.count else { return nil }
        return stations[currentTabIndex]
    }

    private var currentScrollOffset: Double {
        guard let station = currentStation else { return 0.0 }
        return scrollOffsets[station.id] ?? 0.0
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                HeaderMap(
                    station: currentStation,
                    headerHeight: headerHeight,
                    offset: currentScrollOffset
                )
                .zIndex(1)

                MainHeader(
                    station: currentStation,
                    departuresViewModel: departuresViewModel,
                    onSettingsButtonTap: {
                        showStationSelection = true
                    }
                )
                .zIndex(5)

                TabView(selection: $currentTabIndex) {
                    ForEach(Array(stations.enumerated()), id: \.element.id) { index, station in
                        StationTab(
                            station: station,
                            departuresViewModel: departuresViewModel,
                            headerHeight: headerHeight,
                            offset: $scrollOffsets[station.id]
                        )
                        .tag(index)
                        .onAppear {
                            Analytics.logEvent(
                                AnalyticsEventScreenView,
                                parameters: [
                                    AnalyticsParameterScreenName: "station_tab",
                                    AnalyticsParameterScreenClass: "StationTab",
                                    "station_name": station.name,
                                    "show_cancelled_departures": station.showCancelledDepartures
                                        .description,
                                    "products": station.productStringsData,
                                    "enabled_products": station.enabledProductStringsData,
                                ])
                        }
                    }

                    NoStation(onSelectStation: { showStationSelection = true })
                        .tag(stations.count)
                        .onAppear {
                            Analytics.logEvent(
                                AnalyticsEventScreenView,
                                parameters: [
                                    AnalyticsParameterScreenName: "no_station_tab",
                                    AnalyticsParameterScreenClass: "NoStationTab",
                                ])
                        }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .zIndex(2)
            }
            .ignoresSafeArea()
            .navigationBarHidden(true)
            .sheet(isPresented: $showStationSelection) {
                StationSettingsView(
                    station: currentStation,
                    onStationDelete: onStationDeleted,
                    onStationChange: onStationChanged
                )
            }
        }
    }

    private func onStationDeleted(_ station: Station) {
        // Clean up data for deleted station
        scrollOffsets.removeValue(forKey: station.id)
        departuresViewModel.delete(for: station)

        // Adjust currentTabIndex if necessary
        if currentTabIndex >= stations.count && !stations.isEmpty {
            currentTabIndex = stations.count - 1
        }

        // Stop live activity for the deleted station
        Task {
            await liveActivityManager.stopLiveActivity(for: station.id)
        }
    }

    private func onStationChanged(oldStation: Station, newStation: Station) {
        // Stop live activity for the old station
        Task {
            await liveActivityManager.stopLiveActivity(for: oldStation.id)
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
