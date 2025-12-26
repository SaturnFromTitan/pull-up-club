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

  @override
  String toString() {
    final buffer = StringBuffer("WorkoutSet(")
      ..write("number=$number")
      ..write(", group=$group")
      ..write(", targetReps=$targetReps")
      ..write(", completedReps=$completedReps")
      ..write(")");
    return buffer.toString();
  }
}

class Workout {
  Workout({
    required this.workoutType,
    required this.maxGroups,
    this.id,
    this.serverId,
    final DateTime? start,
    this.end,
    this.deletedAt,
    final List<WorkoutSet>? sets,
  }) : start = start ?? clock.now().toUtc(),
       sets = sets ?? <WorkoutSet>[];

  int? id;
  int? serverId;
  final WorkoutType workoutType;
  final int maxGroups;
  final DateTime start;
  DateTime? end;
  DateTime? deletedAt;
  List<WorkoutSet> sets;
  // Even though workouts can be aborted, I decided against adding an isCompleted argument
  // 1) before introducing the abort & persist option, the workaround was to log "0" sets for the remaining groups.
  //    So the exisitng data could contain effectively incomplete workouts, but the isComplete set would be set to true.
  //    Since the cloud sync is optional, this issue can't be handled in a data migration as new old data can come in at any time.
  // 2) it should be therefore more robust to derive the attribute from the set data via a method if ever needed.

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
      ..write("id=$id")
      ..write(", serverId=$serverId")
      ..write(", type=${workoutType.name}")
      ..write(", maxGroups=$maxGroups")
      ..write(", start=$start")
      ..write(", end=$end")
      ..write(", deletedAt=$deletedAt")
      ..write(", numSets=${sets.length}")
      ..write(", totalReps=${totalReps()}")
      ..write(")");
    return buffer.toString();
  }
}
