import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/widgets/screen_scaffold.dart";
import "package:pull_up_club/features/history/screens/history_screen.dart";
import "package:pull_up_club/features/workout/screens/selection_screen.dart";
import "package:pull_up_club/common/providers/app_provider.dart";
import "package:pull_up_club/common/widgets/gradient_navigation_bar.dart";

class Shell extends StatelessWidget {
  static final String route = "/shell";
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    return ScreenScaffold(
      bottomNavigationBar: GradientNavigationBar(
        selectedIndex: appProvider.tabIndex,
        onDestinationSelected: appProvider.setTabIndex,
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
      child: IndexedStack(
        index: appProvider.tabIndex,
        children: [WorkoutSelectionScreen(), HistoryScreen()],
      ),
    );
  }
}
