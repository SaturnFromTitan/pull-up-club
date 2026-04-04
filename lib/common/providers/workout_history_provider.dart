import "dart:async";
import "dart:math";

import "package:clock/clock.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:pull_up_club/common/services/backend_service.dart";
import "package:pull_up_club/common/services/sync_service.dart";
import "package:pull_up_club/common/services/workout_database.dart";
import "package:pull_up_club/domain/models.dart";

class WorkoutHistoryProvider extends ChangeNotifier {
  WorkoutHistoryProvider() {
    // on app start we only do a delta sync
    // full sync only happens when the user signs in
    unawaited(loadWorkouts());
  }
  static final Logger _logger = Logger("WorkoutHistoryProvider");

  final WorkoutDatabase _database = WorkoutDatabase.instance;
  final BackendService _backend = BackendService.instance;
  final SyncService _syncService = SyncService.instance;

  bool _isLoading = true;
  List<Workout> _completedWorkouts = <Workout>[];

  bool get isLoading => _isLoading;
  List<Workout> get completedWorkouts => _completedWorkouts;

  Future<void> loadWorkouts() async {
    _logger.info("Loading workout history");
    _isLoading = true;
    notifyListeners();

    try {
      // Perform sync before loading local workouts
      await _syncService.performSync();

      _completedWorkouts = await _database.getAllNonDeletedWorkouts();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addWorkout(final Workout workout) async {
    _logger.info("Adding workout to history: $workout");
    final savedWorkout = await _database.insertWorkout(workout);
    _completedWorkouts.add(savedWorkout);
    _logger.info("Workout added to history: id=${savedWorkout.id}");

    // push to supabase - if this fails, it will be covered by the next full sync
    if (_backend.isAuthenticated) {
      unawaited(_syncService.pushWorkoutToBackend(savedWorkout));
    } else {
      _logger.info("Not pushing workout to backend as the user is not authenticated");
    }

    notifyListeners();
  }

  Future<void> deleteWorkout(final Workout workout) async {
    if (workout.id == null) {
      throw Exception("Cannot delete workout without ID");
    }
    _logger.info("Deleting workout from history: $workout");

    // Soft delete locally
    workout.deletedAt = clock.now().toUtc();
    await _database.deleteWorkout(workout);
    _completedWorkouts.remove(workout);
    _logger.info("Workout deleted from history: $workout");

    if (_backend.isAuthenticated) {
      // because the workout is pushed to the backend asyncronously, this instance might
      // not contain the serverId yet. Therefore we look it up in the local database as
      // a fallback.
      workout.serverId ??= await _database.getServerIdForWorkout(workout.id!);
      if (workout.serverId == null) {
        _logger.info(
          "Can't push soft-deletion to backend as the serverId is unknown $workout",
        );
      } else {
        // push to supabase - if this fails, it will be covered by the next full sync
        unawaited(_backend.deleteWorkout(localWorkout: workout));
      }
    } else {
      _logger.info(
        "Not pushing workout deletion to backend as the user is not authenticated",
      );
    }

    notifyListeners();
  }

  /// Returns the most recent completed workout of the given type, or null if none exists.
  Workout? getPreviousWorkoutOfType(final WorkoutType type) {
    final matching = _completedWorkouts
        .where((final w) => w.workoutType == type)
        .toList();
    return matching.isNotEmpty ? matching.last : null;
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
        (final set_) => set_.completedReps >= targetReps,
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
          .map((final set_) => set_.completedReps)
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
