import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudlo/tudlo.dart';

void main() {
  testWidgets('Home content scrolls while bottom navigation remains fixed',
      (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    final navigation = find.byKey(const Key('home-bottom-navigation'));
    final navigationBefore = tester.getRect(navigation);
    final settings = find.byKey(const Key('home-settings-button'));
    final settingsBefore = tester.getRect(settings);
    final energy = find.byKey(const Key('home-energy-indicator'));
    final energyBefore = tester.getRect(energy);
    final lamp = find.byKey(const Key('home-lamp-button'));
    final lampBefore = tester.getRect(lamp);
    final window = find.byKey(const Key('home-animated-window'));
    final windowBefore = tester.getRect(window);
    final contentTopBefore =
        tester.getTopLeft(find.byKey(const Key('home-content-top'))).dy;

    await tester.drag(
      find.byKey(const Key('home-content-scroll-view')),
      const Offset(0, -500),
    );
    await tester.pump();

    expect(tester.getRect(navigation), navigationBefore);
    expect(tester.getRect(settings), settingsBefore);
    expect(tester.getRect(energy), energyBefore);
    expect(tester.getRect(lamp).top, lessThan(lampBefore.top));
    expect(tester.getRect(window).top, lessThan(windowBefore.top));
    expect(
      tester.getTopLeft(find.byKey(const Key('home-content-top'))).dy,
      lessThan(contentTopBefore),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home upper navigation materializes as the floor is reached',
      (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    final navigationBar = find.byKey(const Key('home-upper-navigation-bar'));
    expect(tester.widget<Opacity>(navigationBar).opacity, 0);

    await tester.drag(
      find.byKey(const Key('home-content-scroll-view')),
      const Offset(0, -500),
    );
    await tester.pump();

    final revealedOpacity = tester.widget<Opacity>(navigationBar).opacity;
    expect(revealedOpacity, greaterThan(0));
    expect(revealedOpacity, lessThan(.85));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home shell avoids overflow on phone and tablet sizes',
      (tester) async {
    for (final size in const [
      Size(320, 480),
      Size(412, 917),
      Size(800, 1200),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'Home shell at $size');
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('Home window uses the 412-wide Figma placement', (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    final window = find.byKey(const Key('home-animated-window'));
    expect(tester.getSize(window), const Size.square(128));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home bookshelf uses the 412-wide Figma placement',
      (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    final bookshelf = find.byKey(const Key('home-bookshelf'));
    expect(tester.getSize(bookshelf), const Size(160, 37));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home standing lamp uses the chained Figma size', (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    final lamp = find.byKey(const Key('home-standing-lamp'));
    expect(tester.getSize(lamp), const Size(36.25, 126));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home drawer uses the chained Figma size', (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    final drawer = find.byKey(const Key('home-drawer'));
    expect(tester.getSize(drawer), const Size(52, 41));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home couch uses the chained Figma size', (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    final couch = find.byKey(const Key('home-couch'));
    expect(tester.getSize(couch), const Size(152, 79));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home lily mat uses the chained Figma size', (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    final lilyMat = find.byKey(const Key('home-lily-mat'));
    expect(tester.getSize(lilyMat), const Size(361, 88));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home Word of the Day uses the chained Figma size',
      (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    final card = find.byKey(const Key('home-word-of-the-day'));
    expect(tester.getSize(card), const Size(378, 216));
    expect(find.text('word of the day'), findsOneWidget);
    expect(find.text('balay'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home content footer closes the scrolling scene', (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    final footer = find.byKey(const Key('home-content-footer'));
    expect(tester.getSize(footer), const Size(412, 48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home footer meets the fixed navigation without a gap',
      (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();
    await tester.drag(
      find.byKey(const Key('home-content-scroll-view')),
      const Offset(0, -2000),
    );
    await tester.pump();

    final footer = tester.getRect(find.byKey(const Key('home-content-footer')));
    final navigation =
        tester.getRect(find.byKey(const Key('home-bottom-navigation')));
    expect(footer.bottom, moreOrLessEquals(navigation.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home room surfaces keep the cream border behind the floor',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    final creamWall = tester.widget<ColoredBox>(
      find.byKey(const Key('home-cream-wall')),
    );
    final floor = tester.widget<ColoredBox>(
      find.byKey(const Key('home-floor')),
    );
    expect(creamWall.color, const Color(0xFFFBF3E4));
    expect(floor.color, const Color(0xFFB88956));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home settings button opens the existing Settings destination',
      (tester) async {
    final animationController = AppAnimationController();
    await tester.pumpWidget(
      AppAnimationScope(
        controller: animationController,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    final settingsButton = find.byKey(const Key('home-settings-button'));
    expect(settingsButton, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(settingsButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('animations'), findsOneWidget);
    expect(find.byKey(const Key('settings-animation-switch')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings animation switch controls app-wide motion',
      (tester) async {
    final animationController = AppAnimationController();
    await tester.pumpWidget(
      AppAnimationScope(
        controller: animationController,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.tap(find.byKey(const Key('settings-animation-switch')));
    await tester.pump();

    expect(animationController.isEnabled, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home door opens the temporary Map destination', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    expect(find.byKey(const Key('home-door')), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-door-button')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Temporary Map shell'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home bookshelf books open the temporary Lessons destination',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    await tester.tap(find.byKey(const Key('home-bookshelf-books-button')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Temporary Lessons shell'), findsOneWidget);
    final lessonsTile = tester.widget<Material>(
      find.byKey(const Key('home-nav-tile-lessons')),
    );
    expect(lessonsTile.color, const Color(0xFF966E42));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home Map navigation opens the selected Map placeholder',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    await tester.tap(find.byKey(const Key('home-nav-map')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Temporary Map shell'), findsOneWidget);
    expect(find.byKey(const Key('home-bottom-navigation')), findsOneWidget);
    final mapTile = tester.widget<Material>(
      find.byKey(const Key('home-nav-tile-map')),
    );
    expect(mapTile.color, const Color(0xFF966E42));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home navigation tabs do not stack Lessons behind Map',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    await tester.tap(find.byKey(const Key('home-nav-lessons')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Temporary Lessons shell'), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-nav-map')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Temporary Map shell'), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-nav-home')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('home-screen')), findsOneWidget);
    expect(find.text('Temporary Lessons shell'), findsNothing);
    expect(find.text('Temporary Map shell'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home door repeats a short exploration hint', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump(const Duration(milliseconds: 400));

    final nudge = tester.widget<Transform>(
      find.byKey(const Key('home-door-hint-nudge')),
    );
    expect(nudge.transform.storage[12], 0);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      tester
          .widget<Transform>(find.byKey(const Key('home-door-hint-nudge')))
          .transform
          .storage[12]
          .abs(),
      greaterThan(0),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('explore!'), findsOneWidget);
    expect(find.byKey(const Key('home-door-hint-phrase')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home energy indicator uses a Flutter percentage label',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.byKey(const Key('home-energy-indicator')), findsOneWidget);
    expect(find.byKey(const Key('home-energy-label')), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home lamp toggles its light effect', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    final lamp = find.byKey(const Key('home-lamp-button'));
    final lightEffect = find.byKey(const Key('home-lamp-light-effect'));
    expect(lamp, findsOneWidget);
    expect(tester.widget<AnimatedOpacity>(lightEffect).opacity, 0);

    await tester.tap(lamp);
    await tester.pump();

    expect(tester.widget<AnimatedOpacity>(lightEffect).opacity, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home navigation shows six tappable items with Home selected',
      (tester) async {
    var tappedIndex = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: HomeBottomNavigation(
            onItemTapped: (index) => tappedIndex = index,
          ),
        ),
      ),
    );
    await tester.pump();

    for (final label in const [
      'home',
      'translate',
      'lessons',
      'map',
      'dictionary',
      'me',
    ]) {
      expect(find.byKey(Key('home-nav-$label')), findsOneWidget);
    }

    final labelSizes = <double?>{
      for (final label in const [
        'home',
        'translate',
        'lessons',
        'map',
        'dictionary',
        'me',
      ])
        tester
            .widget<Text>(find.byKey(Key('home-nav-label-$label')))
            .style
            ?.fontSize,
    };
    expect(labelSizes, hasLength(1));

    await tester.tap(find.byKey(const Key('home-nav-map')));
    expect(tappedIndex, 3);
    expect(tester.takeException(), isNull);
  });
}
