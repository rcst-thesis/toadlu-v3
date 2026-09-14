import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudlo/features/me/presentation/screens/me_screen.dart';
import 'package:tudlo/features/me/presentation/widgets/me_learner_card.dart';

void main() {
  testWidgets('Me details tab shows age/friendship/human; about tab hides it',
      (tester) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final createdAt = DateTime(2026, 8, 25);
    await tester.pumpWidget(
      MaterialApp(
        home: MeScreen(
          learnerName: 'Josh',
          grade: 2,
          userCode: '0000042',
          createdAt: createdAt,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('me-details-age-value')), findsNothing);

    await tester.tap(find.byKey(const Key('me-tab-details')));
    await tester.pumpAndSettle();

    expect(find.text('friendship'), findsOneWidget);
    expect(find.text('Abyan'), findsOneWidget);
    expect(find.text('human'), findsOneWidget);
    // "Josh" appears both as the card's name and the human value.
    expect(find.text('Josh'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('me-tab-about')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('me-details-age-value')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Me progress tab shows lesson/sticker/badge counts, honestly 0 by default',
      (tester) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(home: MeScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('me-tab-progress')));
    await tester.pumpAndSettle();

    expect(find.text('lesson finished'), findsOneWidget);
    expect(find.text('sticker earned'), findsOneWidget);
    expect(find.text('badges earned'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Me progress tab reflects non-zero counts', (tester) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MeScreen(
          lessonsFinished: 3,
          stickersEarned: 5,
          badgesEarned: 1,
          currentStreak: 7,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('me-tab-progress')));
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Me screen shows the daily streak card', (tester) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(home: MeScreen(currentStreak: 5)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('me-daily-streak-card')), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('formatAge computes elapsed days from an explicit now', () {
    final createdAt = DateTime(2026, 8, 25);
    expect(
      MeLearnerCard.formatAge(createdAt, now: DateTime(2026, 8, 25)),
      '0 days',
    );
    expect(
      MeLearnerCard.formatAge(createdAt, now: DateTime(2026, 8, 26)),
      '1 day',
    );
    expect(
      MeLearnerCard.formatAge(createdAt, now: DateTime(2026, 9, 14)),
      '20 days',
    );
  });
}
