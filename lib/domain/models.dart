import "package:clock/clock.dart";

enum WorkoutType {
  maxSets("Max Sets"),
  submaxVolume("Submax Volume"),
  ladders("Ladders");

  const WorkoutType(this.name);

  final String name;
}

class WorkoutSet {
  WorkoutSet({
    required this.number,
    required this.group,
    required this.targetReps,
    required this.completedReps,
  });
  final int number; // order of the set within the workout (1-based)
  final int group; // to identify ladders (1-based)
  final int? targetReps;
  final int completedReps;
}

class Workout {
  Workout({
    required this.workoutType,
    required this.maxGroups,
    this.id,
    this.serverId,
    final DateTime? start,
    this.end,
    this.sets = const <WorkoutSet>[],
  }) : start = start ?? clock.now().toUtc();
  int? id;
  int? serverId; // TODO: don't expose serverId in the domain model
  final WorkoutType workoutType;
  final int maxGroups;
  final DateTime start;
  DateTime? end;
  List<WorkoutSet> sets = <WorkoutSet>[];

  void finish() {
    end ??= clock.now().toUtc();
  }

  int? durationMillis() {
    if (end == null) {
      return null;
    }
    return end!.difference(start).inMilliseconds;
  }

  int totalReps() => sets.fold(0, (final t, final s) => t + s.completedReps);

  @override
  String toString() {
    final buffer = StringBuffer("Workout(")
      ..write("id=$id, ")
      ..write("type=${workoutType.name}, ")
      ..write("maxGroups=$maxGroups, ")
      ..write("sets=${sets.length}")
      ..write(", totalReps=${totalReps()}")
      ..write(", inProgress=${end == null}")
      ..write(")");
    return buffer.toString();
  }
}
