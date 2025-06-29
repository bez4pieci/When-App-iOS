import Foundation
import SwiftData

@Model
final class Station {
    @Attribute(.unique) var id: String
    var name: String
    var latitude: Double?
    var longitude: Double?
    var selectedAt: Date

    // Store arrays as comma-separated strings to avoid CoreData array issues
    var productStringsData: String = ""

    // Per-station settings
    var showCancelledDepartures: Bool = true
    var enabledProductStringsData: String = ""  // Store enabled product names

    // Computed properties to provide array interface
    var productStrings: [String] {
        get {
            productStringsData.isEmpty ? [] : productStringsData.components(separatedBy: ",")
        }
        set {
            productStringsData = newValue.joined(separator: ",")
        }
    }

    var enabledProductStrings: [String] {
        get {
            enabledProductStringsData.isEmpty
                ? [] : enabledProductStringsData.components(separatedBy: ",")
        }
        set {
            enabledProductStringsData = newValue.joined(separator: ",")
        }
    }

    init(
        id: String, name: String, latitude: Double? = nil, longitude: Double? = nil,
        products: [TransportType] = []
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.selectedAt = Date()
        self.productStrings = products.map { $0.name }

        // Initialize settings with defaults - enable all products available at this station
        self.showCancelledDepartures = true
        self.enabledProductStrings = products.map { $0.name }
    }

    init(from: Station) {
        self.id = ""
        self.name = ""
        self.latitude = nil
        self.longitude = nil
        self.selectedAt = Date()

        applyProps(from: from)
    }

    func applyProps(from: Station, setSelectedAtToNow: Bool = true) {
        self.id = from.id
        self.name = from.name
        self.latitude = from.latitude
        self.longitude = from.longitude

        self.showCancelledDepartures = from.showCancelledDepartures
        self.enabledProductStrings = from.enabledProductStrings

        if setSelectedAtToNow {
            self.selectedAt = Date()
        } else {
            self.selectedAt = from.selectedAt
        }
    }

    // Helper computed property to convert stored strings back to TransportType
    var products: [TransportType] {
        productStrings.compactMap { TransportType.from($0) }
    }

    // Helper method to check if a specific transport type is available at this station
    func hasProduct(_ transportType: TransportType) -> Bool {
        productStrings.contains(transportType.name)
    }

    // Helper computed property for enabled transport types
    var enabledProducts: Set<TransportType> {
        Set(enabledProductStrings.compactMap { TransportType.from($0) })
    }

    // Helper methods for settings management
    func isProductEnabled(_ transportType: TransportType) -> Bool {
        enabledProductStrings.contains(transportType.name)
    }

    func toggleProduct(_ transportType: TransportType) {
        if enabledProductStrings.contains(transportType.name) {
            enabledProductStrings.removeAll { $0 == transportType.name }
        } else {
            enabledProductStrings.append(transportType.name)
        }
    }

    func setProduct(_ transportType: TransportType, enabled: Bool) {
        let productName = transportType.name
        let isCurrentlyEnabled = enabledProductStrings.contains(productName)

        if enabled && !isCurrentlyEnabled {
            enabledProductStrings.append(productName)
        } else if !enabled && isCurrentlyEnabled {
            enabledProductStrings.removeAll { $0 == productName }
        }
    }
}
