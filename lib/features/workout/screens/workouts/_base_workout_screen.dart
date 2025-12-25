import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/providers/workout_history_provider.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:pull_up_club/common/utils/utils.dart";
import "package:pull_up_club/common/widgets/core/screen_scaffold.dart";
import "package:pull_up_club/common/widgets/shared/set_cards.dart";
import "package:pull_up_club/domain/models.dart";
import "package:pull_up_club/features/workout/providers/workout_provider.dart";
import "package:pull_up_club/features/workout/screens/rest_screen.dart";
import "package:pull_up_club/features/workout/screens/success_screen.dart";
import "package:pull_up_club/features/workout/widgets/destructive_workout_buttons.dart";

abstract class BaseWorkoutScreen extends StatefulWidget {
  const BaseWorkoutScreen({super.key});

  @override
  State<BaseWorkoutScreen> createState();
}

abstract class BaseWorkoutState<T extends BaseWorkoutScreen> extends State<T> {
  static final Logger _logger = Logger("BaseWorkoutScreen");
  int get restDurationMillis;

  int? getTargetReps();
  Widget getInputs();

  int getNumCompletedGroups() {
    final workoutProvider = context.read<WorkoutProvider>();
    return workoutProvider.workout.sets.length;
  }

  bool isLastGroup() =>
      getNumCompletedGroups() == context.read<WorkoutProvider>().workout.maxGroups - 1;

  bool isFinished() =>
      getNumCompletedGroups() == context.read<WorkoutProvider>().workout.maxGroups;

  void navigateToSuccess() {
    final workoutProvider = context.read<WorkoutProvider>();
    final workout = workoutProvider.workout;
    _logger.info("Navigating to success screen: $workout");
    unawaited(
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => SuccessScreen(workout: workout)),
      ),
    );
  }

  void navigateToRest() {
    final workoutProvider = context.read<WorkoutProvider>();
    _logger.info("Navigating to rest screen");
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: workoutProvider,
            child: RestScreen(currentGroupIndex: getNumCompletedGroups()),
          ),
        ),
      ),
    );
  }

  void finishSet({required final int group, required final int completedReps}) {
    final workoutProvider = context.read<WorkoutProvider>();
    final workout = workoutProvider.workout;
    final targetReps = getTargetReps();

    _logger.info(
      "Finishing set: group=$group, completedReps=$completedReps, "
      "targetReps=$targetReps, workout: $workout",
    );

    // add set
    final set_ = WorkoutSet(
      number: workout.sets.length + 1,
      group: group,
      targetReps: targetReps,
      completedReps: completedReps,
    );
    workout.sets.add(set_);

    // navigate
    if (isFinished()) {
      _logger.info("Workout finished: $workout");
      // can't await here as `finishSet` is meant to be called synchronously
      // on button press
      final workoutHistoryProvider = context.read<WorkoutHistoryProvider>();
      workout.finish();
      unawaited(workoutHistoryProvider.addWorkout(workout));
      navigateToSuccess();
    } else {
      workoutProvider.rest(restDurationMillis);
      navigateToRest();
    }
  }

  void undoLastSet() {
    context.read<WorkoutProvider>().undoLastSet();
  }

  @override
  Widget build(final BuildContext context) {
    final workoutProvider = context.watch<WorkoutProvider>();
    final workout = workoutProvider.workout;
    final targetReps = getTargetReps();
    final inputs = getInputs();
    const instructionTextStyle = AppTypography.headlineLarge;
    final instructionIconStyle = Screen.isSmall(context)
        ? const TextStyle(fontSize: 100, color: Colors.white, height: 1.3)
        : const TextStyle(fontSize: 110, color: Colors.white, height: 1.4);
    final instructionsNoTargetReps = Column(
      children: [
        const SizedBox(height: AppSpacing.xl),
        const Text(
          "Do as many reps as possible!",
          style: instructionTextStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text("🔥", style: instructionIconStyle, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.md),
      ],
    );
    final instructionsTargetReps = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("do", style: instructionTextStyle),
        const SizedBox(width: AppSpacing.sm),
        ShaderMask(
          shaderCallback: (final bounds) => AppGradients.repCount.createShader(bounds),
          child: Text(targetReps.toString(), style: instructionIconStyle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(targetReps == 1 ? "rep" : "reps", style: instructionTextStyle),
      ],
    );

    return ScreenScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.paddingSm),
              child: Column(
                children: [
                  if (targetReps == null)
                    instructionsNoTargetReps
                  else
                    instructionsTargetReps,
                  inputs,
                ],
              ),
            ),
          ),
          SetCards(
            values: getSetCardValues(workout),
            numExpectedCards: workout.maxGroups,
            highlightedIndex: getNumCompletedGroups(),
          ),
          DestructiveWorkoutButtons(workout: workout, onUndoLastSet: undoLastSet),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty("restDurationMillis", restDurationMillis));
  }
}
