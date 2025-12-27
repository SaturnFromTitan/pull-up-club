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
    let controller = window?.rootViewController as! FlutterViewController
    let liveActivityChannel = FlutterMethodChannel(
      name: "pull_up_club/live_activity",
      binaryMessenger: controller.binaryMessenger
    )

    liveActivityChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "startActivity" {
        self.startLiveActivity(call: call, result: result)
      } else if call.method == "updateActivity" {
        self.updateLiveActivity(call: call, result: result)
      } else if call.method == "endActivity" {
        self.endLiveActivity(call: call, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func startLiveActivity(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let workoutType = args["workoutType"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
      return
    }

    // End any existing activity
    if let existingActivity = currentActivity {
      Task {
        await existingActivity.end(dismissalPolicy: .immediate)
      }
    }

    let attributes = WorkoutActivityAttributes(
      workoutType: workoutType
    )

    print("LiveActivity start")

    let contentState = WorkoutActivityAttributes.ContentState(
      restEndTime: nil,
    )

    do {
      let activity = try Activity<WorkoutActivityAttributes>.request(
        attributes: attributes,
        contentState: contentState,
        pushType: nil
      )
      currentActivity = activity
      result(activity.id)
    } catch {
      result(FlutterError(code: "START_FAILED", message: error.localizedDescription, details: nil))
    }
  }

  private func updateLiveActivity(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let activityId = args["activityId"] as? String,
          let restEndTimeString = args["restEndTime"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
      return
    }

    print("LiveActivity update: restEndTime='\(restEndTimeString ?? "nil")'")

    let contentState = WorkoutActivityAttributes.ContentState(
      restEndTime: restEndTimeString,
    )

    Task {
      for activity in Activity<WorkoutActivityAttributes>.activities where activity.id == activityId {
        await activity.update(using: contentState)
        await MainActor.run {
          result(nil)
        }
        return
      }
      await MainActor.run {
        result(FlutterError(code: "ACTIVITY_NOT_FOUND", message: "Activity not found", details: nil))
      }
    }
  }

  private func endLiveActivity(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let activityId = args["activityId"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
      return
    }

    Task {
      for activity in Activity<WorkoutActivityAttributes>.activities where activity.id == activityId {
        await activity.end(dismissalPolicy: .immediate)
        if activity.id == currentActivity?.id {
          await MainActor.run {
            self.currentActivity = nil
          }
        }
        await MainActor.run {
          result(nil)
        }
        return
      }
      await MainActor.run {
        result(FlutterError(code: "ACTIVITY_NOT_FOUND", message: "Activity not found", details: nil))
      }
    }
  }
}
