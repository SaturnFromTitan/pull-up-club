import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/providers/app_provider.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:pull_up_club/common/utils/utils.dart";
import "package:pull_up_club/common/widgets/home_button.dart";
import "package:pull_up_club/common/widgets/screen_scaffold.dart";
import "package:pull_up_club/features/workout/models.dart";
import "package:pull_up_club/features/workout/providers/workout_provider.dart";
import "package:pull_up_club/features/workout/screens/rest_screen.dart";
import "package:pull_up_club/features/workout/screens/success_screen.dart";
import "package:pull_up_club/features/workout/widgets/set_cards.dart";

abstract class BaseWorkoutScreen extends StatefulWidget {
  const BaseWorkoutScreen({super.key});

  @override
  State<BaseWorkoutScreen> createState();
}

abstract class BaseWorkoutState<T extends BaseWorkoutScreen> extends State<T> {
  int get restDurationSeconds;

  int? getTargetReps();
  Widget getInputs(
    final WorkoutProvider workoutProvider,
    final AppProvider appProvider,
  );

  int getCompletedGroups(final WorkoutProvider workoutProvider) =>
      workoutProvider.workout.sets.length;

  bool isLastGroup(final WorkoutProvider workoutProvider) =>
      getCompletedGroups(workoutProvider) == workoutProvider.workout.maxGroups - 1;

  bool isFinished(final WorkoutProvider workoutProvider) =>
      getCompletedGroups(workoutProvider) == workoutProvider.workout.maxGroups;

  void navigateToSuccess(final WorkoutProvider workoutProvider) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SuccessScreen(workout: workoutProvider.workout),
        ),
      ),
    );
  }

  void navigateToRest(final WorkoutProvider workoutProvider) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: workoutProvider,
            child: const RestScreen(),
          ),
        ),
      ),
    );
  }

  void finishSet({
    required final int group,
    required final int completedReps,
    required final WorkoutProvider workoutProvider,
    required final AppProvider appProvider,
  }) {
    // add set
    final set_ = WorkoutSet(
      group: group,
      targetReps: getTargetReps(),
      completedReps: completedReps,
    );
    workoutProvider.addSet(set_);

    // navigate
    if (isFinished(workoutProvider)) {
      // can't await here as `finishSet` is meant to be called synchronously
      // on button press
      unawaited(workoutProvider.finish(appProvider));
      navigateToSuccess(workoutProvider);
    } else {
      workoutProvider.rest(restDurationSeconds);
      navigateToRest(workoutProvider);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final appProvider = context.read<AppProvider>();
    final workoutProvider = context.watch<WorkoutProvider>();
    final targetReps = getTargetReps();
    final inputs = getInputs(workoutProvider, appProvider);
    const instructionTextStyle = AppTypography.headlineLarge;
    const instructionIconStyle = TextStyle(fontSize: 110, color: Colors.white);
    const instructionsNoTargetReps = Column(
      children: [
        SizedBox(height: AppSpacing.xxxl),
        Text(
          "Do as many reps as possible!",
          style: instructionTextStyle,
          textAlign: TextAlign.center,
        ),
        Text("🔥", style: instructionIconStyle, textAlign: TextAlign.center),
        SizedBox(height: AppSpacing.md),
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
          SizedBox(
            width: double.infinity,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.paddingSmall),
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
          ),
          SetCards(
            values: getSetCardValues(workoutProvider.workout),
            numExpectedCards: workoutProvider.workout.maxGroups,
          ),
          const HomeButton(text: "Exit", icon: Icons.exit_to_app),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty("restDurationSeconds", restDurationSeconds));
  }
}
