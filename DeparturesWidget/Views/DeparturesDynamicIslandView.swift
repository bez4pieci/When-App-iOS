// import ActivityKit
// import SwiftUI
// import WidgetKit

// func makeDynamicIsland(context: ActivityViewContext<DeparturesActivityAttributes>) -> DynamicIsland
// {
//     DynamicIsland {
//         // Expanded region
//         DynamicIslandExpandedRegion(.leading) {
//             VStack(alignment: .leading, spacing: 2) {
//                 Text(context.attributes.stationName)
//                     .font(.caption)
//                     .foregroundColor(.gray)
//                 ForEach(
//                     Array(context.state.departures.prefix(2).enumerated()), id: \.offset
//                 ) { index, departure in
//                     HStack(spacing: 4) {
//                         Text(departure.lineLabel)
//                             .font(.caption2)
//                             .padding(.horizontal, 4)
//                             .padding(.vertical, 1)
//                             .cornerRadius(4)
//                         Text((departure.predictedTime ?? departure.plannedTime).formatTime())
//                             .font(.caption)
//                             .fontWeight(.semibold)
//                     }
//                 }
//             }
//         }

//         DynamicIslandExpandedRegion(.trailing) {
//             VStack(alignment: .trailing, spacing: 2) {
//                 ForEach(
//                     Array(context.state.departures.dropFirst(2).prefix(2).enumerated()),
//                     id: \.offset
//                 ) { index, departure in
//                     HStack(spacing: 4) {
//                         Text(departure.lineLabel)
//                             .font(.caption2)
//                             .padding(.horizontal, 4)
//                             .padding(.vertical, 1)
//                             .cornerRadius(4)
//                         Text((departure.predictedTime ?? departure.plannedTime).formatTime())
//                             .font(.caption)
//                             .fontWeight(.semibold)
//                     }
//                 }
//             }
//         }

//         DynamicIslandExpandedRegion(.bottom) {
//             Text("Updated \(context.state.lastUpdate, style: .relative) ago")
//                 .font(.caption2)
//                 .foregroundColor(.gray)
//         }
//     } compactLeading: {
//         // Compact left side
//         HStack(spacing: 2) {
//             if let firstDeparture = context.state.departures.first {
//                 Text(firstDeparture.lineLabel)
//                     .font(.caption2)
//                     .padding(.horizontal, 3)
//                     .padding(.vertical, 1)
//                     .cornerRadius(3)
//             }
//         }
//     } compactTrailing: {
//         // Compact right side
//         if let firstDeparture = context.state.departures.first {
//             Text((firstDeparture.predictedTime ?? firstDeparture.plannedTime).formatTime())
//                 .font(.caption)
//                 .fontWeight(.medium)
//         }
//     } minimal: {
//         // Minimal view
//         if let firstDeparture = context.state.departures.first {
//             Text(firstDeparture.lineLabel)
//                 .font(.caption2)
//                 .padding(.horizontal, 3)
//                 .padding(.vertical, 1)
//                 .cornerRadius(3)
//         }
//     }
// }
