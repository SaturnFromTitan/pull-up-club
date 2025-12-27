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
                // Expanded Regions
                DynamicIslandExpandedRegion(.leading) {
                    EmptyView()
                }
                DynamicIslandExpandedRegion(.trailing) {
                    EmptyView()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    EmptyView()
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
                    if let endTimeString = context.state.restEndTime,
                       let endTimeUTC = parseISO8601Date(from: endTimeString) {
                        // Display timer when resting
                        Text(timerInterval: Date()...endTimeUTC, countsDown: true)
                            .font(.caption2)
                            .monospacedDigit()
                            .foregroundColor(.orange)
                            .lineLimit(1)
                    } else if context.state.restEndTime != nil {
                        // Parsing failed, show fallback
                        Text("--")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    } else {
                        // Display "Go!" when not resting
                        Text("Go!")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                .frame(minWidth: 35, maxWidth: 35) // Constrain width to keep Dynamic Island compact
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
            // App icon
            Image("AppIconImage")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(context.attributes.workoutType)
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            // Rest timer or status - positioned at very right
            if context.state.restEndTime != nil {
                Group {
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
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                Text("Go!")
                    .font(.caption)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding()
    }
}
