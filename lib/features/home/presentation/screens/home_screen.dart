import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tudlo/core/navigation/fade_page_route.dart';
import 'package:tudlo/features/home/presentation/widgets/animated_home_window.dart';
import 'package:tudlo/features/home/presentation/widgets/home_bottom_navigation.dart';
import 'package:tudlo/features/home/presentation/widgets/home_bookshelf.dart';
import 'package:tudlo/features/home/presentation/widgets/home_couch.dart';
import 'package:tudlo/features/home/presentation/widgets/home_content_footer.dart';
import 'package:tudlo/features/home/presentation/widgets/home_door.dart';
import 'package:tudlo/features/home/presentation/widgets/home_drawer.dart';
import 'package:tudlo/features/home/presentation/widgets/home_energy_indicator.dart';
import 'package:tudlo/features/home/presentation/widgets/home_lily_mat.dart';
import 'package:tudlo/features/home/presentation/widgets/home_koka_mascot.dart';
import 'package:tudlo/features/home/presentation/widgets/home_settings_button.dart';
import 'package:tudlo/features/home/presentation/widgets/home_standing_lamp.dart';
import 'package:tudlo/features/home/presentation/widgets/home_word_of_the_day.dart';
import 'package:tudlo/features/home/presentation/widgets/interactive_home_lamp.dart';
import 'package:tudlo/features/placeholder/presentation/placeholder_screen.dart';
import 'package:tudlo/features/settings/presentation/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({this.learnerName = '', super.key});

  final String learnerName;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _upperNavigationMaxOpacity = .84;
  static const _upperNavigationRevealStartFraction = .45;

  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      FadePageRoute<void>(
        page: const SettingsScreen(),
      ),
    );
  }

  void _openMap(BuildContext context, {bool replaceCurrent = false}) {
    final route = FadePageRoute<void>(
      page: PlaceholderScreen(
        title: 'Map',
        description: 'Temporary Map shell',
        icon: Icons.map_rounded,
        bottomNavigationBar: HomeBottomNavigation(
          selectedIndex: 3,
          onItemTapped: (index) {
            if (index == 0) _openHome(context);
            if (index == 2) _openLessons(context, replaceCurrent: true);
          },
        ),
      ),
    );
    if (replaceCurrent) {
      Navigator.of(context).pushReplacement<void, void>(route);
    } else {
      Navigator.of(context).push(route);
    }
  }

  void _openLessons(BuildContext context, {bool replaceCurrent = false}) {
    final route = FadePageRoute<void>(
      page: PlaceholderScreen(
        title: 'Lessons',
        description: 'Temporary Lessons shell',
        icon: Icons.menu_book_rounded,
        bottomNavigationBar: HomeBottomNavigation(
          selectedIndex: 2,
          onItemTapped: (index) {
            if (index == 0) _openHome(context);
            if (index == 3) _openMap(context, replaceCurrent: true);
          },
        ),
      ),
    );
    if (replaceCurrent) {
      Navigator.of(context).pushReplacement<void, void>(route);
    } else {
      Navigator.of(context).push(route);
    }
  }

  void _openHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('home-screen'),
      backgroundColor: const Color(0xFFEADF99),
      bottomNavigationBar: HomeBottomNavigation(
        onItemTapped: (index) {
          if (index == 2) _openLessons(context);
          if (index == 3) _openMap(context);
        },
      ),
      body: LayoutBuilder(
              builder: (context, viewport) {
                final canvasWidth = math.min(viewport.maxWidth, 720.0);
                final canvasSideInset = (viewport.maxWidth - canvasWidth) / 2;
                final topControlScale = (canvasWidth / 460).clamp(.82, 1.12);
                final sceneScale = canvasWidth / _HomeSceneLayout.designWidth;
                final contentEndSceneHeight =
                    _HomeSceneLayout.footerBottom * sceneScale;
                final minimumScrollableSceneHeight = viewport.maxHeight * 1.5;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: SingleChildScrollView(
                        key: const Key('home-content-scroll-view'),
                        controller: _scrollController,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 720),
                            child: SizedBox(
                              height: math.max(
                                minimumScrollableSceneHeight,
                                contentEndSceneHeight,
                              ),
                              width: double.infinity,
                              child: LayoutBuilder(
                                builder: (context, scene) {
                                  final sceneScale = scene.maxWidth /
                                      _HomeSceneLayout.designWidth;
                                  return Stack(
                                    children: [
                                      const Positioned.fill(
                                        child: _HomeWallBackground(),
                                      ),
                                      Positioned(
                                        top: _HomeSceneLayout
                                                .creamFloorBorderTop *
                                            sceneScale,
                                        left: 0,
                                        right: 0,
                                        bottom: 0,
                                        child: const ColoredBox(
                                          key: Key('home-cream-wall'),
                                          color: Color(0xFFFBF3E4),
                                        ),
                                      ),
                                      Positioned(
                                        top: _HomeSceneLayout.floorTop *
                                            sceneScale,
                                        left: 0,
                                        right: 0,
                                        bottom: 0,
                                        child: const ColoredBox(
                                          key: Key('home-floor'),
                                          color: Color(0xFFB88956),
                                        ),
                                      ),
                                      Positioned(
                                        left: _HomeSceneLayout.lilyMat.left *
                                            sceneScale,
                                        top: _HomeSceneLayout.lilyMat.top *
                                            sceneScale,
                                        width: _HomeSceneLayout.lilyMat.width *
                                            sceneScale,
                                        height:
                                            _HomeSceneLayout.lilyMat.height *
                                                sceneScale,
                                        child: const HomeLilyMat(),
                                      ),
                                      const Positioned(
                                        top: 0,
                                        left: 0,
                                        right: 0,
                                        height: 424,
                                        child: InteractiveHomeLamp(),
                                      ),
                                      Positioned(
                                        left: _HomeSceneLayout.window.left *
                                            sceneScale,
                                        top: _HomeSceneLayout.window.top *
                                            sceneScale,
                                        width: _HomeSceneLayout.window.width *
                                            sceneScale,
                                        height: _HomeSceneLayout.window.height *
                                            sceneScale,
                                        child: const AnimatedHomeWindow(
                                          key: Key('home-animated-window'),
                                        ),
                                      ),
                                      Positioned(
                                        left: _HomeSceneLayout.bookshelf.left *
                                            sceneScale,
                                        top: _HomeSceneLayout.bookshelf.top *
                                            sceneScale,
                                        width:
                                            _HomeSceneLayout.bookshelf.width *
                                                sceneScale,
                                        height:
                                            _HomeSceneLayout.bookshelf.height *
                                                sceneScale,
                                        child: HomeBookshelf(
                                          onTap: () => _openLessons(context),
                                        ),
                                      ),
                                      Positioned(
                                        left: _HomeSceneLayout.couch.left *
                                            sceneScale,
                                        top: _HomeSceneLayout.couch.top *
                                            sceneScale,
                                        width: _HomeSceneLayout.couch.width *
                                            sceneScale,
                                        height: _HomeSceneLayout.couch.height *
                                            sceneScale,
                                        child: const HomeCouch(),
                                      ),
                                      Positioned(
                                        left:
                                            _HomeSceneLayout.standingLamp.left *
                                                sceneScale,
                                        top: _HomeSceneLayout.standingLamp.top *
                                            sceneScale,
                                        width: _HomeSceneLayout
                                                .standingLamp.width *
                                            sceneScale,
                                        height: _HomeSceneLayout
                                                .standingLamp.height *
                                            sceneScale,
                                        child: const HomeStandingLamp(),
                                      ),
                                      Positioned(
                                        left: _HomeSceneLayout.drawer.left *
                                            sceneScale,
                                        top: _HomeSceneLayout.drawer.top *
                                            sceneScale,
                                        width: _HomeSceneLayout.drawer.width *
                                            sceneScale,
                                        height: _HomeSceneLayout.drawer.height *
                                            sceneScale,
                                        child: const HomeDrawer(),
                                      ),
                                      Positioned(
                                        left: _HomeSceneLayout.kokaMascot.left *
                                            sceneScale,
                                        top: _HomeSceneLayout.kokaMascot.top *
                                            sceneScale,
                                        width:
                                            _HomeSceneLayout.kokaMascot.width *
                                                sceneScale,
                                        height:
                                            _HomeSceneLayout.kokaMascot.height *
                                                sceneScale,
                                        child: HomeKokaMascot(
                                          key: const Key('home-koka-mascot'),
                                          learnerName: widget.learnerName,
                                        ),
                                      ),
                                      Positioned(
                                        left: _HomeSceneLayout.door.left *
                                            sceneScale,
                                        top: _HomeSceneLayout.door.top *
                                            sceneScale,
                                        width: _HomeSceneLayout.door.width *
                                            sceneScale,
                                        height: _HomeSceneLayout.door.height *
                                            sceneScale,
                                        child: HomeDoor(
                                          key: const Key('home-door'),
                                          onTap: () => _openMap(context),
                                        ),
                                      ),
                                      Positioned(
                                        left:
                                            _HomeSceneLayout.wordOfTheDay.left *
                                                sceneScale,
                                        top: _HomeSceneLayout.wordOfTheDay.top *
                                            sceneScale,
                                        width: _HomeSceneLayout
                                                .wordOfTheDay.width *
                                            sceneScale,
                                        height: _HomeSceneLayout
                                                .wordOfTheDay.height *
                                            sceneScale,
                                        child: const HomeWordOfTheDay(),
                                      ),
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: 0,
                                        height: _HomeSceneLayout.footerHeight *
                                            sceneScale,
                                        child: const HomeContentFooter(),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 108 * topControlScale,
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _scrollController,
                          builder: (context, child) {
                            final floorScrollOffset = _HomeSceneLayout
                                    .floorTop *
                                (canvasWidth / _HomeSceneLayout.designWidth);
                            final revealStart = floorScrollOffset *
                                _upperNavigationRevealStartFraction;
                            final revealRange = floorScrollOffset - revealStart;
                            final scrollOffset = _scrollController.hasClients
                                ? _scrollController.offset
                                : 0.0;
                            final progress =
                                ((scrollOffset - revealStart) / revealRange)
                                    .clamp(0.0, 1.0);
                            return Opacity(
                              key: const Key('home-upper-navigation-bar'),
                              opacity: progress * _upperNavigationMaxOpacity,
                              child: const ColoredBox(
                                color: Color(0xFFB88956),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 51 * topControlScale,
                      right: canvasSideInset + (30 * topControlScale),
                      width: 47 * topControlScale,
                      height: 49 * topControlScale,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: HomeSettingsButton(
                          onTap: () => _openSettings(context),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 47 * topControlScale,
                      left: canvasSideInset + (30 * topControlScale),
                      width: 78 * topControlScale,
                      height: 52 * topControlScale,
                      child: const FittedBox(
                        fit: BoxFit.contain,
                        child: HomeEnergyIndicator(),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

/// Editable positions measured from the original 412-wide Figma artboard.
abstract final class _HomeSceneLayout {
  static const double designWidth = 412;

  static const window = _HomeSceneItemLayout(
    left: 206,
    top: 143,
    width: 128,
    height: 128,
  );

  static const door = _HomeSceneItemLayout(
    left: 326,
    top: 230,
    width: 73,
    height: 121,
  );

  // Furniture on the wall. Change bookshelfWidth to resize the bookshelf.
  // Its height follows the original 160 x 37 SVG ratio automatically.
  static const double bookshelfWidth = 160;
  static const double _bookshelfAspectRatio = 37 / 160;

  static const bookshelf = _HomeSceneItemLayout(
    left: 7,
    top: 215,
    width: bookshelfWidth,
    height: bookshelfWidth * _bookshelfAspectRatio,
  );

  // Furniture on the floor. Change standingLampHeight to resize the lamp;
  // its width follows the supplied 145 x 504 PNG ratio automatically.
  static const double standingLampHeight = 126;
  static const double _standingLampAspectRatio = 145 / 504;

  static const standingLamp = _HomeSceneItemLayout(
    left: 25,
    top: 245,
    width: standingLampHeight * _standingLampAspectRatio,
    height: standingLampHeight,
  );

  // Furniture on the floor. Change drawerWidth to resize the drawer; its
  // height follows the supplied 52 x 41 SVG ratio automatically.
  static const double drawerWidth = 52;
  static const double _drawerAspectRatio = 41 / 52;

  static const drawer = _HomeSceneItemLayout(
    left: 53,
    top: 325,
    width: drawerWidth,
    height: drawerWidth * _drawerAspectRatio,
  );

  // Furniture on the floor. Change couchWidth to resize the couch; its height
  // follows the supplied 152 x 79 SVG ratio automatically.
  static const double couchWidth = 152;
  static const double _couchAspectRatio = 79 / 152;

  static const couch = _HomeSceneItemLayout(
    left: 110,
    top: 287,
    width: couchWidth,
    height: couchWidth * _couchAspectRatio,
  );

  // Floor mat. Change lilyMatWidth to resize the mat; its height follows the
  // supplied 361 x 88 SVG ratio automatically.
  static const double lilyMatWidth = 361;
  static const double _lilyMatAspectRatio = 88 / 361;

  static const lilyMat = _HomeSceneItemLayout(
    left: 5,
    top: 359,
    width: lilyMatWidth,
    height: lilyMatWidth * _lilyMatAspectRatio,
  );

  // Koka uses the supplied 312 x 573 Rive artboard ratio. Change only
  // kokaMascotHeight to resize the mascot without distortion.
  static const double kokaMascotHeight = 140;
  static const double _kokaMascotAspectRatio = 312 / 573;

  static const kokaMascot = _HomeSceneItemLayout(
    left: 160,
    top: 260,
    width: kokaMascotHeight * _kokaMascotAspectRatio,
    height: kokaMascotHeight,
  );

  // Word of the Day card. Change wordOfTheDayWidth to resize the card; its
  // height follows the supplied 378 x 216 SVG ratio automatically.
  static const double wordOfTheDayWidth = 378;
  static const double _wordOfTheDayAspectRatio = 216 / 378;

  static const wordOfTheDay = _HomeSceneItemLayout(
    left: 17,
    top: 480,
    width: wordOfTheDayWidth,
    height: wordOfTheDayWidth * _wordOfTheDayAspectRatio,
  );

  // The scrollable Home footer uses its own width-relative painted wave.
  static const double footerHeight = 48;

  // Update contentBottom when a new Home item extends below the Word card.
  // The scroll scene will then automatically grow to fit it and the footer.
  static final double contentBottom = wordOfTheDay.top + wordOfTheDay.height;
  static final double footerBottom = contentBottom + footerHeight;

  static const double creamFloorBorderTop = 346;
  static const double floorTop = 350;
}

/// One item's editable Figma coordinates and native size.
class _HomeSceneItemLayout {
  const _HomeSceneItemLayout({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;
}

class _HomeWallBackground extends StatelessWidget {
  const _HomeWallBackground();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFEADF99),
      child: Column(
        children: [
          SizedBox(key: Key('home-content-top'), height: 1),
          Spacer(),
          SizedBox(key: Key('home-content-bottom'), height: 1),
        ],
      ),
    );
  }
}
