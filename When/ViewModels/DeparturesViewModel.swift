import Foundation
import SwiftData
import SwiftUI

@Observable
class DeparturesViewModel {
    private var stationDepartures: [String: [Departure]] = [:]
    private var lastUpdates: [String: Date] = [:]

    // Throttling configuration
    private let automaticRefreshThrottleInterval: TimeInterval = 30.0  // 30 seconds

    // Get departures for a specific station
    func departures(for station: Station) -> [Departure] {
        return stationDepartures[station.id] ?? []
    }

    // Get last update time for a station
    func lastUpdate(for station: Station) -> Date? {
        return lastUpdates[station.id]
    }

    // Check if enough time has passed for automatic refresh
    private func shouldRefreshAutomatically(for station: Station) -> Bool {
        guard let lastUpdate = lastUpdates[station.id] else {
            // Never updated, should refresh
            return true
        }

        let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)
        return timeSinceLastUpdate >= automaticRefreshThrottleInterval
    }

    // Manual refresh - always executes, not throttled
    func loadDepartures(for station: Station) async {
        await load(for: station)
    }

    // Automatic refresh - throttled to prevent excessive API calls
    func loadDeparturesIfNeeded(for station: Station) async {
        guard shouldRefreshAutomatically(for: station) else {
            let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdates[station.id] ?? Date())
            let roundedTimeSinceLastUpdate = String(format: "%.2f", timeSinceLastUpdate)
            let lastUpdateTime =
                lastUpdates[station.id]?.formatted(date: .omitted, time: .shortened) ?? "never"
            print(
                """
                Departures: Skipping automatic refresh for \(station.name) - \
                last update \(roundedTimeSinceLastUpdate) seconds ago (\(lastUpdateTime))
                """)
            return
        }

        await load(for: station)
    }

    // Private method that performs the actual loading
    private func load(for station: Station) async {
        print(
            """
            Departures: Loading departures for \(station.name), \
            enabled products: \(station.enabledProductStrings), \
            showCancelledDepartures: \(station.showCancelledDepartures)
            """)

        // Create a task to ensure minimum loading time
        async let minimumLoadingTime = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
        }

        // Create TransportService instance as needed
        let transportService = TransportService()
        async let departuresTask = transportService.queryDepartures(
            stationId: station.id,
            products: Array(station.enabledProducts),
            showCancelledDepartures: station.showCancelledDepartures
        )

        // Wait for both the API call and minimum loading time to complete
        let (_, departures) = await (minimumLoadingTime, departuresTask)

        self.stationDepartures[station.id] = departures
        self.lastUpdates[station.id] = Date()
        print("Departures: Fetched \(departures.count) departures for \(station.name)")
    }

    func delete(for station: Station) {
        stationDepartures.removeValue(forKey: station.id)
        lastUpdates.removeValue(forKey: station.id)
    }
}
