import "package:flutter/material.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";

class TotalCard extends StatelessWidget {
  final String text;
  final String value;
  final String emoji;
  final Color? color;
  final LinearGradient? gradient;
  const TotalCard({
    super.key,
    required this.text,
    required this.value,
    required this.emoji,
    this.color,
    this.gradient,
  }) : assert((color == null) != (gradient == null));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      padding: EdgeInsets.all(AppSpacing.paddingSmall),
      child: Column(
        children: [
          Text(
            emoji,
            style: AppTypography.headlineLarge.copyWith(fontSize: 30),
          ),
          Text(
            value,
            style: AppTypography.headlineLarge.copyWith(fontSize: 26),
          ),
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
  }
}
