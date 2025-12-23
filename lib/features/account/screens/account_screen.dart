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
        await workoutHistoryProvider.loadWorkouts();
      }
      if (!mounted) {
        return;
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Account",
                  textAlign: TextAlign.center,
                  style: AppTypography.displayMedium,
                ),
                Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.paddingMd),
                        child: Column(
                          children: isAuthenticated
                              ? [
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.cloud_done,
                                        size: 48,
                                        color: AppColors.onLight,
                                      ),
                                      SizedBox(width: AppSpacing.md),
                                      Text(
                                        "Signed In",
                                        style: AppTypography.headlineLarge,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  GradientButton(
                                    onPressed: _isLoading ? null : _handleSignOut,
                                    text: "Sign Out",
                                    icon: Icons.logout,
                                    gradient: AppGradients.secondary,
                                  ),
                                ]
                              : [
                                  SizedBox(
                                    width: Screen.width(context) * 0.7,
                                    child: const Text(
                                      "Sign in to backup your workouts in the cloud:",
                                      textAlign: TextAlign.center,
                                      style: AppTypography.bodyLarge,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  if (_errorMessage != null) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(AppSpacing.md),
                                      decoration: BoxDecoration(
                                        color: AppColors.errorBackground,
                                      ),
                                      child: Text(
                                        _errorMessage!,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.errorText,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                  ],
                                  GradientButton(
                                    onPressed: _isLoading ? null : _handleAppleSignIn,
                                    text: "Sign in with Apple",
                                    icon: Icons.apple,
                                    gradient: AppGradients.secondary,
                                  ),
                                ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text(
                    "${AppConstants.appTitle} @ ${PackageInfoService.instance.versionWithBuildNumber}",
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onColorSecondary,
                    ),
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
