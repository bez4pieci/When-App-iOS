import PhosphorSwift
import SwiftData
import SwiftUI
import TripKit

struct StationSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Station.selectedAt, order: .reverse) private var stations: [Station]
    @EnvironmentObject var settings: Settings

    @State private var searchText = ""
    @State private var suggestedLocations: [SuggestedLocation] = []
    @State private var showingSuggestedLocations = false
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var debounceTimer: Timer?
    @FocusState private var isSearchFieldFocused

    private var selectedStation: Station? {
        stations.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.yellow
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Station Selection Section
                        stationSelectionSection

                        // Show search results inline if searching
                        if showingSuggestedLocations && !searchText.isEmpty {
                            VStack(spacing: 0) {
                                if isSearching {
                                    HStack {
                                        Text("Searching...")
                                            .font(Font.dNormal)
                                            .foregroundColor(Color.dLight)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.white)
                                } else if !suggestedLocations.isEmpty {
                                    StationsList(
                                        searchResults: suggestedLocations,
                                        maxResults: 5,
                                        onSelect: { location in
                                            selectStation(location)
                                        }
                                    )
                                }
                            }
                        }

                        DefaultDivider()

                        // Transport Type Filters Section
                        transportFiltersSection

                        DefaultDivider()

                        // Show Cancelled Departures Toggle
                        showCancelledSection
                    }
                }
                .padding(.top, 1)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.dDefault)
                }
            }
            .toolbarBackground(Color.yellow, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationBackground(Color.black)
    }

    private var stationSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Station")
                .font(Font.dLarge)
                .foregroundColor(Color.dDefault)
                .padding(.horizontal, 20)
                .padding(.top, 20)

            HStack(spacing: 12) {
                Ph.mapPinSimple.regular
                    .frame(width: 24, height: 24)

                TextField(
                    "", text: $searchText,
                    prompt: Text("Search for station...").foregroundColor(Color.dLight)
                )
                .focused($isSearchFieldFocused)
                .textFieldStyle(DefaultTextFieldStyle())
                .foregroundColor(Color.dDefault)
                .disableAutocorrection(true)
                .onChange(of: searchText) { _, newValue in
                    if !isSearchFieldFocused {
                        return
                    }

                    // Show search results when typing
                    showingSuggestedLocations = true

                    // Debounce search
                    debounceTimer?.invalidate()
                    searchTask?.cancel()

                    if newValue.isEmpty {
                        suggestedLocations = []
                        showingSuggestedLocations = false
                    } else {
                        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false)
                        { _ in
                            searchTask = Task {
                                await performSearch(query: newValue)
                            }
                        }
                    }
                }

                if !searchText.isEmpty {
                    Button(action: {
                        // Clear search and selected station
                        searchText = ""
                        suggestedLocations = []
                        showingSuggestedLocations = false

                        if let station = selectedStation {
                            modelContext.delete(station)
                            try? modelContext.save()
                        }
                    }) {
                        Ph.x.regular
                            .frame(width: 24, height: 24)
                            .foregroundColor(Color.dLight)
                    }
                    .fixedSize()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.white)
        .onAppear {
            searchText = selectedStation?.name ?? ""
        }
    }

    private var transportFiltersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transport Types")
                .font(Font.dLarge)
                .foregroundColor(Color.dDefault)
                .padding(.horizontal, 20)
                .padding(.top, 20)

            VStack(spacing: 12) {
                transportToggle(product: .subway, label: "U-Bahn")
                transportToggle(product: .suburbanTrain, label: "S-Bahn")
                transportToggle(product: .bus, label: "Bus")
                transportToggle(product: .tram, label: "Tram")
                transportToggle(product: .regionalTrain, label: "Regional Train")
                transportToggle(product: .ferry, label: "Ferry")
                transportToggle(product: .highSpeedTrain, label: "ICE/IC")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.white)
    }

    private var showCancelledSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Show Cancelled Departures")
                    .font(Font.dNormal)
                    .foregroundColor(Color.dDefault)
                Spacer()
                Toggle("", isOn: $settings.showCancelledDepartures)
                    .labelsHidden()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .background(Color.white)
    }

    private func transportToggle(product: Product, label: String) -> some View {
        HStack {
            Text(label)
                .font(Font.dNormal)
                .foregroundColor(Color.dDefault)
            Spacer()
            Toggle(
                "",
                isOn: Binding(
                    get: { settings.isProductEnabled(product) },
                    set: { _ in settings.toggleProduct(product) }
                )
            )
            .labelsHidden()
        }
    }

    private func selectStation(_ location: Location) {
        // Delete existing station if any
        if let existingStation = selectedStation {
            modelContext.delete(existingStation)
        }

        // Create new station
        let station = Station(
            id: location.id ?? UUID().uuidString,
            name: location.name ?? location.getUniqueShortName(),
            latitude: location.coord?.lat != nil ? Double(location.coord!.lat) / 1000000.0 : nil,
            longitude: location.coord?.lon != nil ? Double(location.coord!.lon) / 1000000.0 : nil
        )

        station.selectedAt = Date()
        modelContext.insert(station)

        do {
            try modelContext.save()

            suggestedLocations = []
            showingSuggestedLocations = false
            isSearchFieldFocused = false

            // Update search text with selected station name
            Task {
                searchText = station.name
            }

        } catch {
            print("Error saving station: \(error)")
        }
    }

    private func performSearch(query: String) async {
        if query.isEmpty {
            suggestedLocations = []
            isSearching = false
            return
        }

        isSearching = true

        let provider = BvgProvider(apiAuthorization: AppConfig.bvgApiAuthorization)
        let (_, result) = await provider.suggestLocations(constraint: query)

        switch result {
        case .success(let locations):
            suggestedLocations = locations.filter { $0.location.type == .station }
            isSearching = false
        case .failure(let error):
            print("Search error: \(error)")
            suggestedLocations = []
            isSearching = false
        }
    }
}
