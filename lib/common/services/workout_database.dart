import "package:drift/drift.dart";
import "package:drift_flutter/drift_flutter.dart";
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:pull_up_club/domain/models.dart";

part "workout_database.g.dart";

@DataClassName("DBWorkout")
class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  // Sync fields
  IntColumn get serverId => integer().nullable()(); // Server-side ID from Supabase
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant("pending"))(); // pending, synced, error
  // Workout fields
  TextColumn get workoutType => text()();
  IntColumn get maxGroups => integer()();
  DateTimeColumn get start => dateTime()();
  DateTimeColumn get end => dateTime().nullable()();
}

@DataClassName("DBWorkoutSet")
class WorkoutSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId =>
      integer().references(Workouts, #id, onDelete: KeyAction.cascade)();
  // Sync fields
  IntColumn get serverId => integer().nullable()(); // Server-side ID from Supabase
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant("pending"))(); // pending, synced, error
  // Set fields
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
      // Enable foreign key constraints in SQLite
      await customStatement("PRAGMA foreign_keys = ON");
    },
    onCreate: (final m) async {
      await m.createAll();
      _logger.fine("Database created");
    },
    onUpgrade: (final m, final from, final to) async {
      if (from < 2) {
        // Add sync fields to workouts table
        await m.customStatement("ALTER TABLE workouts ADD COLUMN server_id INTEGER");
        await m.customStatement(
          "ALTER TABLE workouts ADD COLUMN updated_at TEXT NOT NULL DEFAULT (datetime('now'))",
        );
        await m.customStatement("ALTER TABLE workouts ADD COLUMN deleted_at TEXT");
        await m.customStatement(
          "ALTER TABLE workouts ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'pending'",
        );
        // Add sync fields to workout_sets table
        await m.customStatement(
          "ALTER TABLE workout_sets ADD COLUMN server_id INTEGER",
        );
        await m.customStatement(
          "ALTER TABLE workout_sets ADD COLUMN updated_at TEXT NOT NULL DEFAULT (datetime('now'))",
        );
        await m.customStatement("ALTER TABLE workout_sets ADD COLUMN deleted_at TEXT");
        await m.customStatement(
          "ALTER TABLE workout_sets ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'pending'",
        );
        _logger.fine("Database upgraded to version 2");
      }
    },
  );

  Future<Workout> insertWorkout(final Workout workout) async {
    final now = DateTime.now().toUtc();
    final workoutId = await into(workouts).insert(
      WorkoutsCompanion.insert(
        workoutType: workout.workoutType.name,
        maxGroups: workout.maxGroups,
        start: workout.start,
        end: workout.end == null ? const Value.absent() : Value(workout.end),
        updatedAt: Value(now),
        syncStatus: const Value("pending"),
      ),
    );

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
          updatedAt: Value(now),
          syncStatus: const Value("pending"),
        ),
      );
    }

    // Return workout with the generated ID
    return Workout(
        id: workoutId,
        workoutType: workout.workoutType,
        maxGroups: workout.maxGroups,
        start: workout.start,
      )
      ..end = workout.end
      ..sets = workout.sets;
  }

  Future<List<Workout>> getAllWorkouts() async {
    final workoutRows =
        await (select(workouts)
              ..where((final t) => t.deletedAt.isNull())
              ..orderBy([(final t) => OrderingTerm.asc(t.id)]))
            .get();
    final setRows = await (select(
      workoutSets,
    )..orderBy([(final t) => OrderingTerm.asc(t.id)])).get();

    // Group sets by workout_id for quick lookup (exclude deleted sets)
    final setsByWorkoutId = <int, List<WorkoutSet>>{};
    for (final setRow in setRows) {
      if (setRow.deletedAt != null) continue; // Skip deleted sets
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

      final workout = Workout(
        id: workoutRow.id,
        workoutType: workoutType,
        maxGroups: workoutRow.maxGroups,
        start: workoutRow.start,
      );

      if (workoutRow.end != null) {
        workout.end = workoutRow.end;
      }

      workout.sets = setsByWorkoutId[workoutRow.id] ?? <WorkoutSet>[];

      workoutList.add(workout);
    }

    return workoutList;
  }

  Future<void> deleteWorkout(final int workoutId) async {
    final now = DateTime.now().toUtc();
    // Soft delete: set deleted_at timestamp
    await (update(workouts)..where((final t) => t.id.equals(workoutId))).write(
      WorkoutsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value("pending"),
      ),
    );
    // Soft delete all sets for this workout
    await (update(
      workoutSets,
    )..where((final t) => t.workoutId.equals(workoutId))).write(
      WorkoutSetsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value("pending"),
      ),
    );
  }
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  const dbFileName = "workouts.db";
  WorkoutDatabase._logger.fine("Database location: ${dbFolder.path}/$dbFileName");
  return driftDatabase(name: dbFileName);
});
