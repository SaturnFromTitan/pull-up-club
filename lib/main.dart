import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/constants/app_constants.dart";
import "package:pull_up_club/common/providers/app_provider.dart";
import "package:pull_up_club/common/shell_screen.dart";
import "package:pull_up_club/common/themes/app_theme.dart";

void main() {
  // Configure logging
  Logger.root.level = kDebugMode ? Level.ALL : Level.WARNING;
  Logger.root.onRecord.listen((final record) {
    debugPrint("${record.level.name}: ${record.loggerName}: ${record.message}");
  });

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(final BuildContext context) => MultiProvider(
    providers: [ChangeNotifierProvider(create: (final context) => AppProvider())],
    child: MaterialApp(
      title: AppConstants.appTitle,
      theme: appTheme,
      initialRoute: Shell.route,
      routes: {Shell.route: (final context) => const Shell()},
    ),
  );
}
