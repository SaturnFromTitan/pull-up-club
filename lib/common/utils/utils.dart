import "package:pull_up_club/domain/models.dart";

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
  return repsPerGroup.values.map((final e) => e.toString()).toList();
}

String datetimeToString(final DateTime dt) {
  const weekdayNames = <String>["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  const monthNames = <String>[
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];

  final weekday = weekdayNames[dt.weekday % 7]; // DateTime.weekday 1=Mon ... 7=Sun
  final month = monthNames[dt.month - 1];
  final day = dt.day.toString().padLeft(2, "0");
  final year = dt.year.toString();
  final hour = dt.hour.toString().padLeft(2, "0");
  final minute = dt.minute.toString().padLeft(2, "0");

  return "$weekday, $month $day $year $hour:$minute";
}
