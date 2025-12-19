import "package:logging/logging.dart";
import "package:pull_up_club/common/services/supabase_service.dart";
import "package:pull_up_club/common/services/workout_database.dart";
import "package:pull_up_club/data/repositories/workout_repository.dart";
import "package:pull_up_club/domain/models.dart";

/// Service for synchronizing workout data between local database and Supabase.
/// Implements offline-first approach: failures don't impact user experience.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();
  static final Logger _logger = Logger("SyncService");

  final WorkoutRepository _repository = WorkoutRepository(WorkoutDatabase.instance);
  final SupabaseService _supabase = SupabaseService.instance;

  /// Performs a delta sync: fetches workouts updated after the latest local workout.
  /// If no local workouts exist, performs a full sync.
  /// Silently handles errors to maintain offline-first behavior.
  Future<void> performSync({required final bool isDeltaSync}) async {
    if (!_supabase.isAuthenticated) {
      _logger.info("Skipping delta sync: user not authenticated");
      return;
    }

    try {
      _logger.info("Starting delta sync");
      DateTime? updatedSince;
      if (isDeltaSync) {
        updatedSince = await WorkoutDatabase.instance.getLatestWorkoutStartTime();
      } else {
        updatedSince = null;
      }

      final serverWorkouts = await _supabase.fetchWorkouts(updatedSince: updatedSince);
      _logger.info("Found ${serverWorkouts.length} workouts from server to sync");
      await _mergeServerWorkoutsIntoLocal(serverWorkouts);
      _logger.info("Delta sync completed successfully");
    } on Exception catch (error, stackTrace) {
      _logger.warning("Delta sync failed", error, stackTrace);
    }
  }

  /// Uploads a single workout to Supabase.
  /// Silently handles errors to maintain offline-first behavior.
  Future<void> uploadWorkout(final Workout workout) async {
    if (!_supabase.isAuthenticated) {
      _logger.info("Skipping workout upload: user not authenticated");
      return;
    }

    try {
      _logger.info("Uploading workout to Supabase: $workout");
      await _supabase.createWorkout(workout);
      _logger.info("Workout uploaded successfully");
    } on Exception catch (error, stackTrace) {
      _logger.warning(
        "Workout upload failed (offline-first: continuing)",
        error,
        stackTrace,
      );
      // Silently fail - offline-first approach
    }
  }

  /// Merges server workouts into local database.
  /// Uses start time as the unique identifier to avoid duplicates.
  Future<void> _mergeServerWorkoutsIntoLocal(
    final List<Map<String, dynamic>> serverWorkouts,
  ) async {
    final localWorkouts = await _repository.getAllWorkouts();
    final localWorkoutsByStart = <DateTime, Workout>{};
    for (final workout in localWorkouts) {
      localWorkoutsByStart[workout.start] = workout;
    }

    var addedCount = 0;

    for (final serverWorkoutData in serverWorkouts) {
      try {
        final serverWorkout = _convertServerWorkoutToLocal(serverWorkoutData);
        if (serverWorkout == null) {
          _logger.warning("Failed to convert server workout: $serverWorkoutData");
          continue;
        }

        // Check if workout already exists locally by start time
        // TODO: store server id locally
        final existingWorkout = localWorkoutsByStart[serverWorkout.start];
        if (existingWorkout != null) {
          // Workout exists - skip to avoid duplicates
          // Note: In a real scenario, you might want to compare updated_at timestamps
          // and update if server version is newer. For simplicity, we skip duplicates.
          _logger.fine(
            "Workout already exists locally, skipping: ${serverWorkout.start}",
          );
          continue;
        }

        // Add new workout to local database
        await _repository.saveWorkout(serverWorkout);
        addedCount++;
        _logger.fine("Added workout from server: ${serverWorkout.start}");
      } on Exception catch (error, stackTrace) {
        _logger.warning("Failed to merge server workout", error, stackTrace);
      }
    }

    _logger.info(
      "Merged server workouts: added=$addedCount, skipped=${serverWorkouts.length - addedCount}",
    );
  }

  /// Converts a server workout (from Supabase) to a local Workout model.
  /// Returns null if conversion fails.
  Workout? _convertServerWorkoutToLocal(final Map<String, dynamic> serverData) {
    try {
      // Parse workout type
      final workoutTypeStr = serverData["workout_type"] as String;
      final workoutType = WorkoutType.values.firstWhere(
        (final type) => type.name == workoutTypeStr,
        orElse: () => throw Exception("Unknown workout type: $workoutTypeStr"),
      );

      // Parse dates
      final startStr = serverData["start"] as String;
      final start = DateTime.parse(startStr).toUtc();
      final endStr = serverData["end"] as String?;
      final end = endStr != null ? DateTime.parse(endStr).toUtc() : null;

      // Create workout
      final workout = Workout(
        workoutType: workoutType,
        maxGroups: serverData["max_groups"] as int,
        start: start,
      )..end = end;

      // Parse sets
      final setsData = serverData["workout_sets"] as List<dynamic>? ?? [];
      workout.sets = setsData.map((final setData) {
        return WorkoutSet(
          group: setData["group_number"] as int,
          targetReps: setData["target_reps"] as int?,
          completedReps: setData["completed_reps"] as int,
        );
      }).toList();

      return workout;
    } on Exception catch (error, stackTrace) {
      _logger.severe(
        "Failed to convert server workout to local model",
        error,
        stackTrace,
      );
      return null;
    }
  }
}
