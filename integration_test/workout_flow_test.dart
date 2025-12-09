import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:pull_up_club/main.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group("Workout Flow Integration Test", () {
    testWidgets("complete max sets workout flow", (final tester) async {
      await tester.pumpWidget(
        const App(requiresUpdate: false, setErrorWidgetBuilder: false),
      );
      await tester.pumpAndSettle();

      // Verify we're on the workout selection screen
      expect(find.text("Double your max pull-ups!"), findsOneWidget);
      expect(find.text("Max Sets"), findsOneWidget);
      expect(find.text("Start Workout"), findsOneWidget);

      // Tap the "Start Workout" button
      await tester.tap(find.text("Start Workout"));
      await tester.pumpAndSettle();

      // Verify we're on the Max Sets workout screen
      expect(find.text("Do as many reps as possible!"), findsOneWidget);
      // Find the text input field for reps
      final textField = find.byType(TextFormField);
      expect(textField, findsOneWidget);

      // Enter and submit first set (10 reps)
      await tester.enterText(textField, "10");
      await tester.pumpAndSettle();

      final submitButton = find.text("Submit");
      expect(submitButton, findsOneWidget);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // We should be back on workout screen after rest completes
      // Enter second set (9 reps)
      final textField2 = find.byType(TextFormField);
      expect(textField2, findsOneWidget);
      await tester.enterText(textField2, "9");
      await tester.pumpAndSettle();

      final submitButton2 = find.text("Submit");
      expect(submitButton2, findsOneWidget);
      await tester.tap(submitButton2);
      await tester.pumpAndSettle();

      // Enter third set (8 reps) to complete the workout
      final textField3 = find.byType(TextFormField);
      expect(textField3, findsOneWidget);
      await tester.enterText(textField3, "8");
      await tester.pumpAndSettle();

      final submitButton3 = find.text("Submit");
      expect(submitButton3, findsOneWidget);
      await tester.tap(submitButton3);
      // can't use pumpAndSettle because the success screen has an endless animation
      // if we don't wait long enough, then the test crashes
      await tester.pump(const Duration(milliseconds: 1_000));

      // After completing all sets, we should see the success screen
      // Verify the success screen is displayed
      expect(
        find.text("Workout Completed!"),
        findsOneWidget,
        reason: "Success screen should be displayed after completing workout",
      );

      // Verify workout data via the success screen UI
      // Check workout type
      expect(
        find.text("Max Sets"),
        findsOneWidget,
        reason: "Success screen should show 'Max Sets' as the workout type",
      );

      // Check total reps (should be 10 + 9 + 8 = 27)
      expect(
        find.text("27"),
        findsOneWidget,
        reason: "Success screen should show 27 as total reps",
      );
      expect(
        find.text("Total Reps"),
        findsOneWidget,
        reason: "Success screen should show 'Total Reps' label",
      );

      // Check set values (should show 10, 9, 8 for the three sets)
      // Note: getSetCardValues groups by set number and sorts them
      // Since we entered sets in order (10, 9, 8), they should appear as "10", "9", "8"
      expect(
        find.text("10"),
        findsAtLeastNWidgets(1),
        reason: "Success screen should show '10' for the first set",
      );
      expect(
        find.text("9"),
        findsAtLeastNWidgets(1),
        reason: "Success screen should show '9' for the second set",
      );
      expect(
        find.text("8"),
        findsAtLeastNWidgets(1),
        reason: "Success screen should show '8' for the third set",
      );

      // Verify duration is displayed (format: MM:SS)
      final durationText = find.textContaining(RegExp(r"\d{2}:\d{2}"));
      expect(
        durationText,
        findsAtLeastNWidgets(1),
        reason: "Success screen should show workout duration in MM:SS format",
      );

      // Navigate back to home to avoid the never-ending animation on success screen
      // Tap the "Home" button
      final homeButton = find.text("Home");
      expect(homeButton, findsOneWidget);
      await tester.tap(homeButton);
      await tester.pumpAndSettle();

      // // Navigate to the history tab (index 2 in the bottom navigation)
      // // Find the history icon in the bottom navigation bar
      // final historyIcon = find.byIcon(Icons.history);
      // expect(historyIcon, findsWidgets);
      // await tester.tap(historyIcon.first);
      // await tester.pumpAndSettle();

      // // Verify we're on the history screen
      // expect(find.text("Workout History"), findsOneWidget);

      // // Verify the workout we just completed is in the history
      // // The most recent workout should be at the top (workouts are reversed)
      // expect(find.text("Max Sets"), findsAtLeastNWidgets(1));
      // expect(find.text("27"), findsAtLeastNWidgets(1)); // Total reps
      // expect(find.textContaining("💪 27 reps"), findsAtLeastNWidgets(1));

      // // Verify the set values are displayed (10, 9, 8)
      // expect(find.text("10"), findsAtLeastNWidgets(1));
      // expect(find.text("9"), findsAtLeastNWidgets(1));
      // expect(find.text("8"), findsAtLeastNWidgets(1));

      // // Find the first workout entry (most recent) and swipe to delete it
      // // The workout entries are in a ListView, and each has a Dismissible widget
      // // We need to find the Dismissible and perform a swipe gesture
      // final dismissible = find.byType(Dismissible);
      // expect(dismissible, findsAtLeastNWidgets(1));

      // // Perform a swipe gesture from right to left (endToStart direction)
      // // Start from the right edge and drag to the left
      // final firstWorkout = dismissible.first;
      // final center = tester.getCenter(firstWorkout);
      // final startX = center.dx + 100; // Start from right side
      // final endX = center.dx - 200; // Drag to the left

      // // Perform the swipe gesture
      // await tester.drag(firstWorkout, Offset(endX - startX, 0));
      // await tester.pumpAndSettle();

      // // A confirmation dialog should appear
      // expect(find.text("Delete Workout"), findsOneWidget);
      // expect(find.text("Are you sure you want to delete this workout?"), findsOneWidget);

      // // Tap the "Delete" button to confirm
      // final deleteButton = find.text("Delete");
      // expect(deleteButton, findsOneWidget);
      // await tester.tap(deleteButton);
      // await tester.pumpAndSettle();

      // // Verify the workout was deleted
      // // The workout should no longer be visible (or the history should be empty)
      // // Since we started with 0 workouts and added 1, after deletion we should be back to 0
      // // Check that "Max Sets" is no longer visible (or check the total workouts count)
      // final totalWorkoutsCard = find.textContaining("Total Workouts");
      // if (totalWorkoutsCard.evaluate().isNotEmpty) {
      //   // If the card is visible, verify the count is back to 0
      //   // The card shows the count, but we can't easily extract it, so we'll just verify
      //   // that the workout entry is gone
      //   expect(find.text("Max Sets"), findsNothing);
      // }
    });
  });
}
