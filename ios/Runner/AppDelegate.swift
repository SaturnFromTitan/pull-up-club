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
        self.updateLiveActivity(call: call, result: result)
      } else if call.method == "endActivity" {
        self.endLiveActivity(call: call, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func startLiveActivity(call: FlutterMethodCall, result: @escaping FlutterResult) async {
    guard let args = call.arguments as? [String: Any],
          let workoutType = args["workoutType"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
      return
    }
    print("LiveActivity start")

    // End any existing activity before starting a new one to avoid race conditions
    if let existingActivity = currentActivity {
      await existingActivity.end(dismissalPolicy: .immediate)
    }

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
        result(activity.id)
      }
    } catch {
      await MainActor.run {
        result(FlutterError(code: "START_FAILED", message: error.localizedDescription, details: nil))
      }
    }
  }

  private func updateLiveActivity(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let activityId = args["activityId"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
      return
    }

    let restEndTimeString = args["restEndTime"] as? String
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
    // End the current activity if it exists
    if let existingActivity = currentActivity {
      Task {
        await existingActivity.end(dismissalPolicy: .immediate)
        await MainActor.run {
          self.currentActivity = nil
          result(nil)
        }
      }
    } else {
      result(nil) // No activity to end, but that's fine
    }
  }
}
