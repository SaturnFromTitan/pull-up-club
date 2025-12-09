import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:pull_up_club/common/providers/navigation_provider.dart";
import "package:pull_up_club/domain/models.dart";
import "package:pull_up_club/features/workout/screens/selection_screen.dart";

Future<void> navigateTo(final WidgetTester tester, final AppTab tab) async {
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

void verifyNextBadge(final WidgetTester tester, final WorkoutType workoutType) {
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

Future<void> enterRepsAndWaitRest(
  final WidgetTester tester, {
  required final int reps,
}) async {
  await _enterReps(tester, reps: reps);
  await tester.pumpAndSettle();
}

Future<void> enterRepsAndSkipRest(
  final WidgetTester tester, {
  required final int reps,
}) async {
  await _enterReps(tester, reps: reps);
  // skip rest via button
  await tester.pump(const Duration(milliseconds: 1_000));
  final skipRestButton = find.text("Skip Rest");
  expect(skipRestButton, findsOneWidget);
  await tester.tap(skipRestButton);
  await tester.pumpAndSettle();
}

Future<void> enterRepsToFinishWorkout(
  final WidgetTester tester, {
  required final int reps,
}) async {
  await _enterReps(tester, reps: reps);
  // can't use pumpAndSettle because the success screen has an endless animation
  // fyi if we don't wait long enough, then the test crashes
  await tester.pump(const Duration(milliseconds: 1_000));
}

Future<void> _enterReps(final WidgetTester tester, {required final int reps}) async {
  final textField = find.byType(TextFormField);
  expect(textField, findsOneWidget);
  await tester.enterText(textField, reps.toString());
  await tester.pumpAndSettle();

  final submitButton = find.text("Submit");
  expect(submitButton, findsOneWidget);
  await tester.tap(submitButton);
}

Future<void> deleteWorkout(
  final WidgetTester tester, {
  required final FinderBase<Element> dismissible,
}) async {
  // Perform a swipe gesture from right to left (endToStart direction)
  // Start from the right edge and drag to the left
  final center = tester.getCenter(dismissible);
  final startX = center.dx + 100; // Start from right side
  final endX = center.dx - 200; // Drag to the left

  // Perform the swipe gesture
  await tester.drag(dismissible, Offset(endX - startX, 0));
  await tester.pumpAndSettle();

  // A confirmation dialog should appear
  expect(find.text("Delete Workout"), findsOneWidget);
  expect(find.text("Are you sure you want to delete this workout?"), findsOneWidget);

  // Tap the "Delete" button to confirm
  final deleteButton = find.text("Delete");
  expect(deleteButton, findsOneWidget);
  await tester.tap(deleteButton);
  // fyi if we don't wait long enough, then the test crashes
  await tester.pump(const Duration(milliseconds: 1_000));
  await tester.pumpAndSettle();
}
