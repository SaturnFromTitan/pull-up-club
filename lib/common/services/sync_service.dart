import "package:drift/drift.dart";
import "package:logging/logging.dart";
import "package:pull_up_club/common/services/supabase_service.dart";
import "package:pull_up_club/common/services/workout_database.dart";
import "package:pull_up_club/domain/models.dart";
import "package:supabase_flutter/supabase_flutter.dart";

/// Service for syncing local database with Supabase (offline-first)
class SyncService {
  SyncService(this._database);

  static final Logger _logger = Logger("SyncService");
  final WorkoutDatabase _database;
  final SupabaseClient _supabase = SupabaseService.client;

  /// Perform a full bidirectional sync
  /// 1. Push local changes to server
  /// 2. Pull server changes to local
  Future<void> syncAll() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _logger.warning("Cannot sync: user not authenticated");
      return;
    }

    try {
      _logger.info("Starting sync...");

      // Step 1: Push local changes to server
      await _pushLocalChanges();

      // Step 2: Pull server changes to local
      await _pullServerChanges();

      _logger.info("Sync completed successfully");
    } catch (e) {
      _logger.severe("Sync error: $e");
      rethrow;
    }
  }

  /// Push local changes (pending, updated, deleted) to server
  Future<void> _pushLocalChanges() async {
    _logger.fine("Pushing local changes to server...");

    // Get all workouts that need syncing
    final pendingWorkouts =
        await (_database.select(_database.workouts)
              ..where((final t) => t.syncStatus.equals("pending"))
              ..where((final t) => t.deletedAt.isNull()))
            .get();

    for (final workout in pendingWorkouts) {
      try {
        if (workout.serverId == null) {
          // New workout - insert on server
          await _createWorkoutOnServer(workout);
        } else {
          // Existing workout - update on server
          await _updateWorkoutOnServer(workout);
        }
      } catch (e) {
        _logger.warning("Failed to sync workout ${workout.id}: $e");
        // Mark as error but don't throw - continue with other workouts
        await (_database.update(_database.workouts)
              ..where((final t) => t.id.equals(workout.id)))
            .write(const WorkoutsCompanion(syncStatus: Value("error")));
      }
    }

    // Handle soft deletes
    final deletedWorkouts =
        await (_database.select(_database.workouts)
              ..where((final t) => t.deletedAt.isNotNull())
              ..where((final t) => t.syncStatus.equals("pending")))
            .get();

    for (final workout in deletedWorkouts) {
      if (workout.serverId != null) {
        try {
          // Soft delete on server
          await _supabase
              .from("workouts")
              .update({"deleted_at": workout.deletedAt?.toIso8601String()})
              .eq("id", workout.serverId!);

          // Mark as synced
          await (_database.update(_database.workouts)
                ..where((final t) => t.id.equals(workout.id)))
              .write(const WorkoutsCompanion(syncStatus: Value("synced")));
        } catch (e) {
          _logger.warning("Failed to delete workout ${workout.id} on server: $e");
        }
      } else {
        // Local-only delete - just mark as synced (nothing to delete on server)
        await (_database.update(_database.workouts)
              ..where((final t) => t.id.equals(workout.id)))
            .write(const WorkoutsCompanion(syncStatus: Value("synced")));
      }
    }
  }

  /// Create a new workout on the server
  Future<void> _createWorkoutOnServer(final DBWorkout workout) async {
    // Insert workout
    final workoutData = {
      "workout_type": workout.workoutType,
      "max_groups": workout.maxGroups,
      "start": workout.start.toIso8601String(),
      if (workout.end != null) "end": workout.end!.toIso8601String(),
    };

    final response = await _supabase
        .from("workouts")
        .insert(workoutData)
        .select()
        .single();

    final serverId = response["id"] as int;

    // Update local workout with server ID
    await (_database.update(
      _database.workouts,
    )..where((final t) => t.id.equals(workout.id))).write(
      WorkoutsCompanion(serverId: Value(serverId), syncStatus: const Value("synced")),
    );

    // Insert sets
    final sets =
        await (_database.select(_database.workoutSets)
              ..where((final t) => t.workoutId.equals(workout.id))
              ..where((final t) => t.deletedAt.isNull()))
            .get();

    for (final set in sets) {
      final setData = {
        "workout_id": serverId,
        "group_number": set.groupNumber,
        if (set.targetReps != null) "target_reps": set.targetReps,
        "completed_reps": set.completedReps,
      };

      final setResponse = await _supabase
          .from("workout_sets")
          .insert(setData)
          .select()
          .single();

      final setServerId = setResponse["id"] as int;

      // Update local set with server ID
      await (_database.update(
        _database.workoutSets,
      )..where((final t) => t.id.equals(set.id))).write(
        WorkoutSetsCompanion(
          serverId: Value(setServerId),
          syncStatus: const Value("synced"),
        ),
      );
    }
  }

  /// Update an existing workout on the server
  Future<void> _updateWorkoutOnServer(final DBWorkout workout) async {
    final workoutData = {
      "workout_type": workout.workoutType,
      "max_groups": workout.maxGroups,
      "start": workout.start.toIso8601String(),
      if (workout.end != null) "end": workout.end!.toIso8601String(),
    };

    await _supabase.from("workouts").update(workoutData).eq("id", workout.serverId!);

    // Mark workout as synced
    await (_database.update(_database.workouts)
          ..where((final t) => t.id.equals(workout.id)))
        .write(const WorkoutsCompanion(syncStatus: Value("synced")));

    // Sync sets - this is simplified; in production you'd want more sophisticated
    // conflict resolution (e.g., merge sets, handle deletions, etc.)
    final localSets =
        await (_database.select(_database.workoutSets)
              ..where((final t) => t.workoutId.equals(workout.id))
              ..where((final t) => t.deletedAt.isNull()))
            .get();

    for (final set in localSets) {
      if (set.serverId == null) {
        // New set - create on server
        final setData = {
          "workout_id": workout.serverId,
          "group_number": set.groupNumber,
          if (set.targetReps != null) "target_reps": set.targetReps,
          "completed_reps": set.completedReps,
        };

        final setResponse = await _supabase
            .from("workout_sets")
            .insert(setData)
            .select()
            .single();

        await (_database.update(
          _database.workoutSets,
        )..where((final t) => t.id.equals(set.id))).write(
          WorkoutSetsCompanion(
            serverId: Value(setResponse["id"] as int),
            syncStatus: const Value("synced"),
          ),
        );
      } else if (set.syncStatus == "pending") {
        // Updated set - update on server
        final setData = {
          "group_number": set.groupNumber,
          if (set.targetReps != null) "target_reps": set.targetReps,
          "completed_reps": set.completedReps,
        };

        await _supabase.from("workout_sets").update(setData).eq("id", set.serverId!);

        await (_database.update(_database.workoutSets)
              ..where((final t) => t.id.equals(set.id)))
            .write(const WorkoutSetsCompanion(syncStatus: Value("synced")));
      }
    }
  }

  /// Pull changes from server to local database
  Future<void> _pullServerChanges() async {
    _logger.fine("Pulling server changes...");

    // Get the last sync timestamp (simplified - in production you'd store this per user)
    // For now, we'll pull all workouts and merge
    final response = await _supabase
        .from("workouts")
        .select("""
          *,
          workout_sets(*)
        """)
        .is_("deleted_at", null)
        .order("updated_at", ascending: false);

    final serverWorkouts = response as List<dynamic>;

    for (final serverWorkout in serverWorkouts) {
      final serverId = serverWorkout["id"] as int;
      final serverUpdatedAt = DateTime.parse(serverWorkout["updated_at"] as String);

      // Check if we already have this workout locally
      final localWorkout =
          await (_database.select(_database.workouts)
                ..where((final t) => t.serverId.equals(serverId))
                ..limit(1))
              .getSingleOrNull();

      if (localWorkout == null) {
        // New workout from server - insert locally
        await _insertWorkoutFromServer(serverWorkout);
      } else {
        // Existing workout - check if server version is newer
        if (serverUpdatedAt.isAfter(localWorkout.updatedAt)) {
          // Server is newer - update local
          await _updateLocalWorkoutFromServer(serverWorkout, localWorkout);
        }
      }
    }
  }

  /// Insert a workout from server into local database
  Future<void> _insertWorkoutFromServer(
    final Map<String, dynamic> serverWorkout,
  ) async {
    final workoutType = WorkoutType.values.firstWhere(
      (final type) => type.name == serverWorkout["workout_type"] as String,
    );

    final workoutId = await _database
        .into(_database.workouts)
        .insert(
          WorkoutsCompanion.insert(
            serverId: Value(serverWorkout["id"] as int),
            workoutType: workoutType.name,
            maxGroups: serverWorkout["max_groups"] as int,
            start: DateTime.parse(serverWorkout["start"] as String),
            end: serverWorkout["end"] != null
                ? Value(DateTime.parse(serverWorkout["end"] as String))
                : const Value.absent(),
            updatedAt: Value(DateTime.parse(serverWorkout["updated_at"] as String)),
            syncStatus: const Value("synced"),
          ),
        );

    // Insert sets
    final serverSets = serverWorkout["workout_sets"] as List<dynamic>? ?? [];
    for (final serverSet in serverSets) {
      if (serverSet["deleted_at"] != null) continue; // Skip deleted sets

      await _database
          .into(_database.workoutSets)
          .insert(
            WorkoutSetsCompanion.insert(
              workoutId: workoutId,
              serverId: Value(serverSet["id"] as int),
              groupNumber: serverSet["group_number"] as int,
              targetReps: serverSet["target_reps"] != null
                  ? Value(serverSet["target_reps"] as int)
                  : const Value.absent(),
              completedReps: serverSet["completed_reps"] as int,
              updatedAt: Value(DateTime.parse(serverSet["updated_at"] as String)),
              syncStatus: const Value("synced"),
            ),
          );
    }
  }

  /// Update local workout from server data
  Future<void> _updateLocalWorkoutFromServer(
    final Map<String, dynamic> serverWorkout,
    final DBWorkout localWorkout,
  ) async {
    final workoutType = WorkoutType.values.firstWhere(
      (final type) => type.name == serverWorkout["workout_type"] as String,
    );

    await (_database.update(
      _database.workouts,
    )..where((final t) => t.id.equals(localWorkout.id))).write(
      WorkoutsCompanion(
        workoutType: Value(workoutType.name),
        maxGroups: Value(serverWorkout["max_groups"] as int),
        start: Value(DateTime.parse(serverWorkout["start"] as String)),
        end: serverWorkout["end"] != null
            ? Value(DateTime.parse(serverWorkout["end"] as String))
            : const Value.absent(),
        updatedAt: Value(DateTime.parse(serverWorkout["updated_at"] as String)),
        syncStatus: const Value("synced"),
      ),
    );

    // Sync sets - simplified approach
    final serverSets = serverWorkout["workout_sets"] as List<dynamic>? ?? [];
    final serverSetIds = <int>{};

    for (final serverSet in serverSets) {
      if (serverSet["deleted_at"] != null) continue;

      final setServerId = serverSet["id"] as int;
      serverSetIds.add(setServerId);

      final localSet =
          await (_database.select(_database.workoutSets)
                ..where((final t) => t.serverId.equals(setServerId))
                ..limit(1))
              .getSingleOrNull();

      if (localSet == null) {
        // New set from server
        await _database
            .into(_database.workoutSets)
            .insert(
              WorkoutSetsCompanion.insert(
                workoutId: localWorkout.id,
                serverId: Value(setServerId),
                groupNumber: serverSet["group_number"] as int,
                targetReps: serverSet["target_reps"] != null
                    ? Value(serverSet["target_reps"] as int)
                    : const Value.absent(),
                completedReps: serverSet["completed_reps"] as int,
                updatedAt: Value(DateTime.parse(serverSet["updated_at"] as String)),
                syncStatus: const Value("synced"),
              ),
            );
      } else {
        // Update existing set
        await (_database.update(
          _database.workoutSets,
        )..where((final t) => t.id.equals(localSet.id))).write(
          WorkoutSetsCompanion(
            groupNumber: Value(serverSet["group_number"] as int),
            targetReps: serverSet["target_reps"] != null
                ? Value(serverSet["target_reps"] as int)
                : const Value.absent(),
            completedReps: Value(serverSet["completed_reps"] as int),
            updatedAt: Value(DateTime.parse(serverSet["updated_at"] as String)),
            syncStatus: const Value("synced"),
          ),
        );
      }
    }
  }
}
