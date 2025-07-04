import ActivityKit
import WidgetKit

struct DeparturesActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties
        var departures: [DepartureInfo]
        var lastUpdate: Date

        struct DepartureInfo: Codable, Hashable {
            let lineLabel: String
            let destination: StationName
            let plannedTime: Date
            let predictedTime: Date?
            let isCancelled: Bool
        }
    }

    // Fixed non-changing properties
    let stationName: String
    let stationId: String
}
