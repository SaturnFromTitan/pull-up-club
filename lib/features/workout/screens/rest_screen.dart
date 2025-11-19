import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:pull_up_club/common/utils/utils.dart";
import "package:pull_up_club/common/widgets/core/gradient_button.dart";
import "package:pull_up_club/common/widgets/core/screen_scaffold.dart";
import "package:pull_up_club/common/widgets/shared/home_button.dart";
import "package:pull_up_club/common/widgets/shared/set_cards.dart";
import "package:pull_up_club/features/workout/providers/workout_provider.dart";

class RestScreen extends StatefulWidget {
  const RestScreen({required this.currentGroupIndex, super.key});
  final int currentGroupIndex;

  @override
  State<RestScreen> createState() => _RestScreenState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty("currentGroupIndex", currentGroupIndex));
  }
}

class _RestScreenState extends State<RestScreen> {
  bool _didPop = false;
  late final WorkoutProvider _workoutProvider;

  @override
  void initState() {
    super.initState();
    _workoutProvider = context.read<WorkoutProvider>();
    _workoutProvider.addListener(_onWorkoutChanged);

    // If we somehow arrive when not resting, pop once after first frame
    if (!_workoutProvider.isResting()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _safePop());
    }
  }

  void _onWorkoutChanged() {
    if (!_workoutProvider.isResting()) {
      _safePop();
    }
  }

  void _safePop() {
    if (_didPop) {
      return;
    }
    _didPop = true;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _workoutProvider.removeListener(_onWorkoutChanged);
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final workoutProvider = context.watch<WorkoutProvider>();

    return ScreenScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Text("😴", style: AppTypography.displayLarge.copyWith(fontSize: 64)),
          const _RestTimerSpinner(size: 200),
          SizedBox(
            width: Screen.width(context) * 0.5,
            child: GradientButton(
              onPressed: workoutProvider.resume,
              text: "Skip Rest",
              icon: Icons.skip_next,
              gradient: AppGradients.skipRest,
              border: Border.all(color: AppColors.skipRestBorder),
              textColor: AppColors.skipRestText,
            ),
          ),
          SetCards(
            values: getSetCardValues(workoutProvider.workout),
            numExpectedCards: workoutProvider.workout.maxGroups,
            highlightedIndex: widget.currentGroupIndex,
          ),
          SizedBox(
            width: Screen.width(context) * 0.5,
            child: const HomeButton(text: "Exit", icon: Icons.exit_to_app),
          ),
        ],
      ),
    );
  }
}

class _RestTimerSpinner extends StatefulWidget {
  const _RestTimerSpinner({required this.size});
  final double size;
  @override
  State<_RestTimerSpinner> createState() => _RestTimerSpinnerState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty("size", size));
  }
}

class _RestTimerSpinnerState extends State<_RestTimerSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2_000),
    );
    unawaited(_controller.repeat());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final workoutProvider = context.watch<WorkoutProvider>();

    final remaining = workoutProvider.restRemainingMillis;

    const double ringThickness = 6;
    const arcPortion = 0.25;

    return Column(
      children: [
        SizedBox(
          height: widget.size,
          width: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              RotationTransition(
                turns: _controller,
                child: SizedBox(
                  height: widget.size,
                  width: widget.size,
                  child: const CircularProgressIndicator(
                    value: arcPortion,
                    strokeWidth: ringThickness,
                    backgroundColor: AppColors.glassBorderInactive,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.glassBorderActive,
                    ),
                  ),
                ),
              ),
              // center content
              Text(
                displayDuration(remaining),
                style: AppTypography.displayLarge.copyWith(fontSize: 50),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
