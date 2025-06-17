import SwiftData
import SwiftUI
import TripKit

struct StationTab: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @EnvironmentObject private var liveActivityManager: LiveActivityManager

    let station: Station
    let departuresViewModel: DeparturesViewModel
    let offset: Binding<Double>

    private var headerHeight = 240.0
    private var cornerRadius = AppConfig.cornerRadius

    init(station: Station, departuresViewModel: DeparturesViewModel, offset: Binding<Double>) {
        self.station = station
        self.departuresViewModel = departuresViewModel
        self.offset = offset
    }

    var body: some View {
        ScrollView {
            Color.clear
                .frame(height: headerHeight + 20)

            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    liveToggle

                    VStack(spacing: 0) {
                        VStack(spacing: 0) {
                            DepartureBoard(
                                station: station,
                                departures: departuresViewModel.filteredDepartures(for: station)
                            )
                        }
                        .background(Color.dBackground)
                        .clipShape(
                            .rect(
                                cornerSize: .init(
                                    width: cornerRadius, height: cornerRadius),
                                style: .continuous)
                        )
                        .offset(y: offset.wrappedValue >= 120 ? -(offset.wrappedValue - 120) : 0)
                    }
                    .clipShape(
                        .rect(
                            cornerSize: .init(
                                width: cornerRadius, height: cornerRadius),
                            style: .continuous)
                    )
                }
                .offset(y: offset.wrappedValue >= 120 ? offset.wrappedValue - 120 : 0)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 60 + safeAreaInsets.bottom)
        }
        .refreshable {
            await departuresViewModel.loadDepartures(for: station)
        }
        //        .task {
        //            await departuresViewModel.loadDepartures(for: station)
        //        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            return geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, new in
            offset.wrappedValue = new
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
                        isActive: isActive, station: station)
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
                await departuresViewModel.loadDepartures(for: station)
                liveActivityManager.startLiveActivity(
                    station: station,
                    departures: departuresViewModel.filteredDepartures(for: station)
                )
            }
        } else {
            liveActivityManager.stopAllActivities()
        }
    }
}
