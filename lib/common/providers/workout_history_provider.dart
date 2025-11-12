import "dart:async";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:pull_up_club/data/repositories/workout_repository.dart";
import "package:pull_up_club/domain/models.dart";

class WorkoutHistoryProvider extends ChangeNotifier {
  WorkoutHistoryProvider(this._repository) {
    unawaited(_loadWorkouts());
  }
  static final Logger _logger = Logger("WorkoutHistoryProvider");

  final WorkoutRepository _repository;

  bool _isLoading = true;
  List<Workout> _completedWorkouts = <Workout>[];

  bool get isLoading => _isLoading;
  List<Workout> get completedWorkouts => _completedWorkouts;

  Future<void> _loadWorkouts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _completedWorkouts = await _repository.getAllWorkouts();
    } on Exception catch (e) {
      _logger.fine("Error loading workouts: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addWorkout(final Workout workout) async {
    try {
      final savedWorkout = await _repository.saveWorkout(workout);
      _completedWorkouts.add(savedWorkout);
      notifyListeners();
    } on Exception catch (e) {
      _logger.fine("Error saving workout: $e");
      rethrow;
    }
  }

  Future<void> deleteWorkout(final Workout workout) async {
    try {
      if (workout.id == null) {
        throw Exception("Cannot delete workout without ID");
      }
      await _repository.deleteWorkout(workout.id!);
      _completedWorkouts.remove(workout);
      notifyListeners();
    } on Exception catch (e) {
      _logger.fine("Error deleting workout: $e");
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
