import SwiftData
import SwiftUI
import TripKit

struct DepartureBoardView: View {
    let departures: [Departure]
    let onRefresh: () async -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(departures.enumerated()), id: \.offset) { index, departure in
                    DepartureRow(departure: departure)
                    DefaultDivider()
                }
            }
        }
        .refreshable {
            await onRefresh()
        }
    }
}

#Preview {
    DepartureBoardView(
        departures: [],
        onRefresh: {}
    )
}
