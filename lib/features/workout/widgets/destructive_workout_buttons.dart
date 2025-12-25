import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";
import "package:lucide_icons_flutter/lucide_icons.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/widgets/core/gradient_button.dart";
import "package:pull_up_club/common/widgets/shared/home_button.dart";
import "package:pull_up_club/domain/models.dart";

class DestructiveWorkoutButtons extends StatelessWidget {
  const DestructiveWorkoutButtons({
    required this.workout,
    required this.onUndoLastSet,
    super.key,
  });
  final Workout workout;
  final VoidCallback onUndoLastSet;

  @override
  Widget build(final BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: Screen.width(context) * 0.4,
          child: GradientButton(
            onPressed: workout.sets.isEmpty ? null : onUndoLastSet,
            text: "Undo Set",
            icon: LucideIcons.undo,
            gradient: AppGradients.light,
          ),
        ),
        SizedBox(
          width: Screen.width(context) * 0.4,
          child: const HomeButton(text: "Exit", icon: LucideIcons.x),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Workout>("workout", workout))
      ..add(ObjectFlagProperty<VoidCallback>.has("onUndoLastSet", onUndoLastSet));
  }
}
