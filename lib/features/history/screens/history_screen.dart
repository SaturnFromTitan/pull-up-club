import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/providers/app_provider.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:pull_up_club/common/utils/utils.dart";
import "package:pull_up_club/common/widgets/total_card.dart";
import "package:pull_up_club/features/workout/models.dart";
import "package:pull_up_club/features/workout/widgets/set_cards.dart";

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(final BuildContext context) {
    final appProvider = context.read<AppProvider>();
    final workouts = appProvider.completedWorkouts.reversed.toList();
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
                  WorkoutHistory(workout: workout),
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

class WorkoutHistory extends StatelessWidget {
  const WorkoutHistory({required this.workout, super.key});
  final Workout workout;

  @override
  Widget build(final BuildContext context) => SizedBox(
    width: double.infinity,
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.glassBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
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

          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: SetCards(values: getSetCardValues(workout), withContainer: false),
          ),
        ],
      ),
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Workout>("workout", workout));
  }
}
