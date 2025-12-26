import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:lucide_icons_flutter/lucide_icons.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/providers/workout_history_provider.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:pull_up_club/common/utils/utils.dart";
import "package:pull_up_club/common/widgets/core/dismissible_dialog.dart";
import "package:pull_up_club/common/widgets/core/gradient_button.dart";
import "package:pull_up_club/common/widgets/shared/set_cards.dart";
import "package:pull_up_club/common/widgets/shared/total_card.dart";
import "package:pull_up_club/domain/models.dart";

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static final Logger _logger = Logger("HistoryScreen");

  @override
  Widget build(final BuildContext context) {
    final workoutHistoryProvider = context.watch<WorkoutHistoryProvider>();
    final workouts = workoutHistoryProvider.completedWorkouts.reversed.toList();
    final numWorkouts = workouts.length;
    final totalReps = workouts.fold(0, (final t, final w) => t + w.totalReps());

    return Column(
      children: [
        const Text(
          "Workout History",
          textAlign: TextAlign.center,
          style: AppTypography.displayMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: TotalCard(
                value: numWorkouts.toString(),
                text: "Total Workouts",
                emoji: "🏋",
                color: AppColors.glassBackground,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TotalCard(
                value: totalReps.toString(),
                text: "Total Reps",
                emoji: "💪",
                color: AppColors.glassBackground,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: workouts.isEmpty
              ? const Center(
                  child: Text(
                    "No workouts yet",
                    style: AppTypography.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView(
                  children: [
                    for (final workout in workouts) ...[
                      _DismissablePastWorkout(workout: workout),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _DismissablePastWorkout extends StatelessWidget {
  const _DismissablePastWorkout({required this.workout});

  final Workout workout;
  Future<void> _onDelete(final BuildContext context) async {
    final workoutHistoryProvider = context.read<WorkoutHistoryProvider>();
    HistoryScreen._logger.info("Deleting workout from history screen: $workout");

    try {
      await workoutHistoryProvider.deleteWorkout(workout);
      HistoryScreen._logger.info("Workout deleted successfully from history screen");
    } on Exception catch (e, stackTrace) {
      final message = "Error deleting workout: $e";
      HistoryScreen._logger.severe(message, e, stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<bool?> _confirmDismiss(final BuildContext context) => showDialog<bool>(
    context: context,
    builder: (final dialogContext) => DismissibleDialog(
      children: [
        const Text(
          "Delete Workout",
          style: AppTypography.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          "Are you sure?",
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        GradientButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          text: "Delete",
          icon: LucideIcons.trash,
          gradient: AppGradients.primary,
        ),
      ],
    ),
  );

  @override
  Widget build(final BuildContext context) {
    final key = workout.id != null
        ? ValueKey<int>(workout.id!)
        : ValueKey<String>(
            "${workout.start.millisecondsSinceEpoch}_${workout.workoutType.name}",
          );

    return Dismissible(
      key: key,
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: const Icon(LucideIcons.trash, color: Colors.white, size: 32),
      ),
      confirmDismiss: (final direction) => _confirmDismiss(context),
      onDismissed: (final direction) => _onDelete(context),
      child: _PastWorkout(workout: workout),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Workout>("workout", workout));
  }
}

class _PastWorkout extends StatelessWidget {
  const _PastWorkout({required this.workout});
  final Workout workout;

  @override
  Widget build(final BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.paddingSm),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(workout.workoutType.name, style: AppTypography.headlineMedium),
                  Text(
                    "📅 ${datetimeToString(workout.start.toLocal())}",
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("💪 ${workout.totalReps()} reps"),
                  Text("⏱️ ${displayDuration(workout.durationMillis() ?? 0)}"),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: SetCards(values: getSetCardValues(workout), withContainer: false),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Workout>("workout", workout));
  }
}
