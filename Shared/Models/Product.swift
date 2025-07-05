import Foundation

enum Product: String, CaseIterable, Codable {
    case suburban
    case subway
    case tram
    case bus
    case ferry
    case regional
    case express

    var name: String { self.rawValue }

    var displayName: String {
        switch self {
        case .suburban: return "S-Bahn"
        case .subway: return "U-Bahn"
        case .tram: return "Tram"
        case .bus: return "Bus"
        case .ferry: return "Ferry"
        case .regional: return "RB/RE"
        case .express: return "IC/ICE"
        }
    }

    var shortName: String {
        switch self {
        case .suburban: return "S"
        case .subway: return "U"
        case .tram: return "Tram"
        case .bus: return "Bus"
        case .ferry: return "F"
        case .regional: return "RB/RE"
        case .express: return "IC/ICE"
        }
    }
}
