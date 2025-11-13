import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:pull_up_club/common/themes/app_box_shadows.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:pull_up_club/common/widgets/core/gradient_surface.dart";

class GradientButton extends StatelessWidget {
  const GradientButton({
    required this.text,
    required this.icon,
    required this.gradient,
    super.key,
    this.onPressed,
    this.border,
    this.textColor,
  });
  final String text;
  final VoidCallback? onPressed;
  final IconData icon;
  final LinearGradient gradient;
  final Border? border;
  final Color? textColor;

  @override
  Widget build(final BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Opacity(
        opacity: onPressed == null ? 0.5 : 1.0,
        child: GradientSurface(
          gradient: gradient,
          height: AppSpacing.buttonHeight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: border,
          boxShadow: AppBoxShadows.dark,
          textColor: textColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon),
              const SizedBox(width: AppSpacing.md),
              Text(
                text,
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty("text", text))
      ..add(ObjectFlagProperty<VoidCallback?>.has("onPressed", onPressed))
      ..add(DiagnosticsProperty<IconData>("icon", icon))
      ..add(DiagnosticsProperty<LinearGradient>("gradient", gradient))
      ..add(DiagnosticsProperty<Border?>("border", border))
      ..add(DiagnosticsProperty<Color?>("textColor", textColor));
  }
}
