import "package:clock/clock.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:pull_up_club/common/utils/utils.dart";
import "package:pull_up_club/domain/models.dart";

void main() {
  group("twoDigits", () {
    test("various digits", () {
      expect(twoDigits(0), "00");
      expect(twoDigits(5), "05");
      expect(twoDigits(59), "59");
      expect(twoDigits(100), "100");
    });
  });

  group("displayDuration", () {
    test("formats seconds correctly", () {
      expect(displayDuration(0), "00:00");
      expect(displayDuration(5_000), "00:05");
      expect(displayDuration(30_000), "00:30");
      expect(displayDuration(59_000), "00:59");
    });

    test("formats minutes and seconds correctly", () {
      expect(displayDuration(60_000), "01:00");
      expect(displayDuration(125_000), "02:05");
    });

    test("handles milliseconds by rounding up", () {
      expect(displayDuration(1_000), "00:01");
      expect(displayDuration(1_500), "00:02");
      expect(displayDuration(59_999), "01:00");
    });

    test("handles large durations", () {
      expect(displayDuration(3_600_000), "60:00");
      expect(displayDuration(3_660_000), "61:00");
    });
  });

  group("relativeDateString", () {
    final now = DateTime(2024, 6, 15, 12);

    test("returns 'just now' for less than a minute ago", () {
      withClock(Clock.fixed(now), () {
        expect(relativeDateString(now), "just now");
        expect(
          relativeDateString(now.subtract(const Duration(seconds: 30))),
          "just now",
        );
        expect(
          relativeDateString(now.subtract(const Duration(seconds: 59))),
          "just now",
        );
      });
    });

    test("returns minutes ago for less than an hour", () {
      withClock(Clock.fixed(now), () {
        expect(
          relativeDateString(now.subtract(const Duration(minutes: 1))),
          "1 minute ago",
        );
        expect(
          relativeDateString(now.subtract(const Duration(minutes: 5))),
          "5 minutes ago",
        );
        expect(
          relativeDateString(now.subtract(const Duration(minutes: 59))),
          "59 minutes ago",
        );
      });
    });

    test("returns hours ago for less than a day", () {
      withClock(Clock.fixed(now), () {
        expect(
          relativeDateString(now.subtract(const Duration(hours: 1))),
          "1 hour ago",
        );
        expect(
          relativeDateString(now.subtract(const Duration(hours: 5))),
          "5 hours ago",
        );
        expect(
          relativeDateString(now.subtract(const Duration(hours: 23))),
          "23 hours ago",
        );
      });
    });

    test("returns days ago for less than 30 days", () {
      withClock(Clock.fixed(now), () {
        expect(relativeDateString(now.subtract(const Duration(days: 1))), "1 day ago");
        expect(relativeDateString(now.subtract(const Duration(days: 7))), "7 days ago");
        expect(
          relativeDateString(now.subtract(const Duration(days: 29))),
          "29 days ago",
        );
      });
    });

    test("returns ISO date for 30 days or older", () {
      withClock(Clock.fixed(now), () {
        expect(
          relativeDateString(now.subtract(const Duration(days: 30))),
          "2024-05-16",
        );
        expect(relativeDateString(DateTime(2023, 1, 5)), "2023-01-05");
        expect(relativeDateString(DateTime(2020, 12, 31)), "2020-12-31");
      });
    });

    test("treats future dates as 'just now'", () {
      withClock(Clock.fixed(now), () {
        expect(relativeDateString(now.add(const Duration(hours: 1))), "just now");
      });
    });
  });

  group("getSetCardValues", () {
    test("returns empty list for workout with no sets", () {
      final workout = Workout(workoutType: WorkoutType.maxSets, maxGroups: 3);

      expect(getSetCardValues(workout), isEmpty);
    });

    test("sums reps per group correctly", () {
      final workout = Workout(
        workoutType: WorkoutType.maxSets,
        maxGroups: 3,
        sets: [
          // intentionally using non-sequential group numbers
          WorkoutSet(number: 1, group: 1, targetReps: 10, completedReps: 8),
          WorkoutSet(number: 2, group: 3, targetReps: 10, completedReps: 6),
          WorkoutSet(number: 3, group: 2, targetReps: 10, completedReps: 9),
          WorkoutSet(number: 4, group: 1, targetReps: 10, completedReps: 7),
        ],
      );

      final values = getSetCardValues(workout);
      expect(values, ["15", "9", "6"]); // Group 1: 8+7=15, Group 2: 9, Group 3: 6
    });

    group("lineHeight", () {
      test("calculates line height from fontSize and height", () {
        const style = TextStyle(fontSize: 14.5, height: 1.25);

        expect(lineHeight(style), 18.125);
      });

      test("uses default fontSize of 1 when null", () {
        const style = TextStyle(height: 1.4);

        expect(lineHeight(style), 1 * 1.4);
      });

      test("uses default height of 1.4 when null", () {
        const style = TextStyle(fontSize: 16);

        expect(lineHeight(style), 16 * 1.4);
      });

      test("uses both defaults when both are null", () {
        const style = TextStyle();

        expect(lineHeight(style), 1 * 1.4);
      });

      test("handles fractional values", () {
        const style = TextStyle(fontSize: 14.5, height: 1.25);

        expect(lineHeight(style), 18.125);
      });
    });
  });
}
