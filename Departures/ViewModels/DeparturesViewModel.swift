import Foundation
import SwiftData
import SwiftUI
import TripKit

@Observable
class DeparturesViewModel {
    private var settings: Settings
    private var liveActivityManager: LiveActivityManager
    var departures: [Departure] = []
    var isLoading = false
    var lastUpdate = Date()

    init(settings: Settings, liveActivityManager: LiveActivityManager) {
        self.settings = settings
        self.liveActivityManager = liveActivityManager
    }

    var filteredDepartures: [Departure] {
        departures.filter { departure in
            // Filter by cancelled status
            if !settings.showCancelledDepartures && departure.cancelled {
                return false
            }

            // Filter by transport type
            if let product = departure.line.product {
                return settings.isProductEnabled(product)
            }

            // If no product info, show by default
            return true
        }
    }

    func loadDepartures(for station: Station) async {
        isLoading = true
        defer { isLoading = false }

        // Create a task to ensure minimum loading time
        async let minimumLoadingTime = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second
        }

        let provider = BvgProvider(apiAuthorization: AppConfig.bvgApiAuthorization)
        let (_, result) = await provider.queryDepartures(stationId: station.id)

        // Wait for both the API call and minimum loading time to complete
        _ = await (minimumLoadingTime, result)

        switch result {
        case .success(let stationDepartures):
            await MainActor.run {
                self.departures = stationDepartures.flatMap { $0.departures }
                self.lastUpdate = Date()

                // Update live activity if active with filtered departures
                if liveActivityManager.isLiveActivityActive {
                    liveActivityManager.updateLiveActivity(
                        departures: self.filteredDepartures)
                }
            }
        case .invalidStation:
            print("Invalid station id")
        case .failure(let error):
            print("Error loading departures: \(error)")
        }
    }
}
