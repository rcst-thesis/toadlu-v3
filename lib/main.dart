import 'package:flutter/material.dart';
import 'app_state.dart';
import 'app_theme.dart';
import 'screens/mascot_screen.dart';

void main() {
  runApp(const TudloApp());
}

class TudloApp extends StatelessWidget {
  const TudloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: AppState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Tudlo',
        theme: TudloTheme.theme,
        home: const MascotScreen(),
      ),
    );
  }
}
