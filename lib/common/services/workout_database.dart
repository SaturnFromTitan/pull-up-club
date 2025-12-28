import "package:drift/drift.dart";
import "package:drift_flutter/drift_flutter.dart";
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:pull_up_club/domain/models.dart";

part "workout_database.g.dart";
part "workout_migrations.dart";

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
  TextColumn get idempotencyKey => text()();
  // Indexes are created in migration v5
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
  TextColumn get idempotencyKey => text()();
  // Index is created in migration v5
}

@DriftDatabase(tables: [Workouts, WorkoutSets])
class WorkoutDatabase extends _$WorkoutDatabase {
  WorkoutDatabase._() : super(_openConnection());
  static final WorkoutDatabase instance = WorkoutDatabase._();
  static final Logger _logger = Logger("WorkoutDatabase");

  @override
  int get schemaVersion => 6;

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

      for (var version = from + 1; version <= to; version++) {
        switch (version) {
          case 2:
            await migrateToVersion2(m);
          case 3:
            await migrateToVersion3(m);
          case 4:
            await migrateToVersion4(m);
          case 5:
            await migrateToVersion5(m);
          case 6:
            await migrateToVersion6(m);
          default:
            _logger.warning("No explicit migration defined for version $version");
        }
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
        serverId: workout.serverId == null
            ? const Value.absent()
            : Value(workout.serverId),
        workoutType: workout.workoutType.name,
        maxGroups: workout.maxGroups,
        start: workout.start,
        end: workout.end!,
        deletedAt: workout.deletedAt == null
            ? const Value.absent()
            : Value(workout.deletedAt),
        idempotencyKey: workout.idempotencyKey,
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
          idempotencyKey: set_.idempotencyKey,
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
              //  - there's an index covering "end", but none covering "start"
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
        idempotencyKey: setRow.idempotencyKey,
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
        idempotencyKey: workoutRow.idempotencyKey,
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

  Future<int?> getServerIdForWorkout(final int workoutId) async {
    final query = select(workouts)..where((final t) => t.id.equals(workoutId));
    final workoutRow = await query.getSingleOrNull();
    return workoutRow?.serverId;
  }

  /// Soft deletes a workout by setting deleted_at timestamp.
  Future<bool> deleteWorkout(final Workout workout) async {
    if (workout.deletedAt == null) {
      throw ArgumentError("The local workout isn't deleted yet");
    }
    if (workout.id == null) {
      _logger.warning("Can't delete a workout that's not persisted yet");
      return false;
    }

    _logger.info(
      "Soft deleting workout: id=${workout.id}, deletedAt=${workout.deletedAt}",
    );
    await (update(workouts)..where((final t) => t.id.equals(workout.id!))).write(
      WorkoutsCompanion(deletedAt: Value(workout.deletedAt)),
    );
    _logger.info("Successfully soft deleted workout: id=${workout.id}");
    return true;
  }
}
