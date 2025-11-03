import "package:flutter/material.dart";
import "package:pull_up_club/features/workout/providers/workout_provider.dart";
import "package:pull_up_club/common/providers/app_provider.dart";
import "package:pull_up_club/features/workout/widgets/reps_form.dart";
import "package:pull_up_club/features/workout/screens/workouts/_base_workout_screen.dart";

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
  Widget getInputs(WorkoutProvider workoutProvider, AppProvider appProvider) {
    return RepsForm(
      onValidSubmit: (int reps) {
        finishSet(
          group: workoutProvider.workout.sets.length + 1,
          completedReps: reps,
          workoutProvider: workoutProvider,
          appProvider: appProvider,
        );
      },
    );
  }
}
