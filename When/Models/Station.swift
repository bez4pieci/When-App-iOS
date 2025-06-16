//
//  Station.swift
//  Departures
//
//  Created on 24.05.25.
//

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
    var productStrings: [String] = []

    // Per-station settings
    var showCancelledDepartures: Bool = true
    var enabledProductStrings: [String] = []  // Store enabled product names

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

    func apply(_ other: Station) {
        self.name = other.name
        self.latitude = other.latitude
        self.longitude = other.longitude
        self.selectedAt = other.selectedAt
        self.productStrings = other.productStrings
        self.showCancelledDepartures = other.showCancelledDepartures
        self.enabledProductStrings = other.enabledProductStrings
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
