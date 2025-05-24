//
//  DeparturesApp.swift
//  Departures
//
//  Created by Ernests Karlsons on 24.05.25.
//

import SwiftUI
import SwiftData

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
                .environment(\.font, departureMonoFont)
        }
        .modelContainer(sharedModelContainer)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Station.self, configurations: config)
    
    // Add some sample data
    // let sampleStation = Station(id: "900000100001", name: "Alexanderplatz")
    // container.mainContext.insert(sampleStation)
    
    return MainView()
        .modelContainer(container)
        .environment(\.font, Font.custom("DepartureMono-Regular", size: 20))
}
