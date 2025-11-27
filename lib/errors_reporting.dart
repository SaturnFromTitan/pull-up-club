import "dart:async";
import "dart:ui";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:logging/logging.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:pull_up_club/common/widgets/core/gradient_button.dart";
import "package:sentry_flutter/sentry_flutter.dart";

Logger _logger = Logger("ErrorReporting");

// Set up Sentry error reporting for logged warnings/errors
void initSentryOnLogs() {
  Logger.root.onRecord.listen((final record) {
    if (record.level >= Level.WARNING) {
      try {
        if (record.error != null) {
          // If there's an error object, capture it as an exception
          unawaited(
            Sentry.captureException(
              record.error,
              stackTrace: record.stackTrace,
              hint: Hint.withMap({
                "logger": record.loggerName,
                "message": record.message,
              }),
            ),
          );
        } else {
          // Otherwise, capture as a message with appropriate level
          unawaited(
            Sentry.captureMessage(
              "${record.loggerName}: ${record.message}",
              level: record.level == Level.SEVERE
                  ? SentryLevel.error
                  : SentryLevel.warning,
              hint: Hint.withMap({"logger": record.loggerName}),
            ),
          );
        }
      } on Exception catch (e) {
        _logger.warning("Failed to send error to Sentry", e);
      }
    }
  });
}

// Set up global error handlers for unhandled exceptions
// inspired by https://docs.flutter.dev/testing/errors#handling-all-types-of-errors
void initGlobalErrorHandlers() {
  // Log errors from Flutter framework errors as well
  final originalFlutterError = FlutterError.onError;
  FlutterError.onError = (final details) {
    _logger.severe("Flutter framework error", details.exception, details.stack);
    originalFlutterError?.call(details);
  };

  // Handle async errors and other unhandled exceptions
  final originalPlatformError = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (final error, final stackTrace) {
    _logger.severe("Unhandled platform exception", error, stackTrace);
    if (originalPlatformError != null) {
      return originalPlatformError(error, stackTrace);
    }
    return true;
  };
}

void zoneErrorHandler(final Object error, final StackTrace stackTrace) {
  _logger.severe("zone error", error, stackTrace);
}

Material errorWidget(final FlutterErrorDetails errorDetails) {
  return const Material(
    child: ColoredBox(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: AppSpacing.md),
            Text("Something went wrong", style: AppTypography.headlineMedium),
            SizedBox(height: AppSpacing.sm),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.paddingMd),
              child: Text(
                "The error has been reported.\nPlease restart the app.",
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------- Error Selection Screen ----------------
// This screen is only used to test the error reporting system
// This should be covered by a test case instead
class ErrorSelectionScreen extends StatelessWidget {
  // This widget can be used in ShellScreen inplace of WorkoutSelectionScreen
  const ErrorSelectionScreen({super.key});

  void _triggerFlutterError(final BuildContext context) {
    // Navigate to a screen with a widget that fails to build
    // This simulates a real Flutter framework error
    unawaited(
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const _ErrorTestScreen())),
    );
  }

  void _triggerSyncError() {
    // fyi this will be caught as a flutter error
    throw Exception("sync boom");
  }

  Future<void> _triggerPlatformError() async {
    // as described in https://docs.flutter.dev/testing/errors#errors-not-caught-by-flutter
    // but here it's also caught in the zone handler
    const channel = MethodChannel("crashy-custom-channel");
    await channel.invokeMethod("blah");
  }

  void _triggerZoneError() {
    // Trigger a zone error by throwing in an unawaited async function
    unawaited(_throwAsyncError());
  }

  Future<void> _throwAsyncError() async {
    await Future.delayed(const Duration(milliseconds: 100));
    throw Exception("async boom");
  }

  @override
  Widget build(final BuildContext context) {
    return LayoutBuilder(
      builder: (final context, final constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header section
                Column(
                  children: [
                    GradientButton(
                      text: "Test Build Error",
                      icon: Icons.bug_report,
                      gradient: AppGradients.accentPurple,
                      onPressed: () => _triggerFlutterError(context),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    GradientButton(
                      text: "Test Sync Error",
                      icon: Icons.error_outline,
                      gradient: AppGradients.accentPurple,
                      onPressed: _triggerSyncError,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    GradientButton(
                      text: "Test Async Error",
                      icon: Icons.warning,
                      gradient: AppGradients.accentGreen,
                      onPressed: _triggerZoneError,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    GradientButton(
                      text: "Test Platform Error",
                      icon: Icons.error_outline,
                      gradient: AppGradients.secondary,
                      onPressed: _triggerPlatformError,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ErrorTestScreen extends StatelessWidget {
  const _ErrorTestScreen();

  @override
  Widget build(final BuildContext context) {
    // This widget intentionally throws during build to test Flutter error handling
    throw Exception("widget build failure");
  }
}
