import ActivityKit
import SwiftUI
import TripKit
import WidgetKit

struct DeparturesLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DeparturesActivityAttributes.self) { context in
            DeparturesLiveActivityView(context: context)
                .activityBackgroundTint(Color.dBackground)
                .activitySystemActionForegroundColor(Color.dDefault)

        } dynamicIsland: { context in
            // Temporary dynamic island implementation that effectively disables it
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    EmptyView()
                }
            } compactLeading: {
                EmptyView()
            } compactTrailing: {
                EmptyView()
            } minimal: {
                EmptyView()
            }
        }
    }
}
