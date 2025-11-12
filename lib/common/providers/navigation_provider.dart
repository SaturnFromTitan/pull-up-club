import "package:flutter/material.dart";

/// Provider that manages navigation state (tab index).
/// This is a UI/presentation concern and is kept separate from business logic.
class NavigationProvider extends ChangeNotifier {
  int _tabIndex = 0;

  int get tabIndex => _tabIndex;

  void setTabIndex(final int value) {
    if (value == _tabIndex) {
      return;
    }
    _tabIndex = value;
    notifyListeners();
  }

  void resetTab() {
    setTabIndex(0);
  }
}
