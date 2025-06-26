import Refresher
import SwiftData
import SwiftUI
import TripKit

struct StationTab: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets

    let station: Station
    let departuresViewModel: DeparturesViewModel
    let headerHeight: Double
    let offset: Binding<Double>

    private var cornerRadius = AppConfig.cornerRadius

    init(
        station: Station,
        departuresViewModel: DeparturesViewModel,
        headerHeight: Double,
        offset: Binding<Double>
    ) {
        self.station = station
        self.departuresViewModel = departuresViewModel
        self.headerHeight = headerHeight
        self.offset = offset
    }

    var body: some View {
        ScrollView {
            Color.clear
                .frame(height: headerHeight)

            VStack(spacing: 0) {
                VStack(spacing: 20) {
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
        .refresher(
            style: .overlay,
            config: Config(
                headerShimMaxHeight: RefreshSpinner.height,
                defaultSpinnerSpinnerStopPoint: -RefreshSpinner.height,
                defaultSpinnerOffScreenPoint: -RefreshSpinner.height,
            ),
            refreshView: RefreshSpinner.init
        ) {
            await departuresViewModel.loadDepartures(for: station)
        }
        .task {
            // Automatic refresh when tab appears - throttled to max once per 30 seconds
            await departuresViewModel.loadDeparturesIfNeeded(for: station)
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            return geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, new in
            offset.wrappedValue = new
        }
    }
}
