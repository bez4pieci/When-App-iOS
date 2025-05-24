//
//  MainView.swift
//  Departures
//
//  Created on 24.05.25.
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
                    // Header
                    headerView
                    
                    if let station = selectedStation {
                        // Departure board
                        departureBoard
                    } else {
                        // No station selected
                        noStationView
                    }
                }
            }
            .task {
                await loadDepartures()
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
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                    
                    if let station = selectedStation {
                        Text(station.name.uppercased())
                            .font(.system(size: 20, weight: .medium, design: .monospaced))
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
                    .font(.system(size: 12, design: .monospaced))
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
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.05))
                
                Divider()
                    .background(Color.yellow.opacity(0.5))
                
                // Departures
                ForEach(Array(departures.enumerated()), id: \.offset) { index, departure in
                    DepartureRow(departure: departure)
                        .background(index % 2 == 0 ? Color.white.opacity(0.02) : Color.clear)
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                }
            }
        }
    }
    
    private var noStationView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tram.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("No Station Selected")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Text("Tap the location button to select a station")
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(.gray)
            
            Button(action: { showStationSelection = true }) {
                Text("SELECT STATION")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Color.yellow)
                    .cornerRadius(8)
            }
            .padding(.top, 20)
        }
        .frame(maxHeight: .infinity)
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

struct DepartureRow: View {
    let departure: Departure
    
    var body: some View {
        HStack {
            // Time
            Text(timeString)
                .frame(width: 80, alignment: .leading)
                .foregroundColor(departureColor)
            
            // Line
            HStack(spacing: 4) {
                Text(departure.line.label ?? "")
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(lineBackgroundColor(for: departure.line.product))
                    .foregroundColor(.black)
                    .cornerRadius(4)
            }
            .frame(width: 80, alignment: .leading)
            
            // Destination
            Text(departure.destination?.name ?? "Unknown")
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.white)
                .lineLimit(1)
            
            // Platform
            Text(departure.platform ?? "-")
                .frame(width: 80, alignment: .trailing)
                .foregroundColor(.white)
        }
        .font(.system(size: 16, design: .monospaced))
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private var timeString: String {
        if let predictedTime = departure.predictedTime {
            return formatTime(predictedTime)
        }
        return formatTime(departure.plannedTime)
    }
    
    private var departureColor: Color {
        if departure.cancelled {
            return .red.opacity(0.5)
        } else if let predictedTime = departure.predictedTime,
                  predictedTime > departure.plannedTime {
            return .red
        }
        return .green
    }
    
    private func lineBackgroundColor(for product: Product?) -> Color {
        guard let product = product else { return .gray }
        
        switch product {
        case .suburbanTrain:
            return Color(red: 0.0, green: 0.5, blue: 0.0) // S-Bahn green
        case .subway:
            return Color.blue // U-Bahn blue
        case .tram:
            return Color.red // Tram red
        case .bus:
            return Color.purple // Bus purple
        case .regionalTrain:
            return Color.orange // Regional trains
        default:
            return Color.gray
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
} 