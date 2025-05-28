import ActivityKit
import BackgroundTasks
import Foundation
import TripKit
import UIKit

class LiveActivityManager: ObservableObject {
    @Published var isLiveActivityActive = false
    private var currentActivity: Activity<DeparturesActivityAttributes>?
    private var updateTimer: Timer?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    // Background task identifier
    private let backgroundTaskIdentifier = "com.departures.liveactivity.refresh"

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
            // Request activity without push type for local updates only
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
                            self.stopAllBackgroundTasks()
                        }
                    }
                }
            }

            currentActivity = activity
            isLiveActivityActive = true

            // Start the update timer for foreground updates
            startUpdateTimer()

            // Schedule background task for background updates
            scheduleBackgroundRefresh()

            // Start extended background execution
            startBackgroundTask()

        } catch {
            print("Error starting live activity: \(error)")
        }
    }

    // Update the live activity
    func updateLiveActivity(departures: [Departure]) {
        guard let activity = currentActivity else { return }

        let contentState = createContentState(from: departures)

        Task {
            // Update with a stale date of 60 seconds from now
            // This ensures the UI shows when data might be outdated
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
        stopAllBackgroundTasks()

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

    // Timer management for foreground updates
    private func startUpdateTimer() {
        stopUpdateTimer()

        // Update every 30 seconds when in foreground
        updateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            NotificationCenter.default.post(name: .liveActivityNeedsUpdate, object: nil)
        }
    }

    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: backgroundTaskIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
    }

    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30)  // 30 seconds from now

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background refresh scheduled")
        } catch {
            print("Could not schedule background refresh: \(error)")
        }
    }

    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        // Schedule the next background refresh
        scheduleBackgroundRefresh()

        // Create a task to update the Live Activity
        let updateTask = Task {
            // Check if we have an active Live Activity
            guard let activity = currentActivity,
                activity.activityState == .active
            else {
                task.setTaskCompleted(success: true)
                return
            }

            // Post notification to fetch new departures
            print("Posting background refresh notification to fetch new departures")
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .liveActivityNeedsBackgroundUpdate,
                    object: nil
                )
            }

            // Give the app some time to fetch and update the data
            try? await Task.sleep(nanoseconds: 5_000_000_000)  // 5 seconds

            task.setTaskCompleted(success: true)
        }

        // Provide the task with an expiration handler
        task.expirationHandler = {
            updateTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }

    private func startBackgroundTask() {
        // End any existing background task first
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }

        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.stopAllBackgroundTasks()
        }

        // Schedule periodic updates while in background
        Task {
            while backgroundTask != .invalid && isLiveActivityActive {
                // Wait 30 seconds
                try? await Task.sleep(nanoseconds: 30_000_000_000)

                // Check if still active
                guard isLiveActivityActive else { break }

                // Post update notification
                print("Posting background task notification to fetch new departures")
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .liveActivityNeedsBackgroundUpdate,
                        object: nil
                    )
                }
            }
        }
    }

    /// Stops all types of background tasks and cleanup
    private func stopAllBackgroundTasks() {
        // Cancel scheduled background refresh tasks
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundTaskIdentifier)

        // End extended background execution
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }

    deinit {
        stopUpdateTimer()
        stopAllBackgroundTasks()
    }
}

// Notification for updates
extension Notification.Name {
    static let liveActivityNeedsUpdate = Notification.Name("liveActivityNeedsUpdate")
    static let liveActivityNeedsBackgroundUpdate = Notification.Name(
        "liveActivityNeedsBackgroundUpdate")
}
