import "package:flutter/material.dart";
import "package:provider/provider.dart";
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
  int get restDurationMillis => 5 * 60 * 1_000;

  @override
  Null getTargetReps() => null;

  @override
  Widget getInputs() => RepsForm(
    onValidSubmit: (final reps) {
      final workoutProvider = context.read<WorkoutProvider>();
      finishSet(group: workoutProvider.workout.sets.length + 1, completedReps: reps);
    },
  );
}
