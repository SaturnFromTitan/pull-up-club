import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/constants/app_constants.dart";
import "package:pull_up_club/common/providers/navigation_provider.dart";
import "package:pull_up_club/common/providers/workout_history_provider.dart";
import "package:pull_up_club/common/screens/shell_screen.dart";
import "package:pull_up_club/common/services/logging_service.dart";
import "package:pull_up_club/common/services/workout_database.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_theme.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:pull_up_club/data/repositories/workout_repository.dart";
import "package:sentry_flutter/sentry_flutter.dart";

Future<void> main() async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging
  await LoggingService.instance.initialize();
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;

  // Run app with Sentry error tracking
  final packageInfo = await PackageInfo.fromPlatform();
  final appVersion =
      "${packageInfo.packageName}@${packageInfo.version}+${packageInfo.buildNumber}";

  await SentryFlutter.init(
    (final options) {
      options
        // TODO: only set DSN when not in kDebugMode
        ..dsn =
            "https://e8445aeb8a976bca9c47de2073137e70@o4510399352012800.ingest.de.sentry.io/4510399355289680"
        ..environment = kDebugMode ? "dev" : "prod"
        ..release = appVersion;
    },
    appRunner: () {
      initSentryErrorReporting();
      runApp(const App());
    },
  );
}

// Set up Sentry error reporting for logged warnings/errors
void initSentryErrorReporting() {
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
        Logger("AppSetup").warning("Failed to send error to Sentry", e);
      }
    }
  });
}

class App extends StatelessWidget {
  const App({super.key});

  // Create repository as a static instance to ensure it's only created once
  static final _workoutRepository = WorkoutRepository(WorkoutDatabase.instance);

  @override
  Widget build(final BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (final context) => NavigationProvider()),
        ChangeNotifierProvider(
          create: (final context) => WorkoutHistoryProvider(_workoutRepository),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appTitle,
        theme: appTheme,
        initialRoute: Shell.route,
        routes: {Shell.route: (final context) => const Shell()},
        builder: (final context, final child) {
          // show a user-friendly UI upon unhandled exceptions
          ErrorWidget.builder = (final errorDetails) {
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
                          "The error has been reported. Please restart the app.",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          };

          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}
