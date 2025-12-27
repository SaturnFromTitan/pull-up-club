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
                        Text(context.attributes.workoutType)
                            .font(.headline)
                            .foregroundColor(.white)
                        if context.state.restEndTime != nil {
                            Text("Resting")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        } else {
                            Text("Active")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.restEndTime != nil {
                        RestTimerView(restEndTime: context.state.restEndTime)
                    } else {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Go!")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.restEndTime != nil {
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
                // Compact leading UI - app icon
                Image("AppIconImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            } compactTrailing: {
                // Compact trailing UI - keep width consistent
                Group {
                    if context.state.restEndTime != nil {
                        // Display timer when resting - constrain width to match "Go!"
                        if let endTimeString = context.state.restEndTime,
                           let endTimeUTC = parseISO8601Date(from: endTimeString) {
                            Text(timerInterval: Date()...endTimeUTC, countsDown: true)
                                .font(.caption2)
                                .monospacedDigit()
                                .foregroundColor(.orange)
                                .lineLimit(1)
                        } else {
                            Text("--")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    } else {
                        // Display "Go!" when not resting
                        Text("Go!")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                .frame(minWidth: 30, maxWidth: 35) // Constrain width to keep Dynamic Island compact
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
                // Workout type
                Text(context.attributes.workoutType)
                    .font(.headline)
                    .foregroundColor(.white)

                // Status
                if context.state.restEndTime != nil {
                    Text("Resting")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            Spacer()

            // Rest timer or status - positioned at very right, timer above "Rest" text
            if context.state.restEndTime != nil {
                VStack(alignment: .trailing, spacing: 2) {
                    if let endTimeString = context.state.restEndTime,
                       let endTimeUTC = parseISO8601Date(from: endTimeString) {
                        Text(timerInterval: Date()...endTimeUTC, countsDown: true)
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
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Go!")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding()
    }
}

/// Rest timer view that shows countdown (used in Dynamic Island expanded view)
struct RestTimerView: View {
    let restEndTime: String?

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if let endTimeString = restEndTime {
                if let endTimeUTC = parseISO8601Date(from: endTimeString) {
                    Text(timerInterval: Date()...endTimeUTC, countsDown: true)
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundColor(.orange)
                } else {
                    Text("--:--")
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundColor(.orange)
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
        Group {
            if let endTimeString = restEndTime {
                if let endTimeUTC = parseISO8601Date(from: endTimeString) {
                    // Use a compact format to minimize width - same width as "1/3" format
                    Text(timerInterval: Date()...endTimeUTC, countsDown: true)
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundColor(.orange)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
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
        .frame(minWidth: 30, maxWidth: 40) // Constrain width to match non-resting state
    }
}
