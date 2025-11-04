import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:pull_up_club/common/providers/app_provider.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/widgets/gradient_button.dart";
import "package:pull_up_club/features/workout/providers/workout_provider.dart";
import "package:pull_up_club/features/workout/screens/workouts/_base_workout_screen.dart";
import "package:pull_up_club/features/workout/widgets/reps_form.dart";

class SubmaxVolumeScreen extends BaseWorkoutScreen {
  const SubmaxVolumeScreen({required this.targetReps, super.key});
  final int targetReps;

  @override
  State<SubmaxVolumeScreen> createState() => _SubmaxVolumeScreenState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty("targetReps", targetReps));
  }
}

class _SubmaxVolumeScreenState extends BaseWorkoutState<SubmaxVolumeScreen> {
  bool _showCustomRepsForm = false;

  @override
  int get restDurationSeconds => 60;

  @override
  int getTargetReps() => widget.targetReps;

  @override
  Widget getInputs(
    final WorkoutProvider workoutProvider,
    final AppProvider appProvider,
  ) {
    final buttons = _getButtons(workoutProvider, appProvider);

    final customRepsForm = RepsForm(
      onValidSubmit: (final reps) {
        _showCustomRepsForm = false;
        finishSet(
          group: workoutProvider.workout.sets.length + 1,
          completedReps: reps,
          workoutProvider: workoutProvider,
          appProvider: appProvider,
        );
      },
      onCancel: () {
        setState(() {
          _showCustomRepsForm = !_showCustomRepsForm;
        });
      },
    );

    return _showCustomRepsForm
        ? customRepsForm
        : Column(
            children: List<Widget>.generate(
              buttons.length * 2 - 1,
              (final i) =>
                  i.isEven ? buttons[i ~/ 2] : const SizedBox(height: AppSpacing.sm),
            ),
          );
  }

  List<Widget> _getButtons(
    final WorkoutProvider workoutProvider,
    final AppProvider appProvider,
  ) {
    final targetReps = getTargetReps();
    final buttons = [
      GradientButton(
        onPressed: () {
          finishSet(
            group: workoutProvider.workout.sets.length + 1,
            completedReps: targetReps,
            workoutProvider: workoutProvider,
            appProvider: appProvider,
          );
        },
        text: "Done",
        icon: Icons.check,
        gradient: AppGradients.secondary,
      ),
      GradientButton(
        onPressed: () {
          finishSet(
            group: workoutProvider.workout.sets.length + 1,
            completedReps: targetReps - 1,
            workoutProvider: workoutProvider,
            appProvider: appProvider,
          );
        },
        text: "I did ${targetReps - 1}",
        icon: Icons.thumb_up_alt_outlined,
        gradient: AppGradients.accentGreen,
      ),
    ];
    if (targetReps >= 2) {
      buttons.add(
        GradientButton(
          onPressed: () {
            finishSet(
              group: workoutProvider.workout.sets.length + 1,
              completedReps: targetReps - 2,
              workoutProvider: workoutProvider,
              appProvider: appProvider,
            );
          },
          text: "I did ${targetReps - 2}",
          icon: Icons.ssid_chart_outlined,
          gradient: AppGradients.accentPurple,
        ),
      );
    }
    if (targetReps >= 3) {
      buttons.add(
        GradientButton(
          onPressed: () {
            setState(() {
              _showCustomRepsForm = !_showCustomRepsForm;
            });
          },
          text: "I did fewer",
          icon: Icons.trending_down,
          gradient: AppGradients.light,
        ),
      );
    }
    return buttons;
  }
}
