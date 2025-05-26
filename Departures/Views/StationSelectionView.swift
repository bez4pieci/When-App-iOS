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

    var body: some View {
        NavigationStack {
            ZStack {
                Color.yellow
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar

                    // Results
                    if isSearching {
                        loadingView
                    } else if searchResults.isEmpty && !searchText.isEmpty {
                        emptyResultsView
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

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.dDefault)

                TextField(
                    "", text: $searchText,
                    prompt: Text("Search for station...").foregroundColor(Color.dLight)
                )
                .textFieldStyle(DefaultTextFieldStyle())
                .foregroundColor(Color.dDefault)
                .disableAutocorrection(true)
                .focused($isSearchFieldFocused)
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
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                .scaleEffect(1.5)
                .padding()

            Text("Searching...")
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
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.white)

            Text("Try a different search term")
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
            let provider = BvgProvider(apiAuthorization: [
                "type": "AID", "aid": "dVg4TZbW8anjx9ztPwe2uk4LVRi9wO",
            ])
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
