import "package:flutter/material.dart";
import "package:pull_up_club/common/providers/workout_history_provider.dart";
import "package:pull_up_club/features/workout/providers/workout_provider.dart";
import "package:pull_up_club/features/workout/screens/workouts/_base_workout_screen.dart";
import "package:pull_up_club/features/workout/widgets/reps_form.dart";

class MaxSetsScreen extends BaseWorkoutScreen {
  const MaxSetsScreen({super.key});

  @override
  State<MaxSetsScreen> createState() => _MaxSetsScreenState();
}

class _MaxSetsScreenState extends BaseWorkoutState<MaxSetsScreen> {
  @override
  int get restDurationSeconds => 5 * 60;

  @override
  Null getTargetReps() => null;

  @override
  Widget getInputs(
    final WorkoutProvider workoutProvider,
    final WorkoutHistoryProvider workoutHistoryProvider,
  ) => RepsForm(
    onValidSubmit: (final reps) {
      finishSet(
        group: workoutProvider.workout.sets.length + 1,
        completedReps: reps,
        workoutProvider: workoutProvider,
        workoutHistoryProvider: workoutHistoryProvider,
      );
    },
  );
}
