import SwiftData
import SwiftUI
import TripKit

struct DepartureRow: View {
    let departure: Departure

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Line
            //            HStack() {
            //                Text(departure.line.label ?? "")
            //                    .padding(.horizontal, 6)
            //                    .padding(.vertical, 2)
            //                    .font(Font.custom("DepartureMono-Regular", size: 16))
            //                    .background(Color(hex: departure.line.style?.backgroundColor ?? 0x808080))
            //                    .foregroundColor(Color(hex: departure.line.style?.foregroundColor ?? 0x000000))
            //                    .cornerRadius(departure.line.style?.shape == .rounded ? 4 : departure.line.style?.shape == .circle ? 100 : 0)
            //                Spacer()
            //            }
            //            .frame(width: 50)

            HStack {
                Text(departure.line.label ?? "")
                Spacer()
                Text(timeString)
                    .foregroundColor(departureColor)
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
    }

    private var timeString: String {
        if let predictedTime = departure.predictedTime {
            return predictedTime.formatTime()
        }
        return departure.plannedTime.formatTime()
    }

    private var departureColor: Color {
        if let predictedTime = departure.predictedTime,
            predictedTime > departure.plannedTime
        {
            return .red
        }
        return Color.dDefault
    }
}
