import "package:flutter/material.dart";
import "package:flutter_markdown/flutter_markdown.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:url_launcher/url_launcher.dart";

class ProgramInfoScreen extends StatelessWidget {
  const ProgramInfoScreen({super.key});

  @override
  Widget build(final BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.only(bottom: AppSpacing.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              "Program Info",
              textAlign: TextAlign.center,
              style: AppTypography.displayMedium,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          _YouTubeLink(),
          SizedBox(height: AppSpacing.md),
          Text("... or read my summary:", style: AppTypography.headlineLarge),
          SizedBox(height: AppSpacing.md),
          _ProgramMarkdown(),
        ],
      ),
    );
  }
}

class _ProgramMarkdown extends StatelessWidget {
  const _ProgramMarkdown();

  static const String _markdownContent = """
This proven program is designed to increase your max pull-ups by around 50-100% in 8-12 weeks. It works best if your current max is between 5 and 12 reps.

This is a three-days-per-week program done on non-consecutive days (e.g. Monday, Wednesday, Friday).

## Workouts

### 1. Max Sets

- Perform 3 max effort sets to technical failure.
- Rest at least 5 minutes between each set.

### 2. Submax Volume

- Perform 10 sets of 50% of your max reps from day 1.
- Rest exactly 1 minute between each set.
- When you complete all 10 sets at the target reps, the target will increase by 1 for the next submax workout.

### 3. Ladders

- Perform 5 ladders.
  - In each ladder, every set (or rung) increases the number of reps by 1: start with 1 rep, then 2, then 3, and so on.
  - When you're not confident you can complete the next rung with good form, stop that ladder and start a new one (reset back to 1 rep).
- Rest exactly 30 seconds between each rung.
- Avoid failure!
""";

  @override
  Widget build(final BuildContext context) {
    return MarkdownBody(
      data: _markdownContent,
      styleSheet: MarkdownStyleSheet(
        h2: AppTypography.headlineLarge.copyWith(
          color: AppColors.onColor,
          fontWeight: FontWeight.w600,
        ),
        h3: AppTypography.headlineMedium.copyWith(color: AppColors.onColor),
        p: AppTypography.bodyLarge.copyWith(color: AppColors.onColorSecondary),
        listBullet: AppTypography.bodyLarge.copyWith(color: AppColors.onColorSecondary),
      ),
    );
  }
}

class _YouTubeLink extends StatelessWidget {
  const _YouTubeLink();

  Future<void> _openYouTubeVideo() async {
    final uri = Uri.parse("https://www.youtube.com/watch?v=w9Mu-azxol8");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _openYouTubeVideo,
          child: const Row(
            children: [
              Icon(Icons.play_circle_outline, size: 24),
              SizedBox(width: AppSpacing.xs),
              Text("Watch instructional video", style: AppTypography.bodyLarge),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          "Note: I am not associated with the video creator, but I use his workouts for many years and think they're great.",
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.onColorSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
