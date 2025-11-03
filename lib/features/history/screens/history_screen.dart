import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:pull_up_club/common/widgets/total_card.dart";
import "package:pull_up_club/features/workout/widgets/set_cards.dart";
import "package:pull_up_club/common/providers/app_provider.dart";
import "package:pull_up_club/features/workout/models.dart";
import "package:pull_up_club/common/utils/utils.dart";

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.read<AppProvider>();
    final workouts = appProvider.completedWorkouts.reversed.toList();
    final numWorkouts = workouts.length;
    final totalReps = workouts.fold(0, (t, w) => t + w.totalReps());

    return Column(
      children: [
        Text(
          "Workout History",
          textAlign: TextAlign.center,
          style: AppTypography.displayMedium,
        ),
        SizedBox(height: AppSpacing.md),
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
            SizedBox(width: AppSpacing.sm),
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
        SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ListView(
            children: [
              ...[
                for (var workout in workouts) ...[
                  WorkoutHistory(workout: workout),
                  SizedBox(height: AppSpacing.sm),
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
  final Workout workout;

  const WorkoutHistory({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.glassBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        padding: EdgeInsets.all(AppSpacing.paddingSmall),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.workoutType.name,
                      style: AppTypography.headlineMedium,
                    ),
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
                    Text(
                      "⏱️ ${formatMinutesSeconds(workout.durationSeconds() ?? 0)}",
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: SetCards(
                values: getSetCardValues(workout),
                withContainer: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
