import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/constants/app_constants.dart";
import "package:pull_up_club/common/providers/navigation_provider.dart";
import "package:pull_up_club/common/providers/workout_history_provider.dart";
import "package:pull_up_club/common/services/workout_database.dart";
import "package:pull_up_club/common/shell_screen.dart";
import "package:pull_up_club/common/themes/app_theme.dart";
import "package:pull_up_club/data/repositories/workout_repository.dart";

void main() {
  // Configure logging
  Logger.root.level = kDebugMode ? Level.ALL : Level.WARNING;
  Logger.root.onRecord.listen((final record) {
    debugPrint(
      "${DateTime.now().toUtc().toIso8601String()} ${record.level.name} ${record.loggerName}: ${record.message}",
    );
  });

  runApp(const App());
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
      ),
    );
  }
}
