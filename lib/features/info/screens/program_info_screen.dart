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
      padding: const EdgeInsets.only(bottom: AppSpacing.paddingMd),
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
          // Description
          Text(
            "This proven program is designed to increase your max pull-ups by around 50-100% in 8-12 weeks. It works best if your current max is between 5 and 12 reps.",
            style: AppTypography.bodyLarge.copyWith(color: AppColors.onColorSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "This is a three-days-per-week program done on non-consecutive days (e.g. Monday, Wednesday, Friday).",
            style: AppTypography.bodyLarge.copyWith(color: AppColors.onColorSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Workouts section
          Center(
            child: Text(
              "Workouts",
              style: AppTypography.displaySmall.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const _ProgramInfoSection(
            title: "1. Max Sets",
            descriptions: [
              "Perform 3 max effort sets to technical failure.",
              "Rest at least 5 minutes between each set.",
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _ProgramInfoSection(
            title: "2. Submax Volume",
            descriptions: [
              "Perform 10 sets of 50% of your max reps from day 1.",
              "Rest exactly 1 minute between each set.",
              "When you complete all 10 sets at the target reps, the target will increase by 1 for the next submax workout.",
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _ProgramInfoSection(
            title: "3. Ladders",
            descriptions: [
              "Perform 5 ladders.",
              "In each ladder, every set (or rung) increases the number of reps by 1: start with 1 rep, then 2, then 3, and so on.",
              "When you're not confident you can complete the next rung with good form, stop that ladder and start a new one (reset back to 1 rep).",
              "Rest exactly 30 seconds between each rung.",
              "Avoid failure!",
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgramInfoSection extends StatelessWidget {
  const _ProgramInfoSection({required this.title, required this.descriptions});
  final String title;
  final List<String> descriptions;

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.headlineMedium.copyWith(color: AppColors.onColor),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final description in descriptions)
          Text(
            "\u2022 $description",
            style: AppTypography.bodyLarge.copyWith(color: AppColors.onColorSecondary),
          ),
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty("title", title))
      ..add(IterableProperty<String>("descriptions", descriptions));
  }
}
