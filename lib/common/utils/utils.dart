import "package:pull_up_club/features/workout/models.dart";

String twoDigits(int n) {
  return n.toString().padLeft(2, "0");
}

String formatMinutesSeconds(int totalSeconds) {
  final minutes = twoDigits(totalSeconds ~/ 60);
  final seconds = twoDigits(totalSeconds % 60);
  return "$minutes:$seconds";
}

List<String> getSetCardValues(Workout workout) {
  Map<int, int> repsPerGroup = {};

  for (var set_ in workout.sets) {
    var group = set_.group;
    var reps = set_.completedReps;
    repsPerGroup[group] = (repsPerGroup[group] ?? 0) + reps;
  }
  return repsPerGroup.values.map((int e) => e.toString()).toList();
}

String datetimeToString(DateTime dt) {
  const List<String> weekdayNames = [
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat",
    "Sun",
  ];
  const List<String> monthNames = [
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

  String weekday =
      weekdayNames[dt.weekday % 7]; // DateTime.weekday 1=Mon ... 7=Sun
  String month = monthNames[dt.month - 1];
  String day = dt.day.toString().padLeft(2, "0");
  String year = dt.year.toString();

  return "$weekday, $month $day $year";
}
