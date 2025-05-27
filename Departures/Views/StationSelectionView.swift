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
                        StationSearchResults(searchResults: searchResults)
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
}
