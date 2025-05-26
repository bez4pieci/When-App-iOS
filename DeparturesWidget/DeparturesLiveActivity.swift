import ActivityKit
import SwiftUI
import TripKit
import WidgetKit

// MARK: - Live Activity Widget
struct DeparturesLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DeparturesActivityAttributes.self) { context in
            // Lock screen/banner UI
            DeparturesLiveActivityView(context: context)
                .activityBackgroundTint(Color.yellow)
                .activitySystemActionForegroundColor(Color.dDefault)

        } dynamicIsland: { context in
            makeDynamicIsland(context: context)
        }
    }
}
