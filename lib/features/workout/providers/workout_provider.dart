import "dart:async";
import "dart:math";

import "package:clock/clock.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:pull_up_club/common/config/test_config.dart";
import "package:pull_up_club/common/services/live_activity_service.dart";
import "package:pull_up_club/common/services/sound_service.dart";
import "package:pull_up_club/domain/models.dart";

class WorkoutProvider extends ChangeNotifier {
  // initialisation
  WorkoutProvider({required final WorkoutType workoutType})
    : _workout = Workout(
        workoutType: workoutType,
        maxGroups: () {
          switch (workoutType) {
            case WorkoutType.maxSets:
              return 3;
            case WorkoutType.submaxVolume:
              return 10;
            case WorkoutType.ladders:
              return 5;
          }
        }(),
      ) {
    // Start Live Activity when workout provider is created
    unawaited(LiveActivityService.instance.startActivity(workout: _workout));
  }
  static final Logger _logger = Logger("WorkoutProvider");
  // private state
  final Workout _workout;
  DateTime? _restStartTime;
  DateTime? _restEndTime;
  Timer? _restTimer;

  // getters
  Workout get workout => _workout;
  DateTime? get restEndTime => _restEndTime;

  int getRestRemainingMillis({final bool clampToZero = true}) {
    if (_restEndTime == null) {
      return 0;
    }
    final remainingMillis = _restEndTime!
        .difference(clock.now().toUtc())
        .inMilliseconds;
    return clampToZero ? max(0, remainingMillis) : remainingMillis;
  }

  // lifecyle management
  void rest(final int durationMillis) {
    // In test mode, override rest duration to 5 seconds
    final actualDurationMillis = TestConfig.isTestMode
        ? TestConfig.testRestDurationMillis
        : durationMillis;

    _logger.info(
      "Starting rest period: duration=${actualDurationMillis}ms (requested: ${durationMillis}ms, testMode: ${TestConfig.isTestMode}), workout: $_workout",
    );
    _restStartTime = clock.now().toUtc();
    _restEndTime = _restStartTime!.add(Duration(milliseconds: actualDurationMillis));

    unawaited(LiveActivityService.instance.updateActivity(restEndTime: _restEndTime));

    _restTimer = Timer.periodic(const Duration(seconds: 1), (final timer) {
      // Play countdown sound on last 3 seconds (3, 2, 1)
      // Only play sound when remaining transitions to 3, 2, or 1 (i.e., just after a whole second tick)
      // This ensures that beeps after backgrounding are not repeated in rapid succession
      final remainingMillis = getRestRemainingMillis(clampToZero: false);
      for (final targetSecond in [3, 2, 1]) {
        if (_isClose(remainingMillis, targetSecond * 1_000)) {
          unawaited(SoundService.instance.playCountdown());
          break;
        }
      }

      // only play the sound exactly when we hit 0 - this avoids sounds
      //after the app was in the background for a while
      if (_isClose(remainingMillis, 0)) {
        _logger.info("Rest period completed");
        unawaited(SoundService.instance.playCountdownCompleted());
      }
      if (remainingMillis <= 0) {
        resume(stopSounds: false);
      }

      notifyListeners();
    });
  }

  bool _isClose(
    final int remainingMillis,
    final int targetMillis, {
    final int precisionMillis = 100,
  }) => (remainingMillis - targetMillis).abs() < precisionMillis;

  void resume({final bool stopSounds = true}) {
    _logger.info("Resuming workout: $_workout");
    if (stopSounds) {
      unawaited(SoundService.instance.stop());
    }
    _restTimer?.cancel();
    _restTimer = null;
    _restStartTime = null;
    _restEndTime = null;

    // When the app is in the background, the live activity may not get updated
    // as the background execution is limited by iOS. Therefore the widget doesn't
    // update its text from "00:00" to "Go!". This is a known limitation which is
    // hard to work around.
    // The update call here is still useful for when the rest timer gets skipped
    unawaited(LiveActivityService.instance.updateActivity(restEndTime: null));

    notifyListeners();
  }

  bool isResting() => _restStartTime != null;

  WorkoutSet? undoLastSet() {
    if (_workout.sets.isEmpty) {
      _logger.warning("Cannot undo: no sets to remove");
      return null;
    }
    if (_workout.end != null) {
      throw StateError("Cannot undo: workout finished");
    }

    final removedSet = _workout.sets.removeLast();
    _logger.info(
      "Undid last set: $removedSet, remaining sets: ${_workout.sets.length}",
    );
    notifyListeners();
    return removedSet;
  }

  @override
  void dispose() {
    _logger.fine("WorkoutProvider disposed: $_workout");
    _restTimer?.cancel();
    unawaited(LiveActivityService.instance.endActivity());
    super.dispose();
  }
}
