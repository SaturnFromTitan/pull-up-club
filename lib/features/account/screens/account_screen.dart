import "package:flutter/material.dart";
import "package:pull_up_club/common/constants/app_constants.dart";
import "package:pull_up_club/common/services/package_info_service.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(final BuildContext context) {
    return LayoutBuilder(
      builder: (final context, final constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Cloud Sync",
                  textAlign: TextAlign.center,
                  style: AppTypography.displayMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  "Register to automatically backup your workout history to the cloud. Never lose your progress again!",
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xl),

                Text(
                  "${AppConstants.appTitle} @ ${PackageInfoService.instance.versionWithBuildNumber}",
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onColorSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
