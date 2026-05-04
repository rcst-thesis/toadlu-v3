import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'screens/home_map_page.dart';
import 'screens/streak_page.dart';
import 'screens/test_page.dart';
import 'screens/translation_page.dart';
import 'screens/user_page.dart';

class AppShell extends StatefulWidget {
  final int initialIndex;

  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void switchTo(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeMapPage(),
      const TranslationPage(),
      const StreakPage(),
      const TestPage(),
      const UserPage(),
    ];

    final icons = const [
      Icons.home,
      Icons.translate,
      Icons.local_fire_department,
      Icons.fact_check,
      Icons.person,
    ];
    final labels = const ['Map', 'Words', 'Streak', 'Test', 'Me'];

    return Scaffold(
      body: Stack(
        children: [
          pages[_selectedIndex],
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              height: 74,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: TudloColors.line),
                boxShadow: [
                  BoxShadow(
                    color: TudloColors.ink.withValues(alpha: 0.12),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(icons.length, (index) {
                  final isSelected = _selectedIndex == index;

                  return Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => switchTo(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        height: 58,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? TudloColors.sky.withValues(alpha: 0.14)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              icons[index],
                              size: 23,
                              color: isSelected
                                  ? TudloColors.ink
                                  : TudloColors.muted,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              labels[index],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected
                                    ? TudloColors.ink
                                    : TudloColors.muted,
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
