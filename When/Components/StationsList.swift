import SwiftData
import SwiftUI

struct StationsList: View {
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
            ForEach(Array(results.enumerated()), id: \.offset) {
                index, searchResult in
                stationRow(searchResult)
                if index < results.count - 1 {
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
                    Text(searchResult.name)
                        .font(Font.dNormal)
                        .foregroundColor(Color.dDefault)

                    if !searchResult.products.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(Array(searchResult.products.enumerated()), id: \.offset) {
                                index, product in
                                HStack(spacing: 0) {
                                    Text(product.displayName)
                                    if index < searchResult.products.count - 1 {
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
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(Color.white)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
