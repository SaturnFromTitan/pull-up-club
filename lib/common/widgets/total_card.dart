import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";

class TotalCard extends StatelessWidget {
  const TotalCard({
    required this.text,
    required this.value,
    required this.emoji,
    super.key,
    this.color,
    this.gradient,
  }) : assert((color == null) != (gradient == null));
  final String text;
  final String value;
  final String emoji;
  final Color? color;
  final LinearGradient? gradient;

  @override
  Widget build(final BuildContext context) => Container(
    decoration: BoxDecoration(
      color: color,
      gradient: gradient,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
    ),
    padding: const EdgeInsets.all(AppSpacing.paddingSmall),
    child: Column(
      children: [
        Text(emoji, style: AppTypography.headlineLarge.copyWith(fontSize: 30)),
        Text(value, style: AppTypography.headlineLarge.copyWith(fontSize: 26)),
        Text(
          text,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty("text", text));
    properties.add(StringProperty("value", value));
    properties.add(StringProperty("emoji", emoji));
    properties.add(ColorProperty("color", color));
    properties.add(DiagnosticsProperty<LinearGradient?>("gradient", gradient));
  }
}
