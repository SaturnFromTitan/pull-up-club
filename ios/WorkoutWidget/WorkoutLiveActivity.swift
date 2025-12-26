import ActivityKit
import WidgetKit
import SwiftUI

/// Live Activity widget view for workout state.
struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // Lock screen/banner UI
            WorkoutActivityView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.1))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI for Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.workoutType)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("\(context.state.completedSets)/\(context.state.maxGroups) sets")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isResting {
                        RestTimerView(restEndTime: context.state.restEndTime)
                    } else {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(context.state.totalReps) reps")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Active")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.isResting {
                        Text("Rest time remaining")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        Text("Continue your workout")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            } compactLeading: {
                // Compact leading UI
                Image(systemName: "figure.pullups")
                    .foregroundColor(.white)
            } compactTrailing: {
                // Compact trailing UI
                if context.state.isResting {
                    RestTimerCompactView(restEndTime: context.state.restEndTime)
                } else {
                    Text("\(context.state.completedSets)/\(context.state.maxGroups)")
                        .font(.caption2)
                        .foregroundColor(.white)
                }
            } minimal: {
                // Minimal UI
                Image(systemName: "figure.pullups")
                    .foregroundColor(.white)
            }
        }
    }
}

/// Main view for Lock Screen Live Activity
struct WorkoutActivityView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            // Workout icon
            Image(systemName: "figure.pullups")
                .font(.title2)
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 4) {
                // Workout type and progress
                Text(context.state.workoutType)
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Set \(context.state.completedSets) of \(context.state.maxGroups) • \(context.state.totalReps) reps")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            // Rest timer or status
            if context.state.isResting {
                RestTimerView(restEndTime: context.state.restEndTime)
            } else {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
    }
}

/// Rest timer view that shows countdown
struct RestTimerView: View {
    let restEndTime: String?

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if let endTimeString = restEndTime,
               let endTime = ISO8601DateFormatter().date(from: endTimeString) {
                Text(timerInterval: Date.now...endTime, countsDown: true)
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundColor(.orange)
            } else {
                Text("--:--")
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundColor(.orange)
            }
            Text("Rest")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

/// Compact rest timer view for Dynamic Island
struct RestTimerCompactView: View {
    let restEndTime: String?

    var body: some View {
        if let endTimeString = restEndTime,
           let endTime = ISO8601DateFormatter().date(from: endTimeString) {
            Text(timerInterval: Date.now...endTime, countsDown: true)
                .font(.caption2)
                .monospacedDigit()
                .foregroundColor(.orange)
        } else {
            Text("--")
                .font(.caption2)
                .foregroundColor(.orange)
        }
    }
}
