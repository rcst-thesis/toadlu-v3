import 'package:flutter/material.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/style/app_theme.dart';
import 'package:tudloapp/features/onboarding/mascot_screen.dart';

void main() {
  runApp(const TudloApp());
}

/// Root widget for the app.
///
/// `AppStateScope` wraps the whole app so onboarding choices and profile data
/// can be read from any screen without passing values through constructors.
class TudloApp extends StatefulWidget {
  const TudloApp({super.key});

  @override
  State<TudloApp> createState() => _TudloAppState();
}

class _TudloAppState extends State<TudloApp> {
  final AppState _appState = AppState();

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: _appState,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Tudlo',
        theme: TudloTheme.theme,
        home: const MascotScreen(),
      ),
    );
  }
}
