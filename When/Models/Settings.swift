import Foundation
import SwiftUI
import TripKit

// Protocol defining the settings interface
protocol SettingsProtocol: ObservableObject {
    var showCancelledDepartures: Bool { get set }
    var filterSuburbanTrain: Bool { get set }
    var filterSubway: Bool { get set }
    var filterTram: Bool { get set }
    var filterBus: Bool { get set }
    var filterRegionalTrain: Bool { get set }
    var filterFerry: Bool { get set }
    var filterHighSpeedTrain: Bool { get set }
    var filterOnDemand: Bool { get set }
    var filterCablecar: Bool { get set }

    var enabledProducts: Set<Product> { get }
    func isProductEnabled(_ product: Product) -> Bool
    func toggleProduct(_ product: Product)
    func setProduct(_ product: Product, enabled: Bool)
}

// Extension to provide default implementations
extension SettingsProtocol {
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

    func setProduct(_ product: Product, enabled: Bool) {
        switch product {
        case .suburbanTrain: filterSuburbanTrain = enabled
        case .subway: filterSubway = enabled
        case .tram: filterTram = enabled
        case .bus: filterBus = enabled
        case .regionalTrain: filterRegionalTrain = enabled
        case .ferry: filterFerry = enabled
        case .highSpeedTrain: filterHighSpeedTrain = enabled
        case .onDemand: filterOnDemand = enabled
        case .cablecar: filterCablecar = enabled
        }
    }
}

// Temporary settings that don't persist
class TemporarySettings: SettingsProtocol {
    @Published var showCancelledDepartures: Bool
    @Published var filterSuburbanTrain: Bool
    @Published var filterSubway: Bool
    @Published var filterTram: Bool
    @Published var filterBus: Bool
    @Published var filterRegionalTrain: Bool
    @Published var filterFerry: Bool
    @Published var filterHighSpeedTrain: Bool
    @Published var filterOnDemand: Bool
    @Published var filterCablecar: Bool

    init(from settings: Settings) {
        self.showCancelledDepartures = settings.showCancelledDepartures
        self.filterSuburbanTrain = settings.filterSuburbanTrain
        self.filterSubway = settings.filterSubway
        self.filterTram = settings.filterTram
        self.filterBus = settings.filterBus
        self.filterRegionalTrain = settings.filterRegionalTrain
        self.filterFerry = settings.filterFerry
        self.filterHighSpeedTrain = settings.filterHighSpeedTrain
        self.filterOnDemand = settings.filterOnDemand
        self.filterCablecar = settings.filterCablecar
    }

    func applyTo(_ settings: Settings) {
        settings.showCancelledDepartures = self.showCancelledDepartures
        settings.filterSuburbanTrain = self.filterSuburbanTrain
        settings.filterSubway = self.filterSubway
        settings.filterTram = self.filterTram
        settings.filterBus = self.filterBus
        settings.filterRegionalTrain = self.filterRegionalTrain
        settings.filterFerry = self.filterFerry
        settings.filterHighSpeedTrain = self.filterHighSpeedTrain
        settings.filterOnDemand = self.filterOnDemand
        settings.filterCablecar = self.filterCablecar
    }
}

// Persistent settings using @AppStorage
class Settings: SettingsProtocol {
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
}
