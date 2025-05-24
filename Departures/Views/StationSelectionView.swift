//
//  StationSelectionView.swift
//  Departures
//
//  Created on 24.05.25.
//

import SwiftUI
import SwiftData
import TripKit

struct StationSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var searchResults: [SuggestedLocation] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                    
                    // Results
                    if isSearching {
                        loadingView
                    } else if searchResults.isEmpty && !searchText.isEmpty {
                        emptyResultsView
                    } else if !searchResults.isEmpty {
                        resultsView
                    } else {
                        instructionsView
                    }
                }
            }
            .navigationTitle("Select Station")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.yellow)
                }
            }
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationBackground(Color.black)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.yellow)
            
            TextField("Search for station...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.white)
                .font(.system(size: 16, design: .monospaced))
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onChange(of: searchText) { _, newValue in
                    searchTask?.cancel()
                    searchTask = Task {
                        await performSearch(query: newValue)
                    }
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    searchResults = []
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
        .padding()
    }
    
    private var resultsView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(searchResults.enumerated()), id: \.offset) { index, suggestedLocation in
                    stationRow(suggestedLocation.location)
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                }
            }
        }
    }
    
    private func stationRow(_ location: Location) -> some View {
        Button(action: { selectStation(location) }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.getUniqueShortName())
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                    
                    if let products = location.products, !products.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(Array(products), id: \.self) { product in
                                productBadge(for: product)
                            }
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.yellow)
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func productBadge(for product: Product) -> some View {
        Text(productLabel(for: product))
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(productColor(for: product))
            .foregroundColor(.black)
            .cornerRadius(4)
    }
    
    private func productLabel(for product: Product) -> String {
        switch product {
        case .suburbanTrain: return "S"
        case .subway: return "U"
        case .tram: return "T"
        case .bus: return "B"
        case .regionalTrain: return "RE"
        case .ferry: return "F"
        default: return "?"
        }
    }
    
    private func productColor(for product: Product) -> Color {
        switch product {
        case .suburbanTrain:
            return Color(red: 0.0, green: 0.5, blue: 0.0)
        case .subway:
            return Color.blue
        case .tram:
            return Color.red
        case .bus:
            return Color.purple
        case .regionalTrain:
            return Color.orange
        case .ferry:
            return Color.cyan
        default:
            return Color.gray
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                .scaleEffect(1.5)
                .padding()
            
            Text("Searching...")
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(.gray)
        }
        .frame(maxHeight: .infinity)
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No stations found")
                .font(.system(size: 20, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
            
            Text("Try a different search term")
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(.gray)
        }
        .frame(maxHeight: .infinity)
    }
    
    private var instructionsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tram.fill")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
            
            Text("Search for a station")
                .font(.system(size: 20, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
            
            Text("Type the name of a station in Berlin")
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(.gray)
        }
        .frame(maxHeight: .infinity)
    }
    
    private func performSearch(query: String) async {
        guard !query.isEmpty else {
            await MainActor.run {
                searchResults = []
                isSearching = false
            }
            return
        }
        
        await MainActor.run {
            isSearching = true
        }
        
        do {
            let provider = BvgProvider(apiAuthorization: ["type":"AID", "aid": "dVg4TZbW8anjx9ztPwe2uk4LVRi9wO"])
            let (_, result) = await provider.suggestLocations(constraint: query)
            
            switch result {
            case .success(let locations):
                await MainActor.run {
                    self.searchResults = locations.filter { location in
                        // Filter for stations only
                        location.location.type == .station
                    }
                    self.isSearching = false
                }
            case .failure(let error):
                print("Search error: \(error)")
                await MainActor.run {
                    self.searchResults = []
                    self.isSearching = false
                }
            }
        } catch {
            print("Search error: \(error)")
            await MainActor.run {
                self.searchResults = []
                self.isSearching = false
            }
        }
    }
    
    private func selectStation(_ location: Location) {
        let station = Station(
            id: location.id ?? UUID().uuidString,
            name: location.getUniqueShortName(),
            latitude: location.coord?.lat != nil ? Double(location.coord!.lat) : nil,
            longitude: location.coord?.lon != nil ? Double(location.coord!.lon) : nil
        )
        station.selectedAt = Date()
        modelContext.insert(station)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving station: \(error)")
        }
    }
} 
