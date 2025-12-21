import "package:clock/clock.dart";
import "package:drift/drift.dart";
import "package:drift_flutter/drift_flutter.dart";
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:pull_up_club/domain/models.dart";

part "workout_database.g.dart";

LazyDatabase _openConnection() => LazyDatabase(() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  const dbFileName = "workouts.db";
  WorkoutDatabase._logger.fine("Database location: ${dbFolder.path}/$dbFileName");
  return driftDatabase(name: dbFileName);
});

@DataClassName("DBWorkout")
class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable()();
  TextColumn get workoutType => text()();
  IntColumn get maxGroups => integer()();
  DateTimeColumn get start => dateTime()();
  DateTimeColumn get end => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

@DataClassName("DBWorkoutSet")
class WorkoutSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId =>
      integer().references(Workouts, #id, onDelete: KeyAction.cascade)();
  IntColumn get number => integer()();
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
  int get schemaVersion => 4;

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
      _logger.info("Upgrading database schema from version $from to version $to");
      if (from < 2) {
        // Add number column to workout_sets table as nullable first (for migration safety)
        await customStatement("ALTER TABLE workout_sets ADD COLUMN number INTEGER");
        _logger.info("Added number column to workout_sets table (nullable)");

        // Set number values: for each workout, order sets by id and assign numbers starting from 1
        // We'll use a subquery to assign sequential numbers based on id ordering
        await customStatement("""
          UPDATE workout_sets
          SET number = (
            SELECT COUNT(*) + 1
            FROM workout_sets ws2
            WHERE ws2.workout_id = workout_sets.workout_id
              AND ws2.id < workout_sets.id
          )
        """);
        _logger.info("Populated number values for workout sets");

        // Now make number non-nullable by recreating the table
        // Step 1: Create new table with non-nullable number
        await customStatement("""
          CREATE TABLE workout_sets_new (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            workout_id INTEGER NOT NULL,
            number INTEGER NOT NULL,
            group_number INTEGER NOT NULL,
            target_reps INTEGER,
            completed_reps INTEGER NOT NULL,
            FOREIGN KEY (workout_id) REFERENCES workouts(id) ON DELETE CASCADE
          )
        """);

        // Step 2: Copy data from old table to new table
        await customStatement("""
          INSERT INTO workout_sets_new (
            id, workout_id, number, group_number, target_reps, completed_reps
          )
          SELECT
            id, workout_id, COALESCE(number, 1) as number, group_number, target_reps, completed_reps
          FROM workout_sets
        """);

        // Step 3: Drop old table and rename new table
        await customStatement("DROP TABLE workout_sets");
        await customStatement("ALTER TABLE workout_sets_new RENAME TO workout_sets");

        _logger.info("Migrated number column to non-nullable");
      }
      if (from < 3) {
        // Make end column non-nullable by recreating the workouts table
        // Step 1: Create new table with non-nullable end
        await customStatement("""
          CREATE TABLE workouts_new (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            workout_type TEXT NOT NULL,
            max_groups INTEGER NOT NULL,
            start INTEGER NOT NULL,
            end INTEGER NOT NULL
          )
        """);

        // Step 2: Copy data from old table to new table, setting end to start for null values
        // this is just a precaution for absolute safety - in reality end will always be set
        await customStatement("""
          INSERT INTO workouts_new (
            id, workout_type, max_groups, start, end
          )
          SELECT
            id, workout_type, max_groups, start, COALESCE(end, start) as end
          FROM workouts
        """);

        // Step 3: Drop old table and rename new table
        await customStatement("DROP TABLE workouts");
        await customStatement("ALTER TABLE workouts_new RENAME TO workouts");

        _logger.info("Migrated end column to non-nullable");
      }
      if (from < 4) {
        // Add columns which are needed for the cloud sync
        // Add server_id column
        await m.addColumn(workouts, workouts.serverId);
        _logger.info("Added server_id column to workouts table");
        // Add deleted_at column for soft deletes
        await m.addColumn(workouts, workouts.deletedAt);
        _logger.info("Added deleted_at column to workouts table");
      }
      _logger.info("Database schema upgraded successfully");
    },
  );

  Future<Workout> insertWorkout(final Workout workout) async {
    if (workout.end == null) {
      throw ArgumentError("Can only insert finished workouts");
    }

    _logger.info("Inserting workout: $workout");
    final workoutId = await into(workouts).insert(
      WorkoutsCompanion.insert(
        workoutType: workout.workoutType.name,
        maxGroups: workout.maxGroups,
        start: workout.start,
        end: workout.end!,
      ),
    );
    _logger.info("Workout inserted with ID: $workoutId");

    // Insert sets
    for (final set_ in workout.sets) {
      await into(workoutSets).insert(
        WorkoutSetsCompanion.insert(
          workoutId: workoutId,
          number: set_.number,
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
    workout.id = workoutId;
    return workout;
  }

  /// Updates the server_id for a workout.
  Future<void> updateWorkoutServerId(final int workoutId, final int serverId) async {
    _logger.info("Updating workout server_id: localId=$workoutId, serverId=$serverId");
    await (update(workouts)..where((final t) => t.id.equals(workoutId))).write(
      WorkoutsCompanion(serverId: Value(serverId)),
    );
    _logger.info("Workout server_id updated successfully");
  }

  Future<List<Workout>> getAllNonDeletedWorkouts() async {
    _logger.info("Loading all non-deleted workouts from database");
    final workoutRows =
        await (select(workouts)
              ..where((final t) => t.deletedAt.isNull())
              // sorting by "end" instead of "start" because
              //  - we assume there are no overlapping/concurrent workouts -> it doesn't really matter
              //  - there's an index on "end", but not on "start"
              ..orderBy([(final t) => OrderingTerm.asc(t.end)]))
            .get();
    _logger.info("Loaded ${workoutRows.length} workout rows");

    final setRows = await loadRelatedWorkoutSets(workoutRows);
    return _convertToDomainModel(workoutRows, setRows);
  }

  Future<List<DBWorkoutSet>> loadRelatedWorkoutSets(
    final List<DBWorkout> workoutRows,
  ) async {
    // Only load sets of the relevant workouts
    final workoutIds = workoutRows.map((final row) => row.id).toList();
    final setRows = workoutIds.isEmpty
        ? <DBWorkoutSet>[]
        : await (select(workoutSets)
                ..where((final t) => t.workoutId.isIn(workoutIds))
                ..orderBy([
                  (final t) => OrderingTerm.asc(t.workoutId),
                  (final t) => OrderingTerm.asc(t.number),
                ]))
              .get();
    _logger.info("Loaded ${setRows.length} set rows");
    return setRows;
  }

  List<Workout> _convertToDomainModel(
    final List<DBWorkout> workoutRows,
    final List<DBWorkoutSet> setRows,
  ) {
    // Group sets by workout_id for quick lookup
    final setsByWorkoutId = <int, List<WorkoutSet>>{};
    for (final setRow in setRows) {
      final workoutSet = WorkoutSet(
        number: setRow.number,
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

      final workout = Workout(
        id: workoutRow.id,
        serverId: workoutRow.serverId,
        workoutType: workoutType,
        maxGroups: workoutRow.maxGroups,
        start: workoutRow.start.toUtc(),
        end: workoutRow.end.toUtc(),
        deletedAt: workoutRow.deletedAt?.toUtc(),
        sets: setsByWorkoutId[workoutRow.id] ?? <WorkoutSet>[],
      );

      workoutList.add(workout);
    }
    return workoutList;
  }

  /// Gets workouts for cloud sync.
  /// Returns:
  /// - All workouts with empty serverId (unsynced local workouts)
  /// - All workouts with serverId matching any of the provided [serverIds]
  /// Includes deleted workouts as they need to be synced.
  /// Returns DB rows for sync operations (to access deletedAt field).
  Future<List<Workout>> getWorkoutsForSync(final List<int> serverIds) async {
    _logger.info(
      "Loading workouts for sync (serverIds=${serverIds.length}, including unsynced)",
    );

    var query = select(workouts);

    if (serverIds.isEmpty) {
      // Only return workouts with empty serverId
      query = query..where((final t) => t.serverId.isNull());
    } else {
      // Return workouts with empty serverId OR serverId in the provided list
      query = query
        ..where((final t) => t.serverId.isNull() | t.serverId.isIn(serverIds));
    }

    final workoutRows = await (query..orderBy([(final t) => OrderingTerm.asc(t.end)]))
        .get();
    _logger.info("Loaded ${workoutRows.length} workout rows for sync");

    final setRows = await loadRelatedWorkoutSets(workoutRows);
    return _convertToDomainModel(workoutRows, setRows);
  }

  /// Soft deletes a workout by setting deleted_at timestamp.
  Future<void> deleteWorkout({
    required final int workoutId,
    final DateTime? deletedAt,
  }) async {
    final targetDeletedAt = deletedAt ?? clock.now().toUtc();
    _logger.info(
      "Soft deleting workout: id=$workoutId, targetDeletedAt=$targetDeletedAt",
    );
    await (update(workouts)..where((final t) => t.id.equals(workoutId))).write(
      WorkoutsCompanion(deletedAt: Value(targetDeletedAt)),
    );
    _logger.info("Successfully soft deleted workout: id=$workoutId");
  }

  /// Gets the end time or deleted_at time (whichever is later) across all workouts.
  /// Used for delta sync filtering.
  /// Returns null if no workouts exist.
  Future<DateTime?> getLatestLocalWorkoutDatetime() async {
    _logger.info("Getting latest workout datetime (end or deleted_at)");

    // Get the maximum end time
    final maxEndRow =
        await (select(workouts)
              ..orderBy([(final t) => OrderingTerm.desc(t.end)])
              ..limit(1))
            .getSingleOrNull();

    // Get the maximum deleted_at time
    final maxDeletedAtRow =
        await (select(workouts)
              ..where((final t) => t.deletedAt.isNotNull())
              ..orderBy([(final t) => OrderingTerm.desc(t.deletedAt)])
              ..limit(1))
            .getSingleOrNull();

    // even if no workout is deleted, maxDeletedAtRow can only be null if there are no rows
    if (maxEndRow == null || maxDeletedAtRow == null) {
      _logger.info("No workouts found");
      return null;
    }

    // Compare the maximum end and maximum deleted_at, return the later one
    final maxEnd = maxEndRow.end;
    final maxDeletedAt = maxDeletedAtRow.deletedAt;

    DateTime? syncTime;
    if (maxDeletedAt == null) {
      syncTime = maxEnd;
    } else {
      syncTime = maxDeletedAt.isAfter(maxEnd) ? maxDeletedAt : maxEnd;
    }

    _logger.info(
      "Latest workout sync time: $syncTime (maxEnd=$maxEnd, maxDeletedAt=$maxDeletedAt)",
    );
    return syncTime;
  }
}
