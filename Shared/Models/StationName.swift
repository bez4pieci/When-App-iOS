import Foundation

struct StationName: Codable, Hashable {
    let name: String
    let extraName: String?  // E.g., Bahnhof, Hauptbahnhof, etc.
    let extraShortName: String?  // E.g., Hbf
    let extraInfo: String?  // E.g., Gleis 1-8
    let extraPlace: String?  // E.g., Berlin, BAR, etc., the name in brackets after the station name

    private enum CodingKeys: String, CodingKey {
        case name
        case extraName
        case extraShortName
        case extraInfo
        case extraPlace
    }

    var forDisplay: String {
        return (name + " " + (extraShortName ?? "")).trimmingCharacters(in: .whitespacesAndNewlines)
    }

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
