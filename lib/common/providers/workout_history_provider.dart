import "dart:async";

import "package:flutter/material.dart";
import "package:pull_up_club/common/services/workout_database.dart";
import "package:pull_up_club/features/workout/models.dart";

/// Provider that manages workout history data.
/// The database (WorkoutDatabase) serves as the single source of truth for
/// workout data. This provider maintains an in-memory cache for efficient
/// UI updates, but the database is authoritative.
class WorkoutHistoryProvider extends ChangeNotifier {
  WorkoutHistoryProvider() {
    unawaited(_loadWorkouts());
  }

  bool _isLoading = true;
  List<Workout> _completedWorkouts = <Workout>[];

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
