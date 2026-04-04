import "package:flutter/material.dart";
import "package:lucide_icons_flutter/lucide_icons.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/widgets/core/gradient_button.dart";
import "package:pull_up_club/features/workout/providers/workout_provider.dart";
import "package:pull_up_club/features/workout/screens/workouts/_base_workout_screen.dart";
import "package:pull_up_club/features/workout/widgets/reps_form.dart";

class LaddersScreen extends BaseWorkoutScreen {
  const LaddersScreen({super.key});

  @override
  State<LaddersScreen> createState() => _LaddersState();
}

class _LaddersState extends BaseWorkoutState<LaddersScreen> {
  int _targetReps = 1;
  int _completedGroups = 0;
  bool _showCustomRepsForm = false;

  @override
  int get restDurationMillis => 30 * 1_000;

  @override
  int getNumCompletedGroups() => _completedGroups;

  @override
  int getTargetReps() => _targetReps;

  @override
  void undoLastSet() {
    final workoutProvider = context.read<WorkoutProvider>();
    final removedSet = workoutProvider.undoLastSet();
    if (removedSet == null) {
      return;
    }
    setState(() {
      _targetReps = removedSet.targetReps!;
      if (removedSet.group == _completedGroups) {
        _completedGroups--;
      }
    });
  }

  @override
  Widget getInputs() {
    final buttons = [
      GradientButton(
        onPressed: () {
          finishSet(group: _completedGroups + 1, completedReps: getTargetReps());
          _targetReps++;
        },
        height: AppSpacing.buttonHeightLg,
        text: "Done, continue this ladder",
        icon: LucideIcons.trendingUp,
        gradient: AppGradients.accentGreen,
      ),
      GradientButton(
        onPressed: () {
          // have to increment _completedGroups before calling finishSet
          // so that isFinished() is evaluated correctly
          _completedGroups++;
          finishSet(group: _completedGroups, completedReps: getTargetReps());
          _targetReps = 1;
        },
        height: AppSpacing.buttonHeightLg,
        text: isLastGroup() ? "Finish Workout" : "Done, start new ladder",
        icon: isLastGroup() ? LucideIcons.check : LucideIcons.rotateCcw,
        gradient: AppGradients.accentPurple,
      ),
      GradientButton(
        onPressed: () {
          setState(() {
            _showCustomRepsForm = !_showCustomRepsForm;
          });
        },
        height: AppSpacing.buttonHeightLg,
        text: "Custom",
        icon: Icons.question_mark,
        gradient: AppGradients.light,
      ),
    ];
    final customRepsForm = RepsForm(
      onValidSubmit: (final reps) {
        // have to increment _completedGroups before calling finishSet
        // so that isFinished() is evaluated correctly
        _completedGroups++;
        finishSet(group: _completedGroups, completedReps: reps);
        _targetReps = 1;
        _showCustomRepsForm = false;
      },
      onCancel: () {
        setState(() => _showCustomRepsForm = !_showCustomRepsForm);
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
}
