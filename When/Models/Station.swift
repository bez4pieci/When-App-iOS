import Foundation
import SwiftData
import TripKit

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

    // Helper computed property to convert stored strings back to Product enums
    var products: [Product] {
        productStrings.compactMap { Product.fromName($0) }
    }

    // Helper method to check if a specific product is available at this station
    func hasProduct(_ product: Product) -> Bool {
        productStrings.contains(product.name)
    }

    // Helper computed property for enabled products
    var enabledProducts: Set<Product> {
        Set(enabledProductStrings.compactMap { Product.fromName($0) })
    }

    // Helper methods for settings management
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
