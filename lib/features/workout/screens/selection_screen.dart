import "dart:async";
import "dart:math";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/constants/app_constants.dart";
import "package:pull_up_club/common/providers/workout_history_provider.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_theme.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:pull_up_club/common/widgets/core/gradient_button.dart";
import "package:pull_up_club/common/widgets/core/gradient_surface.dart";
import "package:pull_up_club/domain/models.dart";
import "package:pull_up_club/features/workout/providers/workout_provider.dart";
import "package:pull_up_club/features/workout/screens/workouts/ladders_screen.dart";
import "package:pull_up_club/features/workout/screens/workouts/max_sets_screen.dart";
import "package:pull_up_club/features/workout/screens/workouts/submax_volume_screen.dart";
import "package:pull_up_club/features/workout/widgets/reps_form.dart";

class WorkoutSelectionScreen extends StatefulWidget {
  const WorkoutSelectionScreen({super.key});

  @override
  State<WorkoutSelectionScreen> createState() => _WorkoutSelectionScreenState();
}

class _WorkoutSelectionScreenState extends State<WorkoutSelectionScreen> {
  WorkoutType _selected = WorkoutType.maxSets;
  static const double _cardGap = AppSpacing.base * 3;
  static const double _iconSize = 27;

  ({int? defaultValue, String? infoText}) _calculateDefaultTargetReps(
    final List<Workout> completedWorkouts,
  ) {
    // Find the most recent submax volume workout
    final submaxWorkouts = completedWorkouts
        .where((final w) => w.workoutType == WorkoutType.submaxVolume)
        .toList();

    if (submaxWorkouts.isNotEmpty) {
      final mostRecentSubmax = submaxWorkouts.last;

      // Check if all sets completed the target reps
      final targetReps = mostRecentSubmax.sets.first.targetReps!;
      final allCompleted = mostRecentSubmax.sets.every(
        (final set) => set.completedReps >= targetReps,
      );

      if (allCompleted) {
        return (
          defaultValue: targetReps + 1,
          infoText: "Increased your target by 1 rep",
        );
      } else {
        return (defaultValue: targetReps, infoText: "Same target as the last time");
      }
    }

    // No submax volume workout, check for max sets workout
    final maxSetsWorkouts = completedWorkouts
        .where((final w) => w.workoutType == WorkoutType.maxSets)
        .toList();

    if (maxSetsWorkouts.isNotEmpty) {
      // Find the highest rep count
      final highestReps = maxSetsWorkouts.last.sets
          .map((final set) => set.completedReps)
          .reduce(max);
      final suggestedReps = (highestReps / 2).floor();

      if (suggestedReps > 0) {
        return (
          defaultValue: suggestedReps,
          infoText: "That's 50% of your latest max reps",
        );
      } else {
        return (defaultValue: null, infoText: "Please increase your Max Reps first");
      }
    }

    // No workouts found
    return (
      defaultValue: null,
      infoText: "Complete a Max Sets workout first to get a suggestion",
    );
  }

  Future<int?> askForTargetReps() async {
    final workoutHistoryProvider = context.read<WorkoutHistoryProvider>();
    final defaultData = _calculateDefaultTargetReps(
      workoutHistoryProvider.completedWorkouts,
    );

    final res = await showDialog<int>(
      context: context,
      builder: (final context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.paddingBig),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("🎯", style: TextStyle(fontSize: 40, color: Colors.white)),
              const Text(
                "Enter Your Target Reps",
                style: AppTypography.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              RepsForm(
                submitText: "Start",
                submitIcon: Icons.play_arrow,
                onValidSubmit: (final reps) => Navigator.pop(context, reps),
                minValue: 1,
                cancelText: "Cancel",
                cancelIcon: Icons.close,
                onCancel: () => Navigator.pop(context),
                initialValue: defaultData.defaultValue,
                infoText: defaultData.infoText,
              ),
            ],
          ),
        ),
      ),
    );
    return res;
  }

  Future<void> _handleSubmit() async {
    StatefulWidget workoutScreen;
    switch (_selected) {
      case WorkoutType.maxSets:
        workoutScreen = const MaxSetsScreen();
      case WorkoutType.submaxVolume:
        final targetReps = await askForTargetReps();
        if (!mounted || targetReps == null) {
          return;
        }
        workoutScreen = SubmaxVolumeScreen(targetReps: targetReps);
      case WorkoutType.ladders:
        workoutScreen = const LaddersScreen();
    }
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => WorkoutProvider(workoutType: _selected),
            child: workoutScreen,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final workoutHistoryProvider = context.watch<WorkoutHistoryProvider>();
    final nextWorkoutType = workoutHistoryProvider.getNextWorkoutType();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section
        SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              const Text(
                AppConstants.appTitle,
                style: AppTypography.displayLarge,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.sm),

              Text(
                "The plan for doubling your max pull ups!",
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.onColorSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: _cardGap),

        // Workout cards section
        Expanded(
          child: Column(
            children: [
              _WorkoutCard(
                title: "Max Sets",
                description: "3x max reps with 5 minutes rest",
                icon: const Icon(Icons.speed, size: _iconSize),
                gradient: AppGradients.primary,
                isSelected: _selected == WorkoutType.maxSets,
                isNext: nextWorkoutType == WorkoutType.maxSets,
                onTap: () => setState(() => _selected = WorkoutType.maxSets),
              ),

              const SizedBox(height: _cardGap),

              _WorkoutCard(
                title: "Submax Volume",
                description: "10 sets at 50% max reps with\n1 minute rest",
                icon: const Icon(Icons.center_focus_strong, size: _iconSize),
                gradient: AppGradients.accentPurple,
                isSelected: _selected == WorkoutType.submaxVolume,
                isNext: nextWorkoutType == WorkoutType.submaxVolume,
                onTap: () => setState(() => _selected = WorkoutType.submaxVolume),
              ),

              const SizedBox(height: _cardGap),

              _WorkoutCard(
                title: "Ladders",
                description: "5 ladders (1, 2, 3, ... reps) with\n30 seconds rest",
                icon: const Icon(Icons.trending_up, size: _iconSize),
                gradient: AppGradients.accentGreen,
                isSelected: _selected == WorkoutType.ladders,
                isNext: nextWorkoutType == WorkoutType.ladders,
                onTap: () => setState(() => _selected = WorkoutType.ladders),
              ),
            ],
          ),
        ),

        const SizedBox(height: _cardGap),

        // Start workout button
        GradientButton(
          text: "Start Workout",
          icon: Icons.play_arrow,
          onPressed: _handleSubmit,
          gradient: AppGradients.primary,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.isSelected = false,
    this.isNext = false,
  });
  final String title;
  final String description;
  final Widget icon;
  final bool isSelected;
  final bool isNext;
  final LinearGradient gradient;
  final VoidCallback onTap;

  static const double _cardHeight = 120;
  static const double _iconSize = 55;

  @override
  Widget build(final BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _cardHeight,
        decoration: BoxDecoration(
          color: AppColors.glassBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          border: Border.all(
            color: isSelected
                ? AppColors.glassBorderActive
                : AppColors.glassBorderInactive,
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.paddingSmall),
        child: Stack(
          children: [
            Row(
              children: [
                GradientSurface(
                  width: _iconSize,
                  height: _iconSize,
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  boxShadow: defaultBoxShadows,
                  child: Center(child: icon),
                ),

                const SizedBox(width: AppSpacing.md),

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: AppTypography.headlineMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          description,
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.onColorSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Next badge
            if (isNext) const Positioned(top: 0, right: 0, child: _NextBadge()),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty("title", title))
      ..add(StringProperty("description", description))
      ..add(DiagnosticsProperty<bool>("isSelected", isSelected))
      ..add(DiagnosticsProperty<bool>("isNext", isNext))
      ..add(DiagnosticsProperty<LinearGradient>("gradient", gradient))
      ..add(ObjectFlagProperty<VoidCallback>.has("onTap", onTap));
  }
}

class _NextBadge extends StatelessWidget {
  const _NextBadge();

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.yellow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Text(
        "Next",
        style: AppTypography.bodyMedium.copyWith(color: AppColors.onLight),
      ),
    );
  }
}
