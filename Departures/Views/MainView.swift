import MapKit
import SwiftData
import SwiftUI
import TripKit

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: Settings
    @EnvironmentObject private var liveActivityManager: LiveActivityManager
    @Query(sort: \Station.selectedAt, order: .reverse) private var stations: [Station]
    @State private var viewModel: DeparturesViewModel?

    @State private var showStationSelection = false

    private var selectedStation: Station? {
        stations.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.yellow.ignoresSafeArea()

                VStack(spacing: 0) {
                    MainHeader(
                        station: selectedStation,
                        onGearButtonTap: { showStationSelection = true }
                    )

                    if let station = selectedStation {
                        DepartureBoard(
                            station: station,
                            departures: viewModel?.filteredDepartures ?? [],
                            onRefresh: {
                                if let station = selectedStation {
                                    Task {
                                        await viewModel?.loadDepartures(for: station)
                                    }
                                }
                            }
                        )
                    } else {
                        NoStation(onSelectStation: { showStationSelection = true })
                    }
                }
                .ignoresSafeArea()
                .navigationBarHidden(true)
            }
            .onAppear {
                // Initialize viewModel when the view appears
                viewModel = DeparturesViewModel(
                    settings: settings, liveActivityManager: liveActivityManager)
            }
            .task {
                if let station = selectedStation {
                    await viewModel?.loadDepartures(for: station)
                }
            }
            .onChange(of: selectedStation) { _, newStation in
                if let station = newStation {
                    Task {
                        await viewModel?.loadDepartures(for: station)
                    }
                }
            }
            .sheet(isPresented: $showStationSelection) {
                StationSelectionView()
            }
            .onReceive(NotificationCenter.default.publisher(for: .liveActivityNeedsUpdate)) { _ in
                if let station = selectedStation {
                    Task {
                        await viewModel?.loadDepartures(for: station)
                    }
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(for: .liveActivityNeedsBackgroundUpdate)
            ) { _ in
                print("MainView: Received a notification to fetch new departures")
                if let station = selectedStation {
                    Task {
                        await viewModel?.loadDepartures(for: station)
                    }
                }
            }
        }
    }
}
