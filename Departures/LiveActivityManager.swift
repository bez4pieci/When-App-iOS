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
            print("Live Activities are not enabled")
            return
        }

        // Stop any existing activity
        stopLiveActivity()

        print("Starting live activity...")

        let attributes = DeparturesActivityAttributes(
            stationName: station.name,
            stationId: station.id
        )

        let contentState = createContentState(from: departures)

        do {
            let activity = try Activity<DeparturesActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: Date().addingTimeInterval(60)),
                pushType: .token
            )

            // Observe activity state changes
            Task {
                for await state in activity.activityStateUpdates {
                    await MainActor.run {
                        self.isLiveActivityActive = state == .active
                        if state != .active {
                            self.currentActivity = nil
                        }
                    }
                }
            }

            // Get push token for this activity
            Task {
                for await pushToken in activity.pushTokenUpdates {
                    let pushTokenString = pushToken.map { String(format: "%02x", $0) }.joined()
                    print("Live Activity Push Token: \(pushTokenString)")

                    // Save to Firestore
                    await saveLiveActivityToFirestore(
                        token: pushTokenString,
                        activityId: activity.id,
                        stationId: station.id,
                        stationName: station.name
                    )
                }
            }

            currentActivity = activity
            isLiveActivityActive = true

        } catch {
            print("Error starting live activity: \(error)")
        }
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

        print("Saving live activity to Firestore with userDeviceId: \(appSettings.userDeviceId)")

        let data: [String: Any] = [
            "pushToken": token,
            "activityId": activityId,
            "userDeviceId": appSettings.userDeviceId,
            "stationId": stationId,
            "stationName": stationName,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "isActive": true,
        ]

        do {
            try await db.collection("liveActivities").document(appSettings.userDeviceId).setData(
                data)
            print(
                "Live activity saved to Firestore with for userDeviceId \(appSettings.userDeviceId)"
            )
        } catch {
            print("Error saving live activity to Firestore: \(error)")
        }
    }

    // Delete live activity from Firestore
    private func deleteLiveActivityFromFirestore(activityId: String) async {
        do {
            let appSettings = AppSettings()

            try await db.collection("liveActivities").document(appSettings.userDeviceId).delete()
            print(
                "Deleted live activity from Firestore for userDeviceId \(appSettings.userDeviceId)")
        } catch {
            print("Error deleting live activity in Firestore: \(error)")
        }
    }
}
