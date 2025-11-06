import "dart:async";

import "package:logging/logging.dart";
import "package:pull_up_club/features/workout/models.dart";
import "package:sqflite/sqflite.dart";

class WorkoutDatabase {
  WorkoutDatabase._init();
  static final WorkoutDatabase instance = WorkoutDatabase._init();
  static final Logger _logger = Logger("WorkoutDatabase");
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDB("workouts.db");
    return _database!;
  }

  Future<Database> _initDB(final String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = "$dbPath/$filePath";

    _logger.fine("Database location: $path");

    return openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(final Database db, final int version) async {
    // Create workouts table
    await db.execute("""
      CREATE TABLE workouts (
        id TEXT PRIMARY KEY,
        workout_type TEXT NOT NULL,
        max_groups INTEGER NOT NULL,
        start TEXT NOT NULL,
        end TEXT
      )
    """);

    // Create workout_sets table
    await db.execute("""
      CREATE TABLE workout_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id TEXT NOT NULL,
        group_number INTEGER NOT NULL,
        target_reps INTEGER,
        completed_reps INTEGER NOT NULL,
        FOREIGN KEY (workout_id) REFERENCES workouts (id) ON DELETE CASCADE
      )
    """);
  }

  Future<Workout> insertWorkout(final Workout workout) async {
    final db = await database;
    final workoutId = workout.uuid;

    // Insert workout
    await db.insert("workouts", {
      "id": workoutId,
      "workout_type": workout.workoutType.name,
      "max_groups": workout.maxGroups,
      "start": workout.start.toIso8601String(),
      "end": workout.end?.toIso8601String(),
    });

    // Insert sets
    for (final set_ in workout.sets) {
      await db.insert("workout_sets", {
        "workout_id": workoutId,
        "group_number": set_.group,
        "target_reps": set_.targetReps,
        "completed_reps": set_.completedReps,
      });
    }

    return workout;
  }

  Future<List<Workout>> getAllWorkouts() async {
    final db = await database;

    // Get all workouts
    final workoutMaps = await db.query("workouts", orderBy: "start ASC");

    final workouts = <Workout>[];

    for (final workoutMap in workoutMaps) {
      final workoutId = workoutMap["id"]! as String;

      // Get sets for this workout
      final setMaps = await db.query(
        "workout_sets",
        where: "workout_id = ?",
        whereArgs: [workoutId],
        orderBy: "group_number ASC",
      );

      final sets = setMaps
          .map(
            (final setMap) => WorkoutSet(
              group: setMap["group_number"]! as int,
              targetReps: setMap["target_reps"] as int?,
              completedReps: setMap["completed_reps"]! as int,
            ),
          )
          .toList();

      // Parse workout type
      final workoutTypeName = workoutMap["workout_type"]! as String;
      final workoutType = WorkoutType.values.firstWhere(
        (final type) => type.name == workoutTypeName,
      );

      // Create workout
      final workout = Workout(
        id: workoutId,
        workoutType: workoutType,
        maxGroups: workoutMap["max_groups"]! as int,
        start: DateTime.parse(workoutMap["start"]! as String),
      );

      // Set end time if available
      final endStr = workoutMap["end"] as String?;
      if (endStr != null) {
        workout.end = DateTime.parse(endStr);
      }

      // Set sets
      workout.sets = sets;

      workouts.add(workout);
    }

    return workouts;
  }

  Future<void> deleteWorkout(final String workoutId) async {
    final db = await database;
    await db.delete("workouts", where: "id = ?", whereArgs: [workoutId]);
    // Sets will be deleted automatically due to CASCADE
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
