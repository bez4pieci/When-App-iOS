import SwiftData
import SwiftUI
import TripKit

struct DepartureBoard: View {
    @EnvironmentObject private var liveActivityManager: LiveActivityManager
    let station: Station
    let departures: [Departure]
    let onRefresh: () async -> Void

    var body: some View {
        VStack(spacing: 0) {
            LazyVStack(spacing: 0) {
                ForEach(Array(departures.enumerated()), id: \.offset) { index, departure in
                    DepartureRow(departure: departure)
                    DefaultDivider()
                }
            }
        }
    }
}
