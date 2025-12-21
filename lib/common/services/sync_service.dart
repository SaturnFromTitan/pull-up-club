import "package:logging/logging.dart";
import "package:pull_up_club/common/services/supabase_service.dart";
import "package:pull_up_club/common/services/workout_database.dart";
import "package:pull_up_club/domain/models.dart";

/// Service for syncing the local database with the remote BE.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final WorkoutDatabase _database = WorkoutDatabase.instance;
  final SupabaseService _supabase = SupabaseService.instance;
  static final Logger _logger = Logger("SyncService");

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
  ///   - Workout exists locally, but not on server (-> empty server_id): Upload to server
  ///   - Workout exists on server, but not locally (-> no matching local workout with that server id): Download to local
  ///   - Workout exists both on the server and locally and is only soft-deleted for one of them: perform soft-delete for the other
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
        since = await _database.getLatestLocalWorkoutDatetime();
      }

      // Step 2: Download workouts from server (filter by end >= since OR deleted_at >= since)
      final serverWorkouts = await _supabase.fetchWorkouts(since: since);
      _logger.info("Found ${serverWorkouts.length} workouts from server");

      // Step 3: Load local workouts for sync:
      // - All workouts with empty serverId (unsynced local workouts)
      // - All workouts with serverId matching any server workout we retrieved
      final serverIds = serverWorkouts.map((final w) => w.serverId!).toList();
      final localWorkouts = await _database.getWorkoutsForSync(serverIds);
      _logger.info("Found ${localWorkouts.length} local workouts for sync");

      // Step 4: Perform three-way merge
      await _performThreeWayMerge(serverWorkouts, localWorkouts);

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
    final List<Workout> serverWorkouts,
    final List<Workout> localWorkoutRows,
  ) async {
    _logger.info("Performing three-way merge");

    // Build maps for efficient lookup
    final localByServerId = <int, Workout>{};
    final localWithoutServerId = <Workout>[];

    for (final localRow in localWorkoutRows) {
      if (localRow.serverId != null) {
        localByServerId[localRow.serverId!] = localRow;
      } else {
        localWithoutServerId.add(localRow);
      }
    }

    final serverById = <int, Workout>{};
    for (final serverWorkout in serverWorkouts) {
      serverById[serverWorkout.serverId!] = serverWorkout;
    }

    var uploadedCount = 0;
    var downloadedCount = 0;
    var deletedSyncedCount = 0;
    var skippedCount = 0;

    // ⚠️ processing the workouts 1-by-1 is less efficient, but pretty robust and simpler to reason about
    // e.g. if the sync is aborted for some reason, it's very straight-forward to pick up where you left off last time

    // Group 1: Local but not on server (empty server_id) -> upload
    for (final localWorkout in localWithoutServerId) {
      // Skip deleted workouts - they don't need to be uploaded
      if (localWorkout.deletedAt != null) {
        continue;
      }

      try {
        _logger.fine(
          "Uploading local workout without server_id: localId=${localWorkout.id}",
        );
        // Convert DB row to Workout domain model for upload
        final serverId = await _supabase.createWorkout(localWorkout);
        if (serverId != null) {
          // the workout was loaded from the local DB, so .id must be set
          await _database.updateWorkoutServerId(localWorkout.id!, serverId);
          uploadedCount++;
        }
      } on Exception catch (error, stackTrace) {
        _logger.warning("Failed to upload local workout", error, stackTrace);
      }
    }

    // Process server workouts
    for (final serverWorkout in serverWorkouts) {
      final localWorkout = localByServerId[serverWorkout.id];

      if (localWorkout == null) {
        // Group 2: Server but not locally -> download
        // Only download if not deleted on server
        if (serverWorkout.deletedAt == null) {
          try {
            _logger.fine(
              "Downloading server workout: serverId=${serverWorkout.serverId}",
            );
            await _database.insertWorkout(serverWorkout);
            downloadedCount++;
          } on Exception catch (error, stackTrace) {
            _logger.warning("Failed to download server workout", error, stackTrace);
          }
        } else {
          _logger.fine(
            "Skipping deleted server workout: serverId=${serverWorkout.serverId}",
          );
          skippedCount++;
        }
      } else {
        // Group 3: Both exist -> sync deleted_at status only
        final localDeletedAt = localWorkout.deletedAt;
        final serverDeletedAt = serverWorkout.deletedAt;

        // If deleted_at is both null or both set: no change
        if ((localDeletedAt == null && serverDeletedAt == null) ||
            (localDeletedAt != null && serverDeletedAt != null)) {
          _logger.fine(
            "Workout deleted_at status matches, skipping: serverId=${serverWorkout.serverId}",
          );
          skippedCount++;
        } else {
          // One is deleted and the other isn't -> sync
          if (serverDeletedAt != null && localDeletedAt == null) {
            // Server is deleted, local is not -> soft-delete locally
            try {
              _logger.fine(
                "Server workout is deleted, soft-deleting locally: serverId=${serverWorkout.serverId}",
              );
              // localWorkout was loaded from local DB, so id must be set
              await _database.deleteWorkout(
                workoutId: localWorkout.id!,
                deletedAt: serverDeletedAt,
              );
              deletedSyncedCount++;
            } on Exception catch (error, stackTrace) {
              _logger.warning("Failed to soft-delete local workout", error, stackTrace);
            }
          } else if (localDeletedAt != null && serverDeletedAt == null) {
            // Local is deleted, server is not -> soft-delete on server
            try {
              _logger.fine(
                "Local workout is deleted, soft-deleting on server: serverId=${serverWorkout.serverId}",
              );
              await _supabase.deleteWorkout(
                workoutId: serverWorkout.serverId!,
                deletedAt: localDeletedAt,
              );
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
