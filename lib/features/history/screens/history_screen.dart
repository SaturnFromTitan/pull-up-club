import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:lucide_icons_flutter/lucide_icons.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/providers/workout_history_provider.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:pull_up_club/common/utils/utils.dart";
import "package:pull_up_club/common/widgets/core/dismissible_dialog.dart";
import "package:pull_up_club/common/widgets/core/gradient_button.dart";
import "package:pull_up_club/common/widgets/shared/set_cards.dart";
import "package:pull_up_club/domain/models.dart";

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  static final Logger _logger = Logger("HistoryScreen");

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  WorkoutType? _activeFilter;

  @override
  Widget build(final BuildContext context) {
    final workoutHistoryProvider = context.watch<WorkoutHistoryProvider>();
    final allWorkouts = workoutHistoryProvider.completedWorkouts;
    final workouts = allWorkouts.reversed
        .where((final w) => _activeFilter == null || w.workoutType == _activeFilter)
        .toList();

    return Column(
      children: [
        const Text(
          "Workout History",
          textAlign: TextAlign.center,
          style: AppTypography.displayMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final type in WorkoutType.values) ...[
              _FilterPill(
                label: type.name,
                isActive: _activeFilter == type,
                onTap: () => setState(() {
                  _activeFilter = _activeFilter == type ? null : type;
                }),
              ),
              if (type != WorkoutType.values.last) const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: workouts.isEmpty
              ? Center(
                  child: Text(
                    allWorkouts.isEmpty ? "No workouts yet" : "No matching workouts",
                    style: AppTypography.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView(
                  children: [
                    for (final workout in workouts) ...[
                      _DismissablePastWorkout(workout: workout),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.isActive, required this.onTap});

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.glassBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: isActive ? AppColors.glassBorderActive : AppColors.glassBorderInactive,
        ),
      ),
      child: Text(label, style: AppTypography.bodyMedium),
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty("label", label))
      ..add(DiagnosticsProperty<bool>("isActive", isActive))
      ..add(ObjectFlagProperty<VoidCallback>.has("onTap", onTap));
  }
}

class _DismissablePastWorkout extends StatelessWidget {
  const _DismissablePastWorkout({required this.workout});

  final Workout workout;
  Future<void> _onDelete(final BuildContext context) async {
    final workoutHistoryProvider = context.read<WorkoutHistoryProvider>();
    HistoryScreen._logger.info("Deleting workout from history screen: $workout");

    try {
      await workoutHistoryProvider.deleteWorkout(workout);
      HistoryScreen._logger.info("Workout deleted successfully from history screen");
    } on Exception catch (e, stackTrace) {
      final message = "Error deleting workout: $e";
      HistoryScreen._logger.severe(message, e, stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<bool?> _confirmDismiss(final BuildContext context) => showDialog<bool>(
    context: context,
    builder: (final dialogContext) => DismissibleDialog(
      children: [
        const Text(
          "Delete Workout",
          style: AppTypography.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          "Are you sure?",
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        GradientButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          text: "Delete",
          icon: LucideIcons.trash2,
          gradient: AppGradients.primary,
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
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: const Icon(LucideIcons.trash2, color: Colors.white, size: 32),
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
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.paddingSm),
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
                    "📅 ${datetimeToString(workout.start.toLocal())}",
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("💪 ${workout.totalReps()} reps"),
                  Text("⏱️ ${displayDuration(workout.durationMillis() ?? 0)}"),
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
