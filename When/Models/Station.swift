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
        self.productStrings = products.map { productToString($0) }
    }

    // Helper computed property to convert stored strings back to Product enums
    var products: [Product] {
        productStrings.compactMap { stringToProduct($0) }
    }

    // Helper method to check if a specific product is available at this station
    func hasProduct(_ product: Product) -> Bool {
        productStrings.contains(productToString(product))
    }

    // Convert Product enum to string for storage
    private func productToString(_ product: Product) -> String {
        switch product {
        case .suburbanTrain: return "suburbanTrain"
        case .subway: return "subway"
        case .tram: return "tram"
        case .bus: return "bus"
        case .regionalTrain: return "regionalTrain"
        case .ferry: return "ferry"
        case .highSpeedTrain: return "highSpeedTrain"
        case .onDemand: return "onDemand"
        case .cablecar: return "cablecar"
        }
    }

    // Convert string back to Product enum
    private func stringToProduct(_ string: String) -> Product? {
        switch string {
        case "suburbanTrain": return .suburbanTrain
        case "subway": return .subway
        case "tram": return .tram
        case "bus": return .bus
        case "regionalTrain": return .regionalTrain
        case "ferry": return .ferry
        case "highSpeedTrain": return .highSpeedTrain
        case "onDemand": return .onDemand
        case "cablecar": return .cablecar
        default: return nil
        }
    }
}
