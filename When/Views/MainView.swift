import SwiftData
import SwiftUI
import TripKit

struct MainView: View {
    @EnvironmentObject private var liveActivityManager: LiveActivityManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Station.selectedAt, order: .reverse) private var stations: [Station]
    @State private var viewModel = DeparturesViewModel()

    @State private var showStationSelection = false

    private var headerHeight = 240.0
    @State private var offset = 0.0
    private var cornerRadius = 12

    private var selectedStation: Station? {
        stations.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ZStack(alignment: .top) {
                    HeaderMap(station: selectedStation, offset: offset)
                        .zIndex(1)

                    MainHeader(onGearButtonTap: { showStationSelection = true })
                        .zIndex(5)

                    ScrollView {
                        Color.clear
                            .frame(height: headerHeight + 20)

                        VStack(spacing: 0) {
                            VStack(spacing: 20) {
                                liveToggle

                                VStack(spacing: 0) {
                                    VStack(spacing: 0) {
                                        if let station = selectedStation {
                                            DepartureBoard(
                                                station: station,
                                                departures: viewModel.filteredDepartures,
                                                onRefresh: {
                                                    await viewModel.loadDepartures(for: station)
                                                }
                                            )
                                        } else {
                                            NoStation(onSelectStation: {
                                                showStationSelection = true
                                            })
                                        }
                                    }
                                    .background(Color.dBackground)
                                    .clipShape(
                                        .rect(
                                            cornerSize: .init(
                                                width: cornerRadius, height: cornerRadius),
                                            style: .continuous)
                                    )
                                    .offset(y: offset >= 120 ? -(offset - 120) : 0)
                                }
                                .clipShape(
                                    .rect(
                                        cornerSize: .init(
                                            width: cornerRadius, height: cornerRadius),
                                        style: .continuous)
                                )
                            }
                            .offset(y: offset >= 120 ? offset - 120 : 0)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .zIndex(2)
                    .refreshable {
                        if let station = selectedStation {
                            await viewModel.loadDepartures(for: station)
                        }
                    }
                    .onScrollGeometryChange(for: CGFloat.self) { geometry in
                        return geometry.contentOffset.y + geometry.contentInsets.top
                    } action: { _, new in
                        self.offset = new
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

    var liveToggle: some View {
        HStack {
            Text("Show Live")
                .font(Font.dNormal)
                .foregroundColor(Color.dDefault)
            Spacer()
            Toggle("", isOn: $liveActivityManager.isLiveActivityActive)
                .labelsHidden()
                .tint(Color.dDefault)
                .onChange(of: liveActivityManager.isLiveActivityActive) {
                    _, isActive in
                    handleLiveActivityToggle(
                        isActive: isActive, station: selectedStation!)
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.dBackground)
        .clipShape(
            .rect(
                cornerSize: .init(
                    width: cornerRadius, height: cornerRadius),
                style: .continuous)
        )
    }

    func handleLiveActivityToggle(isActive: Bool, station: Station) {
        if isActive {
            Task {
                await viewModel.loadDepartures(for: station)
                liveActivityManager.startLiveActivity(
                    station: station, departures: viewModel.filteredDepartures)
            }
        } else {
            liveActivityManager.stopAllActivities()
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
