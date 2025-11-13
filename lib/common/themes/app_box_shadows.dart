import "package:flutter/material.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";

class AppBoxShadows {
  static const List<BoxShadow> dark = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: AppSpacing.radiusSmall,
      offset: Offset(0, 4),
    ),
  ];
  static const List<BoxShadow> light = [
    BoxShadow(
      color: AppColors.glassBorderActive,
      offset: Offset(0, 4),
      blurRadius: 10,
      spreadRadius: -2,
    ),
  ];
}
