import MapKit
import SwiftData
import SwiftUI
import TripKit

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Station.selectedAt, order: .reverse) private var stations: [Station]
    @State private var viewModel = DeparturesViewModel()

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
                            departures: viewModel.filteredDepartures,
                            onRefresh: {
                                await viewModel.loadDepartures(for: station)
                            }
                        )
                    } else {
                        NoStation(onSelectStation: { showStationSelection = true })
                    }
                }
                .ignoresSafeArea()
                .navigationBarHidden(true)
            }
            .task {
                if let station = selectedStation {
                    await viewModel.loadDepartures(for: station)
                }
            }
            .onChange(of: selectedStation) { _, newStation in
                if let station = newStation {
                    Task {
                        await viewModel.loadDepartures(for: station)
                    }
                }
            }
            .sheet(isPresented: $showStationSelection) {
                StationSelectionView()
            }
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
