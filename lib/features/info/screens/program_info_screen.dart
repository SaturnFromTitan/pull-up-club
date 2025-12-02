import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";

class ProgramInfoScreen extends StatelessWidget {
  const ProgramInfoScreen({super.key});

  @override
  Widget build(final BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "Program Info",
              textAlign: TextAlign.center,
              style: AppTypography.displayMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Title
          Text(
            "The plan for doubling your max pull-ups!",
            style: AppTypography.headlineLarge.copyWith(
              color: AppColors.onColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Description
          Text(
            "If you do this program consistently, you can expect a 50-100% increase of your max pull-ups within 6-12 weeks. It works best if you're currently in the 5-12 pull-up range. Perform 3 workouts on non-consecutive days of the week, e.g. Monday, Wednesday and Friday. Please use strict form for your own safety and improved muscle stimulus.",
            style: AppTypography.bodyLarge.copyWith(color: AppColors.onColorSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Workouts section
          Text(
            "Workouts:",
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.onColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const _ProgramInfoSection(
            title: "1. Max Sets",
            description:
                "Perform 3 sets of maximum reps with 5 minutes rest between sets. This builds raw strength and tests your current capacity.",
          ),
          const SizedBox(height: AppSpacing.md),
          const _ProgramInfoSection(
            title: "2. Sub-max Volume",
            description:
                "Complete 10 sets at 50% of your max reps with 1 minute rest. This builds endurance and volume capacity without excessive fatigue.",
          ),
          const SizedBox(height: AppSpacing.md),
          const _ProgramInfoSection(
            title: "3. Ladders",
            description:
                "Execute 5 ladders starting at 1 rep and increasing by 1 each rung, with 30 seconds rest between rungs. This builds progressive strength and work capacity.",
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _ProgramInfoSection extends StatelessWidget {
  const _ProgramInfoSection({required this.title, required this.description});
  final String title;
  final String description;

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.headlineSmall.copyWith(color: AppColors.onColor),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          description,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.onColorSecondary),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty("title", title))
      ..add(StringProperty("description", description));
  }
}
