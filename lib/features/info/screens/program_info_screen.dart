import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:youtube_player_flutter/youtube_player_flutter.dart";

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
          _YouTubePlayer(),
          SizedBox(height: AppSpacing.md),
          Text("... or read the summary:", style: AppTypography.headlineLarge),
          SizedBox(height: AppSpacing.md),
          _ProgramContent(),
        ],
      ),
    );
  }
}

class _ProgramContent extends StatelessWidget {
  const _ProgramContent();

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "This proven program is designed to increase your max pull-ups by around 50-100% in 8-12 weeks. It works best if your current max is between 5 and 12 reps.",
          style: AppTypography.bodyLarge.copyWith(color: AppColors.onColorSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          "This is a three-days-per-week program done on non-consecutive days (e.g. Monday, Wednesday, Friday).",
          style: AppTypography.bodyLarge.copyWith(color: AppColors.onColorSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          "Workouts",
          style: AppTypography.headlineLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.md),
        const _WorkoutSection(
          title: "1. Max Sets",
          items: [
            "Perform 3 max effort sets to technical failure.",
            "Rest at least 5 minutes between each set.",
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const _WorkoutSection(
          title: "2. Submax Volume",
          items: [
            "Perform 10 sets of 50% of your max reps from day 1.",
            "Rest exactly 1 minute between each set.",
            "When you complete all 10 sets at the target reps, the target will increase by 1 for the next submax workout.",
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const _WorkoutSection(
          title: "3. Ladders",
          items: [
            "Perform 5 ladders.",
            "In each ladder, every set (or rung) increases the number of reps by 1: start with 1 rep, then 2, then 3, and so on.",
            "When you're not confident you can complete the next rung with good form, stop that ladder and start a new one (reset back to 1 rep).",
            "Rest exactly 30 seconds between each rung.",
            "Avoid failure!",
          ],
        ),
      ],
    );
  }
}

class _WorkoutSection extends StatelessWidget {
  const _WorkoutSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        ...items.map(
          (final item) => Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md, bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "• ",
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.onColorSecondary,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.onColorSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty("title", title))
      ..add(IterableProperty<String>("items", items));
  }
}

class _YouTubePlayer extends StatefulWidget {
  const _YouTubePlayer();

  @override
  State<_YouTubePlayer> createState() => _YouTubePlayerState();
}

class _YouTubePlayerState extends State<_YouTubePlayer> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: "w9Mu-azxol8",
      flags: const YoutubePlayerFlags(autoPlay: false),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: AppColors.gradientPrimary.first,
            progressColors: ProgressBarColors(
              playedColor: AppColors.gradientPrimary.first,
              handleColor: AppColors.gradientPrimary.first,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          "Note: This app is not affiliated with the video creator. This workout program has simply been selected because it works.",
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.onColorSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
