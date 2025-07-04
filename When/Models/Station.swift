import Foundation
import SwiftData

@Model
final class Station {
    @Attribute(.unique) var id: String
    var name: StationName
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
        id: String, name: StationName, latitude: Double? = nil, longitude: Double? = nil,
        products: [Product] = []
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
        self.name = StationName(name: "")
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
        self.productStrings = from.productStrings

        self.showCancelledDepartures = from.showCancelledDepartures
        self.enabledProductStrings = from.enabledProductStrings

        if setSelectedAtToNow {
            self.selectedAt = Date()
        } else {
            self.selectedAt = from.selectedAt
        }
    }

    var products: [Product] {
        productStrings.compactMap { Product(rawValue: $0) }
    }

    func hasProduct(_ product: Product) -> Bool {
        productStrings.contains(product.name)
    }

    var enabledProducts: Set<Product> {
        Set(enabledProductStrings.compactMap { Product(rawValue: $0) })
    }

    func isProductEnabled(_ product: Product) -> Bool {
        enabledProductStrings.contains(product.name)
    }

    func toggleProduct(_ product: Product) {
        if enabledProductStrings.contains(product.name) {
            enabledProductStrings.removeAll { $0 == product.name }
        } else {
            enabledProductStrings.append(product.name)
        }
    }

    func setProduct(_ product: Product, enabled: Bool) {
        let productName = product.name
        let isCurrentlyEnabled = enabledProductStrings.contains(productName)

        if enabled && !isCurrentlyEnabled {
            enabledProductStrings.append(productName)
        } else if !enabled && isCurrentlyEnabled {
            enabledProductStrings.removeAll { $0 == productName }
        }
    }
}
