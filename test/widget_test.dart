import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudlo/tudlo.dart';

void main() {
  testWidgets('welcome farm keeps its SVG proportions and depth interaction',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 412,
          height: 552,
          child: FarmDepthBackground(enableHardwareTilt: false),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('welcome-farm-svg')), findsOneWidget);
    expect(
      tester.widget<SvgPicture>(find.byKey(const Key('welcome-farm-svg'))).fit,
      BoxFit.contain,
    );
    expect(
      find.byKey(const Key('welcome-farm-perspective-transform')),
      findsOneWidget,
    );
    await tester.tapAt(const Offset(350, 450));
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
  });

  testWidgets('welcome upper sky drives the farm depth interaction',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeAboardScreen()));
    await tester.pump();

    final transformFinder =
        find.byKey(const Key('welcome-farm-perspective-transform'));
    final before = tester.widget<Transform>(transformFinder).transform.clone();
    final interactionSurface =
        find.byKey(const Key('welcome-depth-interaction-surface'));
    final upperLeft =
        tester.getTopLeft(interactionSurface) + const Offset(8, 8);
    final gesture = await tester.startGesture(upperLeft);
    await tester.pump();
    expect(
      tester
          .widget<FarmDepthBackground>(find.byType(FarmDepthBackground))
          .tiltTarget,
      isNot(Offset.zero),
    );
    await tester.pump(const Duration(milliseconds: 700));
    final after = tester.widget<Transform>(transformFinder).transform;

    expect(after.storage, isNot(equals(before.storage)));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);
  });

  testWidgets('startup shows both timed splashes then the menu',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StartupFlow(
          splashDuration: const Duration(seconds: 1),
          splashWarmup: () async {},
          assetWarmup: () async {},
        ),
      ),
    );
    expect(find.bySemanticsLabel('Maral MT splash screen'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.bySemanticsLabel('Tudlo splash screen'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('start new koka'), findsOneWidget);
    expect(find.text('continue'), findsOneWidget);
    expect(find.text('load'), findsOneWidget);
  });

  testWidgets('Tudlo splash waits until background preparation is ready',
      (tester) async {
    final preparation = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: StartupFlow(
          splashDuration: const Duration(milliseconds: 100),
          splashWarmup: () async {},
          assetWarmup: () => preparation.future,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.bySemanticsLabel('Tudlo splash screen'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.bySemanticsLabel('Tudlo splash screen'), findsOneWidget);

    preparation.complete();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('start new koka'), findsOneWidget);
  });

  testWidgets('main menu buttons open their screens', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainMenuScreen()));
    await tester.tap(find.text('load'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(FadeTransition), findsWidgets);
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('maayong pag balik! Load saved progress'),
      findsOneWidget,
    );
  });

  testWidgets('start new koka opens the functional name screen',
      (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: MainMenuScreen()));
    await tester.tap(find.text('start new koka'));
    await tester.pumpAndSettle();

    expect(find.byType(NameScreen), findsOneWidget);
    expect(find.byKey(const Key('name-input')), findsOneWidget);
    expect(find.byKey(const Key('name-next-button')), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);

    await tester.enterText(find.byKey(const Key('name-input')), 'Maya');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final nextButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'next'),
    );
    nextButton.onPressed!.call();
    await tester.pumpAndSettle();
    expect(find.byType(GradeSelectionScreen), findsOneWidget);
    expect(find.byKey(const Key('grade-selected-card-1')), findsOneWidget);
  });

  testWidgets('grade arrows rotate the active card and wrap around',
      (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: GradeSelectionScreen(learnerName: 'Maya')),
    );

    expect(find.byKey(const Key('grade-selected-card-1')), findsOneWidget);
    expect(find.text('Grade one kana subong?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('grade-next-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('grade-selected-card-2')), findsOneWidget);
    expect(find.text('Grade two kana subong?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('grade-next-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('grade-selected-card-3')), findsOneWidget);

    await tester.tap(find.byKey(const Key('grade-next-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('grade-selected-card-1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('grade-previous-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('grade-selected-card-3')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('grade speech bubbles expose intro and selected-grade VO',
      (tester) async {
    var introPlays = 0;
    int? spokenGrade;
    await tester.pumpWidget(
      MaterialApp(
        home: GradeSelectionScreen(
          learnerName: 'Maya',
          introVoiceOverPlayer: () async => introPlays++,
          gradeVoiceOverPlayer: (grade) async => spokenGrade = grade,
        ),
      ),
    );

    expect(
      find.text('gusto ni koka ma bal an\nsa ano nga grade kana subong'),
      findsOneWidget,
    );
    expect(
      find.text('nice to meet you, ano na imo nga\ngrade subong?'),
      findsOneWidget,
    );
    final headingBottom = tester
        .getBottomLeft(
          find.text(
            'gusto ni koka ma bal an\nsa ano nga grade kana subong',
          ),
        )
        .dy;
    final introBubbleTop =
        tester.getTopLeft(find.byKey(const Key('grade-intro-bubble'))).dy;
    expect(headingBottom, lessThan(introBubbleTop));
    await tester.tap(find.byKey(const Key('grade-intro-voice-button')));
    await tester.pumpAndSettle();
    expect(introPlays, 1);

    await tester.tap(find.byKey(const Key('grade-next-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('grade-selection-voice-button')));
    await tester.pumpAndSettle();
    expect(spokenGrade, 2);
  });

  testWidgets('only the active grade button continues', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: GradeSelectionScreen(learnerName: 'Maya')),
    );

    expect(find.text('grade 1 na ako'), findsOneWidget);
    expect(find.text('grade 2 na ako'), findsOneWidget);
    expect(find.text('grade 3 na ako'), findsOneWidget);

    await tester.tap(find.byKey(const Key('grade-selected-card-1')));
    await tester.pumpAndSettle();
    expect(find.byType(GradeSelectionScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('grade-1-select-button')));
    await tester.pumpAndSettle();
    expect(find.byType(EnergySetterScreen), findsOneWidget);
  });

  testWidgets('energy setter changes in ten-percent steps and keeps bounds',
      (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: EnergySetterScreen(learnerName: 'Maya', grade: 2),
      ),
    );

    expect(find.text('60%'), findsOneWidget);
    expect(find.byKey(const Key('energy-minus-icon')), findsOneWidget);
    expect(find.byKey(const Key('energy-instructions-image')), findsOneWidget);
    expect(find.byKey(const Key('energy-heading-image')), findsOneWidget);
    expect(find.byKey(const Key('energy-bubble-label-image')), findsOneWidget);
    final energyText = tester.widget<Text>(find.text('60%'));
    expect(energyText.style?.fontSize, 40);
    await tester.tap(find.byKey(const Key('energy-plus-button')));
    await tester.pumpAndSettle();
    expect(find.text('70%'), findsOneWidget);
    await tester.tap(find.byKey(const Key('energy-minus-button')));
    await tester.pumpAndSettle();
    expect(find.text('60%'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('energy bubble speaker invokes its VO callback', (tester) async {
    var plays = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: EnergySetterScreen(
          learnerName: 'Maya',
          grade: 1,
          voiceOverPlayer: () async => plays++,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('energy-voice-button')));
    await tester.pumpAndSettle();
    expect(plays, 1);
  });

  testWidgets('energy next opens the second loading stage', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EnergySetterScreen(learnerName: 'Maya', grade: 2),
      ),
    );

    await tester.tap(find.byKey(const Key('energy-next-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SecondLoadingScreen), findsOneWidget);
    expect(find.bySemanticsLabel('Koka second loading screen'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
  });

  testWidgets('second loading waits for minimum time and preparation',
      (tester) async {
    final preparation = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: SecondLoadingScreen(
          learnerName: 'Maya',
          grade: 3,
          energy: 70,
          minimumDisplayDuration: const Duration(milliseconds: 100),
          prepareNextStage: () => preparation.future,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byType(SecondLoadingScreen), findsOneWidget);

    preparation.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(LearnerCardScreen), findsOneWidget);
    expect(find.text('Maya'), findsOneWidget);
    expect(find.text('grade 3'), findsOneWidget);
    expect(find.bySemanticsLabel('70 percent learning energy'), findsOneWidget);
  });

  testWidgets('learner card displays the saved learner details',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LearnerCardScreen(
          learnerName: 'Maya',
          grade: 2,
          energy: 80,
          earnedBadgeCount: 2,
        ),
      ),
    );

    expect(find.byKey(const Key('learner-card')), findsOneWidget);
    expect(find.byKey(const Key('learner-card-holofoil')), findsOneWidget);
    final learnerCard = tester.widget<Container>(
      find.byKey(const Key('learner-card')),
    );
    final learnerCardDecoration = learnerCard.decoration as BoxDecoration;
    expect(
      learnerCardDecoration.boxShadow?.first.color,
      const Color(0xAAFFF176),
    );
    expect(
      find.byKey(const Key('learner-card-earned-heading')),
      findsOneWidget,
    );
    final headingWidth = tester
        .getRect(find.byKey(const Key('learner-card-earned-heading')))
        .width;
    final cardWidth =
        tester.getRect(find.byKey(const Key('learner-card'))).width;
    expect(headingWidth, lessThan(cardWidth));
    final headingBottom = tester
        .getRect(find.byKey(const Key('learner-card-earned-heading')))
        .bottom;
    final cardTop = tester.getRect(find.byKey(const Key('learner-card'))).top;
    expect(cardTop - headingBottom, greaterThan(0));
    expect(find.text("yeheyy! ara na ang learner's card mo!"), findsNothing);
    await tester.pump();
    expect(find.byKey(const Key('learner-card-header-text')), findsOneWidget);
    final raysBefore = tester
        .widget<Transform>(
          find.byKey(const Key('learner-card-rotating-rays')),
        )
        .transform;
    await tester.pump(const Duration(seconds: 1));
    final raysAfter = tester
        .widget<Transform>(
          find.byKey(const Key('learner-card-rotating-rays')),
        )
        .transform;
    expect(raysAfter, isNot(equals(raysBefore)));
    final headerLeft =
        tester.getTopLeft(find.byKey(const Key('learner-card-header-text'))).dx;
    final portraitLeft = tester
        .getTopLeft(find.byKey(const Key('learner-card-portrait-panel')))
        .dx;
    final detailsLeft = tester
        .getTopLeft(find.byKey(const Key('learner-card-details-panel')))
        .dx;
    expect(headerLeft, closeTo(portraitLeft, 0.01));
    expect(detailsLeft, closeTo(portraitLeft, 0.01));
    expect(find.text('Maya'), findsOneWidget);
    final learnerName = tester.widget<Text>(find.text('Maya'));
    expect(learnerName.style?.fontSize, 18);
    expect(learnerName.style?.fontWeight, FontWeight.w700);
    expect(find.text('grade 2'), findsOneWidget);
    expect(find.bySemanticsLabel('80 percent learning energy'), findsOneWidget);
    for (var index = 0; index < 20; index++) {
      expect(
        find.byKey(Key('learner-card-progress-segment-$index')),
        findsOneWidget,
      );
      final segment = tester.widget<DecoratedBox>(
        find.byKey(Key('learner-card-progress-segment-$index')),
      );
      final decoration = segment.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF8EA7BB));
    }
    final progressTrack = tester.getRect(
      find.byKey(const Key('learner-card-energy')),
    );
    final firstSegment = tester.getRect(
      find.byKey(const Key('learner-card-progress-segment-0')),
    );
    final lastSegment = tester.getRect(
      find.byKey(const Key('learner-card-progress-segment-19')),
    );
    final cardScale =
        tester.getRect(find.byKey(const Key('learner-card'))).width / 352;
    expect(
      firstSegment.left - progressTrack.left,
      closeTo(4 * cardScale, 0.01),
    );
    expect(
      progressTrack.right - lastSegment.right,
      closeTo(4 * cardScale, 0.01),
    );
    expect(find.text('words saved'), findsOneWidget);
    expect(find.text('stickers'), findsOneWidget);
    expect(find.text('lessons finished'), findsOneWidget);
    for (final zero in tester.widgetList<Text>(find.text('0'))) {
      expect(zero.style?.fontWeight, FontWeight.w700);
    }
    final lessonsLabel = tester.getRect(find.text('lessons finished'));
    final lessonsTile = tester.getRect(
      find
          .ancestor(
            of: find.text('lessons finished'),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(lessonsLabel.left, greaterThan(lessonsTile.left));
    expect(lessonsLabel.right, lessThan(lessonsTile.right));
    expect(find.text("learner's badges"), findsOneWidget);
    for (var index = 1; index <= 8; index++) {
      expect(find.byKey(Key('learner-badge-$index')), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'badge $index, ${index <= 2 ? 'earned' : 'locked'}',
        ),
        findsOneWidget,
      );
    }
    expect(
        find.byKey(const Key('learner-card-continue-button')), findsOneWidget);
    expect(find.text('hop. hop. hop. lets gooo'), findsOneWidget);
    expect(find.text('yeheyy!'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('learner reset requires confirmation and returns to name screen',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LearnerCardScreen(
          learnerName: 'Maya',
          grade: 2,
          energy: 80,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('learner-card-reset-button')));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const Key('learner-reset-dialog')), findsOneWidget);
    final dialog = tester.widget<Container>(
      find.byKey(const Key('learner-reset-dialog')),
    );
    final dialogDecoration = dialog.decoration as BoxDecoration;
    expect(dialogDecoration.color, const Color(0xFF98EF6F));
    expect(dialogDecoration.boxShadow?.first.color, AppColors.darkGreen);
    final resetLabel = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('learner-reset-confirm-button')),
        matching: find.text('reset'),
      ),
    );
    expect(resetLabel.style?.color, const Color(0xFFFF5260));

    await tester.tap(find.byKey(const Key('learner-reset-cancel-button')));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(LearnerCardScreen), findsOneWidget);
    expect(find.byKey(const Key('learner-reset-dialog')), findsNothing);

    await tester.tap(find.byKey(const Key('learner-card-reset-button')));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.byKey(const Key('learner-reset-confirm-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(NameScreen), findsOneWidget);
    expect(find.byKey(const Key('learner-reset-dialog')), findsNothing);
  });

  testWidgets('learner card continues through loading 3 to home',
      (tester) async {
    var welcomePrecacheCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: LearnerCardScreen(
          learnerName: 'Maya',
          grade: 2,
          energy: 80,
          precacheWelcomeVectors: (_) async {
            welcomePrecacheCalls++;
          },
        ),
      ),
    );

    // Welcome artwork must stay cold throughout boot, the main menu, and the
    // onboarding screens. Loading 3 is its sole preload boundary.
    expect(welcomePrecacheCalls, 0);
    await tester.tap(find.byKey(const Key('learner-card-continue-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(HomeLoadingScreen), findsOneWidget);
    expect(welcomePrecacheCalls, 1);
    expect(find.byType(LearnerCardScreen), findsNothing);
    expect(
      find.bySemanticsLabel('Koka third loading screen'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('hopping in...'), findsOneWidget);
    expect(find.byKey(const Key('home-loading-koka')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('home-loading-artwork-frame'))).width,
      104,
    );
    await tester.pump(const Duration(milliseconds: 2150));
    await tester.pump();
    expect(find.bySemanticsLabel('packing lessons...'), findsOneWidget);
    for (var frame = 0; frame < 140; frame++) {
      await tester.pump(const Duration(microseconds: 16667));
      expect(tester.takeException(), isNull);
    }
    expect(
      Navigator.of(tester.element(find.byType(HomeLoadingScreen))).canPop(),
      isFalse,
    );

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(WelcomeAboardScreen), findsOneWidget);
    expect(find.byKey(const Key('welcome-aboard-heading')), findsOneWidget);
    expect(find.byKey(const Key('welcome-farm-svg')), findsOneWidget);
    final welcomeFarmSize =
        tester.getSize(find.byKey(const Key('welcome-farm-frame')));
    expect(
      welcomeFarmSize.width / welcomeFarmSize.height,
      closeTo(535 / 552, 0.001),
    );
    expect(
      tester
          .widget<FarmDepthBackground>(find.byType(FarmDepthBackground))
          .enableHardwareTilt,
      isFalse,
    );
    expect(find.byKey(const Key('welcome-aboard-next-button')), findsOneWidget);
    expect(find.byKey(const Key('welcome-aboard-skip-button')), findsOneWidget);
    expect(find.byType(AdaptiveBackButtonPlacement), findsNothing);
  });

  testWidgets('learner card tilts toward a tapped corner and rebalances',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: false),
          child: LearnerCardScreen(
            learnerName: 'Maya',
            grade: 1,
            energy: 60,
          ),
        ),
      ),
    );
    await tester.pump();

    final tiltTarget = tester.widget<Listener>(
      find.byKey(const Key('learner-card-tilt-target')),
    );
    expect(tiltTarget.onPointerDown, isNotNull);
    expect(
        find.byKey(const Key('learner-card-tilt-transform')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byType(LearnerCardScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back buttons use the main-menu two-axis dynamic scale',
      (tester) async {
    const portraitSizes = [Size(320, 480), Size(412, 917), Size(800, 1200)];

    Rect paintedRect(Finder finder) {
      final box = tester.renderObject<RenderBox>(finder);
      final origin = box.localToGlobal(Offset.zero);
      final right = box.localToGlobal(Offset(box.size.width, 0));
      final bottom = box.localToGlobal(Offset(0, box.size.height));
      return Rect.fromLTWH(
        origin.dx,
        origin.dy,
        (right - origin).distance,
        (bottom - origin).distance,
      );
    }

    for (final size in portraitSizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(const MaterialApp(home: NameScreen()));
      await tester.pumpAndSettle();
      final nameBack = paintedRect(
        find.byKey(const Key('load-back-button')),
      );

      await tester.pumpWidget(const MaterialApp(home: LoadScreen()));
      await tester.pumpAndSettle();
      final loadBack = paintedRect(
        find.byKey(const Key('load-back-button')),
      );

      final expectedScale = (size.width / 412) < (size.height / 917)
          ? size.width / 412
          : size.height / 917;

      expect(loadBack.width, closeTo(nameBack.width, 0.01));
      expect(loadBack.height, closeTo(nameBack.height, 0.01));
      expect(loadBack.width, closeTo(93 * expectedScale, 0.01));
      expect(loadBack.height, closeTo(44 * expectedScale, 0.01));
      expect(loadBack.left, closeTo(nameBack.left, 0.01));
      expect(loadBack.top, closeTo(nameBack.top, 0.01));
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('name speech bubble exposes a working voice-over control',
      (tester) async {
    var playCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: NameScreen(
          voiceOverPlayer: () async => playCount++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('gusto ni koka ma bal an'), findsOneWidget);
    expect(find.textContaining('hey, hey, hey! abyan'), findsOneWidget);
    await tester.tap(find.byKey(const Key('name-voice-over-button')));
    await tester.pumpAndSettle();
    expect(playCount, 1);
  });

  testWidgets('load cards keep two columns and horizontal button labels',
      (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LoadScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.byType(SaveCard), findsNWidgets(4));
    expect(find.text('load'), findsNWidgets(4));
    expect(find.text('delete'), findsNWidgets(4));
    expect(find.byKey(const Key('load-pagination')), findsOneWidget);

    final cards = find.byType(SaveCard);
    final firstCard = tester.getRect(cards.at(0));
    expect(firstCard.size, const Size(168, 193));
    expect(firstCard.left, 26);
    expect(firstCard.top, closeTo(323, 1));

    final backSize = tester.getSize(find.byKey(const Key('load-back-button')));
    final previousSize =
        tester.getSize(find.byKey(const Key('load-previous-button')));
    final nextSize = tester.getSize(find.byKey(const Key('load-next-button')));
    expect(backSize, const Size(93, 44));
    expect(previousSize, backSize);
    expect(nextSize, backSize);
    final previousRect =
        tester.getRect(find.byKey(const Key('load-previous-button')));
    final pageRect = tester.getRect(find.byKey(const Key('load-page-number')));
    final nextRect = tester.getRect(find.byKey(const Key('load-next-button')));
    expect(pageRect.left - previousRect.right, closeTo(20, 0.01));
    expect(nextRect.left - pageRect.right, closeTo(20, 0.01));

    final backTop =
        tester.getTopLeft(find.byKey(const Key('load-back-button'))).dy;
    final headerTop =
        tester.getTopLeft(find.byKey(const Key('load-header-image'))).dy;
    final canvasBottom =
        tester.getBottomLeft(find.byKey(const Key('load-page-canvas'))).dy;
    final canvasLeft =
        tester.getTopLeft(find.byKey(const Key('load-page-canvas'))).dx;
    expect(headerTop, greaterThan(backTop));
    expect(canvasLeft, greaterThanOrEqualTo(0));
    expect(canvasBottom, lessThanOrEqualTo(tester.view.physicalSize.height));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pagination shows four saves then three top-left aligned saves',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoadScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(SaveCard), findsNWidgets(4));
    expect(find.text('Koka 5'), findsNothing);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('load-next-button')));
    await tester.pumpAndSettle();

    expect(find.byType(SaveCard), findsNWidgets(3));
    expect(find.text('Koka 5'), findsOneWidget);
    expect(find.text('Koka 7'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    final secondPageCards = find.byType(SaveCard);
    final first = tester.getRect(secondPageCards.at(0));
    final second = tester.getRect(secondPageCards.at(1));
    final third = tester.getRect(secondPageCards.at(2));
    expect(second.width, closeTo(first.width, 0.01));
    expect(second.height, closeTo(first.height, 0.01));
    expect(third.width, closeTo(first.width, 0.01));
    expect(third.height, closeTo(first.height, 0.01));
    expect(third.left, closeTo(first.left, 0.01));
    expect(third.top, greaterThan(first.top));

    await tester.tap(find.byKey(const Key('load-previous-button')));
    await tester.pumpAndSettle();

    expect(find.text('Koka 5'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('load and delete confirmations match the reference geometry',
      (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LoadScreen()));
    await tester.tap(find.text('load').first);
    await tester.pumpAndSettle();

    expect(find.text('do you want to load\nthis one?'), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const Key('load-confirmation-panel'))),
      const Rect.fromLTWH(62, 299, 289, 367),
    );
    expect(
      tester.getSize(find.byKey(const Key('confirmation-no-button'))),
      const Size(92, 54),
    );
    expect(
      tester.getSize(find.byKey(const Key('confirmation-yes-button'))),
      const Size(92, 54),
    );

    await tester.tap(find.byKey(const Key('confirmation-no-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('delete').first);
    await tester.pumpAndSettle();

    expect(find.text('are you sure to\ndelete this one?'), findsOneWidget);
    final yesText = tester.widget<Text>(find.text('yes'));
    expect(yesText.style?.color, const Color(0xFFF13B4B));
    expect(tester.takeException(), isNull);
  });

  testWidgets('all screens avoid overflow across portrait sizes',
      (tester) async {
    const portraitSizes = [
      Size(320, 480),
      Size(360, 640),
      Size(412, 917),
      Size(800, 1200),
    ];

    for (final size in portraitSizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(const MaterialApp(home: MainMenuScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Main menu at $size');

      await tester.pumpWidget(const MaterialApp(home: LoadScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Load screen at $size');
      if (size == const Size(800, 1200)) {
        final tabletCard =
            tester.renderObject<RenderBox>(find.byType(SaveCard).first);
        final cardOrigin = tabletCard.localToGlobal(Offset.zero);
        final cardRight =
            tabletCard.localToGlobal(Offset(tabletCard.size.width, 0));
        final cardBottom =
            tabletCard.localToGlobal(Offset(0, tabletCard.size.height));
        final paintedCardWidth = (cardRight - cardOrigin).distance;
        final paintedCardHeight = (cardBottom - cardOrigin).distance;
        final tabletMascot =
            tester.getRect(find.byKey(const Key('load-header-image')));
        expect(paintedCardWidth, greaterThan(168));
        expect(paintedCardHeight, greaterThan(193));
        expect(tabletMascot.top, lessThan(200));
        expect(cardOrigin.dy, lessThan(500));
      }

      await tester.pumpWidget(
        const MaterialApp(
          home: PlaceholderScreen(
            title: 'Responsive test',
            description:
                'A deliberately longer description used to verify responsive text and layout behavior.',
            icon: Icons.phone_android,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Placeholder at $size');

      await tester.pumpWidget(
        const MaterialApp(
          home: GradeSelectionScreen(learnerName: 'A longer learner name'),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Grade selector at $size');

      await tester.pumpWidget(
        const MaterialApp(
          home: EnergySetterScreen(
            learnerName: 'A longer learner name',
            grade: 3,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Energy setter at $size');
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
