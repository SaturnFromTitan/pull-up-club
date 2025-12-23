// prints are ok for integration tests
// ignore_for_file: avoid_print
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:pull_up_club/common/providers/navigation_provider.dart";
import "package:pull_up_club/domain/models.dart";

import "utils.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group("Workout Flow Integration Test", () {
    testWidgets("complete max sets workout flow", (final tester) async {
      const reps = <int>[10, 9, 8];

      // Start App -----------------------------------------------------
      await restartApp(tester);

      // Home Screen ---------------------------------------------------
      await navigateTo(tester, AppTab.history);

      // History Screen ------------------------------------------------
      expect(find.text("Workout History"), findsOneWidget);
      expect(find.text("No workouts yet"), findsOneWidget);

      await navigateTo(tester, AppTab.workout);

      // Home Screen ---------------------------------------------------
      expect(find.text("Double your max pull-ups!"), findsOneWidget);
      expect(find.text("Max Sets"), findsOneWidget);
      expect(find.text("Start Workout"), findsOneWidget);
      verifyNextBadge(tester, WorkoutType.maxSets);

      // Start Workout -------------------------------------------------
      print("Starting the workout");
      await tester.tap(find.text("Start Workout"));
      await tester.pumpAndSettle();

      // 1st Set -------------------------------------------------------
      expect(find.text("Do as many reps as possible!"), findsOneWidget);
      await enterRepsAndSkipRest(tester, reps: reps[0]);

      // 2nd Set -------------------------------------------------------
      await enterRepsAndWaitRest(tester, reps: reps[1]);

      // 3rd Set -------------------------------------------------------
      await enterRepsToFinishWorkout(tester, reps: reps[2]);

      // Success Screen ------------------------------------------------
      print("Checking the success screen");
      expect(find.text("Workout Completed!"), findsOneWidget);
      expect(find.text("Max Sets"), findsOneWidget);

      final totalReps = reps.reduce((final a, final b) => a + b);
      expect(find.text("Total Reps"), findsOneWidget);
      expect(find.text(totalReps.toString()), findsOneWidget);

      expect(find.text(reps[0].toString()), findsOneWidget);
      expect(find.text(reps[1].toString()), findsOneWidget);
      expect(find.text(reps[2].toString()), findsOneWidget);

      // Verify duration is displayed (format: MM:SS)
      final durationText = find.textContaining(r"\d{2}:\d{2}");
      expect(durationText, findsOneWidget);

      print("Going back home");
      // Navigate back to home to avoid the never-ending animation on success screen
      // Tap the "Home" button
      final homeButton = find.text("Home");
      expect(homeButton, findsOneWidget);
      await tester.tap(homeButton);
      await tester.pumpAndSettle();

      // Home Screen ---------------------------------------------------
      verifyNextBadge(tester, WorkoutType.submaxVolume);

      // ensure the workouts are persisted
      await restartApp(tester);
      await navigateTo(tester, AppTab.history);

      // History Screen ------------------------------------------------
      print("Checking the history screen");
      expect(find.text("Workout History"), findsOneWidget);

      expect(find.text("Max Sets"), findsOneWidget);
      expect(find.text("💪 $totalReps reps"), findsOneWidget);

      expect(find.text(reps[0].toString()), findsOneWidget);
      expect(find.text(reps[1].toString()), findsOneWidget);
      expect(find.text(reps[2].toString()), findsOneWidget);

      // Delete Workout ------------------------------------------------
      final dismissible = find.byType(Dismissible);
      expect(dismissible, findsOneWidget);
      await deleteWorkout(tester, dismissible: dismissible);

      // Verify the workout was deleted
      print("Verifying the workout was deleted");
      expect(find.text("No workouts yet"), findsOneWidget);
    });
  });
}
