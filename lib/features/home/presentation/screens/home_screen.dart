import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tudlo/core/navigation/fade_page_route.dart';
import 'package:tudlo/features/home/presentation/widgets/animated_home_window.dart';
import 'package:tudlo/features/home/presentation/widgets/home_bottom_navigation.dart';
import 'package:tudlo/features/home/presentation/widgets/home_energy_indicator.dart';
import 'package:tudlo/features/home/presentation/widgets/home_settings_button.dart';
import 'package:tudlo/features/home/presentation/widgets/interactive_home_lamp.dart';
import 'package:tudlo/features/placeholder/presentation/placeholder_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      FadePageRoute<void>(
        page: const PlaceholderScreen(
          title: 'Settings',
          description: 'Settings screen placeholder',
          icon: Icons.settings_rounded,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('home-screen'),
      backgroundColor: const Color(0xFFEADF99),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, viewport) {
                final canvasWidth = math.min(viewport.maxWidth, 720.0);
                final canvasSideInset = (viewport.maxWidth - canvasWidth) / 2;
                final topControlScale = (canvasWidth / 460).clamp(.82, 1.12);
                return Stack(
                  children: [
                    Positioned.fill(
                      child: SingleChildScrollView(
                        key: const Key('home-content-scroll-view'),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 720),
                            child: SizedBox(
                              height: math.max(
                                720,
                                viewport.maxHeight * 1.5,
                              ),
                              width: double.infinity,
                              child: LayoutBuilder(
                                builder: (context, scene) {
                                  final sceneScale = scene.maxWidth /
                                      _HomeSceneLayout.designWidth;
                                  return Stack(
                                    children: [
                                      const Positioned.fill(
                                        child: _TemporaryHomeContent(),
                                      ),
                                      const Positioned(
                                        top: 0,
                                        left: 0,
                                        right: 0,
                                        height: 424,
                                        child: InteractiveHomeLamp(),
                                      ),
                                      Positioned(
                                        left: _HomeSceneLayout.windowLeft *
                                            sceneScale,
                                        top: _HomeSceneLayout.windowTop *
                                            sceneScale,
                                        width: _HomeSceneLayout.windowSize *
                                            sceneScale,
                                        height: _HomeSceneLayout.windowSize *
                                            sceneScale,
                                        child: const AnimatedHomeWindow(
                                          key: Key('home-animated-window'),
                                        ),
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
          ),
          const HomeBottomNavigation(),
        ],
      ),
    );
  }
}

/// Editable positions measured from the original 412-wide Figma artboard.
abstract final class _HomeSceneLayout {
  static const double designWidth = 412;
  static const double windowLeft = 194;
  static const double windowTop = 160;
  static const double windowSize = 128;
}

class _TemporaryHomeContent extends StatelessWidget {
  const _TemporaryHomeContent();

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
