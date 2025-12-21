import "dart:async";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/constants/app_constants.dart";
import "package:pull_up_club/common/providers/workout_history_provider.dart";
import "package:pull_up_club/common/services/backend_service.dart";
import "package:pull_up_club/common/services/package_info_service.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:pull_up_club/common/widgets/core/gradient_button.dart";
import "package:sign_in_with_apple/sign_in_with_apple.dart";

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  static final Logger _logger = Logger("AccountScreen");
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await BackendService.instance.signInWithApple();
      if (success && mounted) {
        // Perform full sync after successful authentication
        final workoutHistoryProvider = context.read<WorkoutHistoryProvider>();
        await workoutHistoryProvider.loadWorkouts(isDeltaSync: false);
      }
    } on Exception catch (error, stackTrace) {
      _logger.severe("Apple Sign In failed", error, stackTrace);
      setState(() => _errorMessage = error.toString().replaceAll("Exception: ", ""));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _handleSignOut() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await BackendService.instance.signOut();
    } on Exception catch (error, stackTrace) {
      _logger.severe("Sign out failed", error, stackTrace);
      setState(() => _errorMessage = "Failed to sign out");
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(final BuildContext context) {
    final supabase = BackendService.instance;
    final isAuthenticated = supabase.isAuthenticated;

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
                if (isAuthenticated) ...[
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.paddingMd),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.cloud_done,
                            size: 48,
                            color: AppColors.onLight,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          GradientButton(
                            onPressed: _isLoading ? null : _handleSignOut,
                            text: "Sign Out",
                            icon: Icons.logout,
                            gradient: AppGradients.light,
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.paddingMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.red.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          SignInWithAppleButton(
                            onPressed: _isLoading ? null : _handleAppleSignIn,
                            height: AppSpacing.buttonHeight,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxxl),
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
