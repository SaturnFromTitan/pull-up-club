import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:pull_up_club/main.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group("Workout Flow Integration Test", () {
    testWidgets("complete max sets workout flow", (final tester) async {
      const reps = <int>[10, 9, 8];

      // Start App ------------------------------------------------
      await tester.pumpWidget(
        const App(requiresUpdate: false, setErrorWidgetBuilder: false),
      );
      await tester.pumpAndSettle();

      // Verify initial state: Check history screen has no workouts
      // Navigate to history screen
      final historyIconInitial = find.byIcon(Icons.history);
      expect(historyIconInitial, findsWidgets);
      await tester.tap(historyIconInitial.first);
      await tester.pumpAndSettle();

      // Verify we're on the history screen and it's empty
      expect(find.text("Workout History"), findsOneWidget);
      expect(find.text("No workouts yet"), findsOneWidget);

      // Navigate back to home screen (workout tab)
      final homeIconInitial = find.byIcon(Icons.home_outlined);
      expect(homeIconInitial, findsWidgets);
      await tester.tap(homeIconInitial.first);
      await tester.pumpAndSettle();

      // Start Workout ------------------------------------------------
      expect(find.text("Double your max pull-ups!"), findsOneWidget);
      expect(find.text("Max Sets"), findsOneWidget);
      expect(find.text("Start Workout"), findsOneWidget);

      await tester.tap(find.text("Start Workout"));
      await tester.pumpAndSettle();

      // 1st Set ------------------------------------------------
      expect(find.text("Do as many reps as possible!"), findsOneWidget);
      final textField = find.byType(TextFormField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, reps[0].toString());
      await tester.pumpAndSettle();

      final submitButton = find.text("Submit");
      expect(submitButton, findsOneWidget);
      await tester.tap(submitButton);
      // skip rest via button
      await tester.pump(const Duration(milliseconds: 1_000));
      final skipRestButton = find.text("Skip Rest");
      expect(skipRestButton, findsOneWidget);
      await tester.tap(skipRestButton);
      await tester.pumpAndSettle();

      // 2nd Set ------------------------------------------------
      final textField2 = find.byType(TextFormField);
      expect(textField2, findsOneWidget);
      await tester.enterText(textField2, reps[1].toString());
      await tester.pumpAndSettle();

      final submitButton2 = find.text("Submit");
      expect(submitButton2, findsOneWidget);
      await tester.tap(submitButton2);
      // wait for rest timer to finish
      await tester.pumpAndSettle();

      // 3rd Set ------------------------------------------------
      final textField3 = find.byType(TextFormField);
      expect(textField3, findsOneWidget);
      await tester.enterText(textField3, reps[2].toString());
      await tester.pumpAndSettle();

      final submitButton3 = find.text("Submit");
      expect(submitButton3, findsOneWidget);
      await tester.tap(submitButton3);
      // can't use pumpAndSettle because the success screen has an endless animation
      // fyi if we don't wait long enough, then the test crashes
      await tester.pump(const Duration(milliseconds: 1_000));

      // Success Screen ------------------------------------------------
      expect(find.text("Workout Completed!"), findsOneWidget);
      expect(find.text("Max Sets"), findsOneWidget);

      final totalReps = reps.reduce((final a, final b) => a + b);
      expect(find.text("Total Reps"), findsOneWidget);
      expect(find.text(totalReps.toString()), findsOneWidget);

      // Check set values (should show 10, 9, 8 for the three sets)
      // Note: getSetCardValues groups by set number and sorts them
      // Since we entered sets in order (10, 9, 8), they should appear as "10", "9", "8"
      expect(find.text(reps[0].toString()), findsAtLeastNWidgets(1));
      expect(find.text(reps[1].toString()), findsAtLeastNWidgets(1));
      expect(find.text(reps[2].toString()), findsAtLeastNWidgets(1));

      // Verify duration is displayed (format: MM:SS)
      final durationText = find.textContaining(RegExp(r"\d{2}:\d{2}"));
      expect(durationText, findsAtLeastNWidgets(1));

      // Navigate back to home to avoid the never-ending animation on success screen
      // Tap the "Home" button
      final homeButton = find.text("Home");
      expect(homeButton, findsOneWidget);
      await tester.tap(homeButton);
      await tester.pumpAndSettle();

      // Home Screen ------------------------------------------------
      final historyIcon = find.byIcon(Icons.history);
      expect(historyIcon, findsWidgets);
      await tester.tap(historyIcon.first);
      await tester.pumpAndSettle();

      // History Screen ------------------------------------------------
      expect(find.text("Workout History"), findsOneWidget);

      expect(find.text("Max Sets"), findsAtLeastNWidgets(1));
      expect(find.text("💪 $totalReps reps"), findsAtLeastNWidgets(1));

      expect(find.text(reps[0].toString()), findsAtLeastNWidgets(1));
      expect(find.text(reps[1].toString()), findsAtLeastNWidgets(1));
      expect(find.text(reps[2].toString()), findsAtLeastNWidgets(1));

      final dismissible = find.byType(Dismissible);
      expect(dismissible, findsAtLeastNWidgets(1));

      // Perform a swipe gesture from right to left (endToStart direction)
      // Start from the right edge and drag to the left
      final firstWorkout = dismissible.first;
      final center = tester.getCenter(firstWorkout);
      final startX = center.dx + 100; // Start from right side
      final endX = center.dx - 200; // Drag to the left

      // Perform the swipe gesture
      await tester.drag(firstWorkout, Offset(endX - startX, 0));
      await tester.pumpAndSettle();

      // A confirmation dialog should appear
      expect(find.text("Delete Workout"), findsOneWidget);
      expect(
        find.text("Are you sure you want to delete this workout?"),
        findsOneWidget,
      );

      // Tap the "Delete" button to confirm
      final deleteButton = find.text("Delete");
      expect(deleteButton, findsOneWidget);
      await tester.tap(deleteButton);
      // fyi if we don't wait long enough, then the test crashes
      await tester.pump(const Duration(milliseconds: 1_000));
      await tester.pumpAndSettle();

      // Verify the workout was deleted
      expect(find.text("No workouts yet"), findsOneWidget);
    });
  });
}
