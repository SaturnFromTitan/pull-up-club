import "package:drift/drift.dart";
import "package:drift_flutter/drift_flutter.dart";
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:pull_up_club/domain/models.dart";

part "workout_database.g.dart";

@DataClassName("DBWorkout")
class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
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
  int get schemaVersion => 1;

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
  );

  Future<Workout> insertWorkout(final Workout workout) async {
    _logger.info("Inserting workout: $workout");
    final workoutId = await into(workouts).insert(
      WorkoutsCompanion.insert(
        workoutType: workout.workoutType.name,
        maxGroups: workout.maxGroups,
        start: workout.start,
        end: workout.end == null ? const Value.absent() : Value(workout.end),
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
        workoutType: workout.workoutType,
        maxGroups: workout.maxGroups,
        start: workout.start,
      )
      ..end = workout.end
      ..sets = workout.sets;
  }

  Future<List<Workout>> getAllWorkouts() async {
    _logger.info("Loading all workouts from database");
    final workoutRows = await (select(
      workouts,
    )..orderBy([(final t) => OrderingTerm.asc(t.id)])).get();
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

    _logger.info("Successfully loaded ${workoutList.length} workouts from database");
    return workoutList;
  }

  Future<void> deleteWorkout(final int workoutId) async {
    _logger.info("Deleting workout: id=$workoutId");
    await (delete(workouts)..where((final t) => t.id.equals(workoutId))).go();
    // Sets will be deleted automatically due to CASCADE
    _logger.info("Successfully deleted workout: id=$workoutId");
  }
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  const dbFileName = "workouts.db";
  WorkoutDatabase._logger.fine("Database location: ${dbFolder.path}/$dbFileName");
  return driftDatabase(name: dbFileName);
});
