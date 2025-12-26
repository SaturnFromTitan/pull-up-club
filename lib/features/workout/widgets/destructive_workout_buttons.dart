import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:lucide_icons_flutter/lucide_icons.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/providers/navigation_provider.dart";
import "package:pull_up_club/common/providers/workout_history_provider.dart";
import "package:pull_up_club/common/screens/shell_screen.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:pull_up_club/common/widgets/core/gradient_button.dart";
import "package:pull_up_club/domain/models.dart";

class DestructiveWorkoutButtons extends StatelessWidget {
  const DestructiveWorkoutButtons({
    required this.workout,
    required this.onUndoLastSet,
    super.key,
  });
  final Workout workout;
  final VoidCallback onUndoLastSet;

  @override
  Widget build(final BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: Screen.width(context) * 0.4,
          child: GradientButton(
            onPressed: workout.sets.isEmpty ? null : onUndoLastSet,
            text: "Undo Set",
            icon: LucideIcons.undo,
            gradient: AppGradients.light,
          ),
        ),
        SizedBox(
          width: Screen.width(context) * 0.4,
          child: GradientButton(
            onPressed: () => _handleExit(context),
            text: "Exit",
            icon: LucideIcons.doorClosed,
            gradient: AppGradients.light,
          ),
        ),
      ],
    );
  }

  Future<void> _handleExit(final BuildContext context) async {
    // If no sets have been added, exit immediately without dialog
    if (workout.sets.isEmpty) {
      context.read<NavigationProvider>().resetTab();
      await Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(Shell.route, (final route) => false);
      return;
    }

    // Let user decide if the workout gets saved or scrapped
    final shouldSave = await _showExitDialog(context);
    if (shouldSave == null || !context.mounted) {
      // User cancelled
      return;
    }

    // Save incomplete workout
    if (shouldSave) {
      workout.finish();
      await context.read<WorkoutHistoryProvider>().addWorkout(workout);
    }

    // Navigate home
    if (context.mounted) {
      context.read<NavigationProvider>().resetTab();
      await Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(Shell.route, (final route) => false);
    }
  }

  Future<bool?> _showExitDialog(final BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (final dialogContext) => Dialog(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.paddingLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Exit Workout",
                    style: AppTypography.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    "Do you want to save this incomplete workout?",
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GradientButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    text: "Save",
                    icon: LucideIcons.save,
                    gradient: AppGradients.secondary,
                  ),
                  const SizedBox(height: AppSpacing.buttonDistance),
                  GradientButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    text: "Scrap",
                    icon: LucideIcons.trash,
                    gradient: AppGradients.light,
                  ),
                ],
              ),
            ),
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: IconButton(
                icon: const Icon(
                  LucideIcons.x,
                  size: 30,
                  color: AppColors.onLightSecondary,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Workout>("workout", workout))
      ..add(ObjectFlagProperty<VoidCallback>.has("onUndoLastSet", onUndoLastSet));
  }
}
