import Foundation
import TripKit

extension Product {
    var label: String {
        switch self {
        case .suburbanTrain: return "S-Bahn"
        case .subway: return "U-Bahn"
        case .tram: return "Tram"
        case .bus: return "Bus"
        case .regionalTrain: return "Regional Train"
        case .ferry: return "Ferry"
        case .highSpeedTrain: return "ICE/IC"
        case .onDemand: return "On Demand"
        case .cablecar: return "Cable Car"
        default: return "Other"  // For future products
        }
    }
}
