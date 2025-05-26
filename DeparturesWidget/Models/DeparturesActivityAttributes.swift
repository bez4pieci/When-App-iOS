import ActivityKit
import WidgetKit

struct DeparturesActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties
        var departures: [DepartureInfo]
        var lastUpdate: Date

        struct DepartureInfo: Codable, Hashable {
            let lineLabel: String
            let destination: String
            let plannedTime: Date
            let predictedTime: Date?
            let isCancelled: Bool
            let lineBackgroundColor: Int
            let lineForegroundColor: Int
        }
    }

    // Fixed non-changing properties
    let stationName: String
    let stationId: String
}
