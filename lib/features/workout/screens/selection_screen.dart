import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/constants/app_constants.dart";
import "package:pull_up_club/common/providers/workout_history_provider.dart";
import "package:pull_up_club/common/themes/app_box_shadows.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:pull_up_club/common/utils/utils.dart";
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
  static final Logger _logger = Logger("WorkoutSelectionScreen");
  WorkoutType _selected = WorkoutType.maxSets;
  static const double _cardGap = AppSpacing.md;
  static const double _iconSize = 28;

  Future<int?> askForTargetReps() async {
    final workoutHistoryProvider = context.read<WorkoutHistoryProvider>();
    final defaultData = workoutHistoryProvider.calculateDefaultTargetReps();

    final res = await showDialog<int>(
      context: context,
      builder: (final context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.paddingLg),
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
                submitGradient: AppGradients.primary,
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
    _logger.info("Starting workout: type=${_selected.name}");
    StatefulWidget workoutScreen;
    switch (_selected) {
      case WorkoutType.maxSets:
        workoutScreen = const MaxSetsScreen();
      case WorkoutType.submaxVolume:
        final targetReps = await askForTargetReps();
        if (!mounted || targetReps == null) {
          _logger.fine(
            "Workout start cancelled: targetReps dialog cancelled or widget unmounted",
          );
          return;
        }
        workoutScreen = SubmaxVolumeScreen(targetReps: targetReps);
      case WorkoutType.ladders:
        workoutScreen = const LaddersScreen();
    }
    unawaited(
      Navigator.of(context).pushReplacement(
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

    return LayoutBuilder(
      builder: (final context, final constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header section
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    children: [
                      const Text(
                        AppConstants.appTitle,
                        style: AppTypography.displayAppTitle,
                      ),

                      const SizedBox(height: AppSpacing.xs),

                      Text(
                        "Double your max pull-ups!",
                        style: AppTypography.displaySmall.copyWith(
                          color: AppColors.onColorSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Workout cards section
                Column(
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
                      description:
                          "5 ladders (1, 2, 3, ... reps) with\n30 seconds rest",
                      icon: const Icon(Icons.trending_up, size: _iconSize),
                      gradient: AppGradients.accentGreen,
                      isSelected: _selected == WorkoutType.ladders,
                      isNext: nextWorkoutType == WorkoutType.ladders,
                      onTap: () => setState(() => _selected = WorkoutType.ladders),
                    ),
                  ],
                ),

                // Start workout button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: SizedBox(
                    width: 0.8 * Screen.width(context),
                    child: GradientButton(
                      text: "Start Workout",
                      icon: Icons.play_arrow,
                      onPressed: _handleSubmit,
                      gradient: AppGradients.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  @override
  Widget build(final BuildContext context) {
    final iconSize = Screen.isSmall(context) ? 50.0 : 55.0;
    final paddingFactor = Screen.isSmall(context) ? 0.7 : 1.0;
    final paddingVert = paddingFactor * AppSpacing.paddingSm;
    const descriptionTextStyle = AppTypography.bodyLarge;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.gradientSurface[1],
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected
                ? AppColors.glassBorderActive
                : AppColors.glassBorderInactive,
          ),
          boxShadow: isSelected ? AppBoxShadows.light : null,
        ),
        padding: EdgeInsets.symmetric(
          vertical: paddingVert,
          horizontal: AppSpacing.paddingSm,
        ),
        child: Stack(
          children: [
            Row(
              children: [
                GradientSurface(
                  width: iconSize,
                  height: iconSize,
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  boxShadow: AppBoxShadows.dark,
                  child: Center(child: icon),
                ),

                const SizedBox(width: AppSpacing.md),

                // Text content
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.headlineMedium),
                      const SizedBox(height: AppSpacing.xs),
                      SizedBox(
                        // size every card as if there are 2 description lines
                        height: 2 * lineHeight(descriptionTextStyle),
                        child: Text(
                          description,
                          style: descriptionTextStyle.copyWith(
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
            if (isNext) const Positioned(top: 0, right: 0, child: _NextTag()),
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

class _NextTag extends StatelessWidget {
  const _NextTag();

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.yellow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Text(
        "Next",
        style: AppTypography.bodySmall.copyWith(color: AppColors.onLight),
      ),
    );
  }
}
