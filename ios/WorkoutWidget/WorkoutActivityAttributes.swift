import ActivityKit
import Foundation

/// Attributes for the workout Live Activity.
/// This file must be included in both the Runner and WorkoutWidget targets.
struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var workoutType: String
        var maxGroups: Int
        var completedSets: Int
        var totalReps: Int
        var isResting: Bool
        var restRemainingMillis: Int
        var restEndTime: String?
    }

    var workoutType: String
    var maxGroups: Int
    var completedSets: Int
    var totalReps: Int
}
