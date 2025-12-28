import "package:pull_up_club/domain/models.dart";

// Server-side workout set model from Supabase API.
class ServerWorkoutSet {
  ServerWorkoutSet({
    required this.id,
    required this.idempotencyKey,
    required this.workoutId,
    required this.groupNumber,
    required this.completedReps,
    required this.number,
    required this.targetReps,
  });

  factory ServerWorkoutSet.fromJson(final Map<String, dynamic> json) {
    return ServerWorkoutSet(
      id: json["id"] as int,
      idempotencyKey: json["idempotency_key"] as String,
      workoutId: json["workout_id"] as int,
      groupNumber: json["group_number"] as int,
      targetReps: json["target_reps"] as int?,
      completedReps: json["completed_reps"] as int,
      number: json["number"] as int,
    );
  }

  final int id;
  final String idempotencyKey;
  final int workoutId;
  final int groupNumber;
  final int? targetReps;
  final int completedReps;
  final int number;

  /// Converts to local WorkoutSet model.
  WorkoutSet toLocal() {
    return WorkoutSet(
      idempotencyKey: idempotencyKey,
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
    required this.idempotencyKey,
    required this.workoutType,
    required this.maxGroups,
    required this.start,
    required this.end,
    required this.deletedAt,
    required this.sets,
  });

  factory ServerWorkout.fromJson(final Map<String, dynamic> json) {
    final sets =
        (json["workout_sets"] as List<dynamic>? ?? [])
            .map(
              (final setJson) =>
                  ServerWorkoutSet.fromJson(setJson as Map<String, dynamic>),
            )
            .toList()
          ..sort((final a, final b) => a.number.compareTo(b.number));

    return ServerWorkout(
      id: json["id"] as int,
      idempotencyKey: json["idempotency_key"] as String,
      workoutType: _parseWorkoutType(json["workout_type"] as String),
      maxGroups: json["max_groups"] as int,
      start: DateTime.parse(json["start"] as String).toUtc(),
      end: DateTime.parse(json["end"] as String).toUtc(),
      deletedAt: json["deleted_at"] != null
          ? DateTime.parse(json["deleted_at"] as String).toUtc()
          : null,
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
  final String idempotencyKey;
  final WorkoutType workoutType;
  final int maxGroups;
  final DateTime start;
  final DateTime end;
  final DateTime? deletedAt;
  final List<ServerWorkoutSet> sets;

  /// Converts to local Workout model.
  Workout toLocal() {
    final workout = Workout(
      serverId: id,
      idempotencyKey: idempotencyKey,
      workoutType: workoutType,
      maxGroups: maxGroups,
      start: start,
      end: end,
      deletedAt: deletedAt,
      sets: sets.map((final set) => set.toLocal()).toList(),
    );
    return workout;
  }
}
