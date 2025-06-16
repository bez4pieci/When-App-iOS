import Foundation
import SwiftData
import SwiftUI
import TripKit

@Observable
class DeparturesViewModel {
    private var station: Station?
    var departures: [Departure] = []
    var isLoading = false
    var lastUpdate = Date()

    init() {
        // No longer takes settings in init
    }

    var filteredDepartures: [Departure] {
        guard let station = station else { return [] }

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

    func loadDepartures(for station: Station) async {
        self.station = station
        isLoading = true
        defer { isLoading = false }

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
            departures = stationDepartures.flatMap { $0.departures }
            lastUpdate = Date()
            print("Departures: Fetched \(departures.count) departures")

        case .invalidStation:
            print("Departures: Invalid station id")

        case .failure(let error):
            print("Departures: Error loading departures: \(error)")

        }
    }
}
