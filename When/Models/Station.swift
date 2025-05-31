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
    }

    // Helper computed property to convert stored strings back to Product enums
    var products: [Product] {
        productStrings.compactMap { Product.fromName($0) }
    }

    // Helper method to check if a specific product is available at this station
    func hasProduct(_ product: Product) -> Bool {
        productStrings.contains(product.name)
    }
}
