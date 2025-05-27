import SwiftData
import SwiftUI
import TripKit

struct StationSearchResults: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let searchResults: [SuggestedLocation]
    let maxResults: Int?
    let onSelect: ((Location) -> Void)?

    init(
        searchResults: [SuggestedLocation], maxResults: Int? = nil,
        onSelect: ((Location) -> Void)? = nil
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
                index, suggestedLocation in
                stationRow(suggestedLocation.location)
                if index < results.count - 1 {
                    DefaultDivider()
                }
            }
        }
    }

    private func stationRow(_ location: Location) -> some View {
        Button(action: {
            if let onSelect = onSelect {
                onSelect(location)
            } else {
                selectStation(location)
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.getUniqueShortName())
                        .font(Font.dNormal)
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
            .padding(.vertical, 12)
            .background(Color.white)
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
