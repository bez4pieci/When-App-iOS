import PhosphorSwift
import SwiftData
import SwiftUI
import TripKit

struct StationSearchField: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Station.selectedAt, order: .reverse) private var stations: [Station]

    let onSearch: (String) async -> Void

    @State private var searchText: String = ""
    @State private var debounceTimer: Timer?
    @State private var searchTask: Task<Void, Never>?
    @FocusState private var isSearchFieldFocused: Bool

    private var selectedStation: Station? {
        stations.first
    }

    var body: some View {
        HStack(spacing: 12) {
            Ph.mapPinSimple.regular
                .frame(width: 24, height: 24)

            TextField(
                "", text: $searchText,
                prompt: Text("Search for station...").foregroundColor(Color.dLight)
            )
            .textFieldStyle(PlainTextFieldStyle())
            .foregroundColor(Color.dDefault)
            .disableAutocorrection(true)
            .focused($isSearchFieldFocused)
            .onChange(of: searchText) { _, newValue in
                if !isSearchFieldFocused {
                    return
                }

                // Debounce search
                debounceTimer?.invalidate()
                searchTask?.cancel()

                debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) {
                    _ in
                    searchTask = Task {
                        await onSearch(newValue)
                    }
                }
            }

            if !searchText.isEmpty {
                Button(action: {
                    // Clear search and selected station
                    searchText = ""

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
        .padding(.vertical, 32)
        .background(Color.white)
        .onAppear {
            searchText = selectedStation?.name ?? ""
        }
        .onChange(of: selectedStation) { _, newStation in
            if let station = newStation {
                isSearchFieldFocused = false
                Task {
                    searchText = station.name
                }
            }
        }
    }
}
