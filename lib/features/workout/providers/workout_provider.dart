import "dart:async";

import "package:flutter/material.dart";
import "package:pull_up_club/common/providers/app_provider.dart";
import "package:pull_up_club/features/workout/models.dart";

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
  int _restRemainingSeconds = 0;
  int _restTotalSeconds = 0;
  Timer? _restTimer;

  // getters
  Workout get workout => _workout;
  int get restTimeRemaining => _restRemainingSeconds;
  int get restTotalSeconds => _restTotalSeconds;

  // lifecyle management
  void addSet(final WorkoutSet set_) {
    _workout.sets.add(set_);
  }

  void rest(final int durationSeconds) {
    _restRemainingSeconds = durationSeconds;
    _restTotalSeconds = durationSeconds;

    _restTimer = Timer.periodic(const Duration(seconds: 1), (final timer) {
      _restRemainingSeconds--;
      notifyListeners();

      if (_restRemainingSeconds <= 0) {
        resume();
      }
    });
  }

  void resume() {
    _restTimer?.cancel();
    _restRemainingSeconds = 0;
    _restTotalSeconds = 0;
    notifyListeners();
  }

  bool isResting() => _restTimer?.isActive ?? false;

  Future<void> finish(final AppProvider appProvider) async {
    _workout.finish();
    await appProvider.addWorkout(_workout);
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }
}
