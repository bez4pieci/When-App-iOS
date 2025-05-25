//
//  DeparturesApp.swift
//  Departures
//
//  Created by Ernests Karlsons on 24.05.25.
//

import SwiftData
import SwiftUI

extension Font {
    static let dSmall = Font.custom("DepartureMono-Regular", size: 16)
    static let dNormal = Font.custom("DepartureMono-Regular", size: 20)
    static let dLarge = Font.custom("DepartureMono-Regular", size: 24)
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
    static let dDefault = Color(hex: 0x000000)
    static let dMedium = Color(hex: 0x000000, alpha: 0.8)
    static let dLight = Color(hex: 0x000000, alpha: 0.6)
}

@main
struct DeparturesApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Station.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    let departureMonoFont = Font.custom("DepartureMono-Regular", size: 16)

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.font, Font.dNormal)
                .environment(\.colorScheme, .light)
        }
        .modelContainer(sharedModelContainer)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Station.self, configurations: config)

    // Add some sample data
    let sampleStation = Station(
        id: "900058101", name: "S Südkreuz Bhf (Berlin)",
        latitude: 52.475501,
        longitude: 13.365548)
    container.mainContext.insert(sampleStation)

    return MainView()
        .modelContainer(container)
        .environment(\.font, Font.dNormal)
        .environment(\.colorScheme, .light)
}
