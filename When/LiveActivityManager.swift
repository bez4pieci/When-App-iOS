import ActivityKit
import FirebaseFirestore
import Foundation
import TripKit

class LiveActivityManager: ObservableObject {
    @Published var activeStationIDs: Set<String> = []
    private lazy var db = Firestore.firestore()

    func isLiveActivityActive(for stationId: String) -> Bool {
        activeStationIDs.contains(stationId)
    }

    func stopAllActivities() {
        let existingActivities = Activity<DeparturesActivityAttributes>.activities

        print("Live Activity: Stopping \(existingActivities.count) existing activities...")

        Task {
            for activity in existingActivities {
                await activity.end(nil, dismissalPolicy: .immediate)
                print("Live Activity: Ended activity with ID: \(activity.id)")
            }
        }
    }

    func stopLiveActivity(for stationId: String) async {
        guard let activity = getActivityByStationId(stationId: stationId) else {
            print("Live Activity: No activity found for station ID: \(stationId)")
            return
        }

        print("Live Activity: Stopping activity for station ID: \(stationId)...")

        await activity.end(nil, dismissalPolicy: .immediate)
        print(
            "Live Activity: Ended activity with ID: \(activity.id) for station ID: \(stationId)"
        )

    }

    func startLiveActivity(station: Station, departures: [Departure]) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activity: Activities are not enabled")
            return
        }

        for activity in Activity<DeparturesActivityAttributes>.activities {
            print("Listing Live Activity \(activity.id)")
            print(activity.attributes)
        }

        if let activity = getActivityByStationId(stationId: station.id) {
            print(
                "Live Activity: Ending existing activity for station \(station.name) before starting a new one."
            )
            await activity.end(nil, dismissalPolicy: .immediate)
        }

        print("Live Activity: Starting for station \(station.name)...")

        let contentState = createContentState(from: departures)
        let activity: Activity<DeparturesActivityAttributes>

        do {
            activity = try Activity<DeparturesActivityAttributes>.request(
                attributes: DeparturesActivityAttributes(
                    stationName: station.name,
                    stationId: station.id
                ),
                content: .init(state: contentState, staleDate: Date().addingTimeInterval(60)),
                pushType: .token
            )
        } catch {
            print("Live Activity: Error starting: \(error)")
            return
        }

        print("Live Activity: Started for station \(station.name)!")

        observeActivity(activity: activity, station: station)
    }

    private func getActivityByStationId(stationId: String) -> Activity<
        DeparturesActivityAttributes
    >? {
        for activity in Activity<DeparturesActivityAttributes>.activities {
            if activity.attributes.stationId == stationId {
                return activity
            }
        }

        return nil
    }

    private func observeActivity(
        activity: Activity<DeparturesActivityAttributes>,
        station: Station
    ) {
        let stationId = station.id
        let stationName = station.name

        Task {
            for await state in activity.activityStateUpdates {
                if state == .active {
                    print("Live Activity: State changed to active for \(stationName)")
                    await addActiveStation(stationId)
                } else {
                    print("Live Activity: State changed to inactive for \(stationName)")
                    await deleteLiveActivityFromFirestore(activityId: activity.id)
                    await removeActiveStation(stationId)
                }
            }
        }

        Task {
            for await pushToken in activity.pushTokenUpdates {
                let pushTokenString = pushToken.map { String(format: "%02x", $0) }.joined()

                print("Live Activity: received push token for \(stationName)")

                await self.saveLiveActivityToFirestore(
                    token: pushTokenString,
                    activityId: activity.id,
                    station: station
                )
            }
        }
    }

    @MainActor
    private func addActiveStation(_ id: String) {
        activeStationIDs.insert(id)
    }

    @MainActor
    private func removeActiveStation(_ id: String) {
        activeStationIDs.remove(id)
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

    private func saveLiveActivityToFirestore(
        token: String,
        activityId: String,
        station: Station
    ) async {
        let appSettings = AppSettings()

        let data: [String: Any] = [
            "pushToken": token,
            "activityId": activityId,
            "userDeviceId": appSettings.userDeviceId,
            "stationId": station.id,
            "stationName": station.name,
            "createdAt": FieldValue.serverTimestamp(),
            "enabledProducts": station.enabledProductStrings,
            "showCancelledDepartures": station.showCancelledDepartures,
        ]

        do {
            try await db.collection("liveActivities").document(activityId).setData(
                data)
            print("Live Activity: Saved to Firestore for activityId \(activityId)")
        } catch {
            print("Live Activity: Error saving to Firestore: \(error)")
            await stopLiveActivity(for: station.id)
        }
    }

    // Delete live activity from Firestore
    private func deleteLiveActivityFromFirestore(activityId: String) async {
        do {
            try await db.collection("liveActivities").document(activityId).delete()
            print(
                "Live Activity: Deleted from Firestore for activityId \(activityId)"
            )
        } catch {
            print("Live Activity: Error deleting from Firestore: \(error)")
        }
    }
}
