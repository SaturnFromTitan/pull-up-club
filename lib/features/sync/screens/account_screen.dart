import "dart:async";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/providers/workout_history_provider.dart";
import "package:pull_up_club/common/services/package_info_service.dart";
import "package:pull_up_club/common/services/supabase_service.dart";
import "package:pull_up_club/common/services/sync_service.dart";
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
      final success = await SupabaseService.instance.signInWithApple();

      if (!success) {
        // User canceled
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Perform full sync after successful authentication
      await SyncService.instance.performSync(isDeltaSync: false);

      // Refresh workout history
      if (mounted) {
        // TODO: is this really necessary?
        final workoutHistoryProvider = context.read<WorkoutHistoryProvider>();
        await workoutHistoryProvider.refresh();

        setState(() {
          _isLoading = false;
        });
      }
    } on Exception catch (error, stackTrace) {
      _logger.severe("Apple Sign In failed", error, stackTrace);
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceAll("Exception: ", "");
      });
    }
  }

  Future<void> _handleSignOut() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.instance.signOut();
      setState(() {
        _isLoading = false;
      });
    } on Exception catch (error, stackTrace) {
      _logger.severe("Sign out failed", error, stackTrace);
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to sign out";
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    final supabase = SupabaseService.instance;
    final isAuthenticated = supabase.isAuthenticated;
    final versionString = PackageInfoService.instance.versionString;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    const Icon(Icons.cloud_done, size: 48, color: AppColors.onLight),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      "Signed in",
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.onLightSecondary,
                      ),
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
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
          const Spacer(),
          const SizedBox(height: AppSpacing.xxxl),
          Text(
            versionString,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.onColorSecondary),
          ),
        ],
      ),
    );
  }
}
