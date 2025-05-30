import ActivityKit
import FirebaseFirestore
import Foundation
import TripKit

class LiveActivityManager: ObservableObject {
    @Published var isLiveActivityActive = false
    private var currentActivity: Activity<DeparturesActivityAttributes>?
    private lazy var db = Firestore.firestore()

    // Start the live activity
    func startLiveActivity(station: Station, departures: [Departure]) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activity: Activities are not enabled")
            return
        }

        // Stop any existing activity
        stopLiveActivity()

        print("Live Activity: Starting...")

        let attributes = DeparturesActivityAttributes(
            stationName: station.name,
            stationId: station.id
        )

        let contentState = createContentState(from: departures)
        let activity: Activity<DeparturesActivityAttributes>

        do {
            activity = try Activity<DeparturesActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: Date().addingTimeInterval(60)),
                pushType: .token
            )
        } catch {
            print("Live Activity: Error starting: \(error)")
            isLiveActivityActive = false
            return
        }

        print("Live Activity: Started!")

        observeActivity(activity: activity, station: station)

        currentActivity = activity
        isLiveActivityActive = true
    }

    // Stop the live activity
    func stopLiveActivity() {
        guard let activity = currentActivity else { return }

        Task {
            // Delete from Firestore
            await deleteLiveActivityFromFirestore(activityId: activity.id)

            await activity.end(nil, dismissalPolicy: .immediate)
            await MainActor.run {
                self.currentActivity = nil
                self.isLiveActivityActive = false
            }
        }
    }

    private func observeActivity(
        activity: Activity<DeparturesActivityAttributes>, station: Station
    ) {
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { @MainActor in
                    for await state in activity.activityStateUpdates {
                        await MainActor.run {
                            self.isLiveActivityActive = state == .active
                            if state != .active {
                                self.currentActivity = nil
                            }
                        }
                    }
                }

                group.addTask { @MainActor in
                    for await pushToken in activity.pushTokenUpdates {
                        let pushTokenString = pushToken.map { String(format: "%02x", $0) }.joined()

                        // Save to Firestore
                        await self.saveLiveActivityToFirestore(
                            token: pushTokenString,
                            activityId: activity.id,
                            stationId: station.id,
                            stationName: station.name
                        )
                    }
                }
            }
        }
    }

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
            )
        }

        return DeparturesActivityAttributes.ContentState(
            departures: Array(departureInfos),
            lastUpdate: Date()
        )
    }

    // Save live activity to Firestore
    private func saveLiveActivityToFirestore(
        token: String, activityId: String, stationId: String, stationName: String
    ) async {
        let appSettings = AppSettings()

        let data: [String: Any] = [
            "pushToken": token,
            "activityId": activityId,
            "userDeviceId": appSettings.userDeviceId,
            "stationId": stationId,
            "stationName": stationName,
            "createdAt": FieldValue.serverTimestamp(),
        ]

        do {
            try await db.collection("liveActivities").document(appSettings.userDeviceId).setData(
                data)
            print("Live Activity: Saved to Firestore for userDeviceId \(appSettings.userDeviceId)")
        } catch {
            print("Live Activity: Error saving to Firestore: \(error)")
            stopLiveActivity()
        }
    }

    // Delete live activity from Firestore
    private func deleteLiveActivityFromFirestore(activityId: String) async {
        do {
            let appSettings = AppSettings()

            try await db.collection("liveActivities").document(appSettings.userDeviceId).delete()
            print(
                "Live Activity: Deleted from Firestore for userDeviceId \(appSettings.userDeviceId)"
            )
        } catch {
            print("Live Activity: Error deleting from Firestore: \(error)")
        }
    }
}
