import SwiftData
import SwiftUI
import TripKit

struct StationSearchResults: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let searchResults: [SuggestedLocation]

    var body: some View {
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
