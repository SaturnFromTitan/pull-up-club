import "package:pull_up_club/common/services/sync_service.dart";
import "package:pull_up_club/common/services/workout_database.dart";
import "package:pull_up_club/domain/models.dart";

class WorkoutRepository {
  WorkoutRepository(this._database, this._syncService);

  final WorkoutDatabase _database;
  final SyncService _syncService;

  Future<List<Workout>> getAllWorkouts() => _database.getAllWorkouts();

  Future<Workout> saveWorkout(final Workout workout) async {
    final saved = await _database.insertWorkout(workout);
    // Trigger sync in background (don't wait for it)
    _syncService.syncAll().catchError((final e) {
      // Log error but don't fail the save operation
    });
    return saved;
  }

  Future<void> deleteWorkout(final int workoutId) async {
    await _database.deleteWorkout(workoutId);
    // Trigger sync in background
    _syncService.syncAll().catchError((final e) {
      // Log error but don't fail the delete operation
    });
  }

  /// Manually trigger a sync
  Future<void> sync() => _syncService.syncAll();
}
