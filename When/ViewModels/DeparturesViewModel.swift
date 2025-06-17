import Foundation
import SwiftData
import SwiftUI
import TripKit

@Observable
class DeparturesViewModel {
    private var stationDepartures: [String: [Departure]] = [:]
    private var loadingStations: Set<String> = []
    private var lastUpdates: [String: Date] = [:]

    init() {}

    // Get departures for a specific station
    func departures(for station: Station) -> [Departure] {
        return stationDepartures[station.id] ?? []
    }

    // Get filtered departures for a specific station
    func filteredDepartures(for station: Station) -> [Departure] {
        let departures = self.departures(for: station)

        return departures.filter { departure in
            // Filter by cancelled status
            if !station.showCancelledDepartures && departure.cancelled {
                return false
            }

            // Filter by transport type
            if let product = departure.line.product {
                return station.isProductEnabled(product)
            }

            // If no product info, show by default
            return true
        }
    }

    // Check if a station is loading
    func isLoading(for station: Station) -> Bool {
        return loadingStations.contains(station.id)
    }

    // Get last update time for a station
    func lastUpdate(for station: Station) -> Date? {
        return lastUpdates[station.id]
    }

    func loadDepartures(for station: Station) async {
        loadingStations.insert(station.id)
        defer { loadingStations.remove(station.id) }

        print("Departures: Loading departures for \(station.name)...")
        print("Departures: Products: \(station.productStrings)")
        print("Departures: Enabled products: \(station.enabledProductStrings)")

        // Create a task to ensure minimum loading time
        async let minimumLoadingTime = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second
        }

        let provider = BvgProvider(apiAuthorization: AppConfig.bvgApiAuthorization)
        let (_, result) = await provider.queryDepartures(
            stationId: station.id,
            maxDepartures: 40  // Larger number to allow for filtering
        )

        // Wait for both the API call and minimum loading time to complete
        _ = await (minimumLoadingTime, result)

        switch result {
        case .success(let stationDepartures):
            let departures = stationDepartures.flatMap { $0.departures }
            self.stationDepartures[station.id] = departures
            self.lastUpdates[station.id] = Date()
            print("Departures: Fetched \(departures.count) departures for \(station.name)")

        case .invalidStation:
            print("Departures: Invalid station id for \(station.name)")

        case .failure(let error):
            print("Departures: Error loading departures for \(station.name): \(error)")
        }
    }

    func delete(for station: Station) {
        stationDepartures.removeValue(forKey: station.id)
        lastUpdates.removeValue(forKey: station.id)
        loadingStations.remove(station.id)
    }
}
