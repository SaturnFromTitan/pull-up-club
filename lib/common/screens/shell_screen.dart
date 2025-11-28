import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/providers/navigation_provider.dart";
import "package:pull_up_club/common/providers/workout_history_provider.dart";
import "package:pull_up_club/common/screens/splash_screen.dart";
import "package:pull_up_club/common/widgets/core/gradient_navigation_bar.dart";
import "package:pull_up_club/common/widgets/core/screen_scaffold.dart";
import "package:pull_up_club/features/history/screens/history_screen.dart";
import "package:pull_up_club/features/workout/screens/selection_screen.dart";

class Shell extends StatelessWidget {
  const Shell({super.key});
  static const String route = "/shell";
  static final Logger _logger = Logger("Shell");

  @override
  Widget build(final BuildContext context) {
    final navigationProvider = context.watch<NavigationProvider>();
    final workoutHistoryProvider = context.watch<WorkoutHistoryProvider>();

    if (workoutHistoryProvider.isLoading) {
      _logger.fine("Showing splash screen: loading workout history");
      return const ScreenScaffold(child: SplashScreen());
    }

    return ScreenScaffold(
      bottomNavigationBar: GradientNavigationBar(
        selectedIndex: navigationProvider.currentTab.index,
        onDestinationSelected: navigationProvider.setTabIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: "Workout",
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history),
            label: "History",
          ),
        ],
      ),
      child: switch (navigationProvider.currentTab) {
        AppTab.workout => const WorkoutSelectionScreen(),
        AppTab.history => const HistoryScreen(),
      },
    );
  }
}
