import ActivityKit
import Foundation
import TripKit

class LiveActivityManager: ObservableObject {
    @Published var isLiveActivityActive = false
    private var currentActivity: Activity<DeparturesActivityAttributes>?
    private var updateTimer: Timer?

    // Start the live activity
    func startLiveActivity(station: Station, departures: [Departure]) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }

        // Stop any existing activity
        stopLiveActivity()

        let attributes = DeparturesActivityAttributes(
            stationName: station.name,
            stationId: station.id
        )

        let contentState = createContentState(from: departures)

        do {
            let activity = try Activity<DeparturesActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: Date().addingTimeInterval(60))
            )

            // Observe activity state changes
            Task {
                for await state in activity.activityStateUpdates {
                    await MainActor.run {
                        self.isLiveActivityActive = state == .active
                        if state != .active {
                            self.currentActivity = nil
                            self.stopUpdateTimer()
                        }
                    }
                }
            }

            currentActivity = activity
            isLiveActivityActive = true

            // Start the update timer
            startUpdateTimer()

        } catch {
            print("Error starting live activity: \(error)")
        }
    }

    // Update the live activity
    func updateLiveActivity(departures: [Departure]) {
        guard let activity = currentActivity else { return }

        let contentState = createContentState(from: departures)

        Task {
            await activity.update(
                ActivityContent(
                    state: contentState,
                    staleDate: Date().addingTimeInterval(60)
                )
            )
        }
    }

    // Stop the live activity
    func stopLiveActivity() {
        stopUpdateTimer()

        guard let activity = currentActivity else { return }

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            await MainActor.run {
                self.currentActivity = nil
                self.isLiveActivityActive = false
            }
        }
    }

    // Create content state from departures
    private func createContentState(from departures: [Departure])
        -> DeparturesActivityAttributes.ContentState
    {
        let departureInfos = departures.prefix(4).map { departure in
            DeparturesActivityAttributes.ContentState.DepartureInfo(
                lineLabel: departure.line.label ?? "",
                destination: departure.destination?.name ?? "",
                plannedTime: departure.plannedTime,
                predictedTime: departure.predictedTime,
                isCancelled: departure.cancelled,
                lineBackgroundColor: Int(departure.line.style?.backgroundColor ?? 0x808080),
                lineForegroundColor: Int(departure.line.style?.foregroundColor ?? 0x000000)
            )
        }

        return DeparturesActivityAttributes.ContentState(
            departures: Array(departureInfos),
            lastUpdate: Date()
        )
    }

    // Timer management
    private func startUpdateTimer() {
        stopUpdateTimer()

        // Update every 30 seconds
        updateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            NotificationCenter.default.post(name: .liveActivityNeedsUpdate, object: nil)
        }
    }

    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    deinit {
        stopUpdateTimer()
    }
}

// Notification for updates
extension Notification.Name {
    static let liveActivityNeedsUpdate = Notification.Name("liveActivityNeedsUpdate")
}
