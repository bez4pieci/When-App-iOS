import SwiftData
import SwiftUI

struct StationSearchResultsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let searchResults: [SearchResult]
    let maxResults: Int?
    let onSelect: ((SearchResult) -> Void)?

    init(
        searchResults: [SearchResult], maxResults: Int? = nil,
        onSelect: ((SearchResult) -> Void)? = nil
    ) {
        self.searchResults = searchResults
        self.maxResults = maxResults
        self.onSelect = onSelect
    }

    var body: some View {
        LazyVStack(spacing: 0) {
            let results =
                maxResults != nil ? Array(searchResults.prefix(maxResults!)) : searchResults
            ForEach(results, id: \.id) { searchResult in
                stationRow(searchResult)
                if searchResult.id != results.last?.id {
                    DefaultDivider()
                }
            }
        }
    }

    private func stationRow(_ searchResult: SearchResult) -> some View {
        Button(action: {
            if let onSelect = onSelect {
                onSelect(searchResult)
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(searchResult.stationName.forDisplay)
                        .font(Font.dNormal)
                        .foregroundColor(Color.dDefault)

                    if !searchResult.products.isEmpty {
                        HStack(spacing: 16) {
                            ForEach(Array(searchResult.products.enumerated()), id: \.offset) {
                                index, product in
                                Text(product.shortName)
                            }
                        }
                        .font(Font.dSmall)
                        .foregroundColor(Color.dLight)
                    }
                }
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(Color.white)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
