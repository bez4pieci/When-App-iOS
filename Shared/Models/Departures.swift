import Foundation

struct Line: Decodable {
    let name: String
    let productName: String
    let product: Product
}

struct StationName: Codable, Hashable {
    let name: String
    let extraName: String?  // E.g., Bahnhof, Hauptbahnhof, etc.
    let extraShortName: String?  // E.g., Hbf
    let extraInfo: String?  // E.g., Gleis 1-8
    let extraPlace: String?  // E.g., Berlin, BAR, etc., the name in brackets after the station name

    init(
        name: String, extraName: String? = nil, extraShortName: String? = nil,
        extraInfo: String? = nil, extraPlace: String? = nil
    ) {
        self.name = name
        self.extraName = extraName
        self.extraShortName = extraShortName
        self.extraInfo = extraInfo
        self.extraPlace = extraPlace
    }

    init(name: String) {
        self.name = name
        self.extraName = nil
        self.extraShortName = nil
        self.extraInfo = nil
        self.extraPlace = nil
    }
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
