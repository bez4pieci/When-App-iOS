//
//  MainView 2.swift
//  Departures
//
//  Created by Ernests Karlsons on 24.05.25.
//


import SwiftUI
import SwiftData
import TripKit

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Station.selectedAt, order: .reverse) private var stations: [Station]
    
    @State private var departures: [Departure] = []
    @State private var isLoading = false
    @State private var showStationSelection = false
    @State private var lastUpdate = Date()
    
    private var selectedStation: Station? {
        stations.first
    }
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
    }

    var body: some View {
        NavigationStack {
            ZStack {
               Color.black.ignoresSafeArea()
                .foregroundColor(.white)
                
                VStack(spacing: 0) {
                    if selectedStation != nil {
                        departureBoard
                    } else {
                        NoStationView(onSelectStation: { showStationSelection = true })
                    }
                }
                .navigationTitle(selectedStation?.name ?? "Departures")
                .navigationBarItems(trailing: Button(action: {
                    showStationSelection = true
                }) {
                    Image(systemName: "gearshape")
                        .foregroundColor(.yellow)
                        .padding()
                })
            }
            .task {
                await loadDepartures()
            }
            .onChange(of: selectedStation) { _, newStation in
                if newStation != nil {
                    Task {
                        await loadDepartures()
                    }
                }
            }
            .sheet(isPresented: $showStationSelection) {
                StationSelectionView()
            }
        }
    }
    
    private var departureBoard: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Header row
                HStack {
                    Text("TIME")
                        .frame(width: 80, alignment: .leading)
                    Text("LINE")
                        .frame(width: 80, alignment: .leading)
                    Text("DESTINATION")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("PLATFORM")
                        .frame(width: 80, alignment: .trailing)
                }
                .fontWeight(.bold)
                .foregroundColor(.yellow)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.05))
                
                Divider()
                    .background(Color.yellow.opacity(0.5))
                
                // Departures
                ForEach(Array(departures.enumerated()), id: \.offset) { index, departure in
                    DepartureRow(departure: departure)
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                }
            }
        }
        .refreshable {
            await loadDepartures()
        }
    }
    
    private func loadDepartures() async {
        guard let station = selectedStation else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        // Create a task to ensure minimum loading time
        async let minimumLoadingTime = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 1 second
        }
        
        do {
            let provider = BvgProvider(apiAuthorization: ["type":"AID", "aid": "dVg4TZbW8anjx9ztPwe2uk4LVRi9wO"])
            let tripKitStation = Station(id: station.id, name: station.name)
            
            let (_, result) = await provider.queryDepartures(stationId: tripKitStation.id)
            
            // Wait for both the API call and minimum loading time to complete
            _ = await (minimumLoadingTime, result)
            
            switch result {
            case .success(let stationDepartures):
                await MainActor.run {
                    self.departures = stationDepartures.flatMap { $0.departures }
                    self.lastUpdate = Date()
                }
            case .invalidStation:
                print("Invalid station id")
            case .failure(let error):
                print("Error loading departures: \(error)")
            }
        } catch {
            print("Error loading departures: \(error)")
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter
    }
}
