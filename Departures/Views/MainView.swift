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
    
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background like a departure board
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    
                    if selectedStation != nil {
                        departureBoard
                    } else {
                        NoStationView(onSelectStation: { showStationSelection = true })
                    }
                }
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
            .onReceive(timer) { _ in
                Task {
                    await loadDepartures()
                }
            }
            .sheet(isPresented: $showStationSelection) {
                StationSelectionView()
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DEPARTURES")
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                    
                    if let station = selectedStation {
                        Text(station.name.uppercased())
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                Button(action: { showStationSelection = true }) {
                    Image(systemName: "location.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Last update time
            HStack {
                Text("Last updated: \(lastUpdate, formatter: timeFormatter)")
                    .font(.caption)
                    .foregroundColor(.green)
                Spacer()
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .green))
                        .scaleEffect(0.7)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .background(Color.black.opacity(0.95))
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
    }
    
    private func loadDepartures() async {
        guard let station = selectedStation else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let provider = BvgProvider(apiAuthorization: ["type":"AID", "aid": "dVg4TZbW8anjx9ztPwe2uk4LVRi9wO"])
            let tripKitStation = Station(id: station.id, name: station.name)
            
            let (_, result) = await provider.queryDepartures(stationId: tripKitStation.id)
            
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