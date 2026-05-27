import 'package:flutter/material.dart';
import 'package:tudloapp/core/constants/app_strings.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/features/onboarding/screens/mascot_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppData.initialize();
  runApp(const TudloApp());
}

class TudloApp extends StatefulWidget {
  const TudloApp({super.key});

  @override
  State<TudloApp> createState() => _TudloAppState();
}

class _TudloAppState extends State<TudloApp> {
  final AppState _appState = AppState();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _appState.initialize().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return AppStateScope(
      notifier: _appState,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppStrings.appName,
        theme: TudloTheme.theme,
        home: const MascotScreen(),
      ),
    );
  }
}
