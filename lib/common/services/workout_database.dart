import "dart:async";

import "package:logging/logging.dart";
import "package:path/path.dart" as path;
import "package:pull_up_club/features/workout/models.dart";
import "package:sqflite/sqflite.dart";

enum TableNames {
  workouts("workouts"),
  workoutSets("workout_sets");

  const TableNames(this.name);

  final String name;
}

class WorkoutDatabase {
  WorkoutDatabase._init();
  static final WorkoutDatabase instance = WorkoutDatabase._init();
  static final Logger _logger = Logger("WorkoutDatabase");
  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDB("workouts.db");
    return _database!;
  }

  Future<Database> _initDB(final String filePath) async {
    final dbPath = path.join(await getDatabasesPath(), filePath);
    _logger.fine("Database location: $dbPath");
    return openDatabase(dbPath, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(final Database db, final int version) async {
    // Create workouts table
    await db.execute("""
      CREATE TABLE ${TableNames.workouts.name} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_type TEXT NOT NULL,
        max_groups INTEGER NOT NULL,
        start TEXT NOT NULL,
        end TEXT
      )
    """);

    // Create workout_sets table
    await db.execute("""
      CREATE TABLE ${TableNames.workoutSets.name} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER NOT NULL,
        group_number INTEGER NOT NULL,
        target_reps INTEGER,
        completed_reps INTEGER NOT NULL,
        FOREIGN KEY (workout_id) REFERENCES ${TableNames.workouts.name} (id) ON DELETE CASCADE
      )
    """);
  }

  Future<Workout> insertWorkout(final Workout workout) async {
    final db = await database;

    // Insert workout
    final workoutId = await db.insert(TableNames.workouts.name, {
      "workout_type": workout.workoutType.name,
      "max_groups": workout.maxGroups,
      "start": workout.start.toIso8601String(),
      "end": workout.end?.toIso8601String(),
    });

    // Insert sets
    for (final set_ in workout.sets) {
      await db.insert(TableNames.workoutSets.name, {
        "workout_id": workoutId,
        "group_number": set_.group,
        "target_reps": set_.targetReps,
        "completed_reps": set_.completedReps,
      });
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
    final db = await database;

    // Get db data
    final workoutMaps = await db.query(TableNames.workouts.name, orderBy: "id ASC");
    final setMaps = await db.query(TableNames.workoutSets.name, orderBy: "id ASC");

    // Group sets by workout_id for quick lookup
    final setsByWorkoutId = <int, List<WorkoutSet>>{};
    for (final setMap in setMaps) {
      final workoutId = setMap["workout_id"]! as int;
      final workoutSet = WorkoutSet(
        group: setMap["group_number"]! as int,
        targetReps: setMap["target_reps"] as int?,
        completedReps: setMap["completed_reps"]! as int,
      );
      setsByWorkoutId.putIfAbsent(workoutId, () => <WorkoutSet>[]).add(workoutSet);
    }

    // Build workout objects with their associated sets
    final workouts = <Workout>[];
    for (final workoutMap in workoutMaps) {
      final workoutId = workoutMap["id"]! as int;

      final workoutTypeName = workoutMap["workout_type"]! as String;
      final workoutType = WorkoutType.values.firstWhere(
        (final type) => type.name == workoutTypeName,
      );

      final workout = Workout(
        id: workoutId,
        workoutType: workoutType,
        maxGroups: workoutMap["max_groups"]! as int,
        start: DateTime.parse(workoutMap["start"]! as String),
      );

      final endStr = workoutMap["end"] as String?;
      if (endStr != null) {
        workout.end = DateTime.parse(endStr);
      }

      workout.sets = setsByWorkoutId[workoutId] ?? <WorkoutSet>[];

      workouts.add(workout);
    }

    return workouts;
  }

  Future<void> deleteWorkout(final int workoutId) async {
    final db = await database;
    await db.delete(TableNames.workouts.name, where: "id = ?", whereArgs: [workoutId]);
    // Sets will be deleted automatically due to CASCADE
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
