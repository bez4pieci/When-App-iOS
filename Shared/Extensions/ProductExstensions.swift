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

    var shortLabel: String {
        switch self {
        case .suburbanTrain: return "S"
        case .subway: return "U"
        case .tram: return "Tram"
        case .bus: return "Bus"
        case .regionalTrain: return "RE"
        case .ferry: return "F"
        case .highSpeedTrain: return "IC/ICE"
        case .onDemand: return "On Demand"
        case .cablecar: return "Cable Car"
        default: return "?"  // For future products
        }
    }

    var name: String {
        switch self {
        case .suburbanTrain: return "suburbanTrain"
        case .subway: return "subway"
        case .tram: return "tram"
        case .bus: return "bus"
        case .regionalTrain: return "regionalTrain"
        case .ferry: return "ferry"
        case .highSpeedTrain: return "highSpeedTrain"
        case .onDemand: return "onDemand"
        case .cablecar: return "cablecar"
        }
    }

    static func fromName(_ name: String) -> Product {
        switch name {
        case "suburbanTrain": return .suburbanTrain
        case "subway": return .subway
        case "tram": return .tram
        case "bus": return .bus
        case "regionalTrain": return .regionalTrain
        case "ferry": return .ferry
        case "highSpeedTrain": return .highSpeedTrain
        case "onDemand": return .onDemand
        case "cablecar": return .cablecar
        default: return .subway
        }
    }
}
