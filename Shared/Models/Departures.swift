import Foundation

struct Line: Decodable {
    let name: String
    let productName: String
    let product: Product
}

struct Departure: Decodable, Hashable {
    let id: String
    let plannedTime: Date
    let predictedTime: Date?
    let line: Line
    let destination: StationName
    let isCancelled: Bool

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(plannedTime)
        hasher.combine(predictedTime)
        hasher.combine(destination.name)
        hasher.combine(line.name)
    }

    static func == (lhs: Departure, rhs: Departure) -> Bool {
        return lhs.id == rhs.id
    }
}
