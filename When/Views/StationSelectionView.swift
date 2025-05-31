import PhosphorSwift
import SwiftData
import SwiftUI
import TripKit

struct StationSelectionView: View {
    @Environment(\.dismiss) private var dismiss

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var settings: Settings
    @Query(sort: \Station.selectedAt, order: .reverse) private var stations: [Station]

    private var selectedStation: Station? {
        stations.first
    }

    var body: some View {
        StationSelectionViewContent(
            settings: settings,
            selectedStation: selectedStation,
            onApply: saveChanges,
            onCancel: { dismiss() }
        )
    }

    private func saveChanges(station: Station?, temporarySettings: TemporarySettings) {
        guard let station = station else { return }

        if let existingStation = selectedStation {
            modelContext.delete(existingStation)
        }

        station.selectedAt = Date()
        modelContext.insert(station)

        do {
            try modelContext.save()
        } catch {
            print("Error saving station: \(error)")
        }

        // Apply temporary settings to persistent settings
        temporarySettings.applyTo(settings)

        dismiss()
    }
}

private struct StationSelectionViewContent: View {
    let onApply: (_ station: Station?, _ temporarySettings: TemporarySettings) -> Void
    let onCancel: () -> Void

    @State private var suggestedLocations: [SuggestedLocation] = []
    @State private var showingSuggestedLocations = false
    @State private var isSearching = false
    @FocusState private var isSearchFieldFocused

    // Local state for temporary changes
    @State private var temporarySelectedStation: Station?
    @StateObject private var temporarySettings: TemporarySettings

    init(
        settings: Settings,
        selectedStation: Station?,
        onApply: @escaping (_ station: Station?, _ temporarySettings: TemporarySettings) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.onApply = onApply
        self.onCancel = onCancel

        self.temporarySelectedStation = selectedStation
        _temporarySettings = StateObject(wrappedValue: TemporarySettings(from: settings))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.yellow
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        StationSearchField(
                            selectedStation: temporarySelectedStation,
                            onSearch: performSearch
                        )

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
                                        setStation(location)
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(Color.dDefault)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onApply(temporarySelectedStation, temporarySettings)
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
                // TODO: use allCases for Settings, so that we don't depend here on TripKit.
                //       TripKit might change products, and our settings will break.
                ForEach(Product.allCases, id: \.self) { product in
                    if temporarySelectedStation?.hasProduct(product) ?? true {
                        transportToggle(
                            product: product,
                            label: product.label,
                            forceEnable: temporarySelectedStation?.products.count ?? 0 < 2
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
    }

    private func transportToggle(product: Product, label: String, forceEnable: Bool = false)
        -> some View
    {
        if forceEnable {
            Task {
                temporarySettings.setProduct(product, enabled: true)
            }
        }

        return HStack {
            Text(label)
                .font(Font.dNormal)
                .foregroundColor(Color.dDefault)
            Spacer()
            Toggle(
                "",
                isOn: Binding(
                    get: { temporarySettings.isProductEnabled(product) },
                    set: { _ in temporarySettings.toggleProduct(product) }
                )
            )
            .labelsHidden()
            .tint(Color.dDefault)
            .disabled(forceEnable)
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
                Toggle("", isOn: $temporarySettings.showCancelledDepartures)
                    .labelsHidden()
                    .tint(Color.dDefault)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
    }

    private func setStation(_ location: Location) {
        // Store the selection temporarily
        temporarySelectedStation = Station(
            id: location.id ?? UUID().uuidString,
            name: location.name ?? location.getUniqueShortName(),
            latitude: location.coord?.lat != nil
                ? Double(location.coord!.lat) / 1000000.0 : nil,
            longitude: location.coord?.lon != nil
                ? Double(location.coord!.lon) / 1000000.0 : nil,
            products: location.products ?? []
        )

        // Clear search results
        suggestedLocations = []
        showingSuggestedLocations = false
        isSearchFieldFocused = false
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
