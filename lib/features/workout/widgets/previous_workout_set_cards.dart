import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/providers/workout_history_provider.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:pull_up_club/common/utils/utils.dart";
import "package:pull_up_club/common/widgets/shared/set_cards.dart";
import "package:pull_up_club/domain/models.dart";

/// Wraps [SetCards] with a press-and-hold gesture that temporarily replaces
/// the displayed values with those from the most recent workout of the same
/// type, dimmed to indicate they are historical.
class PreviousWorkoutSetCards extends StatefulWidget {
  const PreviousWorkoutSetCards({
    required this.values,
    required this.numExpectedCards,
    required this.workoutType,
    this.highlightedIndex,
    super.key,
  });

  final List<String> values;
  final int numExpectedCards;
  final WorkoutType workoutType;
  final int? highlightedIndex;

  @override
  State<PreviousWorkoutSetCards> createState() => _PreviousWorkoutSetCardsState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>("values", values))
      ..add(IntProperty("numExpectedCards", numExpectedCards))
      ..add(EnumProperty<WorkoutType>("workoutType", workoutType))
      ..add(IntProperty("highlightedIndex", highlightedIndex));
  }
}

class _PreviousWorkoutSetCardsState extends State<PreviousWorkoutSetCards> {
  bool _showingPrevious = false;

  @override
  Widget build(final BuildContext context) {
    final historyProvider = context.watch<WorkoutHistoryProvider>();
    final previousWorkout = historyProvider.getPreviousWorkoutOfType(
      widget.workoutType,
    );
    final previousValues = previousWorkout != null
        ? getSetCardValues(previousWorkout)
        : null;
    final displayValues = _showingPrevious && previousValues != null
        ? previousValues
        : widget.values;

    String? previousLabel;
    if (previousWorkout != null) {
      final daysAgo = DateTime.now().difference(previousWorkout.start).inDays;
      final daysText = switch (daysAgo) {
        0 => "today",
        1 => "yesterday",
        _ => "$daysAgo days ago",
      };
      previousLabel = "Previous workout ($daysText)";
    }

    return Listener(
      onPointerDown: previousValues != null
          ? (_) => setState(() => _showingPrevious = true)
          : null,
      onPointerUp: (_) => setState(() => _showingPrevious = false),
      onPointerCancel: (_) => setState(() => _showingPrevious = false),
      child: Column(
        children: [
          AnimatedOpacity(
            opacity: _showingPrevious ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 150),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(previousLabel ?? "", style: AppTypography.bodySmall),
            ),
          ),
          AnimatedOpacity(
            opacity: _showingPrevious ? 0.6 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: SetCards(
              values: displayValues,
              numExpectedCards: widget.numExpectedCards,
              highlightedIndex: _showingPrevious ? null : widget.highlightedIndex,
            ),
          ),
        ],
      ),
    );
  }
}
