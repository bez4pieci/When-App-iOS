import SwiftData
import SwiftUI

struct DepartureBoard: View {
    @EnvironmentObject private var liveActivityManager: LiveActivityManager
    let station: Station
    let departures: [DepartureInfo]

    var body: some View {
        // Use VStack instead of LazyVStack for better performance
        VStack(spacing: 0) {
            ForEach(departures, id: \.id) { departure in
                DepartureRow(departure: departure)

                if departure != departures.last {
                    DefaultDivider()
                }
            }
        }
    }
}

private struct DepartureRow: View {
    let departure: DepartureInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(departure.line.name ?? departure.line.label ?? "")
                Spacer()
                Text(timeString)
                    .foregroundColor(timeColor)
            }
            .font(Font.dLarge)
            .strikethrough(departure.cancelled)

            HStack(spacing: 8) {
                Text(destination)
                    .lineLimit(1)
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
        .opacity(departure.cancelled ? 0.25 : 1)
    }

    private var destination: String {
        if let place = departure.destination.place,
            let name = departure.destination.name,
            place != "Berlin"
        {
            return "\(place), \(name)"
        }

        return departure.destination.name ?? ""
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
