import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:pull_up_club/common/services/sound_service.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:pull_up_club/common/utils/utils.dart";
import "package:pull_up_club/common/widgets/core/screen_scaffold.dart";
import "package:pull_up_club/common/widgets/shared/home_button.dart";
import "package:pull_up_club/common/widgets/shared/set_cards.dart";
import "package:pull_up_club/common/widgets/shared/total_card.dart";
import "package:pull_up_club/domain/models.dart";
import "package:pull_up_club/features/workout/widgets/animated_trophy.dart";

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({required this.workout, super.key});
  final Workout workout;

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Workout>("workout", workout));
  }
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
      curve: const Interval(0.25, 1, curve: Curves.easeOut),
    );
    _headlineOffset = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.25, 1, curve: Curves.easeOut),
          ),
        );

    // Play triumphant sound when success screen loads
    unawaited(SoundService.instance.playTriumphant());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final durationText = displayDuration(widget.workout.durationMillis() ?? 0);
    final totalReps = widget.workout.totalReps();

    return ScreenScaffold(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                AnimatedTrophy(size: Screen.isTiny(context) ? 100 : 110),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _headlineOpacity,
                  child: SlideTransition(
                    position: _headlineOffset,
                    child: const Text(
                      "Workout Completed!",
                      style: AppTypography.displayMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            Card(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.only(
                  top: AppSpacing.paddingSm,
                  left: AppSpacing.paddingSm,
                  right: AppSpacing.paddingSm,
                  bottom: Screen.isTiny(context)
                      ? AppSpacing.paddingSm
                      : AppSpacing.paddingMd,
                ),
                child: Column(
                  children: [
                    Text(
                      widget.workout.workoutType.name,
                      style: AppTypography.headlineLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
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
                        const SizedBox(width: AppSpacing.md),
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
            SetCards(values: getSetCardValues(widget.workout)),
            SizedBox(
              width: Screen.width(context) * 0.5,
              child: const HomeButton(text: "Home", gradient: AppGradients.primary),
            ),
          ],
        ),
      ),
    );
  }
}
