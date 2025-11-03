import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/widgets/screen_scaffold.dart";
import "package:pull_up_club/common/shell_screen.dart";
import "package:pull_up_club/common/widgets/home_button.dart";
import "package:pull_up_club/features/workout/widgets/set_cards.dart";
import "package:pull_up_club/features/workout/providers/workout_provider.dart";
import "package:pull_up_club/common/utils/utils.dart";
import "package:flutter/cupertino.dart";

import "package:pull_up_club/common/providers/app_provider.dart";
import "package:pull_up_club/features/workout/models.dart";
import "../rest_screen.dart";
import "../success_screen.dart";

abstract class BaseWorkoutScreen extends StatefulWidget {
  const BaseWorkoutScreen({super.key});

  @override
  State<BaseWorkoutScreen> createState();
}

abstract class BaseWorkoutState<T extends BaseWorkoutScreen> extends State<T> {
  int get restDurationSeconds;

  int? getTargetReps();
  Widget getInputs(WorkoutProvider workoutProvider, AppProvider appProvider);

  int getCompletedGroups(WorkoutProvider workoutProvider) {
    return workoutProvider.workout.sets.length;
  }

  bool isLastGroup(WorkoutProvider workoutProvider) {
    return getCompletedGroups(workoutProvider) ==
        workoutProvider.workout.maxGroups - 1;
  }

  bool isFinished(WorkoutProvider workoutProvider) {
    return getCompletedGroups(workoutProvider) ==
        workoutProvider.workout.maxGroups;
  }

  void navigateToSuccess(WorkoutProvider workoutProvider) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SuccessScreen(workout: workoutProvider.workout),
      ),
    );
  }

  void navigateToRest(WorkoutProvider workoutProvider) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: workoutProvider,
          child: RestScreen(),
        ),
      ),
    );
  }

  void navigateToHome() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => Shell()));
  }

  void finishSet({
    required int group,
    required int completedReps,
    required WorkoutProvider workoutProvider,
    required AppProvider appProvider,
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
      workoutProvider.finish(appProvider);
      navigateToSuccess(workoutProvider);
    } else {
      workoutProvider.rest(restDurationSeconds);
      navigateToRest(workoutProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    var appProvider = context.read<AppProvider>();
    var workoutProvider = context.watch<WorkoutProvider>();
    int? targetReps = getTargetReps();
    Widget inputs = getInputs(workoutProvider, appProvider);
    final instructionTextStyle = AppTypography.headlineLarge;
    final instructionTarget = targetReps == null
        ? Icon(CupertinoIcons.infinite, size: 110, color: Colors.white)
        : Text(
            targetReps.toString(),
            style: TextStyle(fontSize: 110, color: Colors.white),
          );

    return ScreenScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: double.infinity,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.paddingSmall),
                child: Column(
                  children: [
                    if (targetReps == null) SizedBox(height: AppSpacing.xxxl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("do", style: instructionTextStyle),
                        const SizedBox(width: AppSpacing.sm),
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              AppGradients.repCount.createShader(bounds),
                          child: instructionTarget,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          targetReps == 1 ? "rep" : "reps",
                          style: instructionTextStyle,
                        ),
                      ],
                    ),
                    if (targetReps == null) SizedBox(height: AppSpacing.xl),
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
          HomeButton(text: "Exit", icon: Icons.exit_to_app),
        ],
      ),
    );
  }
}
