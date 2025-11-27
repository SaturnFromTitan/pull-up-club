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
import "package:pull_up_club/common/services/remote_config_service.dart";
import "package:pull_up_club/common/services/workout_database.dart";
import "package:pull_up_club/common/themes/app_theme.dart";
import "package:pull_up_club/data/repositories/workout_repository.dart";
import "package:pull_up_club/errors_reporting.dart";
import "package:sentry_flutter/sentry_flutter.dart";

Logger _logger = Logger("Main");

Future<void> main() async {
  // Wrap everything in a zone to catch unawaited async errors
  await runZonedGuarded(() async {
    _logger.info("App starting: debugMode=$kDebugMode");

    // Initialize Flutter bindings
    WidgetsFlutterBinding.ensureInitialized();
    _logger.fine("Flutter bindings initialized");

    // Initialize logging
    Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
    await LoggingService.instance.initialize();

    // Load remote app configuration
    final appConfig = await RemoteConfigService.instance.initialize();

    // Get app version for Sentry
    String appVersion;
    if (kDebugMode) {
      appVersion = "com.saturnfromtitan.pullupclub@debug";
    } else {
      appVersion = "com.saturnfromtitan.pullupclub@unknown";
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        appVersion =
            "${packageInfo.packageName}@${packageInfo.version}+${packageInfo.buildNumber}";
      } on Exception catch (error, stackTrace) {
        _logger.severe("Failed to get package info", error, stackTrace);
      }
    }
    _logger.info("App version: $appVersion");

    // Initialize Sentry and run app
    await SentryFlutter.init(
      (final options) {
        options
          ..dsn = kDebugMode ? "" : appConfig.sentryDsn
          ..environment = kDebugMode ? "dev" : "prod"
          ..release = appVersion
          // in the max sets workout, the user might put the app to background for 5 minutes
          // using 10 minutes to be safe
          ..autoSessionTrackingInterval = const Duration(minutes: 10);
        options.replay
          ..sessionSampleRate = 1.0
          ..onErrorSampleRate = 1.0;
      },
      appRunner: () {
        initSentryOnLogs();
        initGlobalErrorHandlers();
        runApp(SentryWidget(child: const App()));
      },
    );
  }, zoneErrorHandler);
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
