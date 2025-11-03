import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/constants/app_constants.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_theme.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:pull_up_club/common/widgets/gradient_button.dart";
import "package:pull_up_club/common/widgets/gradient_surface.dart";
import "package:pull_up_club/features/workout/models.dart";
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

  Future<int?> askForTargetReps() async {
    final res = await showDialog<int>(
      context: context,
      builder: (final context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.paddingBig),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "🎯\nEnter Your Target Reps",
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
        if (!mounted || targetReps == null) return;
        workoutScreen = SubmaxVolumeScreen(targetReps: targetReps);
      case WorkoutType.ladders:
        workoutScreen = const LaddersScreen();
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => WorkoutProvider(workoutType: _selected),
          child: workoutScreen,
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header section
      SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            // App title
            const Text(
              AppConstants.appTitle,
              style: AppTypography.displayLarge,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.sm),

            // Subtitle - centered
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
              onTap: () => setState(() => _selected = WorkoutType.maxSets),
            ),

            const SizedBox(height: _cardGap),

            _WorkoutCard(
              title: "Submax Volume",
              description: "10 sets at 50% max reps with\n1 minute rest",
              icon: const Icon(Icons.center_focus_strong, size: _iconSize),
              gradient: AppGradients.accentPurple,
              isSelected: _selected == WorkoutType.submaxVolume,
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

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({
    // super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.isSelected = false,
  });
  final String title;
  final String description;
  final Widget icon;
  final bool isSelected;
  final LinearGradient gradient;
  final VoidCallback onTap;

  static const double _cardHeight = 120;
  static const double _iconSize = 55;

  @override
  Widget build(final BuildContext context) => GestureDetector(
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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.paddingSmall),
        child: Row(
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
      ),
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty("title", title));
    properties.add(StringProperty("description", description));
    properties.add(DiagnosticsProperty<bool>("isSelected", isSelected));
    properties.add(DiagnosticsProperty<LinearGradient>("gradient", gradient));
    properties.add(ObjectFlagProperty<VoidCallback>.has("onTap", onTap));
  }
}
