import "package:clock/clock.dart";
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
  /// Updates the activity when rest state changes.
  Future<void> startActivity({
    required final Workout workout,
    required final bool isResting,
    required final int restRemainingMillis,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      _logger.fine("Live Activities only supported on iOS");
      return;
    }

    try {
      // End any existing activity first
      await endActivity();

      final restEndTime = isResting && restRemainingMillis > 0
          ? clock
                .now()
                .toUtc()
                .add(Duration(milliseconds: restRemainingMillis))
                .toIso8601String()
          : null;

      _logger.info(
        "Starting Live Activity: isResting=$isResting, restRemainingMillis=$restRemainingMillis, restEndTime=$restEndTime",
      );

      final result = await _channel.invokeMethod<String>("startActivity", {
        "workoutType": workout.workoutType.name,
        "maxGroups": workout.maxGroups,
        "completedSets": workout.sets.length,
        "totalReps": workout.totalReps(),
        "isResting": isResting,
        "restRemainingMillis": restRemainingMillis,
        "restEndTime": restEndTime,
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
    required final bool isResting,
    required final int restRemainingMillis,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    if (_currentActivityId == null) {
      // Activity doesn't exist, start a new one
      await startActivity(
        workout: workout,
        isResting: isResting,
        restRemainingMillis: restRemainingMillis,
      );
      return;
    }

    try {
      final restEndTime = isResting && restRemainingMillis > 0
          ? clock
                .now()
                .toUtc()
                .add(Duration(milliseconds: restRemainingMillis))
                .toIso8601String()
          : null;

      _logger.info(
        "Updating Live Activity: isResting=$isResting, restRemainingMillis=$restRemainingMillis, restEndTime=$restEndTime",
      );

      await _channel.invokeMethod("updateActivity", {
        "activityId": _currentActivityId,
        "workoutType": workout.workoutType.name,
        "maxGroups": workout.maxGroups,
        "completedSets": workout.sets.length,
        "totalReps": workout.totalReps(),
        "isResting": isResting,
        "restRemainingMillis": restRemainingMillis,
        "restEndTime": restEndTime,
      });

      _logger.fine(
        "Live Activity updated: isResting=$isResting, restEndTime=$restEndTime",
      );
    } on Exception catch (error, stackTrace) {
      _logger.severe("Failed to update Live Activity", error, stackTrace);
    }
  }

  /// Ends the current Live Activity.
  Future<void> endActivity() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    if (_currentActivityId == null) {
      return;
    }

    try {
      await _channel.invokeMethod("endActivity", {"activityId": _currentActivityId});
      _logger.info("Live Activity ended: $_currentActivityId");
      _currentActivityId = null;
    } on Exception catch (error, stackTrace) {
      _logger.severe("Failed to end Live Activity", error, stackTrace);
      _currentActivityId = null;
    }
  }

  /// Checks if a Live Activity is currently active.
  bool get isActive => _currentActivityId != null;
}
