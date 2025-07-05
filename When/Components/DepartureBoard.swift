import SwiftData
import SwiftUI

struct DepartureBoard: View {
    @ObserveInjection var redraw

    @EnvironmentObject private var liveActivityManager: LiveActivityManager
    let station: Station
    let departures: [Departure]

    var body: some View {
        // Use VStack instead of LazyVStack for better performance
        VStack(spacing: 0) {
            ForEach(departures) { departure in
                DepartureRow(departure: departure)

                if departure != departures.last {
                    DefaultDivider()
                }
            }
        }
        .enableInjection()
    }
}

private struct DepartureRow: View {
    let departure: Departure

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(departure.line.name)
                Spacer()
                Text(timeString)
                    .foregroundColor(timeColor)
            }
            .font(Font.dLarge)
            .strikethrough(departure.isCancelled)

            HStack(spacing: 8) {
                Text(departure.destination.forDisplay).lineLimit(1)

                Spacer()

                if let predictedTime = departure.predictedTime,
                    predictedTime > departure.plannedTime
                {
                    Text(departure.plannedTime.formatTime())
                        .strikethrough()
                        .foregroundColor(Color.dMedium)
                }

            }
            .font(Font.dSmall)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .opacity(departure.isCancelled ? 0.25 : 1)
    }

    private var timeString: String {
        if let predictedTime = departure.predictedTime {
            return predictedTime.formatTime()
        }
        return departure.plannedTime.formatTime()
    }

    private var timeColor: Color {
        if let predictedTime = departure.predictedTime,
            predictedTime > departure.plannedTime
        {
            return .red
        }

        return .dDefault
    }
}
