import ActivityKit
import SwiftUI
import WidgetKit

struct DeparturesLiveActivityView: View {
    let context: ActivityViewContext<DeparturesActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(context.attributes.stationName)
                    .font(Font.dNormal)
                    .foregroundColor(Color.dDefault)
                Spacer()
                Text(context.state.lastUpdate, style: .timer)
                    .font(Font.dSmall)
                    .foregroundColor(Color.dDefault)
                    .multilineTextAlignment(.trailing)

            }

            // Departures list
            VStack(spacing: 4) {
                ForEach(Array(context.state.departures.prefix(4).enumerated()), id: \.offset) {
                    index, departure in
                    HStack(spacing: 8) {
                        Text(departure.lineLabel)
                            .foregroundColor(Color.dDefault)

                        // Destination
                        Text(departure.destination)
                            .lineLimit(1)
                            .foregroundColor(Color.dDefault)

                        Spacer()

                        if let predictedTime = departure.predictedTime,
                            predictedTime > departure.plannedTime
                        {
                            Text(departure.plannedTime.formatTime())
                                .strikethrough()
                                .foregroundColor(.black.opacity(0.5))
                        }

                        Text((departure.predictedTime ?? departure.plannedTime).formatTime())
                            .foregroundColor(
                                departure.predictedTime != nil
                                    && departure.predictedTime! > departure.plannedTime
                                    ? .red : Color.dDefault)
                    }
                    .font(Font.dSmall)
                    .opacity(departure.isCancelled ? 0.5 : 1.0)

                    // if index < min(3, context.state.departures.count - 1) {
                    //     Divider()
                    //         .background(Color.black.opacity(0.2))
                    // }
                }
            }
        }
        .padding([.top, .bottom], 20)
        .padding([.leading, .trailing], 12)
    }
}
