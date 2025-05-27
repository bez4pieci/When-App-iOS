import MapKit
import SwiftData
import SwiftUI
import TripKit

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var liveActivityManager: LiveActivityManager
    @Query(sort: \Station.selectedAt, order: .reverse) private var stations: [Station]
    @StateObject private var settings = Settings()

    @State private var departures: [Departure] = []
    @State private var isLoading = false
    @State private var showStationSelection = false
    @State private var lastUpdate = Date()

    private var selectedStation: Station? {
        stations.first
    }

    private var filteredDepartures: [Departure] {
        departures.filter { departure in
            // Filter by cancelled status
            if !settings.showCancelledDepartures && departure.cancelled {
                return false
            }

            // Filter by transport type
            if let product = departure.line.product {
                return settings.isProductEnabled(product)
            }

            // If no product info, show by default
            return true
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.yellow.ignoresSafeArea()

                VStack(spacing: 0) {
                    HeaderMapView(
                        station: selectedStation,
                        onGearButtonTap: { showStationSelection = true }
                    )

                    if selectedStation != nil {
                        // Live Activity Toggle
                        HStack {
                            Text("Show Live")
                                .font(Font.dNormal)
                                .foregroundColor(Color.dDefault)
                            Spacer()
                            Toggle("", isOn: $liveActivityManager.isLiveActivityActive)
                                .labelsHidden()
                                .onChange(of: liveActivityManager.isLiveActivityActive) {
                                    _, isActive in
                                    handleLiveActivityToggle(isActive: isActive)
                                }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)

                        DefaultDivider()

                        DepartureBoardView(
                            departures: filteredDepartures,
                            onRefresh: loadDepartures
                        )
                    } else {
                        NoStationView(onSelectStation: { showStationSelection = true })
                    }
                }
                .ignoresSafeArea()
                .navigationBarHidden(true)
            }
            .task {
                await loadDepartures()
            }
            .onChange(of: selectedStation) { _, newStation in
                if newStation != nil {
                    Task {
                        await loadDepartures()
                    }
                }
            }
            .sheet(isPresented: $showStationSelection) {
                StationSelectionView()
                    .environmentObject(settings)
            }
            .onReceive(NotificationCenter.default.publisher(for: .liveActivityNeedsUpdate)) { _ in
                Task {
                    await loadDepartures()
                }
            }
        }
    }

    private func loadDepartures() async {
        guard let station = selectedStation else { return }

        isLoading = true
        defer { isLoading = false }

        // Create a task to ensure minimum loading time
        async let minimumLoadingTime = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second
        }

        do {
            let provider = BvgProvider(apiAuthorization: AppConfig.bvgApiAuthorization)

            let (_, result) = await provider.queryDepartures(stationId: station.id)

            // Wait for both the API call and minimum loading time to complete
            _ = await (minimumLoadingTime, result)

            switch result {
            case .success(let stationDepartures):
                await MainActor.run {
                    self.departures = stationDepartures.flatMap { $0.departures }
                    self.lastUpdate = Date()

                    // Update live activity if active with filtered departures
                    if liveActivityManager.isLiveActivityActive {
                        liveActivityManager.updateLiveActivity(departures: self.filteredDepartures)
                    }
                }
            case .invalidStation:
                print("Invalid station id")
            case .failure(let error):
                print("Error loading departures: \(error)")
            }
        } catch {
            print("Error loading departures: \(error)")
        }
    }

    private func handleLiveActivityToggle(isActive: Bool) {
        guard let station = selectedStation else { return }

        if isActive {
            liveActivityManager.startLiveActivity(station: station, departures: filteredDepartures)
        } else {
            liveActivityManager.stopLiveActivity()
        }
    }
}
