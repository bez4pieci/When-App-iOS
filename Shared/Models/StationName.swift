import Foundation

struct StationName: Codable, Hashable {
    let clean: String
    let raw: String?  // Full name from the API
    let suffix: String?  // E.g., Bahnhof, Hauptbahnhof, etc.
    let suffixShort: String?  // E.g., Hbf
    let extraInfo: String?  // E.g., Gleis 1-8
    let place: String?  // E.g., Berlin, BAR, etc., the name in brackets after the station name

    private enum CodingKeys: String, CodingKey {
        case clean
        case raw
        case suffix
        case suffixShort
        case extraInfo
        case place
    }

    var forDisplay: String {
        return (clean + " " + (suffixShort ?? "")).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var forTracking: String {
        return raw ?? forDisplay
    }

    init(
        clean: String, raw: String? = nil, suffix: String? = nil, suffixShort: String? = nil,
        extraInfo: String? = nil, place: String? = nil
    ) {
        self.clean = clean
        self.raw = raw
        self.suffix = suffix
        self.suffixShort = suffixShort
        self.extraInfo = extraInfo
        self.place = place
    }

    init(clean: String) {
        self.clean = clean
        self.raw = nil
        self.suffix = nil
        self.suffixShort = nil
        self.extraInfo = nil
        self.place = nil
    }
}
