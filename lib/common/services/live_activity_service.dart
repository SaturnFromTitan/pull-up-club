import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:logging/logging.dart";
import "package:pull_up_club/domain/models.dart";

/// Service to manage Live Activities for workout state on iOS Lock Screen.
/// Uses platform channels to communicate with native iOS code.
class LiveActivityService {
  LiveActivityService._();
  static final LiveActivityService instance = LiveActivityService._();
  static final Logger _logger = Logger("LiveActivityService");

  static const MethodChannel _channel = MethodChannel("pull_up_club/live_activity");
  String? _currentActivityId;

  /// Starts a Live Activity for the given workout.
  Future<void> startActivity({required final Workout workout}) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      _logger.warning("Live Activities only supported on iOS");
      return;
    }

    try {
      _logger.info("Starting Live Activity: workout=$workout");

      final result = await _channel.invokeMethod<String>("startActivity", {
        "workoutType": workout.workoutType.name,
      });

      _currentActivityId = result;
      _logger.info("Live Activity started: $_currentActivityId");
    } on Exception catch (error, stackTrace) {
      _logger.severe("Failed to start Live Activity", error, stackTrace);
    }
  }

  /// Updates the current Live Activity with new state.
  Future<void> updateActivity({
    required final Workout workout,
    required final DateTime? restEndTime,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      _logger.warning(
        "Attempted to update Live Activity on unsupported platform: $defaultTargetPlatform",
      );
      return;
    }

    if (_currentActivityId == null) {
      await startActivity(workout: workout); // just to be safe
      return;
    }

    try {
      final restEndTimeString = restEndTime?.toIso8601String();

      _logger.info(
        "Updating Live Activity: restEndTime=$restEndTimeString, activityId=$_currentActivityId",
      );

      await _channel.invokeMethod("updateActivity", {
        "activityId": _currentActivityId,
        "restEndTime": restEndTimeString,
      });

      _logger.fine("Live Activity updated: $_currentActivityId");
    } on Exception catch (error, stackTrace) {
      _logger.severe("Failed to update Live Activity", error, stackTrace);
    }
  }

  /// Ends the current Live Activity.
  Future<void> endActivity() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      _logger.warning(
        "Attempted to end Live Activity on unsupported platform: $defaultTargetPlatform",
      );
      return;
    }

    try {
      await _channel.invokeMethod("endActivity");
      _logger.info("Live Activity ended");
      _currentActivityId = null;
    } on Exception catch (error, stackTrace) {
      _logger.severe("Failed to end Live Activity", error, stackTrace);
      _currentActivityId = null;
    }
  }
}
