import "package:flutter/material.dart";
import "package:pull_up_club/features/workout/models.dart";

class AppProvider extends ChangeNotifier {
  List<Workout> completedWorkouts = <Workout>[];
  int _tabIndex = 0;

  int get tabIndex => _tabIndex;

  void setTabIndex(final int value) {
    if (value == _tabIndex) return;
    _tabIndex = value;
    notifyListeners();
  }

  void resetTab() {
    setTabIndex(0);
  }
}
