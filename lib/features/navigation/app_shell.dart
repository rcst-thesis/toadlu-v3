import 'package:flutter/material.dart';
import 'package:tudloapp/features/dictionary/screens/dictionary_page.dart';
import 'package:tudloapp/features/test/screens/test_page.dart';
import 'package:tudloapp/features/translation/screens/translation_page.dart';
import 'package:tudloapp/features/home_map/screens/home_map_page.dart';
import 'package:tudloapp/features/pet/screens/pet_page.dart';
import 'package:tudloapp/features/profile/screens/profile_page.dart';
import 'package:tudloapp/features/navigation/bottom_nav_bar.dart';

/// Main app container after onboarding.
///
/// It keeps the currently selected tab and overlays the floating navigation bar
/// above each feature page. Child screens can open this with `initialIndex` to
/// land on a specific tab.
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
    // Called by the bottom navigation bar and by child pages that need to jump
    // back to another tab, such as Test returning to Map.
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Keep page order, icons, and labels aligned by index.
    // Example: index 0 = Map page, Map icon, and "Map" label.
    final pages = [
      // Opens the Home Map where learners choose lesson levels.
      const HomeMapPage(),
      // Opens the translator helper tab.
      const TranslationPage(),
      // Opens the searchable vocabulary dictionary.
      const DictionaryPage(),
      // Opens Koka's energy companion page.
      const PetPage(),
      // Opens the unit test page. Its back button returns to the Map tab.
      TestPage(onBack: () => switchTo(0)),
      // Opens the user's profile, streak, and progress page.
      const ProfilePage(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          pages[_selectedIndex],
          // Floating navbar stays above the current page instead of being part
          // of each screen, so tab styling is consistent everywhere.
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: TudloBottomNavBar(
              selectedIndex: _selectedIndex,
              onTap: switchTo,
            ),
          ),
        ],
      ),
    );
  }
}
