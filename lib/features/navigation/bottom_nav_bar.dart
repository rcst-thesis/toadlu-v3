import 'package:flutter/material.dart';
import 'package:tudloapp/core/constants/app_strings.dart';
import 'package:tudloapp/core/theme/app_theme.dart';

/// Floating bottom navigation used by the main app shell.
///
/// AppShell owns which page is active; this widget only renders the shared nav
/// UI and reports taps back to the shell.
class TudloBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const TudloBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  static const icons = [
    Icons.home,
    Icons.translate,
    Icons.menu_book_rounded,
    Icons.pets_rounded,
    Icons.fact_check,
    Icons.person,
  ];

  static const labels = [
    AppStrings.navMap,
    AppStrings.navTranslate,
    AppStrings.navDictionary,
    AppStrings.navPet,
    AppStrings.navTest,
    AppStrings.navProfile,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
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
          final isSelected = selectedIndex == index;

          return Expanded(
            child: AnimatedScale(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              scale: isSelected ? 1.03 : 1,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onTap(index),
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
                        size: isSelected ? 31 : 29,
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
    );
  }
}
