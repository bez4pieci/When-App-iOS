import SwiftData
import SwiftUI
import TripKit

struct DepartureBoardView: View {
    let departures: [Departure]
    let onRefresh: () async -> Void

    var body: some View {
        ScrollView {
            Divider()
                .frame(height: 1)
                .overlay(.black.opacity(0.5))

            LazyVStack(spacing: 0) {
                ForEach(Array(departures.enumerated()), id: \.offset) { index, departure in
                    DepartureRow(departure: departure)

                    Divider()
                        .frame(height: 1)
                        .overlay(.black.opacity(0.5))
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
