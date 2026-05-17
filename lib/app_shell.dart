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
    final labels = const ['Map', 'Translate', 'Streak', 'Test', 'Profile'];

    return Scaffold(
      body: Stack(
        children: [
          pages[_selectedIndex],
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              height: 78,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: .92)),
                boxShadow: [
                  BoxShadow(
                    color: TudloColors.forest.withValues(alpha: 0.12),
                    blurRadius: 34,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: TudloColors.brightGreen.withValues(alpha: 0.07),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(icons.length, (index) {
                  final isSelected = _selectedIndex == index;

                  return Expanded(
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      scale: isSelected ? 1.03 : 1,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => switchTo(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? TudloColors.softGreen
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: TudloColors.brightGreen.withValues(
                                        alpha: .10,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 7),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                icons[index],
                                size: isSelected ? 24 : 23,
                                color: isSelected
                                    ? TudloColors.forest
                                    : TudloColors.muted,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                labels[index],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected
                                      ? TudloColors.forest
                                      : TudloColors.muted,
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w900
                                      : FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
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
