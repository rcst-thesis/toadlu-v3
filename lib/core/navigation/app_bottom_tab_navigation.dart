import 'package:flutter/material.dart';

import 'package:tudlo/core/navigation/fade_page_route.dart';
import 'package:tudlo/features/home/presentation/widgets/home_bottom_navigation.dart';
import 'package:tudlo/features/me/presentation/screens/me_screen.dart';
import 'package:tudlo/features/placeholder/presentation/placeholder_screen.dart';

/// Single source of truth for the six-tab bottom navigation's routing.
///
/// Every screen reachable from the bottom navigation supplies this as its
/// `bottomNavigationBar` with its own tab index. That keeps tab-switch
/// behavior (push away from Home, replace between siblings, clear back to
/// Home) and per-tab color identical everywhere instead of each screen
/// re-deriving its own partial `onItemTapped` switch.
class AppBottomTabNavigation extends StatelessWidget {
  const AppBottomTabNavigation({required this.currentIndex, super.key});

  final int currentIndex;

  static const _defaultNavigationColor = Color(0xFFBD8C57);
  static const _meNavigationColor = Color(0xFF7C6B41);

  static const _meTabIndex = 5;

  @override
  Widget build(BuildContext context) {
    return HomeBottomNavigation(
      selectedIndex: currentIndex,
      backgroundColor: currentIndex == _meTabIndex
          ? _meNavigationColor
          : _defaultNavigationColor,
      onItemTapped: (index) => _navigate(context, index),
    );
  }

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) return;
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    final route = FadePageRoute<void>(page: destinationFor(index));
    if (currentIndex == 0) {
      Navigator.of(context).push(route);
    } else {
      Navigator.of(context).pushReplacement<void, void>(route);
    }
  }

  /// The destination screen for [index], each pre-wired with its own
  /// [AppBottomTabNavigation] so the bar keeps working after arrival.
  static Widget destinationFor(int index) {
    switch (index) {
      case 1:
        return const PlaceholderScreen(
          title: 'Translate',
          description: 'Temporary Translate shell',
          icon: Icons.translate_rounded,
          bottomNavigationBar: AppBottomTabNavigation(currentIndex: 1),
        );
      case 2:
        return const PlaceholderScreen(
          title: 'Lessons',
          description: 'Temporary Lessons shell',
          icon: Icons.menu_book_rounded,
          bottomNavigationBar: AppBottomTabNavigation(currentIndex: 2),
        );
      case 3:
        return const PlaceholderScreen(
          title: 'Map',
          description: 'Temporary Map shell',
          icon: Icons.map_rounded,
          bottomNavigationBar: AppBottomTabNavigation(currentIndex: 3),
        );
      case 4:
        return const PlaceholderScreen(
          title: 'Dictionary',
          description: 'Temporary Dictionary shell',
          icon: Icons.menu_book_outlined,
          bottomNavigationBar: AppBottomTabNavigation(currentIndex: 4),
        );
      case 5:
        return MeScreen();
      default:
        throw ArgumentError.value(index, 'index', 'Unsupported tab index');
    }
  }
}
