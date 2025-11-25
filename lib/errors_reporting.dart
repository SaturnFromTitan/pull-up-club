import "dart:async";
import "dart:ui";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
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
