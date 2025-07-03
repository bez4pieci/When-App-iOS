import FirebaseFunctions
import Foundation

// MARK: - Custom Types

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
        case .regional: return "Regional"
        case .express: return "Express"
        }
    }
}

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
    let destination: String
    let isCancelled: Bool

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Departure, rhs: Departure) -> Bool {
        return lhs.id == rhs.id
    }
}

struct SearchResult: Decodable {
    let id: String
    let name: String
    let latitude: Double?
    let longitude: Double?
    let products: [Product]
}

struct SearchStationsRequest: Encodable {
    let query: String
}

struct SearchStationsResponse: Decodable {
    let results: [SearchResult]
}

struct QueryDeparturesRequest: Encodable {
    let stationId: String
    let products: [Product]
    let showCancelledDepartures: Bool
}

struct QueryDeparturesResponse: Decodable {
    let departures: [Departure]
}

// MARK: - TransportService

class TransportService {
    lazy var functions = Functions.functions(region: AppConfig.firebaseFunctionsRegion)

    init() {
        // Enable for testing
        //self.functions.useEmulator(withHost: "localhost", port: 5001)
    }

    // MARK: - Location Search

    /// Search for locations/stations based on a query string
    /// - Parameter query: The search query
    /// - Returns: Array of search results
    func searchLocations(query: String) async -> [SearchResult] {
        guard !query.isEmpty else {
            return []
        }

        let searchLocationsFunc: Callable<SearchStationsRequest, SearchStationsResponse> =
            functions.httpsCallable("searchStations")

        let request = SearchStationsRequest(query: query)
        do {
            let response = try await searchLocationsFunc.call(request)
            let results = response.results
            print(
                "TransportService: Fetched \(results.count) stations for query \"\(query)\"")
            return results
        } catch {
            print("TransportService: Error loading stations for query \"\(query)\": \(error)")
            return []
        }
    }

    // MARK: - Departures

    /// Query departures for a specific station
    /// - Parameters:
    ///   - stationId: The station ID to query departures for
    ///   - products: Filter by products (default: all)
    ///   - showCancelledDepartures: Whether to show cancelled departures
    /// - Returns: Array of departures or empty array on failure
    func queryDepartures(
        stationId: String,
        products: [Product] = [],
        showCancelledDepartures: Bool = true
    ) async -> [Departure] {
        let queryDeparturesCloudFunc: Callable<QueryDeparturesRequest, QueryDeparturesResponse> =
            functions.httpsCallable("queryDepartures")

        let request = QueryDeparturesRequest(
            stationId: stationId, products: products,
            showCancelledDepartures: showCancelledDepartures)
        do {
            let response = try await queryDeparturesCloudFunc.call(request)
            let departures = response.departures
            print(
                "TransportService: Fetched \(departures.count) departures for station \(stationId)")
            return departures
        } catch {
            print("TransportService: Error loading departures for station \(stationId): \(error)")
            return []
        }
    }
}
