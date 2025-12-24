import "package:flutter/material.dart";
import "package:lucide_icons_flutter/lucide_icons.dart";
import "package:pull_up_club/common/constants/app_constants.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:pull_up_club/common/widgets/core/gradient_button.dart";
import "package:pull_up_club/common/widgets/core/screen_scaffold.dart";
import "package:url_launcher/url_launcher.dart";

class ForcedUpdateScreen extends StatelessWidget {
  const ForcedUpdateScreen({super.key});
  static const String route = "/forced-update";

  Future<void> _openAppStore() async {
    final uri = Uri.parse(AppConstants.appStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(final BuildContext context) {
    return ScreenScaffold(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.fileDown, size: 64, color: AppColors.onColor),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                "Update Required",
                style: AppTypography.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                "A new version of ${AppConstants.appTitle} is available. Please update to continue using the app.",
                style: AppTypography.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: Screen.width(context) * 0.6,
                child: GradientButton(
                  onPressed: _openAppStore,
                  text: "Update Now",
                  icon: LucideIcons.externalLink,
                  gradient: AppGradients.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
