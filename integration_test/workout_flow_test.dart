import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:pull_up_club/common/providers/navigation_provider.dart";
import "package:pull_up_club/domain/models.dart";
import "package:pull_up_club/features/workout/screens/selection_screen.dart";
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

      // Home Screen ------------------------------------------------
      await _navigateTo(tester, AppTab.history);

      // History Screen ------------------------------------------------
      expect(find.text("Workout History"), findsOneWidget);
      expect(find.text("No workouts yet"), findsOneWidget);

      await _navigateTo(tester, AppTab.workout);

      // Home Screen ------------------------------------------------
      expect(find.text("Double your max pull-ups!"), findsOneWidget);
      expect(find.text("Max Sets"), findsOneWidget);
      expect(find.text("Start Workout"), findsOneWidget);
      _verifyNextBadge(tester, WorkoutType.maxSets);

      // Start Workout ------------------------------------------------
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
      expect(find.text(reps[0].toString()), findsOne);
      expect(find.text(reps[1].toString()), findsOne);
      expect(find.text(reps[2].toString()), findsOne);

      // Verify duration is displayed (format: MM:SS)
      final durationText = find.textContaining(RegExp(r"\d{2}:\d{2}"));
      expect(durationText, findsOne);

      // Navigate back to home to avoid the never-ending animation on success screen
      // Tap the "Home" button
      final homeButton = find.text("Home");
      expect(homeButton, findsOneWidget);
      await tester.tap(homeButton);
      await tester.pumpAndSettle();

      // Home Screen ------------------------------------------------
      _verifyNextBadge(tester, WorkoutType.submaxVolume);
      await _navigateTo(tester, AppTab.history);

      // History Screen ------------------------------------------------
      expect(find.text("Workout History"), findsOneWidget);

      expect(find.text("Max Sets"), findsOne);
      expect(find.text("💪 $totalReps reps"), findsOneWidget);

      expect(find.text(reps[0].toString()), findsOne);
      expect(find.text(reps[1].toString()), findsOne);
      expect(find.text(reps[2].toString()), findsOne);

      final dismissible = find.byType(Dismissible);
      expect(dismissible, findsOne);

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

Future<void> _navigateTo(final WidgetTester tester, final AppTab tab) async {
  IconData targetIconData;
  switch (tab) {
    case AppTab.workout:
      targetIconData = Icons.home_outlined;
    case AppTab.programInfo:
      targetIconData = Icons.info_outline;
    case AppTab.history:
      targetIconData = Icons.history_outlined;
  }

  final targetIcon = find.byIcon(targetIconData);
  expect(targetIcon, findsOneWidget);
  await tester.tap(targetIcon.first);
  await tester.pumpAndSettle();
}

void _verifyNextBadge(final WidgetTester tester, final WorkoutType workoutType) {
  // ensure there's only one "Next" badge
  final nextBadge = find.text("Next");
  expect(nextBadge, findsOneWidget);

  // Verify the "Next" badge is shown on the Max Sets workout card
  final maxSetsText = find.text(workoutType.name);
  expect(maxSetsText, findsOneWidget);

  final maxSetsCard = find.ancestor(
    of: maxSetsText,
    matching: find.byType(WorkoutCard),
  );
  expect(maxSetsCard, findsOneWidget);

  final maxSetsCardWithNext = find.descendant(
    of: maxSetsCard,
    matching: find.text("Next"),
  );
  expect(maxSetsCardWithNext, findsOneWidget);
}
