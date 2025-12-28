import ActivityKit
import Foundation

/// Attributes for the workout Live Activity.
/// This file must be included in both the Runner and WorkoutWidget targets.
struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Only dynamic values that change during the activity
        var restEndTime: String?
    }

    // Only immutable values that identify the activity
    var workoutType: String
}
