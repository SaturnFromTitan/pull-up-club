import "dart:async";
import "dart:math";

import "package:flutter/material.dart";
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
  // private state
  final Workout _workout;
  DateTime? _restStartTime;
  int _restTotalSeconds = 0;
  Timer? _restTimer;

  // getters
  Workout get workout => _workout;

  int get restTimeRemaining {
    if (_restStartTime == null) {
      return 0;
    }
    final elapsed = DateTime.now()
        .toUtc()
        .difference(_restStartTime!.toUtc())
        .inSeconds;
    return max(0, _restTotalSeconds - elapsed);
  }

  int get restTotalSeconds => _restTotalSeconds;

  // lifecyle management
  void rest(final int durationSeconds) {
    _restStartTime = DateTime.now().toUtc();
    _restTotalSeconds = durationSeconds;

    _restTimer = Timer.periodic(const Duration(seconds: 1), (final timer) {
      final remaining = restTimeRemaining;

      // Play countdown sound on last 3 seconds (3, 2, 1)
      if (1 <= remaining && remaining <= 3) {
        unawaited(SoundService.instance.playCountdown());
      }

      // Play complete sound when timer reaches 0
      if (remaining <= 0) {
        unawaited(SoundService.instance.playCountdownCompleted());
        resume(stopSounds: false);
        return;
      }

      notifyListeners();
    });
  }

  void resume({final bool stopSounds = true}) {
    if (stopSounds) {
      unawaited(SoundService.instance.stop());
    }
    _restTimer?.cancel();
    _restTimer = null;
    _restStartTime = null;
    _restTotalSeconds = 0;
    notifyListeners();
  }

  bool isResting() => _restStartTime != null;

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }
}
