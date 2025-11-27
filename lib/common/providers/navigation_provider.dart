import "package:flutter/material.dart";
import "package:logging/logging.dart";

/// Enum representing the available tabs in the app.
enum AppTab { workout, history }

/// Provider that manages navigation state (tab selection).
class NavigationProvider extends ChangeNotifier {
  static final Logger _logger = Logger("NavigationProvider");
  static const AppTab _defaultTab = AppTab.workout;
  AppTab _currentTab = _defaultTab;

  AppTab get currentTab => _currentTab;

  void setTabIndex(final int index) {
    final tab = AppTab.values[index];
    if (tab == _currentTab) {
      return;
    }
    _logger.info("Tab changed: ${_currentTab.name} -> ${tab.name}");
    _currentTab = tab;
    notifyListeners();
  }

  void resetTab() {
    if (_currentTab == _defaultTab) {
      return;
    }
    _logger.info("Tab reset to default: ${_currentTab.name} -> ${_defaultTab.name}");
    _currentTab = _defaultTab;
    notifyListeners();
  }
}
