import "dart:async";
import "dart:math";

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

  /// Calculates the default target reps for submax volume workouts based on workout history.
  /// Returns a record with the default value and info text explaining the suggestion.
  ({int? defaultValue, String? infoText}) calculateDefaultTargetReps() {
    // Find the most recent submax volume workout
    final submaxWorkouts = _completedWorkouts
        .where((final w) => w.workoutType == WorkoutType.submaxVolume)
        .toList();

    if (submaxWorkouts.isNotEmpty) {
      final mostRecentSubmax = submaxWorkouts.last;

      // Check if all sets completed the target reps
      final targetReps = mostRecentSubmax.sets.first.targetReps!;
      final allCompleted = mostRecentSubmax.sets.every(
        (final set) => set.completedReps >= targetReps,
      );

      if (allCompleted) {
        return (
          defaultValue: targetReps + 1,
          infoText: "Increased your target by 1 rep",
        );
      } else {
        return (defaultValue: targetReps, infoText: "Same target as the last time");
      }
    }

    // No submax volume workout, check for max sets workout
    final maxSetsWorkouts = _completedWorkouts
        .where((final w) => w.workoutType == WorkoutType.maxSets)
        .toList();

    if (maxSetsWorkouts.isNotEmpty) {
      // Find the highest rep count
      final highestReps = maxSetsWorkouts.last.sets
          .map((final set) => set.completedReps)
          .reduce(max);
      final suggestedReps = (highestReps / 2).floor();

      if (suggestedReps > 0) {
        return (
          defaultValue: suggestedReps,
          infoText: "That's 50% of your latest max reps",
        );
      } else {
        return (defaultValue: null, infoText: "Please increase your Max Reps first");
      }
    }

    // No workouts found
    return (
      defaultValue: null,
      infoText: "Complete a Max Sets workout first to get a suggestion",
    );
  }
}
