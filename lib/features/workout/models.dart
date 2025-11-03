import "package:uuid/uuid.dart";

enum WorkoutType {
  maxSets("Max Sets"),
  submaxVolume("Submax Volume"),
  ladders("Ladders");

  const WorkoutType(this.name);

  final String name;
}

class WorkoutSet {
  WorkoutSet({
    required this.group,
    required this.targetReps,
    required this.completedReps,
  });
  final int group; // to identify ladders
  final int? targetReps;
  final int completedReps;
}

class Workout {
  Workout({
    required this.workoutType,
    required this.maxGroups,
    final Uuid? id,
    final DateTime? start,
  }) : uuid = id ?? const Uuid(),
       start = start ?? DateTime.now().toUtc();
  final Uuid uuid;
  final WorkoutType workoutType;
  final int maxGroups;
  final DateTime start;
  DateTime? end;
  List<WorkoutSet> sets = <WorkoutSet>[];

  void finish() {
    end ??= DateTime.now().toUtc();
  }

  int? durationSeconds() {
    if (end == null) {
      return null;
    }
    return end!.second - start.second;
  }

  int totalReps() => sets.fold(0, (final t, final s) => t + s.completedReps);
}
