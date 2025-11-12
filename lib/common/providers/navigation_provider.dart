import "package:flutter/material.dart";

/// Enum representing the available tabs in the app.
enum AppTab { workout, history }

/// Provider that manages navigation state (tab selection).
class NavigationProvider extends ChangeNotifier {
  static const AppTab _defaultTab = AppTab.workout;
  AppTab _currentTab = _defaultTab;

  AppTab get currentTab => _currentTab;

  void setTabIndex(final int index) {
    final tab = AppTab.values[index];
    if (tab == _currentTab) {
      return;
    }
    _currentTab = tab;
    notifyListeners();
  }

  void resetTab() {
    if (_currentTab == _defaultTab) {
      return;
    }
    _currentTab = _defaultTab;
    notifyListeners();
  }
}
