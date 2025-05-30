import SwiftData
import SwiftUI
import TripKit

struct DepartureRow: View {
    let departure: Departure

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(departure.line.label ?? "")
                Spacer()
                Text(timeString)
                    .foregroundColor(timeColor)
            }
            .font(Font.dLarge)
            .strikethrough(departure.cancelled)

            HStack(spacing: 8) {
                Text(departure.destination?.name ?? "")
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
