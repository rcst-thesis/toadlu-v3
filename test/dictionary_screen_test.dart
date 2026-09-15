import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tudlo/core/navigation/app_bottom_tab_navigation.dart';
import 'package:tudlo/features/dictionary/domain/dictionary_entry.dart';
import 'package:tudlo/features/dictionary/presentation/screens/dictionary_browse_screen.dart';
import 'package:tudlo/features/dictionary/presentation/screens/dictionary_screen.dart';
import 'package:tudlo/features/dictionary/presentation/widgets/dictionary_bento_grid.dart';
import 'package:tudlo/features/dictionary/presentation/widgets/dictionary_heart_icon.dart';
import 'package:tudlo/features/dictionary/presentation/widgets/dictionary_lookup_page.dart';
import 'package:tudlo/features/learner/domain/learner_scope.dart';

Future<LearnerController> _controllerWithProfile() async {
  final controller = LearnerController();
  await controller.createAndSave(name: 'Josh', grade: 2, energy: 60);
  return controller;
}

Widget _wrap(Widget child, LearnerController controller) {
  return MaterialApp(
    home: LearnerScope(controller: controller, child: child),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> setLargeViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
      'Dictionary screen renders header, search, word card, and favorites',
      (tester) async {
    await setLargeViewport(tester);
    final controller = await _controllerWithProfile();
    await tester.pumpWidget(_wrap(const DictionaryScreen(), controller));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dictionary-header')), findsOneWidget);
    expect(find.byKey(const Key('dictionary-search-field')), findsOneWidget);
    expect(find.byKey(const Key('dictionary-word-card')), findsOneWidget);
    expect(find.text('my favorites'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dictionary bottom nav renders at index 4', (tester) async {
    await setLargeViewport(tester);
    final controller = await _controllerWithProfile();
    await tester.pumpWidget(_wrap(const DictionaryScreen(), controller));
    await tester.pumpAndSettle();

    final nav = tester.widget<AppBottomTabNavigation>(
      find.byType(AppBottomTabNavigation),
    );
    expect(nav.currentIndex, 4);
  });

  testWidgets(
      'Main screen search bar is a decoy -- typing does nothing, tapping it opens the browse screen',
      (tester) async {
    await setLargeViewport(tester);
    final controller = await _controllerWithProfile();
    await tester.pumpWidget(_wrap(const DictionaryScreen(), controller));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('dictionary-search-field')),
      'ido',
    );
    await tester.pumpAndSettle();
    // readOnly: typed text never lands in the field.
    final field = tester.widget<TextField>(
      find.byKey(const Key('dictionary-search-field')),
    );
    expect(field.controller, isNull);

    await tester.tap(find.byKey(const Key('dictionary-search-bar-tap')));
    await tester.pumpAndSettle();

    expect(find.byType(DictionaryBrowseScreen), findsOneWidget);
  });

  testWidgets('Tapping the word-of-the-day card flips to the back face',
      (tester) async {
    await setLargeViewport(tester);
    final controller = await _controllerWithProfile();
    await tester.pumpWidget(_wrap(const DictionaryScreen(), controller));
    await tester.pumpAndSettle();

    expect(find.text('naga istar ako sa akon balay'), findsNothing);

    await tester.tap(find.byKey(const Key('dictionary-word-card')));
    await tester.pumpAndSettle();

    expect(find.text('naga istar ako sa akon balay'), findsOneWidget);
  });

  testWidgets(
      'Favoriting the word-of-the-day toggles the heart and persists on the learner',
      (tester) async {
    await setLargeViewport(tester);
    final controller = await _controllerWithProfile();
    await tester.pumpWidget(_wrap(const DictionaryScreen(), controller));
    await tester.pumpAndSettle();

    // Flip to the back face where the favorite button lives.
    await tester.tap(find.byKey(const Key('dictionary-word-card')));
    await tester.pumpAndSettle();

    expect(controller.profile!.favoritedWords, isEmpty);
    expect(
      tester
          .widget<DictionaryHeartIcon>(find.byType(DictionaryHeartIcon))
          .favorited,
      isFalse,
    );

    await tester.tap(
      find.byKey(const Key('dictionary-word-favorite-button')),
    );
    await tester.pumpAndSettle();

    expect(controller.profile!.favoritedWords, contains('balay'));
    expect(
      tester
          .widget<DictionaryHeartIcon>(find.byType(DictionaryHeartIcon))
          .favorited,
      isTrue,
    );
  });

  testWidgets(
      'Browse screen shows a featured bento tile and a catalog card for every word',
      (tester) async {
    await setLargeViewport(tester);
    final controller = await _controllerWithProfile();
    await tester.pumpWidget(_wrap(const DictionaryScreen(), controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dictionary-search-bar-tap')));
    await tester.pumpAndSettle();

    expect(find.byType(DictionaryBrowseScreen), findsOneWidget);
    expect(
        find.byKey(const Key('dictionary-bento-tile-balay')), findsOneWidget);
    expect(
      find.byKey(const Key('dictionary-catalog-card-ido')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('dictionary-catalog-card-balay')),
      findsOneWidget,
    );
  });

  testWidgets(
      'Selecting a word in the browse screen shows its card inline, without leaving the screen',
      (tester) async {
    await setLargeViewport(tester);
    final controller = await _controllerWithProfile();
    await tester.pumpWidget(_wrap(const DictionaryScreen(), controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dictionary-search-bar-tap')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dictionary-catalog-card-ido')));
    await tester.pumpAndSettle();

    // Still the browse screen -- just showing the selected word's plain
    // lookup page now, not the flip card.
    expect(find.byType(DictionaryBrowseScreen), findsOneWidget);
    expect(find.byType(DictionaryLookupPage), findsOneWidget);
    expect(find.byKey(const Key('dictionary-browse-list')), findsNothing);
  });

  testWidgets(
      'Typing in the browse screen\'s own search bar filters the catalog',
      (tester) async {
    await setLargeViewport(tester);
    final controller = await _controllerWithProfile();
    await tester.pumpWidget(_wrap(const DictionaryScreen(), controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dictionary-search-bar-tap')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('dictionary-browse-search-field')),
      'ido',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('dictionary-catalog-card-ido')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('dictionary-catalog-card-balay')),
      findsNothing,
    );
    // Featured section hides while actively searching.
    expect(find.byType(DictionaryBentoGrid), findsNothing);
  });

  testWidgets(
      'Searching a term that only appears in a definition still finds that word',
      (tester) async {
    await setLargeViewport(tester);
    final controller = await _controllerWithProfile();
    await tester.pumpWidget(_wrap(const DictionaryScreen(), controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dictionary-search-bar-tap')));
    await tester.pumpAndSettle();

    // "tawo" (person) appears in balay's definition but isn't a word
    // itself.
    await tester.enterText(
      find.byKey(const Key('dictionary-browse-search-field')),
      'tawo',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('dictionary-catalog-card-balay')),
      findsOneWidget,
    );
  });

  testWidgets('Category chip narrows the catalog to that category',
      (tester) async {
    await setLargeViewport(tester);
    final controller = await _controllerWithProfile();
    await tester.pumpWidget(_wrap(const DictionaryScreen(), controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dictionary-search-bar-tap')));
    await tester.pumpAndSettle();

    // "animals" is within the chip row's initial scroll viewport; "food"
    // contains kan-on/tinapay, not ido.
    await tester.tap(
      find.byKey(const Key('dictionary-category-chip-animals')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('dictionary-catalog-card-ido')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('dictionary-catalog-card-balay')),
      findsNothing,
    );
  });

  testWidgets('Browse screen also shows the bottom nav at index 4',
      (tester) async {
    await setLargeViewport(tester);
    final controller = await _controllerWithProfile();
    await tester.pumpWidget(_wrap(const DictionaryScreen(), controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dictionary-search-bar-tap')));
    await tester.pumpAndSettle();

    final navs = tester.widgetList<AppBottomTabNavigation>(
      find.byType(AppBottomTabNavigation),
    );
    expect(navs, isNotEmpty);
    expect(navs.every((nav) => nav.currentIndex == 4), isTrue);
  });

  testWidgets(
      'Back pill returns to the catalog from a word\'s detail, then exits the browse screen',
      (tester) async {
    await setLargeViewport(tester);
    final controller = await _controllerWithProfile();
    await tester.pumpWidget(_wrap(const DictionaryScreen(), controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dictionary-search-bar-tap')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dictionary-catalog-card-ido')));
    await tester.pumpAndSettle();
    expect(find.byType(DictionaryLookupPage), findsOneWidget);

    await tester.tap(find.byKey(const Key('dictionary-browse-back-pill')));
    await tester.pumpAndSettle();
    expect(find.byType(DictionaryLookupPage), findsNothing);
    expect(find.byKey(const Key('dictionary-browse-list')), findsOneWidget);

    await tester.tap(find.byKey(const Key('dictionary-browse-back-pill')));
    await tester.pumpAndSettle();
    expect(find.byType(DictionaryBrowseScreen), findsNothing);
  });

  testWidgets('Back pill and search bar are the same height', (tester) async {
    await setLargeViewport(tester);
    final controller = await _controllerWithProfile();
    await tester.pumpWidget(_wrap(const DictionaryScreen(), controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dictionary-search-bar-tap')));
    await tester.pumpAndSettle();

    final backPillHeight = tester
        .getSize(find.byKey(const Key('dictionary-browse-back-pill')))
        .height;
    final searchFieldHeight = tester
        .getSize(find.byKey(const Key('dictionary-browse-search-field')))
        .height;
    expect(backPillHeight, closeTo(searchFieldHeight, 0.5));
  });

  testWidgets(
      'Bento tray pads missing featured entries with blank compartments',
      (tester) async {
    await setLargeViewport(tester);
    final controller = await _controllerWithProfile();
    const entries = [
      DictionaryEntry(
        id: 'solo',
        word: 'solo',
        phonetic: '/so-lo/',
        definition: 'n. test entry.',
        example: 'test',
        imageAsset: 'assets/images/home_sticker_house.png',
        category: 'test',
        featured: true,
      ),
    ];
    await tester.pumpWidget(
      _wrap(const DictionaryBrowseScreen(entries: entries), controller),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('dictionary-bento-tile-solo')),
      findsOneWidget,
    );
    // 5 slots total, only 1 real (tappable) entry -- the other 4 are
    // blank, non-interactive compartments (no InkWell).
    expect(
      find.descendant(
        of: find.byType(DictionaryBentoGrid),
        matching: find.byType(InkWell),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'Letter index is collapsible: tapping a letter expands it, tapping again collapses it',
      (tester) async {
    await setLargeViewport(tester);
    final controller = await _controllerWithProfile();
    await tester.pumpWidget(_wrap(const DictionaryScreen(), controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dictionary-search-bar-tap')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dictionary-letter-panel')), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const Key('dictionary-letter-chip-B')),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('dictionary-browse-scroll-view')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const Key('dictionary-letter-chip-B')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dictionary-letter-panel')), findsOneWidget);
    expect(
      find.byKey(const Key('dictionary-letter-entry-balay')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('dictionary-letter-chip-B')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dictionary-letter-panel')), findsNothing);
  });

  testWidgets(
      'Tapping a word in "my favorites" opens straight to its definition page',
      (tester) async {
    await setLargeViewport(tester);
    final controller = await _controllerWithProfile();
    await tester.pumpWidget(_wrap(const DictionaryScreen(), controller));
    await tester.pumpAndSettle();

    // Favorite "balay" via the word-of-the-day card.
    await tester.tap(find.byKey(const Key('dictionary-word-card')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('dictionary-word-favorite-button')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dictionary-favorite-tile-balay')));
    await tester.pumpAndSettle();

    expect(find.byType(DictionaryBrowseScreen), findsOneWidget);
    expect(find.byType(DictionaryLookupPage), findsOneWidget);
    expect(find.byKey(const Key('dictionary-browse-list')), findsNothing);
  });
}
