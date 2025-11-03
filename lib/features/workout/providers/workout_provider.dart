import "dart:async";

import "package:flutter/material.dart";
import "package:pull_up_club/features/workout/models.dart";
import "package:pull_up_club/common/providers/app_provider.dart";

class WorkoutProvider extends ChangeNotifier {
  // private state
  final Workout _workout;
  int _restRemainingSeconds = 0;
  int _restTotalSeconds = 0;
  Timer? _restTimer;

  // initialisation
  WorkoutProvider({required WorkoutType workoutType})
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

  // getters
  Workout get workout => _workout;
  int get restTimeRemaining => _restRemainingSeconds;
  int get restTotalSeconds => _restTotalSeconds;

  // lifecyle management
  void addSet(WorkoutSet set_) {
    _workout.sets.add(set_);
  }

  void rest(final int durationSeconds) {
    _restRemainingSeconds = durationSeconds;
    _restTotalSeconds = durationSeconds;

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

  bool isResting() {
    return _restTimer?.isActive == true;
  }

  void finish(AppProvider appProvider) {
    _workout.finish();
    appProvider.completedWorkouts.add(_workout);
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }
}
