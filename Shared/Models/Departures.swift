import Foundation

struct Line: Decodable {
    let name: String
    let productName: String
    let product: Product
}

struct Departure: Decodable, Hashable, Identifiable {
    let id: String
    let plannedTime: Date
    let predictedTime: Date?
    let line: Line
    let destination: StationName
    let isCancelled: Bool

    // Include all properties in the hash function,
    // so that the view is re-rendered when a departure is updated,
    // e.g., delayed or cancelled.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(plannedTime)
        hasher.combine(predictedTime)
        hasher.combine(destination.raw)
        hasher.combine(line.name)
        hasher.combine(isCancelled)
    }

    // Use hashValue comparison, instead of id comparison,
    // so that the view is re-rendered when a departure is updated,
    // e.g., delayed or cancelled.
    static func == (lhs: Departure, rhs: Departure) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
