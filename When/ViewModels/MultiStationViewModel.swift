import Foundation
import SwiftData
import SwiftUI
import TripKit

@Observable
class MultiStationViewModel {
    var departuresViewModels: [String: DeparturesViewModel] = [:]
    var currentStationIndex: Int = 0

    func getDeparturesViewModel(for station: Station) -> DeparturesViewModel {
        if let existing = departuresViewModels[station.id] {
            return existing
        }

        let newViewModel = DeparturesViewModel()
        departuresViewModels[station.id] = newViewModel
        return newViewModel
    }

    func removeDeparturesViewModel(for stationId: String) {
        departuresViewModels.removeValue(forKey: stationId)
    }

    func loadDepartures(for station: Station) async {
        let viewModel = getDeparturesViewModel(for: station)
        await viewModel.loadDepartures(for: station)
    }
}
