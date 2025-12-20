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

  /// Performs a sync: merges server and local workouts.
  ///
  /// By convention, updating workouts or workout sets is not allowed locally or on the server (setting deleted_at
  /// is the single exception to this rule).
  /// In the app itself, this won't be possible for the forseeable future anyway.
  /// On the server, it's possible via the admin interface of Supabase. Instead of altering an existing resource,
  /// a new resource with the same attributes should be added instead and the old one soft-deleted.
  ///
  /// Sync logic:
  /// - Download all workouts from server
  ///   - filter by end >= since OR deleted_at >= since if "since" is provided
  /// - Load all workouts from local DB
  ///   - All workouts with empty serverId (unsynced local workouts)
  ///   - All workouts with serverId matching any server workout we retrieved
  /// - 3 groups:
  ///   - Workout that exists locally, but not on server (-> empty server_id): Upload to server
  ///   - Workout that exists on server, but not locally (-> no matching local workout with that server id): Download to local
  ///   - Workout that exists both on the server and locally:
  ///     - If deleted_at is set for one but not the other: perform soft-delete locally or on the server
  ///     - Otherwise no change
  /// If [isDeltaSync] is true, only fetches workouts after the latest local workout sync time.
  /// Silently handles errors to maintain offline-first behavior.
  Future<void> performSync({required final bool isDeltaSync}) async {
    if (!_supabase.isAuthenticated) {
      _logger.info("Skipping sync: user not authenticated");
      return;
    }

    try {
      _logger.info("Starting sync (isDeltaSync=$isDeltaSync)");

      // Step 1: Determine sync time filter
      DateTime? since;
      if (isDeltaSync) {
        since = await _database.getLatestWorkoutSyncTime();
      }

      // Step 2: Download workouts from server (filter by end >= since OR deleted_at >= since)
      final serverWorkouts = await _supabase.fetchWorkouts(since: since);
      _logger.info("Found ${serverWorkouts.length} workouts from server");

      // Step 3: Load local workouts for sync:
      // - All workouts with empty serverId (unsynced local workouts)
      // - All workouts with serverId matching any server workout we retrieved
      final serverIds = serverWorkouts.map((final w) => w.id).toList();
      final localWorkoutRows = await _database.getWorkoutsForSync(serverIds);
      _logger.info("Found ${localWorkoutRows.length} local workouts for sync");

      // Step 4: Perform three-way merge
      await _performThreeWayMerge(serverWorkouts, localWorkoutRows);

      _logger.info("Sync completed successfully");
    } on Exception catch (error, stackTrace) {
      _logger.warning("Sync failed", error, stackTrace);
    }
  }

  /// Performs three-way merge:
  /// - Local but not on server (empty server_id) -> upload
  /// - Server but not locally (no matching server_id) -> download
  /// - Both exist -> sync deleted_at status only
  Future<void> _performThreeWayMerge(
    final List<ServerWorkout> serverWorkouts,
    final List<DBWorkout> localWorkoutRows,
  ) async {
    _logger.info("Performing three-way merge");

    // Build maps for efficient lookup
    final localByServerId = <int, DBWorkout>{};
    final localWithoutServerId = <DBWorkout>[];

    for (final localRow in localWorkoutRows) {
      if (localRow.serverId != null) {
        localByServerId[localRow.serverId!] = localRow;
      } else {
        localWithoutServerId.add(localRow);
      }
    }

    final serverById = <int, ServerWorkout>{};
    for (final server in serverWorkouts) {
      serverById[server.id] = server;
    }

    var uploadedCount = 0;
    var downloadedCount = 0;
    var deletedSyncedCount = 0;
    var skippedCount = 0;

    // Group 1: Local but not on server (empty server_id) -> upload
    for (final localRow in localWithoutServerId) {
      // Skip deleted workouts - they don't need to be uploaded
      if (localRow.deletedAt != null) {
        continue;
      }

      try {
        _logger.fine(
          "Uploading local workout without server_id: localId=${localRow.id}",
        );
        // Convert DB row to Workout domain model for upload
        final localWorkout = await _database.dbWorkoutToWorkout(localRow);
        final serverId = await _supabase.createWorkout(localWorkout);
        if (serverId != null) {
          await _database.updateWorkoutServerId(localRow.id, serverId);
          uploadedCount++;
        }
      } on Exception catch (error, stackTrace) {
        _logger.warning("Failed to upload local workout", error, stackTrace);
      }
    }

    // Process server workouts
    for (final server in serverWorkouts) {
      final localRow = localByServerId[server.id];

      if (localRow == null) {
        // Group 2: Server but not locally -> download
        // Only download if not deleted on server
        if (server.deletedAt == null) {
          try {
            _logger.fine("Downloading server workout: serverId=${server.id}");
            final localWorkout = server.toLocal();
            await _database.insertWorkout(localWorkout);
            downloadedCount++;
          } on Exception catch (error, stackTrace) {
            _logger.warning("Failed to download server workout", error, stackTrace);
          }
        } else {
          _logger.fine("Skipping deleted server workout: serverId=${server.id}");
          skippedCount++;
        }
      } else {
        // Group 3: Both exist -> sync deleted_at status only
        final localDeletedAt = localRow.deletedAt;
        final serverDeletedAt = server.deletedAt;

        // If deleted_at is both null or both set: no change
        if ((localDeletedAt == null && serverDeletedAt == null) ||
            (localDeletedAt != null && serverDeletedAt != null)) {
          _logger.fine(
            "Workout deleted_at status matches, skipping: serverId=${server.id}",
          );
          skippedCount++;
        } else {
          // One is deleted and the other isn't -> sync
          if (serverDeletedAt != null && localDeletedAt == null) {
            // Server is deleted, local is not -> soft-delete locally
            try {
              _logger.fine(
                "Server workout is deleted, soft-deleting locally: serverId=${server.id}",
              );
              await _database.updateWorkoutDeletedAt(localRow.id, serverDeletedAt);
              deletedSyncedCount++;
            } on Exception catch (error, stackTrace) {
              _logger.warning("Failed to soft-delete local workout", error, stackTrace);
            }
          } else if (localDeletedAt != null && serverDeletedAt == null) {
            // Local is deleted, server is not -> soft-delete on server
            try {
              _logger.fine(
                "Local workout is deleted, soft-deleting on server: serverId=${server.id}",
              );
              await _supabase.deleteWorkout(server.id);
              deletedSyncedCount++;
            } on Exception catch (error, stackTrace) {
              _logger.warning(
                "Failed to soft-delete server workout",
                error,
                stackTrace,
              );
            }
          }
        }
      }
    }

    _logger.info(
      "Three-way merge completed: uploaded=$uploadedCount, downloaded=$downloadedCount, "
      "deletedSynced=$deletedSyncedCount, skipped=$skippedCount",
    );
  }
}
