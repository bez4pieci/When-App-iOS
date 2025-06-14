import PhosphorSwift
import SwiftData
import SwiftUI
import TripKit

struct StationSearchField: View {
    let selectedStation: Station?
    let onSearch: (String) async -> Void

    @State private var searchText: String = ""
    @State private var debounceTimer: Timer?
    @State private var searchTask: Task<Void, Never>?
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Ph.mapPinSimple.regular
                .frame(width: 24, height: 24)

            TextField(
                "",
                text: $searchText,
                prompt: Text("Search for a station").foregroundColor(Color.dLight)
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
                    searchText = ""
                    isSearchFieldFocused = true
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
