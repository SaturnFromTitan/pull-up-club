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
            "This tried and true program will increase your max pull-ups by 50-100% within 8-12 weeks. It works best if your current max is in the 5-12 rep range.",
            style: AppTypography.bodyLarge.copyWith(color: AppColors.onColorSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "This is a three day per week program done on non-consecutive days (e.g. Monday, Wednesday, Friday).",
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
              "This builds raw strength and tests your current capacity.",
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _ProgramInfoSection(
            title: "2. Sub-max Volume",
            descriptions: [
              "Perform 10 sets of 50% of your max reps from day 1.",
              "Rest exactly 1 minutes between each set.",
              "When you complete all sets at the target rep, the target will increase by 1.",
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _ProgramInfoSection(
            title: "3. Ladders",
            descriptions: [
              "Perform 5 ladders",
              "In a ladder, each set (or rung) increases the number of reps by 1. So you start with 1, then 2, 3, etc. When you're not confident that you will complete the next rung with good form, start a new ladder instead, i.e. reset the target reps to 1 again.",
              "Rest exactly 30 seconds between each rung",
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
