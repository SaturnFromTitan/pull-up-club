import "dart:async";

import "package:clock/clock.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/providers/navigation_provider.dart";
import "package:pull_up_club/common/screens/shell_screen.dart";
import "package:pull_up_club/domain/models.dart";

double lineHeight(final TextStyle style) {
  final fontSize = style.fontSize ?? 1;
  final lineHeight = style.height ?? 1.4;
  return fontSize * lineHeight;
}

void navigateToHome(final BuildContext context) {
  context.read<NavigationProvider>().resetTab();
  unawaited(
    Navigator.of(context).pushNamedAndRemoveUntil(Shell.route, (final route) => false),
  );
}

String twoDigits(final int n) => n.toString().padLeft(2, "0");

String displayDuration(final int totalMillis) {
  final totalSeconds = (totalMillis / 1_000).ceil();
  final minutes = twoDigits(totalSeconds ~/ 60);
  final seconds = twoDigits(totalSeconds % 60);
  return "$minutes:$seconds";
}

List<String> getSetCardValues(final Workout workout) {
  final repsPerGroup = <int, int>{};

  for (final set_ in workout.sets) {
    final group = set_.group;
    final reps = set_.completedReps;
    repsPerGroup[group] = (repsPerGroup[group] ?? 0) + reps;
  }
  final entries = repsPerGroup.entries.toList()
    ..sort((final a, final b) => a.key.compareTo(b.key));
  return entries.map((final e) => e.value.toString()).toList();
}

String relativeDateString(final DateTime dt) {
  final diff = clock.now().difference(dt);

  if (diff.inMinutes < 1) {
    return "just now";
  }
  if (diff.inHours < 1) {
    final minutes = diff.inMinutes;
    return "$minutes ${minutes == 1 ? "minute" : "minutes"} ago";
  }
  if (diff.inDays < 1) {
    final hours = diff.inHours;
    return "$hours ${hours == 1 ? "hour" : "hours"} ago";
  }
  if (diff.inDays < 30) {
    final days = diff.inDays;
    return "$days ${days == 1 ? "day" : "days"} ago";
  }

  final year = dt.year.toString().padLeft(4, "0");
  final month = dt.month.toString().padLeft(2, "0");
  final day = dt.day.toString().padLeft(2, "0");
  return "$year-$month-$day";
}
