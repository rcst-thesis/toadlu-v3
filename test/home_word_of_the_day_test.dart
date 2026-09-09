import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudlo/features/home/presentation/widgets/home_word_of_the_day.dart';

void main() {
  testWidgets('Word of the Day toggles its local favorite state',
      (tester) async {
    final favoriteChanges = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 378,
            child: HomeWordOfTheDay(
              onFavoriteChanged: favoriteChanges.add,
            ),
          ),
        ),
      ),
    );

    final favorite = find.byKey(const Key('home-word-favorite-button'));
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

    await tester.tap(favorite);
    await tester.pump(const Duration(milliseconds: 200));
    expect(favoriteChanges, [true]);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

    await tester.tap(favorite);
    await tester.pump(const Duration(milliseconds: 200));
    expect(favoriteChanges, [true, false]);
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
  });

  testWidgets('Word of the Day requests pronunciation through its callback',
      (tester) async {
    var pronunciationRequests = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 378,
            child: HomeWordOfTheDay(
              onPronunciationRequested: () async {
                pronunciationRequests++;
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('home-word-speaker-button')));
    await tester.pump();

    expect(pronunciationRequests, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Word of the Day scales a long word down within its card',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 378,
            child: HomeWordOfTheDay(word: 'pinakamasinadyahon'),
          ),
        ),
      ),
    );

    expect(find.text('pinakamasinadyahon'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('pinakamasinadyahon'),
        matching: find.byType(FittedBox),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
