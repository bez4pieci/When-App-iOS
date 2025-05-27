import SwiftData
import SwiftUI
import TripKit

struct DepartureBoard: View {
    @EnvironmentObject private var liveActivityManager: LiveActivityManager
    let station: Station
    let departures: [Departure]
    let onRefresh: () async -> Void

    var body: some View {
        HStack {
            Text("Show Live")
                .font(Font.dNormal)
                .foregroundColor(Color.dDefault)
            Spacer()
            Toggle("", isOn: $liveActivityManager.isLiveActivityActive)
                .labelsHidden()
                .tint(Color.dDefault)
                .onChange(of: liveActivityManager.isLiveActivityActive) {
                    _, isActive in
                    handleLiveActivityToggle(isActive: isActive, station: station)
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)

        DefaultDivider()
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(departures.enumerated()), id: \.offset) { index, departure in
                    DepartureRow(departure: departure)
                    DefaultDivider()
                }
            }
        }
        .refreshable {
            await onRefresh()
        }
    }

    func handleLiveActivityToggle(isActive: Bool, station: Station) {
        if isActive {
            liveActivityManager.startLiveActivity(
                station: station, departures: departures)
        } else {
            liveActivityManager.stopLiveActivity()
        }
    }
}
