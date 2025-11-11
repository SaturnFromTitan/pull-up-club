import "dart:async";

import "package:flutter/material.dart";
import "package:pull_up_club/common/services/workout_database.dart";
import "package:pull_up_club/features/workout/models.dart";

class AppProvider extends ChangeNotifier {
  AppProvider() {
    unawaited(_loadWorkouts());
  }
  int _tabIndex = 0;
  bool _isLoading = true;
  List<Workout> _completedWorkouts = <Workout>[];

  int get tabIndex => _tabIndex;
  bool get isLoading => _isLoading;
  List<Workout> get completedWorkouts => _completedWorkouts;

  Future<void> _loadWorkouts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _completedWorkouts = await WorkoutDatabase.instance.getAllWorkouts();
    } on Exception catch (e) {
      // Handle error - for now, just log it
      debugPrint("Error loading workouts: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addWorkout(final Workout workout) async {
    try {
      final savedWorkout = await WorkoutDatabase.instance.insertWorkout(workout);
      _completedWorkouts.add(savedWorkout);
      notifyListeners();
    } on Exception catch (e) {
      debugPrint("Error saving workout: $e");
      rethrow;
    }
  }

  Future<void> deleteWorkout(final Workout workout) async {
    try {
      if (workout.id == null) {
        throw Exception("Cannot delete workout without ID");
      }
      await WorkoutDatabase.instance.deleteWorkout(workout.id!);
      _completedWorkouts.remove(workout);
      notifyListeners();
    } on Exception catch (e) {
      debugPrint("Error deleting workout: $e");
      rethrow;
    }
  }

  void setTabIndex(final int value) {
    if (value == _tabIndex) {
      return;
    }
    _tabIndex = value;
    notifyListeners();
  }

  void resetTab() {
    setTabIndex(0);
  }

  /// Determines the next workout type based on the most recent workout.
  /// Cycles through WorkoutType enum values: maxSets -> submaxVolume -> ladders -> maxSets
  WorkoutType? getNextWorkoutType() {
    if (_completedWorkouts.isEmpty) {
      return WorkoutType.values.first;
    }

    final currentIndex = WorkoutType.values.indexOf(
      _completedWorkouts.last.workoutType,
    );
    final nextIndex = (currentIndex + 1) % WorkoutType.values.length;
    return WorkoutType.values[nextIndex];
  }
}
