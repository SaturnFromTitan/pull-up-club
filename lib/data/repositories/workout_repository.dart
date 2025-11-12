import "package:pull_up_club/common/services/workout_database.dart";
import "package:pull_up_club/features/workout/models.dart";

class WorkoutRepository {
  WorkoutRepository(this._database);

  final WorkoutDatabase _database;

  Future<List<Workout>> getAllWorkouts() => _database.getAllWorkouts();

  Future<Workout> saveWorkout(final Workout workout) =>
      _database.insertWorkout(workout);

  Future<void> deleteWorkout(final int workoutId) => _database.deleteWorkout(workoutId);
}
