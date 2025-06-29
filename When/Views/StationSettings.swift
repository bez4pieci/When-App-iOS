import FirebaseAnalytics
import PhosphorSwift
import SwiftData
import SwiftUI

struct StationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Station.selectedAt, order: .reverse) private var stations: [Station]

    let station: Station?
    let onStationDelete: ((Station) -> Void)
    let onStationChange: ((Station, Station) -> Void)

    var body: some View {
        StationSettingsContentView(
            station: station,
            onApply: save,
            onCancel: cancel,
            onDelete: delete
        )
        .onAppear {
            Analytics.logEvent(
                AnalyticsEventScreenView,
                parameters: [
                    AnalyticsParameterScreenName: "station_settings",
                    AnalyticsParameterScreenClass: "StationSettings",
                    "station_name": station?.name ?? "none",
                ])
        }
    }

    private func cancel() {
        Analytics.logEvent(
            "cancel_station_settings",
            parameters: [
                AnalyticsParameterScreenName: "station_settings",
                AnalyticsParameterScreenClass: "StationSettings",
                "station_name": station?.name ?? "none",
            ])

        dismiss()
    }

    private func delete(station: Station) {
        modelContext.delete(station)

        Analytics.logEvent(
            "delete_station",
            parameters: [
                AnalyticsParameterScreenName: "station_settings",
                AnalyticsParameterScreenClass: "StationSettings",
                "station_name": station.name,
                "show_cancelled_departures": station.showCancelledDepartures.description,
                "products": station.productStringsData,
                "enabled_products": station.enabledProductStringsData,
            ])

        onStationDelete(station)
        dismiss()
    }

    private func save(changedStation: Station?) {
        guard let changedStation = changedStation else { return }

        if let existingStation = station {
            let oldStation = Station(from: existingStation)
            existingStation.applyProps(from: changedStation)

            Analytics.logEvent(
                "update_station",
                parameters: [
                    AnalyticsParameterScreenName: "station_settings",
                    AnalyticsParameterScreenClass: "StationSettings",
                    "old_station_name": oldStation.name,
                    "old_show_cancelled_departures": oldStation.showCancelledDepartures,
                    "old_products": oldStation.productStringsData,
                    "old_enabled_products": oldStation.enabledProductStringsData,
                    "station_name": changedStation.name,
                    "show_cancelled_departures": changedStation.showCancelledDepartures.description,
                    "products": changedStation.productStringsData,
                    "enabled_products": changedStation.enabledProductStringsData,
                ])

            onStationChange(oldStation, existingStation)

        } else {
            changedStation.selectedAt = Date()
            modelContext.insert(changedStation)

            // Important to save, otherwise station is first added to the beginning of the list,
            // but then, after a few seconds, when the autosave triggers, the order is changed.
            try? modelContext.save()

            Analytics.logEvent(
                "add_station",
                parameters: [
                    AnalyticsParameterScreenName: "station_settings",
                    AnalyticsParameterScreenClass: "StationSettings",
                    "station_name": changedStation.name,
                    "show_cancelled_departures": changedStation.showCancelledDepartures,
                    "products": changedStation.productStringsData,
                    "enabled_products": changedStation.enabledProductStringsData,
                ])
        }

        dismiss()
    }
}

private struct StationSettingsContentView: View {
    let onApply: (_ station: Station?) -> Void
    let onCancel: () -> Void
    let onDelete: ((Station) -> Void)?
    let wasInitialisedWithAStation: Bool

    @State private var searchResults: [SearchResult] = []
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

                            if searchResults.count > 0 {
                                DefaultDivider()
                                StationsList(
                                    searchResults: searchResults,
                                    maxResults: 5,
                                    onSelect: { searchResult in
                                        setStation(searchResult)
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
                ForEach(TransportType.allCases, id: \.self) { transportType in
                    if temporarySelectedStation?.hasProduct(transportType) ?? true {
                        transportToggle(
                            transportType: transportType,
                            label: transportType.label,
                            forceEnable: temporarySelectedStation?.products.count ?? 0 < 2
                        )
                    }
                }
            }
            .padding(.horizontal, hPadding)
            .padding(.vertical, vPadding)
        }
    }

    private func transportToggle(
        transportType: TransportType, label: String, forceEnable: Bool = false
    )
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
                    get: { temporarySelectedStation?.isProductEnabled(transportType) ?? false },
                    set: { _ in temporarySelectedStation?.toggleProduct(transportType) }
                )
            )
            .labelsHidden()
            .tint(Color.dDefault)
            .disabled(forceEnable)
        }
        .onAppear {
            if forceEnable {
                temporarySelectedStation?.setProduct(transportType, enabled: true)
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

    private func setStation(_ searchResult: SearchResult) {
        // Store the selection temporarily
        temporarySelectedStation = Station(
            id: searchResult.id,
            name: !searchResult.name.isEmpty ? searchResult.name : searchResult.displayName,
            latitude: searchResult.latitude,
            longitude: searchResult.longitude,
            products: searchResult.products
        )

        // Clear search results
        searchResults = []
        showingSuggestedLocations = false
        isSearchFieldFocused = false
    }

    private func performSearch(query: String) async {
        if query.isEmpty {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true
        searchResults = []

        let transportService = TransportService()
        searchResults = await transportService.searchLocations(query: query)
        isSearching = false
    }
}
