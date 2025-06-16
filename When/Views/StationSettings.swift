import PhosphorSwift
import SwiftData
import SwiftUI
import TripKit

struct StationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Station.selectedAt, order: .reverse) private var stations: [Station]

    let station: Station?
    let onDelete: ((Station) -> Void)

    var body: some View {
        StationSettingsContentView(
            station: station,
            onApply: saveChanges,
            onCancel: { dismiss() },
            onDelete: { station in
                onDelete(station)
                dismiss()
            }
        )
    }

    private func saveChanges(changedStation: Station?) {
        guard let changedStation = changedStation else { return }

        if let existingStation = station {
            // Update existing station with values from changed station
            existingStation.id = changedStation.id
            existingStation.name = changedStation.name
            existingStation.latitude = changedStation.latitude
            existingStation.longitude = changedStation.longitude
            existingStation.productStrings = changedStation.productStrings
            existingStation.showCancelledDepartures = changedStation.showCancelledDepartures
            existingStation.selectedAt = Date()

            // Copy enabled products settings
            existingStation.enabledProductStrings = changedStation.enabledProductStrings
        } else {
            // Insert new station
            changedStation.selectedAt = Date()
            modelContext.insert(changedStation)
        }

        do {
            try modelContext.save()
        } catch {
            print("Error saving station: \(error)")
        }

        dismiss()
    }
}

private struct StationSettingsContentView: View {
    let onApply: (_ station: Station?) -> Void
    let onCancel: () -> Void
    let onDelete: ((Station) -> Void)?
    let wasInitialisedWithAStation: Bool

    @State private var suggestedLocations: [SuggestedLocation] = []
    @State private var showingSuggestedLocations = false
    @State private var isSearching = false
    @FocusState private var isSearchFieldFocused

    // Local state for temporary changes
    @State private var temporarySelectedStation: Station?

    private var hPadding: CGFloat = 20
    private var vPadding: CGFloat = 20

    init(
        station: Station?,
        onApply: @escaping (_ station: Station?) -> Void,
        onCancel: @escaping () -> Void,
        onDelete: ((Station) -> Void)? = nil,
    ) {
        self.onApply = onApply
        self.onCancel = onCancel
        self.onDelete = onDelete
        _temporarySelectedStation = State(initialValue: station)
        self.wasInitialisedWithAStation = station != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dBackground
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
                                .padding(.horizontal, hPadding)
                                .padding(.vertical, vPadding)
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

                        // Delete button
                        if wasInitialisedWithAStation {
                            deleteButton
                        }

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
                        onApply(temporarySelectedStation)
                    }
                    .foregroundColor(Color.dDefault)
                }
            }
            .toolbarBackground(Color.dBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
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
            .padding(.horizontal, hPadding)
            .padding(.vertical, vPadding)
        }
    }

    private func transportToggle(product: Product, label: String, forceEnable: Bool = false)
        -> some View
    {
        HStack {
            Text(label)
                .font(Font.dNormal)
                .foregroundColor(Color.dDefault)
            Spacer()
            Toggle(
                "",
                isOn: Binding(
                    get: { temporarySelectedStation?.isProductEnabled(product) ?? false },
                    set: { _ in temporarySelectedStation?.toggleProduct(product) }
                )
            )
            .labelsHidden()
            .tint(Color.dDefault)
            .disabled(forceEnable)
        }
        .onAppear {
            if forceEnable {
                temporarySelectedStation?.setProduct(product, enabled: true)
            }
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
                Toggle(
                    "",
                    isOn: Binding(
                        get: { temporarySelectedStation?.showCancelledDepartures ?? true },
                        set: { newValue in
                            temporarySelectedStation?.showCancelledDepartures = newValue
                        }
                    )
                )
                .labelsHidden()
                .tint(Color.dDefault)
            }
            .padding(.horizontal, hPadding)
            .padding(.vertical, vPadding)
        }
    }

    private var deleteButton: some View {
        VStack(spacing: 0) {
            DefaultDivider()
            Button(action: {
                if let station = temporarySelectedStation {
                    onDelete?(station)
                }
            }) {
                HStack {
                    Ph.trash.regular
                        .frame(width: 24, height: 24)
                        .foregroundColor(.red)

                    Text("Delete")
                        .font(Font.dNormal)
                        .foregroundColor(.red)

                    Spacer()
                }
                .padding(.horizontal, hPadding)
                .padding(.vertical, vPadding)
            }
            .buttonStyle(.plain)
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
