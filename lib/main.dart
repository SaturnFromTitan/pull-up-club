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
import "package:pull_up_club/common/themes/app_theme.dart";
import "package:pull_up_club/data/repositories/workout_repository.dart";
import "package:pull_up_club/errors_reporting.dart";
import "package:sentry_flutter/sentry_flutter.dart";

Future<void> main() async {
  // Wrap everything in a zone to catch unawaited async errors
  await runZonedGuarded(
    () async {
      // Initialize Flutter bindings
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize logging
      Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
      await LoggingService.instance.initialize();

      // Get app version for Sentry
      String appVersion;
      if (kDebugMode) {
        appVersion = "pull-up-club@debug";
      } else {
        final packageInfo = await PackageInfo.fromPlatform();
        appVersion =
            "${packageInfo.packageName}@${packageInfo.version}+${packageInfo.buildNumber}";
      }

      // Initialize Sentry and run app
      await SentryFlutter.init(
        (final options) {
          options
            ..dsn = kDebugMode
                ? ""
                : "https://e8445aeb8a976bca9c47de2073137e70@o4510399352012800.ingest.de.sentry.io/4510399355289680"
            ..environment = kDebugMode ? "dev" : "prod"
            ..release = appVersion;
        },
        appRunner: () {
          initSentryOnLogs();
          setupPlatformErrorHandlers();
          runApp(const App());
        },
      );
    },
    (final error, final stackTrace) {
      Logger("ErrorReporting").severe("zone error", error, stackTrace);
    },
  );
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
          ErrorWidget.builder = errorWidget;
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}
