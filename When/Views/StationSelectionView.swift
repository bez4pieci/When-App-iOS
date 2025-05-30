import PhosphorSwift
import SwiftData
import SwiftUI
import TripKit

struct StationSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Station.selectedAt, order: .reverse) private var stations: [Station]
    @EnvironmentObject var settings: Settings

    @State private var suggestedLocations: [SuggestedLocation] = []
    @State private var showingSuggestedLocations = false
    @State private var isSearching = false
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
                        StationSearchField(onSearch: performSearch)

                        // Show search results inline
                        VStack(spacing: 0) {
                            if isSearching {
                                DefaultDivider()
                                HStack {
                                    Text("Searching...")
                                        .font(Font.dNormal)
                                        .foregroundColor(Color.dLight)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 20)
                                .background(Color.white)
                            }

                            if suggestedLocations.count > 0 {
                                DefaultDivider()
                                StationsList(
                                    searchResults: suggestedLocations,
                                    maxResults: 5,
                                    onSelect: { location in
                                        selectStation(location)
                                    }
                                )
                            }
                        }

                        // Transport Type Filters Section
                        transportFiltersSection

                        // Show Cancelled Departures Toggle
                        showCancelledSection

                        DefaultDivider()
                    }
                }
                .padding(.top, 1)
            }
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

    private var transportFiltersSection: some View {
        VStack(spacing: 0) {
            DefaultDivider()
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
            .padding(.vertical, 20)
        }
    }

    private var showCancelledSection: some View {
        VStack(spacing: 0) {
            DefaultDivider()
            HStack {
                Text("Show Cancelled")
                    .font(Font.dNormal)
                    .foregroundColor(Color.dDefault)
                Spacer()
                Toggle("", isOn: $settings.showCancelledDepartures)
                    .labelsHidden()
                    .tint(Color.dDefault)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
    }

    private func transportToggle(product: Product, label: String) -> some View {
        let isAvailable = selectedStation?.hasProduct(product) ?? true

        return HStack {
            Text(label)
                .font(Font.dNormal)
                .foregroundColor(isAvailable ? Color.dDefault : Color.dLight)
            Spacer()
            Toggle(
                "",
                isOn: Binding(
                    get: { settings.isProductEnabled(product) },
                    set: { _ in settings.toggleProduct(product) }
                )
            )
            .labelsHidden()
            .tint(Color.dDefault)
            .disabled(!isAvailable)
            .opacity(isAvailable ? 1.0 : 0.25)
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
            longitude: location.coord?.lon != nil ? Double(location.coord!.lon) / 1000000.0 : nil,
            products: location.products ?? []
        )

        station.selectedAt = Date()
        modelContext.insert(station)

        do {
            try modelContext.save()

            suggestedLocations = []
            showingSuggestedLocations = false
            isSearchFieldFocused = false

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
        suggestedLocations = []

        let provider = BvgProvider(apiAuthorization: AppConfig.bvgApiAuthorization)
        let (_, result) = await provider.suggestLocations(
            constraint: query,
            types: [.station]
        )

        switch result {
        case .success(let locations):
            suggestedLocations = locations
        case .failure(let error):
            print("Search error: \(error)")
            suggestedLocations = []
        }

        isSearching = false
    }
}
