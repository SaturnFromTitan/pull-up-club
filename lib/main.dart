import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:provider/provider.dart";
import "package:pub_semver/pub_semver.dart";
import "package:pull_up_club/common/constants/app_constants.dart";
import "package:pull_up_club/common/providers/navigation_provider.dart";
import "package:pull_up_club/common/providers/workout_history_provider.dart";
import "package:pull_up_club/common/screens/forced_update_screen.dart";
import "package:pull_up_club/common/screens/shell_screen.dart";
import "package:pull_up_club/common/services/logging_service.dart";
import "package:pull_up_club/common/services/package_info_service.dart";
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

    // Load remote app config
    await RemoteConfigService.instance.initialize();
    final appConfig = RemoteConfigService.instance.getConfig();

    // Initialize package info service (loads version info once)
    await PackageInfoService.instance.initialize();

    final requiresUpdate = checkIfUpdateRequired(
      currentVersion: PackageInfoService.instance.packageInfo.version,
      minAppVersion: appConfig.minAppVersion,
    );

    // Initialize Sentry and run app
    await SentryFlutter.init(
      (final options) {
        options
          ..dsn = kDebugMode ? "" : appConfig.sentryDsn
          ..environment = kDebugMode ? "dev" : "prod"
          ..release = PackageInfoService.instance.versionString
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
        runApp(
          SentryWidget(
            child: App(requiresUpdate: requiresUpdate, setErrorWidgetBuilder: false),
          ),
        );
      },
    );
  }, zoneErrorHandler);
}

/// Checks if the current app version is older than the required minimum version.
/// Returns true if an update is required, false otherwise.
/// Logs the result and handles FormatException if version parsing fails.
bool checkIfUpdateRequired({
  required final String currentVersion,
  required final String minAppVersion,
}) {
  _logger.info("Comparing versions: current=$currentVersion, target=$minAppVersion");
  try {
    final current = Version.parse(currentVersion);
    final target = Version.parse(minAppVersion);
    final versionComparison = current.compareTo(target);
    final requiresUpdate = versionComparison < 0;
    if (requiresUpdate) {
      _logger.info("Update required");
    } else {
      _logger.info("Version check passed");
    }
    return requiresUpdate;
  } on FormatException catch (error) {
    if (!kDebugMode) {
      _logger.severe(
        "Invalid semver format in version comparison",
        error,
        StackTrace.current,
      );
    }
    // can't force update if the version format is invalid
    return false;
  }
}

class App extends StatelessWidget {
  const App({
    required this.requiresUpdate,
    required this.setErrorWidgetBuilder,
    super.key,
  });

  final bool requiresUpdate;
  // setting ErorWidget.builder is not compatible with the integration test framework
  final bool setErrorWidgetBuilder;

  // Create repository as a static instance to ensure it's only created once
  static final _workoutRepository = WorkoutRepository(WorkoutDatabase.instance);

  @override
  Widget build(final BuildContext context) {
    // Show forced update screen if update is required
    if (requiresUpdate) {
      return buildMaterialApp(
        context,
        isForcedUpdate: true,
        setErrorWidgetBuilder: setErrorWidgetBuilder,
      );
    }

    // Otherwise show normal app
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (final context) => NavigationProvider()),
        ChangeNotifierProvider(
          create: (final context) => WorkoutHistoryProvider(_workoutRepository),
        ),
      ],
      child: buildMaterialApp(context, setErrorWidgetBuilder: setErrorWidgetBuilder),
    );
  }

  Widget builderWithCustomErrorWidget(final BuildContext context, final Widget? child) {
    ErrorWidget.builder = errorWidget;
    return child ?? const SizedBox.shrink();
  }

  MaterialApp buildMaterialApp(
    final BuildContext context, {
    required final bool setErrorWidgetBuilder,
    final bool isForcedUpdate = false,
  }) {
    final screen = isForcedUpdate ? const ForcedUpdateScreen() : const Shell();
    final route = isForcedUpdate ? ForcedUpdateScreen.route : Shell.route;

    return MaterialApp(
      title: AppConstants.appTitle,
      theme: appTheme,
      builder: setErrorWidgetBuilder ? builderWithCustomErrorWidget : null,
      routes: {route: (final context) => screen},
      initialRoute: route,
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>("requiresUpdate", requiresUpdate))
      ..add(DiagnosticsProperty<bool>("setErrorWidgetBuilder", setErrorWidgetBuilder));
  }
}
