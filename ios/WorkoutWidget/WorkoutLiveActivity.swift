import ActivityKit
import WidgetKit
import SwiftUI
import Foundation

/// Helper function to parse ISO8601 date strings from Flutter
func parseISO8601Date(from string: String) -> Date? {
    // Dart's toIso8601String() produces format like "2024-12-27T12:34:56.789Z"
    // Try ISO8601DateFormatter with different option combinations
    let formatOptionsList: [ISO8601DateFormatter.Options] = [
        [.withInternetDateTime, .withFractionalSeconds, .withTimeZone], // "2024-12-27T12:34:56.789Z"
        [.withInternetDateTime, .withTimeZone], // "2024-12-27T12:34:56Z"
    ]

    for formatOptions in formatOptionsList {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = formatOptions
        // Don't set timeZone - let the formatter use the timezone from the string (Z = UTC)
        if let date = formatter.date(from: string) {
            print("parseISO8601Date: Successfully parsed '\(string)' to \(date)")
            return date
        }
    }

    // Fallback: try DateFormatter with explicit format
    let fallbackFormatter = DateFormatter()
    fallbackFormatter.locale = Locale(identifier: "en_US_POSIX")
    fallbackFormatter.timeZone = TimeZone(secondsFromGMT: 0)

    // Try with fractional seconds first
    fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    if let date = fallbackFormatter.date(from: string) {
        print("parseISO8601Date: Successfully parsed '\(string)' to \(date) (with fractional seconds)")
        return date
    }

    // Try without fractional seconds
    fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    if let date = fallbackFormatter.date(from: string) {
        print("parseISO8601Date: Successfully parsed '\(string)' to \(date) (without fractional seconds)")
        return date
    }

    print("parseISO8601Date: Failed to parse '\(string)'")
    return nil
}

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
            if let endTimeString = restEndTime {
                if let endTimeUTC = parseISO8601Date(from: endTimeString) {
                    // Convert UTC time to local time for the timer
                    // The parsed date is in UTC, but Date.now is in local timezone
                    // So we need to use the UTC date directly - Date.now will be compared correctly
                    // Actually, Date objects are timezone-agnostic, so we can use them directly
                    Text(timerInterval: Date()...endTimeUTC, countsDown: true)
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundColor(.orange)
                } else {
                    // Date parsing failed - log for debugging
                    Text("--:--")
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundColor(.orange)
                        .onAppear {
                            print("RestTimerView: Failed to parse date '\(endTimeString)'")
                        }
                }
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
        if let endTimeString = restEndTime {
            if let endTimeUTC = parseISO8601Date(from: endTimeString) {
                Text(timerInterval: Date()...endTimeUTC, countsDown: true)
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundColor(.orange)
            } else {
                // Date parsing failed
                Text("--")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        } else {
            Text("--")
                .font(.caption2)
                .foregroundColor(.orange)
        }
    }
}
