import Foundation
import TripKit

// MARK: - Custom Types (TripKit-free)

/// Transport type information for UI display
struct TransportType {
    let name: String
    let shortLabel: String
    let label: String

    init(from product: Product) {
        self.name = product.name
        self.shortLabel = product.shortLabel
        self.label = product.label
    }
}

/// Search result for location/station search
struct SearchResult {
    let id: String
    let name: String
    let displayName: String
    let latitude: Double?
    let longitude: Double?
    let products: [TransportType]

    init(from suggestedLocation: SuggestedLocation) {
        let location = suggestedLocation.location
        self.id = location.id ?? UUID().uuidString
        self.displayName = location.getUniqueShortName()
        self.name = location.name ?? self.displayName
        self.latitude = location.coord?.lat != nil ? Double(location.coord!.lat) / 1000000.0 : nil
        self.longitude = location.coord?.lon != nil ? Double(location.coord!.lon) / 1000000.0 : nil
        self.products = (location.products ?? []).map { TransportType(from: $0) }
    }
}

/// Line information for departures
struct LineInfo {
    let name: String?
    let label: String?
    let transportType: TransportType?

    init(from line: Line) {
        self.name = line.name
        self.label = line.label
        self.transportType = line.product != nil ? TransportType(from: line.product!) : nil
    }
}

/// Destination information for departures
struct DestinationInfo {
    let name: String?
    let place: String?

    init(from destination: Location?) {
        self.name = destination?.name
        self.place = destination?.place
    }
}

/// Departure information for UI display
struct DepartureInfo: Hashable {
    let id: String
    let line: LineInfo
    let destination: DestinationInfo
    let plannedTime: Date
    let predictedTime: Date?
    let cancelled: Bool

    init(from departure: Departure) {
        // Create a unique ID based on departure properties for ForEach
        self.id =
            "\(departure.line.label ?? "")-\(departure.destination?.name ?? "")-\(departure.plannedTime.timeIntervalSince1970)"
        self.line = LineInfo(from: departure.line)
        self.destination = DestinationInfo(from: departure.destination)
        self.plannedTime = departure.plannedTime
        self.predictedTime = departure.predictedTime
        self.cancelled = departure.cancelled
    }

    // Implement Hashable for ForEach compatibility
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DepartureInfo, rhs: DepartureInfo) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - TransportService

class TransportService {
    private let provider: BvgProvider

    init() {
        self.provider = BvgProvider(apiAuthorization: AppConfig.bvgApiAuthorization)
    }

    // MARK: - Location Search

    /// Search for locations/stations based on a query string
    /// - Parameter query: The search query
    /// - Returns: Array of search results
    func searchLocations(query: String) async -> [SearchResult] {
        guard !query.isEmpty else {
            return []
        }

        let (_, result) = await provider.suggestLocations(
            constraint: query,
            types: [.station]
        )

        switch result {
        case .success(let locations):
            return locations.map { SearchResult(from: $0) }
        case .failure(let error):
            print("TransportService: Search error: \(error)")
            return []
        }
    }

    // MARK: - Departures

    /// Query departures for a specific station
    /// - Parameters:
    ///   - stationId: The station ID to query departures for
    ///   - maxDepartures: Maximum number of departures to fetch
    /// - Returns: Array of departure info or empty array on failure
    func queryDepartures(stationId: String, maxDepartures: Int = 40) async -> [DepartureInfo] {
        let (_, result) = await provider.queryDepartures(
            stationId: stationId,
            maxDepartures: maxDepartures
        )

        switch result {
        case .success(let stationDepartures):
            let departures = stationDepartures.flatMap { $0.departures }
            let departureInfos = departures.map { DepartureInfo(from: $0) }
            print(
                "TransportService: Fetched \(departureInfos.count) departures for station \(stationId)"
            )
            return departureInfos

        case .invalidStation:
            print("TransportService: Invalid station id: \(stationId)")
            return []

        case .failure(let error):
            print("TransportService: Error loading departures for station \(stationId): \(error)")
            return []
        }
    }
}
