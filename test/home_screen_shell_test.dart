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

  testWidgets('Home settings button opens the existing Settings destination',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    final settingsButton = find.byKey(const Key('home-settings-button'));
    expect(settingsButton, findsOneWidget);

    await tester.tap(settingsButton);
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Settings screen placeholder'), findsOneWidget);
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
