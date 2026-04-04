import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:lucide_icons_flutter/lucide_icons.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/widgets/core/gradient_button.dart";
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
  int get restDurationMillis => 60 * 1_000;

  @override
  int getTargetReps() => widget.targetReps;

  @override
  Widget getInputs() {
    final buttons = _getButtons();

    final customRepsForm = RepsForm(
      onValidSubmit: (final reps) {
        _showCustomRepsForm = false;
        final workoutProvider = context.read<WorkoutProvider>();
        finishSet(group: workoutProvider.workout.sets.length + 1, completedReps: reps);
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
              (final i) => i.isEven
                  ? buttons[i ~/ 2]
                  : const SizedBox(height: AppSpacing.buttonDistance),
            ),
          );
  }

  List<Widget> _getButtons() {
    final workoutProvider = context.read<WorkoutProvider>();
    final targetReps = getTargetReps();
    final buttons = [
      GradientButton(
        onPressed: () {
          finishSet(
            group: workoutProvider.workout.sets.length + 1,
            completedReps: targetReps,
          );
        },
        height: AppSpacing.buttonHeightLg,
        text: "I did $targetReps",
        icon: LucideIcons.check,
        gradient: AppGradients.secondary,
      ),
      GradientButton(
        onPressed: () {
          finishSet(
            group: workoutProvider.workout.sets.length + 1,
            completedReps: targetReps - 1,
          );
        },
        height: AppSpacing.buttonHeightLg,
        text: "I did ${targetReps - 1}",
        icon: LucideIcons.thumbsUp,
        gradient: AppGradients.accentGreen,
      ),
    ];
    if (!Screen.isTiny(context) && targetReps >= 2) {
      buttons.add(
        GradientButton(
          onPressed: () {
            finishSet(
              group: workoutProvider.workout.sets.length + 1,
              completedReps: targetReps - 2,
            );
          },
          height: AppSpacing.buttonHeightLg,
          text: "I did ${targetReps - 2}",
          icon: LucideIcons.batteryMedium,
          gradient: AppGradients.accentPurple,
        ),
      );
    }
    buttons.add(
      GradientButton(
        onPressed: () {
          setState(() {
            _showCustomRepsForm = !_showCustomRepsForm;
          });
        },
        height: AppSpacing.buttonHeightLg,
        text: "Custom",
        icon: Icons.question_mark_outlined,
        gradient: AppGradients.light,
      ),
    );
    return buttons;
  }
}
