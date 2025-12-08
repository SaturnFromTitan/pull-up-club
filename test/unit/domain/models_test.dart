import "package:flutter_test/flutter_test.dart";
import "package:pull_up_club/domain/models.dart";

void main() {
  group("Workout", () {
    test("creates a workout with default start time", () {
      final beforeCreation = DateTime.now().toUtc();
      final workout = Workout(workoutType: WorkoutType.maxSets, maxGroups: 3);
      final afterCreation = DateTime.now().toUtc();

      expect(workout.workoutType, WorkoutType.maxSets);
      expect(workout.maxGroups, 3);
      expect(workout.id, isNull);
      expect(workout.end, isNull);
      expect(workout.sets, isEmpty);
      expect(
        workout.start.isAfter(beforeCreation) ||
            workout.start.isAtSameMomentAs(beforeCreation),
        isTrue,
      );
      expect(
        workout.start.isBefore(afterCreation) ||
            workout.start.isAtSameMomentAs(afterCreation),
        isTrue,
      );
    });

    test("finish sets end time", () {
      final workout = Workout(workoutType: WorkoutType.maxSets, maxGroups: 3);

      expect(workout.end, isNull);

      final beforeFinish = DateTime.now().toUtc();
      workout.finish();
      final afterFinish = DateTime.now().toUtc();

      expect(workout.end, isNotNull);
      expect(workout.end!.isAfter(beforeFinish), isTrue);
      expect(workout.end!.isBefore(afterFinish), isTrue);
    });

    test("finish does not overwrite existing end time", () {
      final workout = Workout(workoutType: WorkoutType.maxSets, maxGroups: 3);

      final firstEnd = DateTime(2024, 1, 1, 12).toUtc();
      workout
        ..end = firstEnd
        ..finish();

      expect(workout.end, firstEnd);
    });

    test("durationMillis returns null when workout not finished", () {
      final workout = Workout(workoutType: WorkoutType.maxSets, maxGroups: 3);

      expect(workout.durationMillis(), isNull);
    });

    test("durationMillis returns correct duration when workout finished", () {
      final start = DateTime(2024, 1, 1, 12).toUtc();
      final end = DateTime(2024, 1, 1, 12, 5, 30).toUtc(); // 5 minutes 30 seconds
      final workout = Workout(
        workoutType: WorkoutType.maxSets,
        maxGroups: 3,
        start: start,
      )..end = end;

      expect(workout.durationMillis(), 330_000); // 5 * 60 * 1000 + 30 * 1000
    });

    test("totalReps returns 0 for empty sets", () {
      final workout = Workout(workoutType: WorkoutType.maxSets, maxGroups: 3);

      expect(workout.totalReps(), 0);
    });

    test("totalReps calculates sum of all completed reps", () {
      final workout = Workout(workoutType: WorkoutType.maxSets, maxGroups: 3)
        ..sets = [
          WorkoutSet(group: 1, targetReps: 10, completedReps: 8),
          WorkoutSet(group: 1, targetReps: 10, completedReps: 7),
          WorkoutSet(group: 2, targetReps: 10, completedReps: 9),
        ];

      expect(workout.totalReps(), 24); // 8 + 7 + 9
    });

    test("toString includes all relevant information", () {
      final workout = Workout(id: 1, workoutType: WorkoutType.maxSets, maxGroups: 3)
        ..sets = [WorkoutSet(group: 1, targetReps: 10, completedReps: 8)];

      final str = workout.toString();

      expect(str, contains("id=1"));
      expect(str, contains("type=Max Sets"));
      expect(str, contains("maxGroups=3"));
      expect(str, contains("sets=1"));
      expect(str, contains("totalReps=8"));
      expect(str, contains("inProgress=true"));
    });
  });
}
