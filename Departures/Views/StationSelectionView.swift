import PhosphorSwift
import SwiftData
import SwiftUI
import TripKit

struct StationSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFieldFocused: Bool

    @State private var searchText = ""
    @State private var searchResults: [SuggestedLocation] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var debounceTimer: Timer?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.yellow
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar

                    if isSearching {
                        loadingView
                    } else if !searchResults.isEmpty {
                        resultsView
                    } else {
                        Spacer()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.dDefault)
                }
            }
            .toolbarBackground(Color.yellow, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationBackground(Color.black)
        .onAppear {
            isSearchFieldFocused = true
        }
    }

    private var searchBar: some View {
        VStack {
            DefaultDivider()

            HStack(spacing: 12) {
                Ph.mapPinSimple.regular
                    .frame(width: 24, height: 24)

                TextField(
                    "", text: $searchText,
                    prompt: Text("Search for station...").foregroundColor(Color.dLight)
                )
                .textFieldStyle(DefaultTextFieldStyle())
                .foregroundColor(Color.dDefault)
                .disableAutocorrection(true)
                .focused($isSearchFieldFocused)
                .onChange(of: searchText) { _, newValue in
                    debounceTimer?.invalidate()
                    searchTask?.cancel()
                    debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) {
                        _ in
                        searchTask = Task {
                            await performSearch(query: newValue)
                        }
                    }
                }

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        searchResults = []
                    }) {
                        Ph.x.regular
                            .frame(width: 24, height: 24)
                            .foregroundColor(Color.dLight)
                    }
                    .fixedSize()
                }
            }
            .padding()

            DefaultDivider()
        }
        .background(Color.white)
        .padding([.top], 1)
    }

    private var resultsView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(searchResults.enumerated()), id: \.offset) {
                    index, suggestedLocation in

                    stationRow(suggestedLocation.location)
                    DefaultDivider()
                }
            }
        }
    }

    private func stationRow(_ location: Location) -> some View {
        Button(action: { selectStation(location) }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.getUniqueShortName())
                        .foregroundColor(Color.dDefault)

                    if let products = location.products, !products.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(Array(products.enumerated()), id: \.element) { index, product in
                                HStack(spacing: 0) {
                                    Text(productLabel(for: product))
                                    if index < products.count - 1 {
                                        Text(",")
                                    }
                                }
                                .font(Font.dSmall)
                                .foregroundColor(Color.dLight)
                            }
                        }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func productLabel(for product: Product) -> String {
        switch product {
        case .suburbanTrain: return "S"
        case .subway: return "U"
        case .tram: return "Tram"
        case .bus: return "Bus"
        case .regionalTrain: return "RE"
        case .ferry: return "F"
        case .highSpeedTrain: return "ICE"
        case .onDemand: return "On Demand"
        case .cablecar: return "Cable Car"
        }
    }

    private var loadingView: some View {
        VStack {
            Text("Searching...").foregroundColor(Color.dLight)
        }
        .frame(maxHeight: .infinity)
    }

    private func performSearch(query: String) async {
        if query.isEmpty {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true

        do {
            let provider = BvgProvider(apiAuthorization: AppConfig.bvgApiAuthorization)
            let (_, result) = await provider.suggestLocations(constraint: query)

            switch result {
            case .success(let locations):
                searchResults = locations.filter { $0.location.type == .station }
            case .failure(let error):
                print("Search error: \(error)")
                searchResults = []
            }
        } catch {
            print("Search error: \(error)")
            searchResults = []
        }

        isSearching = false
    }

    private func selectStation(_ location: Location) {
        print("Selecting station: \(location.coord?.lat ?? 0), \(location.coord?.lon ?? 0)")
        let station = Station(
            id: location.id ?? UUID().uuidString,
            name: location.getUniqueShortName(),
            latitude: location.coord?.lat != nil ? Double(location.coord!.lat) / 1000000.0 : nil,
            longitude: location.coord?.lon != nil ? Double(location.coord!.lon) / 1000000.0 : nil
        )
        print("Selecting station: \(station.latitude), \(station.longitude)")

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
