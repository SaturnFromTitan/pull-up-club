import "dart:async";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:lucide_icons_flutter/lucide_icons.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/constants/app_constants.dart";
import "package:pull_up_club/common/providers/workout_history_provider.dart";
import "package:pull_up_club/common/services/backend_service.dart";
import "package:pull_up_club/common/services/package_info_service.dart";
import "package:pull_up_club/common/services/workout_database.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:pull_up_club/common/widgets/core/dismissible_dialog.dart";
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

  Future<bool?> _confirmDeleteAccount(final BuildContext context) => showDialog<bool>(
    context: context,
    builder: (final dialogContext) => DismissibleDialog(
      children: [
        const Text(
          "Delete Account",
          style: AppTypography.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          "This will permanently delete your account and workout data in the cloud.",
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          "You can still keep your local data.",
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        GradientButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          text: "Keep Local Data",
          icon: LucideIcons.cloudOff,
          gradient: AppGradients.light,
        ),
        const SizedBox(height: AppSpacing.md),
        GradientButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          text: "Delete Everything",
          icon: LucideIcons.trash2,
          gradient: AppGradients.primary,
        ),
      ],
    ),
  );

  Future<void> _handleDeleteAccount() async {
    final deleteEverything = await _confirmDeleteAccount(context);
    if (deleteEverything == null || !mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await BackendService.instance.deleteAccount();
      if (!mounted) {
        return;
      }

      if (success) {
        if (deleteEverything) {
          // Delete all local workout data
          await WorkoutDatabase.instance.deleteAllWorkouts();
        } else {
          // Clear serverIds from all workouts so they could be synced again if needed.
          await WorkoutDatabase.instance.clearAllServerIds();
        }
        // Reload workouts to update the UI
        if (mounted) {
          final workoutHistoryProvider = context.read<WorkoutHistoryProvider>();
          await workoutHistoryProvider.loadWorkouts();
        }
      } else {
        setState(() => _errorMessage = "Failed to delete account");
      }
    } on Exception catch (error, stackTrace) {
      _logger.severe("Account deletion failed", error, stackTrace);
      if (mounted) {
        setState(() => _errorMessage = "Failed to delete account");
      }
    }
    setState(() => _isLoading = false);
  }

  List<Widget> _buildErrorMessage() {
    if (_errorMessage == null) {
      return [];
    }
    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: AppColors.errorBackground),
        child: Text(
          _errorMessage!,
          style: AppTypography.bodySmall.copyWith(color: AppColors.errorText),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
    ];
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
                                        size: 42,
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
                                  ..._buildErrorMessage(),
                                  GradientButton(
                                    onPressed: _isLoading ? null : _handleSignOut,
                                    text: "Sign Out",
                                    icon: LucideIcons.logOut,
                                    gradient: AppGradients.secondary,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  GradientButton(
                                    onPressed: _isLoading ? null : _handleDeleteAccount,
                                    text: "Delete Account",
                                    icon: LucideIcons.trash2,
                                    gradient: AppGradients.light,
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
                                  ..._buildErrorMessage(),
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
