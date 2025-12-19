import "package:pull_up_club/domain/models.dart";

// Server-side workout set model from Supabase API.
class ServerWorkoutSet {
  ServerWorkoutSet({
    required this.id,
    required this.workoutId,
    required this.groupNumber,
    required this.completedReps,
    required this.number,
    this.targetReps,
  });

  factory ServerWorkoutSet.fromJson(final Map<String, dynamic> json) {
    return ServerWorkoutSet(
      id: json["id"] as int,
      workoutId: json["workout_id"] as int,
      groupNumber: json["group_number"] as int,
      targetReps: json["target_reps"] as int?,
      completedReps: json["completed_reps"] as int,
      number: json["number"] as int,
    );
  }

  final int id;
  final int workoutId;
  final int groupNumber;
  final int? targetReps;
  final int completedReps;
  final int number;

  /// Converts to local WorkoutSet model.
  WorkoutSet toLocal() {
    return WorkoutSet(
      group: groupNumber,
      targetReps: targetReps,
      completedReps: completedReps,
      number: number,
    );
  }
}

/// Server-side workout model from Supabase API.
class ServerWorkout {
  ServerWorkout({
    required this.id,
    required this.workoutType,
    required this.maxGroups,
    required this.start,
    required this.end,
    required this.updatedAt,
    required this.sets,
  });

  factory ServerWorkout.fromJson(final Map<String, dynamic> json) {
    final setsData = json["workout_sets"] as List<dynamic>? ?? [];
    final sets = setsData
        .map(
          (final setJson) => ServerWorkoutSet.fromJson(setJson as Map<String, dynamic>),
        )
        .toList();

    return ServerWorkout(
      id: json["id"] as int,
      workoutType: _parseWorkoutType(json["workout_type"] as String),
      maxGroups: json["max_groups"] as int,
      start: DateTime.parse(json["start"] as String).toUtc(),
      end: DateTime.parse(json["end"] as String).toUtc(),
      updatedAt: DateTime.parse(json["updated_at"] as String).toUtc(),
      sets: sets,
    );
  }

  static WorkoutType _parseWorkoutType(final String typeStr) {
    return WorkoutType.values.firstWhere(
      (final type) => type.name == typeStr,
      orElse: () => throw Exception("Unknown workout type: $typeStr"),
    );
  }

  final int id;
  final WorkoutType workoutType;
  final int maxGroups;
  final DateTime start;
  final DateTime end;
  final DateTime updatedAt;
  final List<ServerWorkoutSet> sets;

  /// Converts to local Workout model.
  Workout toLocal() {
    final workout =
        Workout(workoutType: workoutType, maxGroups: maxGroups, start: start)
          ..end = end
          ..sets = sets.map((final set) => set.toLocal()).toList()
          ..serverId = id;

    return workout;
  }
}
