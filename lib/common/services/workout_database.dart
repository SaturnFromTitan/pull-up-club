import "package:drift/drift.dart";
import "package:drift_flutter/drift_flutter.dart";
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:pull_up_club/domain/models.dart";

part "workout_database.g.dart";

@DataClassName("DBWorkout")
class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable()();
  TextColumn get workoutType => text()();
  IntColumn get maxGroups => integer()();
  DateTimeColumn get start => dateTime()();
  DateTimeColumn get end => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName("DBWorkoutSet")
class WorkoutSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId =>
      integer().references(Workouts, #id, onDelete: KeyAction.cascade)();
  IntColumn get groupNumber => integer()();
  IntColumn get targetReps => integer().nullable()();
  IntColumn get completedReps => integer()();
}

@DriftDatabase(tables: [Workouts, WorkoutSets])
class WorkoutDatabase extends _$WorkoutDatabase {
  WorkoutDatabase._() : super(_openConnection());
  static final WorkoutDatabase instance = WorkoutDatabase._();
  static final Logger _logger = Logger("WorkoutDatabase");

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (final details) async {
      _logger.info(
        "Opening database: wasCreated=${details.wasCreated}, "
        "versionNow=${details.versionNow}, versionBefore=${details.versionBefore}",
      );
      // Enable foreign key constraints in SQLite
      await customStatement("PRAGMA foreign_keys = ON");
    },
    onCreate: (final m) async {
      _logger.info("Creating database schema");
      await m.createAll();
      _logger.info("Database created successfully");
    },
    onUpgrade: (final m, final from, final to) async {
      _logger.info("Migrating database from version $from to $to");
      if (from < 2) {
        // Add server_id column
        await m.addColumn(workouts, workouts.serverId);
        _logger.info("Added server_id column to workouts table");
        // Add deleted_at column for soft deletes
        await m.addColumn(workouts, workouts.deletedAt);
        _logger.info("Added deleted_at column to workouts table");
        // Add updated_at column as nullable first (for migration safety)
        await customStatement("ALTER TABLE workouts ADD COLUMN updated_at INTEGER");
        // Set updated_at to start time for existing workouts (best approximation)
        await customStatement(
          "UPDATE workouts SET updated_at = end WHERE updated_at IS NULL",
        );
        _logger.info("Added updated_at column to workouts table (nullable)");

        // Now make updated_at non-nullable by recreating the table
        // Step 1: Create new table with non-nullable updated_at
        await customStatement("""
          CREATE TABLE workouts_new (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            server_id INTEGER,
            workout_type TEXT NOT NULL,
            max_groups INTEGER NOT NULL,
            start INTEGER NOT NULL,
            end INTEGER NOT NULL,
            deleted_at INTEGER,
            updated_at INTEGER NOT NULL
          )
        """);

        // Step 2: Copy data from old table to new table
        await customStatement("""
          INSERT INTO workouts_new (
            id, server_id, workout_type, max_groups, start, end, deleted_at, updated_at
          )
          SELECT
            id, server_id, workout_type, max_groups, start, end, deleted_at,
            COALESCE(COALESCE(updated_at, end), start) as updated_at
          FROM workouts
        """);

        // Step 3: Copy workout_sets foreign key references
        await customStatement("""
          UPDATE workout_sets
          SET workout_id = (
            SELECT workouts_new.id
            FROM workouts_new
            WHERE workouts_new.id = workout_sets.workout_id
          )
        """);

        // Step 4: Drop old table and rename new table
        await customStatement("DROP TABLE workouts");
        await customStatement("ALTER TABLE workouts_new RENAME TO workouts");

        // Step 5: Recreate indexes (if any were defined)
        // Note: Drift will handle foreign keys automatically

        _logger.info("Migrated updated_at column to non-nullable");
      }
    },
  );

  Future<Workout> insertWorkout(final Workout workout) async {
    if (workout.end == null) {
      throw ArgumentError("Can only insert finished workouts");
    }

    _logger.info("Inserting workout: $workout");
    final workoutId = await into(workouts).insert(
      WorkoutsCompanion.insert(
        serverId: workout.serverId == null
            ? const Value.absent()
            : Value(workout.serverId),
        workoutType: workout.workoutType.name,
        maxGroups: workout.maxGroups,
        start: workout.start,
        end: workout.end!,
        updatedAt: workout.updatedAt ?? workout.start,
      ),
    );
    _logger.info("Workout inserted with ID: $workoutId");

    // Insert sets
    for (final set_ in workout.sets) {
      await into(workoutSets).insert(
        WorkoutSetsCompanion.insert(
          workoutId: workoutId,
          groupNumber: set_.group,
          targetReps: set_.targetReps == null
              ? const Value.absent()
              : Value(set_.targetReps),
          completedReps: set_.completedReps,
        ),
      );
    }
    _logger.fine("Inserted ${workout.sets.length} sets for workout $workoutId");

    // Return workout with the generated ID
    return Workout(
        id: workoutId,
        serverId: workout.serverId,
        workoutType: workout.workoutType,
        maxGroups: workout.maxGroups,
        start: workout.start,
      )
      ..end = workout.end
      ..sets = workout.sets;
  }

  /// Updates the server_id and updated_at for a workout.
  Future<void> updateWorkoutServerId(
    final int workoutId,
    final int serverId, {
    required final DateTime updatedAt,
  }) async {
    _logger.info("Updating workout server_id: localId=$workoutId, serverId=$serverId");
    await (update(workouts)..where((final t) => t.id.equals(workoutId))).write(
      WorkoutsCompanion(serverId: Value(serverId), updatedAt: Value(updatedAt)),
    );
    _logger.info("Workout server_id updated successfully");
  }

  /// Updates a workout with server data (used during sync when server version is newer).
  Future<void> updateWorkoutFromServer(
    final int workoutId,
    final Workout serverWorkout,
    final DateTime serverUpdatedAt,
  ) async {
    _logger.info(
      "Updating workout from server: localId=$workoutId, serverId=${serverWorkout.serverId}",
    );
    if (serverWorkout.end == null) {
      throw ArgumentError("Cannot update workout from server: workout.end is null");
    }
    final endValue = serverWorkout.end!;
    // Delete existing sets
    await (delete(workoutSets)..where((final t) => t.workoutId.equals(workoutId))).go();

    // Update workout
    await (update(workouts)..where((final t) => t.id.equals(workoutId))).write(
      WorkoutsCompanion(
        serverId: Value(serverWorkout.serverId),
        workoutType: Value(serverWorkout.workoutType.name),
        maxGroups: Value(serverWorkout.maxGroups),
        start: Value(serverWorkout.start),
        end: Value(endValue),
        updatedAt: Value(serverUpdatedAt),
      ),
    );

    // Insert new sets
    for (final set_ in serverWorkout.sets) {
      await into(workoutSets).insert(
        WorkoutSetsCompanion.insert(
          workoutId: workoutId,
          groupNumber: set_.group,
          targetReps: set_.targetReps == null
              ? const Value.absent()
              : Value(set_.targetReps),
          completedReps: set_.completedReps,
        ),
      );
    }

    _logger.info("Workout updated from server successfully");
  }

  Future<List<Workout>> getAllWorkouts() async {
    _logger.info("Loading all workouts from database");
    final workoutRows =
        await (select(workouts)
              ..where((final t) => t.deletedAt.isNull())
              ..orderBy([(final t) => OrderingTerm.asc(t.start)]))
            .get();
    _logger.info("Loaded ${workoutRows.length} workout rows");

    final setRows = await (select(
      workoutSets,
    )..orderBy([(final t) => OrderingTerm.asc(t.id)])).get();
    _logger.info("Loaded ${setRows.length} set rows");

    // Group sets by workout_id for quick lookup
    final setsByWorkoutId = <int, List<WorkoutSet>>{};
    for (final setRow in setRows) {
      final workoutSet = WorkoutSet(
        group: setRow.groupNumber,
        targetReps: setRow.targetReps,
        completedReps: setRow.completedReps,
      );
      setsByWorkoutId
          .putIfAbsent(setRow.workoutId, () => <WorkoutSet>[])
          .add(workoutSet);
    }

    // Build workout objects with their associated sets
    final workoutList = <Workout>[];
    for (final workoutRow in workoutRows) {
      final workoutType = WorkoutType.values.firstWhere(
        (final type) => type.name == workoutRow.workoutType,
      );

      final workout =
          Workout(
              id: workoutRow.id,
              serverId: workoutRow.serverId,
              workoutType: workoutType,
              maxGroups: workoutRow.maxGroups,
              start: workoutRow.start,
            )
            ..end = workoutRow.end
            ..updatedAt = workoutRow.updatedAt
            ..sets = setsByWorkoutId[workoutRow.id] ?? <WorkoutSet>[];

      workoutList.add(workout);
    }

    _logger.info("Successfully loaded ${workoutList.length} workouts from database");
    return workoutList;
  }

  /// Gets a workout by its server_id (including deleted workouts).
  /// Returns null if not found.
  Future<Workout?> getWorkoutByServerId(final int serverId) async {
    _logger.info("Getting workout by server_id: $serverId");
    final workoutRow =
        await (select(workouts)
              ..where((final t) => t.serverId.equals(serverId))
              ..limit(1))
            .getSingleOrNull();

    if (workoutRow == null) {
      return null;
    }

    // Load sets for this workout
    final setRows = await (select(
      workoutSets,
    )..where((final t) => t.workoutId.equals(workoutRow.id))).get();

    final workoutType = WorkoutType.values.firstWhere(
      (final type) => type.name == workoutRow.workoutType,
    );

    final workout =
        Workout(
            id: workoutRow.id,
            serverId: workoutRow.serverId,
            workoutType: workoutType,
            maxGroups: workoutRow.maxGroups,
            start: workoutRow.start,
          )
          ..end = workoutRow.end
          ..updatedAt = workoutRow.updatedAt;

    if (workoutRow.deletedAt != null) {
      workout.deletedAt = workoutRow.deletedAt;
    }

    workout.sets = setRows.map((final setRow) {
      return WorkoutSet(
        group: setRow.groupNumber,
        targetReps: setRow.targetReps,
        completedReps: setRow.completedReps,
      );
    }).toList();

    return workout;
  }

  /// Soft deletes a workout by setting deleted_at timestamp.
  Future<void> deleteWorkout(final int workoutId) async {
    _logger.info("Soft deleting workout: id=$workoutId");
    await (update(workouts)..where((final t) => t.id.equals(workoutId))).write(
      WorkoutsCompanion(deletedAt: Value(DateTime.now().toUtc())),
    );
    _logger.info("Successfully soft deleted workout: id=$workoutId");
  }

  /// Gets the updated_at time of the most recent workout, ordered by updated_at descending.
  /// Returns null if no workouts exist.
  Future<DateTime?> getLatestWorkoutUpdatedAt() async {
    _logger.info("Getting latest workout updated_at");
    final workoutRow =
        await (select(workouts)
              ..where((final t) => t.deletedAt.isNull())
              ..orderBy([(final t) => OrderingTerm.desc(t.updatedAt)])
              ..limit(1))
            .getSingleOrNull();
    if (workoutRow == null) {
      _logger.info("No workouts found");
      return null;
    }
    _logger.info("Latest workout updated_at: ${workoutRow.updatedAt}");
    return workoutRow.updatedAt;
  }

  /// Gets all workouts including deleted ones (for sync operations).
  Future<List<Workout>> getAllWorkoutsIncludingDeleted() async {
    _logger.info("Loading all workouts from database (including deleted)");
    final workoutRows = await (select(
      workouts,
    )..orderBy([(final t) => OrderingTerm.asc(t.start)])).get();
    _logger.info("Loaded ${workoutRows.length} workout rows");

    final setRows = await (select(
      workoutSets,
    )..orderBy([(final t) => OrderingTerm.asc(t.id)])).get();
    _logger.info("Loaded ${setRows.length} set rows");

    // Group sets by workout_id for quick lookup
    final setsByWorkoutId = <int, List<WorkoutSet>>{};
    for (final setRow in setRows) {
      final workoutSet = WorkoutSet(
        group: setRow.groupNumber,
        targetReps: setRow.targetReps,
        completedReps: setRow.completedReps,
      );
      setsByWorkoutId
          .putIfAbsent(setRow.workoutId, () => <WorkoutSet>[])
          .add(workoutSet);
    }

    // Build workout objects with their associated sets
    final workoutList = <Workout>[];
    for (final workoutRow in workoutRows) {
      final workoutType = WorkoutType.values.firstWhere(
        (final type) => type.name == workoutRow.workoutType,
      );

      final workout =
          Workout(
              id: workoutRow.id,
              serverId: workoutRow.serverId,
              workoutType: workoutType,
              maxGroups: workoutRow.maxGroups,
              start: workoutRow.start,
            )
            ..end = workoutRow.end
            ..updatedAt = workoutRow.updatedAt;

      if (workoutRow.deletedAt != null) {
        workout.deletedAt = workoutRow.deletedAt;
      }

      workout.sets = setsByWorkoutId[workoutRow.id] ?? <WorkoutSet>[];

      workoutList.add(workout);
    }

    _logger.info("Successfully loaded ${workoutList.length} workouts from database");
    return workoutList;
  }

  /// Gets all workouts that don't have a server_id yet (unsynced workouts).
  /// Only returns non-deleted workouts.
  Future<List<Workout>> getUnsyncedWorkouts() async {
    _logger.info("Getting unsynced workouts");
    final workoutRows =
        await (select(workouts)
              ..where((final t) => t.serverId.isNull() & t.deletedAt.isNull())
              ..orderBy([(final t) => OrderingTerm.asc(t.start)]))
            .get();
    _logger.info("Found ${workoutRows.length} unsynced workouts");

    final setRows = await select(workoutSets).get();
    final setsByWorkoutId = <int, List<WorkoutSet>>{};
    for (final setRow in setRows) {
      final workoutSet = WorkoutSet(
        group: setRow.groupNumber,
        targetReps: setRow.targetReps,
        completedReps: setRow.completedReps,
      );
      setsByWorkoutId
          .putIfAbsent(setRow.workoutId, () => <WorkoutSet>[])
          .add(workoutSet);
    }

    final workoutList = <Workout>[];
    for (final workoutRow in workoutRows) {
      final workoutType = WorkoutType.values.firstWhere(
        (final type) => type.name == workoutRow.workoutType,
      );

      final workout =
          Workout(
              id: workoutRow.id,
              serverId: workoutRow.serverId,
              workoutType: workoutType,
              maxGroups: workoutRow.maxGroups,
              start: workoutRow.start,
            )
            ..end = workoutRow.end
            ..updatedAt = workoutRow.updatedAt;

      if (workoutRow.deletedAt != null) {
        workout.deletedAt = workoutRow.deletedAt;
      }

      workout.sets = setsByWorkoutId[workoutRow.id] ?? <WorkoutSet>[];
      workoutList.add(workout);
    }

    return workoutList;
  }

  /// Gets all locally deleted workouts that have a server_id (need to be synced to server).
  Future<List<Workout>> getLocallyDeletedWorkouts() async {
    _logger.info("Getting locally deleted workouts");
    final workoutRows =
        await (select(workouts)
              ..where((final t) => t.deletedAt.isNotNull() & t.serverId.isNotNull())
              ..orderBy([(final t) => OrderingTerm.asc(t.start)]))
            .get();
    _logger.info("Found ${workoutRows.length} locally deleted workouts");

    final setRows = await select(workoutSets).get();
    final setsByWorkoutId = <int, List<WorkoutSet>>{};
    for (final setRow in setRows) {
      final workoutSet = WorkoutSet(
        group: setRow.groupNumber,
        targetReps: setRow.targetReps,
        completedReps: setRow.completedReps,
      );
      setsByWorkoutId
          .putIfAbsent(setRow.workoutId, () => <WorkoutSet>[])
          .add(workoutSet);
    }

    final workoutList = <Workout>[];
    for (final workoutRow in workoutRows) {
      final workoutType = WorkoutType.values.firstWhere(
        (final type) => type.name == workoutRow.workoutType,
      );

      final workout =
          Workout(
              id: workoutRow.id,
              serverId: workoutRow.serverId,
              workoutType: workoutType,
              maxGroups: workoutRow.maxGroups,
              start: workoutRow.start,
            )
            ..end = workoutRow.end
            ..updatedAt = workoutRow.updatedAt;

      if (workoutRow.deletedAt != null) {
        workout.deletedAt = workoutRow.deletedAt;
      }

      workout.sets = setsByWorkoutId[workoutRow.id] ?? <WorkoutSet>[];
      workoutList.add(workout);
    }

    return workoutList;
  }
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  const dbFileName = "workouts.db";
  WorkoutDatabase._logger.fine("Database location: ${dbFolder.path}/$dbFileName");
  return driftDatabase(name: dbFileName);
});
