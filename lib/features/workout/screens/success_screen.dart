import "package:flutter/material.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:pull_up_club/common/widgets/screen_scaffold.dart";
import "package:pull_up_club/common/widgets/home_button.dart";
import "package:pull_up_club/common/widgets/total_card.dart";
import "package:pull_up_club/features/workout/widgets/animated_trophy.dart";
import "package:pull_up_club/features/workout/widgets/set_cards.dart";

import "package:pull_up_club/features/workout/models.dart";
import "package:pull_up_club/common/utils/utils.dart";

class SuccessScreen extends StatefulWidget {
  final Workout workout;

  const SuccessScreen({super.key, required this.workout});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _headlineOpacity;
  late final Animation<Offset> _headlineOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headlineOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    );
    _headlineOffset =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
          ),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final durationText = formatMinutesSeconds(
      widget.workout.durationSeconds() ?? 0,
    );
    final totalReps = widget.workout.totalReps();

    return ScreenScaffold(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const AnimatedTrophy(size: 112),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _headlineOpacity,
                  child: SlideTransition(
                    position: _headlineOffset,
                    child: Text(
                      "Workout Completed!",
                      style: AppTypography.displayLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.paddingBig,
                    horizontal: AppSpacing.paddingSmall,
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.workout.workoutType.name,
                        style: AppTypography.headlineLarge,
                      ),
                      SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: TotalCard(
                              text: "Total Reps",
                              value: totalReps.toString(),
                              emoji: "💪",
                              gradient: AppGradients.surfaceOnLight,
                            ),
                          ),
                          SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TotalCard(
                              text: "Duration",
                              value: durationText,
                              emoji: "⏱️",
                              gradient: AppGradients.surfaceOnLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SetCards(values: getSetCardValues(widget.workout)),
            HomeButton(text: "Home", gradient: AppGradients.primary),
          ],
        ),
      ),
    );
  }
}
