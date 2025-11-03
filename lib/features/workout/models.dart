import "package:uuid/uuid.dart";

enum WorkoutType {
  maxSets("Max Sets"),
  submaxVolume("Submax Volume"),
  ladders("Ladders");

  final String name;
  const WorkoutType(this.name);
}

class WorkoutSet {
  final int group; // to identify ladders
  final int? targetReps;
  final int completedReps;

  WorkoutSet({
    required this.group,
    required this.targetReps,
    required this.completedReps,
  });
}

class Workout {
  final Uuid uuid;
  final WorkoutType workoutType;
  final int maxGroups;
  final DateTime start;
  DateTime? end;
  List<WorkoutSet> sets = <WorkoutSet>[];

  Workout({
    Uuid? id,
    required this.workoutType,
    required this.maxGroups,
    DateTime? start,
  }) : uuid = id ?? Uuid(),
       start = start ?? DateTime.now().toUtc();

  void finish() {
    end ??= DateTime.now().toUtc();
  }

  int? durationSeconds() {
    if (end == null) {
      return null;
    }
    return end!.second - start.second;
  }

  int totalReps() {
    return sets.fold(0, (t, s) => t + s.completedReps);
  }
}
