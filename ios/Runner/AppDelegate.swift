import Flutter
import UIKit
import ActivityKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var currentActivity: Activity<WorkoutActivityAttributes>?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    guard let registrar = self.registrar(forPlugin: "LiveActivityPlugin") else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    let liveActivityChannel = FlutterMethodChannel(
      name: "pull_up_club/live_activity",
      binaryMessenger: registrar.messenger()
    )

    liveActivityChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "startActivity" {
        Task {
          await self.startLiveActivity(call: call, result: result)
        }
      } else if call.method == "updateActivity" {
        Task {
          await self.updateLiveActivity(call: call, result: result)
        }
      } else if call.method == "endActivity" {
        Task {
          await self.endLiveActivity(call: call, result: result)
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // Clean up any stale activities on app launch
    Task {
      await self.endAllActivities()
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func endAllActivities() async {
    let activities = Activity<WorkoutActivityAttributes>.activities
    for activity in activities {
      await activity.end(dismissalPolicy: .immediate)
    }
    await MainActor.run {
      self.currentActivity = nil
    }
  }

  private func startLiveActivity(call: FlutterMethodCall, result: @escaping FlutterResult) async {
    guard let args = call.arguments as? [String: Any],
          let workoutType = args["workoutType"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
      return
    }
    print("LiveActivity start")

    // End existing activities beforehand to avoid race conditions
    await endAllActivities()

    let attributes = WorkoutActivityAttributes(
      workoutType: workoutType
    )
    let contentState = WorkoutActivityAttributes.ContentState(
      restEndTime: nil,
    )

    do {
      let activity = try Activity<WorkoutActivityAttributes>.request(
        attributes: attributes,
        contentState: contentState,
        pushType: nil
      )
      await MainActor.run {
        self.currentActivity = activity
        result(nil)
      }
    } catch {
      await MainActor.run {
        result(FlutterError(code: "START_FAILED", message: error.localizedDescription, details: nil))
      }
    }
  }

  private func updateLiveActivity(call: FlutterMethodCall, result: @escaping FlutterResult) async {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
      return
    }

    let restEndTimeString = args["restEndTime"] as? String
    print("LiveActivity update: restEndTime='\(restEndTimeString ?? "nil")'")

    let contentState = WorkoutActivityAttributes.ContentState(
      restEndTime: restEndTimeString,
    )

    // Use the stored activity, or find the first active activity if we lost track of it
    // (e.g., after app restart)
    var activityToUpdate: Activity<WorkoutActivityAttributes>?
    await MainActor.run {
      if let activity = self.currentActivity {
        activityToUpdate = activity
      } else {
        // Restore from active activities if we lost track (e.g., after app restart)
        activityToUpdate = Activity<WorkoutActivityAttributes>.activities.first
        if let restoredActivity = activityToUpdate {
          self.currentActivity = restoredActivity
        }
      }
    }

    guard let activity = activityToUpdate else {
      await MainActor.run {
        result(FlutterError(code: "ACTIVITY_NOT_FOUND", message: "No active activity found", details: nil))
      }
      return
    }

    await activity.update(using: contentState)
    await MainActor.run {
      result(nil)
    }
  }

  private func endLiveActivity(call: FlutterMethodCall, result: @escaping FlutterResult) async {
    await endAllActivities()
    await MainActor.run {
      result(nil)
    }
  }
}
