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
  int _restTotalMillis = 0;
  Timer? _restTimer;

  // getters
  Workout get workout => _workout;

  int get restRemainingMillis {
    if (_restStartTime == null) {
      return 0;
    }
    final elapsedMillis = clock
        .now()
        .toUtc()
        .difference(_restStartTime!.toUtc())
        .inMilliseconds;
    return max(0, _restTotalMillis - elapsedMillis);
  }

  // lifecyle management
  void rest(final int durationMillis) {
    // In test mode, override rest duration to 5 seconds
    final actualDuration = TestConfig.isTestMode
        ? TestConfig.testRestDurationMillis
        : durationMillis;

    _logger.info(
      "Starting rest period: duration=${actualDuration}ms (requested: ${durationMillis}ms, testMode: ${TestConfig.isTestMode}), workout: $_workout",
    );
    _restStartTime = clock.now().toUtc();
    _restTotalMillis = actualDuration;

    // Update Live Activity
    unawaited(
      LiveActivityService.instance.updateActivity(
        workout: _workout,
        isResting: true,
        restRemainingMillis: restRemainingMillis,
      ),
    );

    _restTimer = Timer.periodic(const Duration(seconds: 1), (final timer) {
      final remaining = restRemainingMillis;

      // Play countdown sound on last 3 seconds (3, 2, 1)
      // Only play sound when remaining transitions to 3, 2, or 1 (i.e., just after a whole second tick)
      // This ensures that beeps after backgrounding are not repeated in rapid succession
      const precision = 100; // 100ms
      for (final targetSecond in [3, 2, 1]) {
        if ((remaining - targetSecond * 1_000).abs() < precision) {
          unawaited(SoundService.instance.playCountdown());
          break;
        }
      }

      // Play complete sound when timer reaches 0
      if (remaining <= 0) {
        _logger.info("Rest period completed");
        unawaited(SoundService.instance.playCountdownCompleted());
        resume(stopSounds: false);
        return;
      }

      // Update Live Activity every second during rest
      unawaited(
        LiveActivityService.instance.updateActivity(
          workout: _workout,
          isResting: true,
          restRemainingMillis: remaining,
        ),
      );

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
    _restTotalMillis = 0;

    // Update Live Activity to show not resting
    unawaited(
      LiveActivityService.instance.updateActivity(
        workout: _workout,
        isResting: false,
        restRemainingMillis: 0,
      ),
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
