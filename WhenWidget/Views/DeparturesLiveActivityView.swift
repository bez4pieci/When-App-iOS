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
                // Text("Updated \(context.state.lastUpdate, style: .relative) ago")
                //     .font(.caption)
                //     .foregroundColor(.black.opacity(0.6))
            }

            // Departures list
            VStack(spacing: 4) {
                ForEach(Array(context.state.departures.prefix(4).enumerated()), id: \.offset) {
                    index, departure in
                    HStack(spacing: 8) {
                        Text(departure.lineLabel)
                            .strikethrough(departure.isCancelled)
                            .foregroundColor(Color.dDefault)

                        Text(departure.destination.name)
                            .lineLimit(1)
                            .strikethrough(departure.isCancelled)
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
                            .strikethrough(departure.isCancelled)
                            .foregroundColor(
                                departure.predictedTime != nil
                                    && departure.predictedTime! > departure.plannedTime
                                    ? .red : Color.dDefault)
                    }
                    .font(Font.dSmall)
                    .opacity(departure.isCancelled ? 0.25 : 1.0)
                }
            }
        }
        .padding([.top, .bottom], 20)
        .padding([.leading, .trailing], 12)
    }
}
