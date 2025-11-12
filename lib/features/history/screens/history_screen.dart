import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/providers/workout_history_provider.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:pull_up_club/common/utils/utils.dart";
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
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ListView(
            children: [
              ...[
                for (final workout in workouts) ...[
                  _DismissablePastWorkout(workout: workout),
                  const SizedBox(height: AppSpacing.sm),
                ],
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

    try {
      await workoutHistoryProvider.deleteWorkout(workout);
    } on Exception catch (e) {
      final message = "Error deleting workout: $e";
      HistoryScreen._logger.severe(message);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<bool?> _confirmDismiss(final BuildContext context) => showDialog<bool>(
    context: context,
    builder: (final context) => AlertDialog(
      title: const Text("Delete Workout"),
      content: const Text("Are you sure you want to delete this workout?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("Delete", style: TextStyle(color: Colors.red)),
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
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 32),
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
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.paddingSmall),
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
                    "📅 ${datetimeToString(workout.start)}",
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("💪 ${workout.totalReps()} reps"),
                  Text("⏱️ ${formatMinutesSeconds(workout.durationSeconds() ?? 0)}"),
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
