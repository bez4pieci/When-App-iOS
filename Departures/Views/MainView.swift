import MapKit
import SwiftData
import SwiftUI
import TripKit

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Station.selectedAt, order: .reverse) private var stations: [Station]

    @State private var departures: [Departure] = []
    @State private var isLoading = false
    @State private var showStationSelection = false
    @State private var lastUpdate = Date()

    private var selectedStation: Station? {
        stations.first
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
                        DepartureBoardView(
                            departures: departures,
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
            }
        }
    }

    private func loadDepartures() async {
        guard let station = selectedStation else { return }

        isLoading = true
        defer { isLoading = false }

        // Create a task to ensure minimum loading time
        async let minimumLoadingTime = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)  // 1 second
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

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter
    }
}
