import SwiftData
import SwiftUI
import TripKit

struct DepartureBoard: View {
    @EnvironmentObject private var liveActivityManager: LiveActivityManager
    let station: Station
    let departures: [Departure]
    let onRefresh: () async -> Void

    var body: some View {
        // Use VStack instead of LazyVStack for better performance
        VStack(spacing: 0) {
            ForEach(departures, id: \.hash) { departure in
                DepartureRow(departure: departure)

                if departure != departures.last {
                    DefaultDivider()
                }
            }
        }
    }
}
