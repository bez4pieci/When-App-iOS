import Foundation
import SwiftUI
import TripKit

class Settings: ObservableObject {
    @AppStorage("showCancelledDepartures") var showCancelledDepartures: Bool = true

    // Transport type filters - storing as individual booleans for simplicity with @AppStorage
    @AppStorage("filterSuburbanTrain") var filterSuburbanTrain: Bool = true
    @AppStorage("filterSubway") var filterSubway: Bool = true
    @AppStorage("filterTram") var filterTram: Bool = true
    @AppStorage("filterBus") var filterBus: Bool = true
    @AppStorage("filterRegionalTrain") var filterRegionalTrain: Bool = true
    @AppStorage("filterFerry") var filterFerry: Bool = true
    @AppStorage("filterHighSpeedTrain") var filterHighSpeedTrain: Bool = true
    @AppStorage("filterOnDemand") var filterOnDemand: Bool = true
    @AppStorage("filterCablecar") var filterCablecar: Bool = true

    // Helper computed property to get enabled products
    var enabledProducts: Set<Product> {
        var products = Set<Product>()
        if filterSuburbanTrain { products.insert(.suburbanTrain) }
        if filterSubway { products.insert(.subway) }
        if filterTram { products.insert(.tram) }
        if filterBus { products.insert(.bus) }
        if filterRegionalTrain { products.insert(.regionalTrain) }
        if filterFerry { products.insert(.ferry) }
        if filterHighSpeedTrain { products.insert(.highSpeedTrain) }
        if filterOnDemand { products.insert(.onDemand) }
        if filterCablecar { products.insert(.cablecar) }
        return products
    }

    // Helper method to check if a product is enabled
    func isProductEnabled(_ product: Product) -> Bool {
        switch product {
        case .suburbanTrain: return filterSuburbanTrain
        case .subway: return filterSubway
        case .tram: return filterTram
        case .bus: return filterBus
        case .regionalTrain: return filterRegionalTrain
        case .ferry: return filterFerry
        case .highSpeedTrain: return filterHighSpeedTrain
        case .onDemand: return filterOnDemand
        case .cablecar: return filterCablecar
        }
    }

    // Helper method to toggle a product
    func toggleProduct(_ product: Product) {
        switch product {
        case .suburbanTrain: filterSuburbanTrain.toggle()
        case .subway: filterSubway.toggle()
        case .tram: filterTram.toggle()
        case .bus: filterBus.toggle()
        case .regionalTrain: filterRegionalTrain.toggle()
        case .ferry: filterFerry.toggle()
        case .highSpeedTrain: filterHighSpeedTrain.toggle()
        case .onDemand: filterOnDemand.toggle()
        case .cablecar: filterCablecar.toggle()
        }
    }
}
