import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";
import "package:pub_semver/pub_semver.dart";
import "package:pull_up_club/common/constants/app_constants.dart";
import "package:pull_up_club/common/providers/navigation_provider.dart";
import "package:pull_up_club/common/providers/workout_history_provider.dart";
import "package:pull_up_club/common/screens/forced_update_screen.dart";
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
    await RemoteConfigService.instance.initialize();
    final appConfig = RemoteConfigService.instance.getConfig();

    // Get app version for Sentry and version check
    final versionInfo = await _getAppVersion(appConfig);
    final appVersion = versionInfo.appVersion;
    final requiresUpdate = versionInfo.requiresUpdate;
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
        runApp(SentryWidget(child: App(requiresUpdate: requiresUpdate)));
      },
    );
  }, zoneErrorHandler);
}

/// Retrieves the app version and checks if an update is required.
/// Returns a record with the app version string and whether an update is required.
Future<({String appVersion, bool requiresUpdate})> _getAppVersion(
  final AppConfig appConfig,
) async {
  if (kDebugMode) {
    return (appVersion: "com.saturnfromtitan.pullupclub@debug", requiresUpdate: false);
  }

  var appVersion = "com.saturnfromtitan.pullupclub@unknown";
  var requiresUpdate = false;
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    appVersion =
        "${packageInfo.packageName}@${packageInfo.version}+${packageInfo.buildNumber}";

    // Check if update is required
    requiresUpdate = _checkIfUpdateRequired(currentVersion, appConfig.minAppVersion);
  } on Exception catch (error, stackTrace) {
    _logger.severe("Failed to get package info", error, stackTrace);
  }

  return (appVersion: appVersion, requiresUpdate: requiresUpdate);
}

/// Checks if the current app version is older than the required minimum version.
/// Returns true if an update is required, false otherwise.
/// Logs the result and handles FormatException if version parsing fails.
bool _checkIfUpdateRequired(final String currentVersion, final String minAppVersion) {
  _logger.info("Comparing versions: current=$currentVersion, target=$minAppVersion");
  try {
    final current = Version.parse(currentVersion);
    final target = Version.parse(minAppVersion);
    final versionComparison = current.compareTo(target);
    final requiresUpdate = versionComparison < 0;
    if (requiresUpdate) {
      _logger.warning("Update required");
    } else {
      _logger.info("Version check passed");
    }
    return requiresUpdate;
  } on FormatException catch (error) {
    _logger.severe(
      "Invalid semver format in version comparison",
      error,
      StackTrace.current,
    );
    // If version format is invalid, don't force update (fail open)
    return false;
  }
}

class App extends StatelessWidget {
  const App({required this.requiresUpdate, super.key});

  final bool requiresUpdate;

  // Create repository as a static instance to ensure it's only created once
  static final _workoutRepository = WorkoutRepository(WorkoutDatabase.instance);

  @override
  Widget build(final BuildContext context) {
    // Show forced update screen if update is required
    if (requiresUpdate) {
      return buildMaterialApp(context, isForcedUpdate: true);
    }

    // Otherwise show normal app
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (final context) => NavigationProvider()),
        ChangeNotifierProvider(
          create: (final context) => WorkoutHistoryProvider(_workoutRepository),
        ),
      ],
      child: buildMaterialApp(context),
    );
  }

  MaterialApp buildMaterialApp(
    final BuildContext context, {
    final bool isForcedUpdate = false,
  }) {
    final screen = isForcedUpdate ? const ForcedUpdateScreen() : const Shell();
    final route = isForcedUpdate ? ForcedUpdateScreen.route : Shell.route;
    return MaterialApp(
      title: AppConstants.appTitle,
      theme: appTheme,
      builder: (final context, final child) {
        ErrorWidget.builder = errorWidget;
        return child ?? const SizedBox.shrink();
      },
      routes: {route: (final context) => screen},
      initialRoute: route,
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>("requiresUpdate", requiresUpdate));
  }
}
