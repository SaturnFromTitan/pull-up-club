import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_theme.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:pull_up_club/common/widgets/core/gradient_surface.dart";

class GradientButton extends StatelessWidget {
  const GradientButton({
    required this.text,
    required this.icon,
    required this.gradient,
    super.key,
    this.onPressed,
  });
  final String text;
  final VoidCallback? onPressed;
  final IconData icon;
  final LinearGradient gradient;

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
          border: Border.all(color: AppColors.onLightSecondary, width: 0.2),
          boxShadow: defaultBoxShadows,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon),
              const SizedBox(width: AppSpacing.md),
              Text(
                text,
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w500,
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
      ..add(DiagnosticsProperty<LinearGradient>("gradient", gradient));
  }
}
