import "dart:async";
import "dart:math";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
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
    final elapsedMillis = DateTime.now()
        .toUtc()
        .difference(_restStartTime!.toUtc())
        .inMilliseconds;
    return max(0, _restTotalMillis - elapsedMillis);
  }

  // lifecyle management
  void rest(final int durationMillis) {
    _logger.info(
      "Starting rest period: duration=${durationMillis}ms, workout: $_workout",
    );
    _restStartTime = DateTime.now().toUtc();
    _restTotalMillis = durationMillis;

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
    notifyListeners();
  }

  bool isResting() => _restStartTime != null;

  @override
  void dispose() {
    _logger.fine("WorkoutProvider disposed: $_workout");
    _restTimer?.cancel();
    super.dispose();
  }
}
