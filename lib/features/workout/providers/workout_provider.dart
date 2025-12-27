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
      );
  static final Logger _logger = Logger("WorkoutProvider");
  // private state
  final Workout _workout;
  DateTime? _restStartTime;
  DateTime? _restEndTime;
  Timer? _restTimer;

  // getters
  Workout get workout => _workout;
  DateTime? get restEndTime => _restEndTime;

  int getRestRemainingMillis() {
    if (_restEndTime == null) {
      return 0;
    }
    final remainingMillis = _restEndTime!
        .difference(clock.now().toUtc())
        .inMilliseconds;
    return max(0, remainingMillis);
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

    // Update Live Activity
    unawaited(
      LiveActivityService.instance.updateActivity(
        workout: _workout,
        restEndTime: _restEndTime,
      ),
    );

    _restTimer = Timer.periodic(const Duration(seconds: 1), (final timer) {
      // Play countdown sound on last 3 seconds (3, 2, 1)
      // Only play sound when remaining transitions to 3, 2, or 1 (i.e., just after a whole second tick)
      // This ensures that beeps after backgrounding are not repeated in rapid succession
      final remainingMillis = getRestRemainingMillis();
      const precision = 100; // 100ms
      for (final targetSecond in [3, 2, 1]) {
        if ((remainingMillis - targetSecond * 1_000).abs() < precision) {
          unawaited(SoundService.instance.playCountdown());
          break;
        }
      }

      // Play complete sound when timer reaches 0
      if (remainingMillis <= 0) {
        _logger.info("Rest period completed");
        unawaited(SoundService.instance.playCountdownCompleted());
        resume(stopSounds: false);
        return;
      }

      notifyListeners();
    });
  }

  void resume({final bool stopSounds = true}) {
    _logger.info("Resuming workout: $_workout");
    if (stopSounds) {
      unawaited(SoundService.instance.stop());
    }
    _restTimer?.cancel();
    _restTimer = null;
    _restStartTime = null;
    _restEndTime = null;

    // Update Live Activity to show not resting
    unawaited(
      LiveActivityService.instance.updateActivity(workout: _workout, restEndTime: null),
    );

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
    // End Live Activity when workout provider is disposed
    unawaited(LiveActivityService.instance.endActivity());
    super.dispose();
  }
}
