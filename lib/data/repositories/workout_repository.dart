import "package:logging/logging.dart";
import "package:pull_up_club/common/services/supabase_service.dart";
import "package:pull_up_club/common/services/workout_database.dart";
import "package:pull_up_club/domain/models.dart";
import "package:pull_up_club/domain/server_models.dart";

/// Repository for managing workouts with local database and cloud sync.
/// Coordinates between local storage and Supabase backend.
class WorkoutRepository {
  WorkoutRepository(this._database);

  final WorkoutDatabase _database;
  final SupabaseService _supabase = SupabaseService.instance;
  static final Logger _logger = Logger("WorkoutRepository");

  /// Gets all active (non-deleted) workouts from local database.
  Future<List<Workout>> getAllWorkouts() => _database.getAllWorkouts();

  /// Saves a workout to the local database.
  Future<Workout> saveWorkout(final Workout workout) =>
      _database.insertWorkout(workout);

  /// Soft deletes a workout locally.
  Future<void> deleteWorkout(final int workoutId) => _database.deleteWorkout(workoutId);

  /// Performs a sync: merges server and local workouts using three-way merge logic.
  /// If [isDeltaSync] is true, only fetches workouts updated after the latest local workout.
  /// Silently handles errors to maintain offline-first behavior.
  Future<void> performSync({required final bool isDeltaSync}) async {
    if (!_supabase.isAuthenticated) {
      _logger.info("Skipping sync: user not authenticated");
      return;
    }

    try {
      _logger.info("Starting sync (isDeltaSync=$isDeltaSync)");

      // Step 1: Download workouts from server
      DateTime? updatedSince;
      if (isDeltaSync) {
        updatedSince = await _database.getLatestWorkoutUpdatedAt();
      }

      final serverWorkouts = await _supabase.fetchWorkouts(updatedSince: updatedSince);
      _logger.info("Found ${serverWorkouts.length} workouts from server");

      // Step 2: Handle server-side deletions
      final deletedServerIds = await _supabase.fetchDeletedWorkoutIds(
        updatedSince: updatedSince,
      );
      await _markServerDeletionsLocally(deletedServerIds);

      // Step 3: Load all local workouts (including deleted for sync logic)
      final localWorkouts = await _database.getAllWorkoutsIncludingDeleted();

      // Step 4: Perform three-way merge
      await _performThreeWayMerge(serverWorkouts, localWorkouts);

      // Step 5: Upload local deletions to server
      await _uploadLocalDeletions();

      _logger.info("Sync completed successfully");
    } on Exception catch (error, stackTrace) {
      _logger.warning("Sync failed", error, stackTrace);
    }
  }

  /// Performs three-way merge:
  /// - Local but not on server (empty server_id) -> upload
  /// - Server but not locally (no matching server_id) -> download
  /// - Both exist -> compare updated_at, use later one
  Future<void> _performThreeWayMerge(
    final List<ServerWorkout> serverWorkouts,
    final List<Workout> localWorkouts,
  ) async {
    _logger.info("Performing three-way merge");

    // Build maps for efficient lookup
    final localByServerId = <int, Workout>{};
    final localWithoutServerId = <Workout>[];

    for (final local in localWorkouts) {
      if (local.deletedAt != null) {
        continue; // Skip deleted workouts in merge
      }
      if (local.serverId != null) {
        localByServerId[local.serverId!] = local;
      } else {
        localWithoutServerId.add(local);
      }
    }

    final serverById = <int, ServerWorkout>{};
    for (final server in serverWorkouts) {
      serverById[server.id] = server;
    }

    var uploadedCount = 0;
    var downloadedCount = 0;
    var updatedCount = 0;
    var skippedCount = 0;

    // Group 1: Local but not on server -> upload
    for (final local in localWithoutServerId) {
      if (local.id == null) continue;
      try {
        _logger.fine("Uploading local workout without server_id: localId=${local.id}");
        final serverId = await _supabase.createWorkout(local);
        if (serverId != null) {
          // Fetch the server workout to get updated_at
          final serverWorkout = await _supabase.fetchWorkoutById(serverId);
          if (serverWorkout != null) {
            await _database.updateWorkoutServerId(
              local.id!,
              serverId,
              updatedAt: serverWorkout.updatedAt,
            );
          } else {
            await _database.updateWorkoutServerId(local.id!, serverId);
          }
          uploadedCount++;
        }
      } on Exception catch (error, stackTrace) {
        _logger.warning("Failed to upload local workout", error, stackTrace);
      }
    }

    // Process server workouts
    for (final server in serverWorkouts) {
      final local = localByServerId[server.id];

      if (local == null) {
        // Group 2: Server but not locally -> download
        try {
          _logger.fine("Downloading server workout: serverId=${server.id}");
          final localWorkout = server.toLocal();
          await _database.insertWorkout(localWorkout);
          downloadedCount++;
        } on Exception catch (error, stackTrace) {
          _logger.warning("Failed to download server workout", error, stackTrace);
        }
      } else {
        // Group 3: Both exist -> compare updated_at
        if (local.id == null) continue;

        final localUpdatedAt = local.updatedAt ?? local.start;
        final serverUpdatedAt = server.updatedAt;

        if (serverUpdatedAt.isAfter(localUpdatedAt)) {
          // Server version is newer -> update local
          try {
            _logger.fine(
              "Server version newer (server=${serverUpdatedAt.toIso8601String()}, "
              "local=${localUpdatedAt.toIso8601String()}), updating local: serverId=${server.id}",
            );
            final localWorkout = server.toLocal();
            await _database.updateWorkoutFromServer(
              local.id!,
              localWorkout,
              serverUpdatedAt,
            );
            updatedCount++;
          } on Exception catch (error, stackTrace) {
            _logger.warning(
              "Failed to update local workout from server",
              error,
              stackTrace,
            );
          }
        } else if (localUpdatedAt.isAfter(serverUpdatedAt)) {
          // Local version is newer -> upload to server
          try {
            _logger.fine(
              "Local version newer (local=${localUpdatedAt.toIso8601String()}, "
              "server=${serverUpdatedAt.toIso8601String()}), uploading to server: serverId=${server.id}",
            );
            // Update the workout on server (note: API doesn't support update, so we'd need to delete and recreate)
            // For now, we'll skip and let the user know that local changes take precedence
            // In a real implementation, you might want to implement update on server
            _logger.info(
              "Local version is newer but server doesn't support updates. "
              "Local version will be kept. serverId=${server.id}",
            );
            skippedCount++;
          } on Exception catch (error, stackTrace) {
            _logger.warning(
              "Failed to upload local workout to server",
              error,
              stackTrace,
            );
          }
        } else {
          // Equal timestamps -> skip (already in sync)
          _logger.fine(
            "Versions equal (${localUpdatedAt.toIso8601String()}), skipping: serverId=${server.id}",
          );
          skippedCount++;
        }
      }
    }

    _logger.info(
      "Three-way merge completed: uploaded=$uploadedCount, downloaded=$downloadedCount, "
      "updated=$updatedCount, skipped=$skippedCount",
    );
  }

  /// Marks server-side deletions locally by setting deleted_at for workouts with matching server_id.
  Future<void> _markServerDeletionsLocally(final List<int> deletedServerIds) async {
    if (deletedServerIds.isEmpty) {
      _logger.info("No server-side deletions to process");
      return;
    }

    _logger.info("Processing ${deletedServerIds.length} server-side deletions");
    var markedCount = 0;
    var notFoundCount = 0;

    for (final deletedServerId in deletedServerIds) {
      final localWorkout = await _database.getWorkoutByServerId(deletedServerId);
      if (localWorkout == null) {
        _logger.fine("Local workout not found for deleted serverId=$deletedServerId");
        notFoundCount++;
        continue;
      }

      // Check if already deleted locally
      if (localWorkout.deletedAt != null) {
        _logger.fine("Workout already deleted locally: serverId=$deletedServerId");
        continue;
      }

      // Mark as deleted locally
      if (localWorkout.id != null) {
        await _database.deleteWorkout(localWorkout.id!);
        markedCount++;
        _logger.fine("Marked workout as deleted locally: serverId=$deletedServerId");
      }
    }

    _logger.info(
      "Marked $markedCount workouts as deleted locally based on server deletions "
      "(not found: $notFoundCount)",
    );
  }

  /// Uploads all locally deleted workouts to the server.
  Future<void> _uploadLocalDeletions() async {
    final locallyDeletedWorkouts = await _database.getLocallyDeletedWorkouts();
    _logger.info(
      "Uploading ${locallyDeletedWorkouts.length} local deletions to server",
    );

    for (final workout in locallyDeletedWorkouts) {
      if (workout.serverId != null) {
        try {
          await _supabase.deleteWorkout(workout.serverId!);
          _logger.fine("Uploaded deletion to server: serverId=${workout.serverId}");
        } on Exception catch (error, stackTrace) {
          _logger.warning("Failed to upload deletion to server", error, stackTrace);
        }
      }
    }

    _logger.info("Finished uploading local deletions");
  }
}
