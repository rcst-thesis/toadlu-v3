import 'package:flutter/material.dart';

class TudloColors {
  static const navy = Color(0xFF1D2A62);
  static const blue = Color(0xFF87AECE);
  static const cloud = Color(0xFFEDEDED);
  static const meadow = Color(0xFFAFD06E);
  static const forest = Color(0xFF437118);

  static const sky = blue;
  static const mint = meadow;
  static const ink = navy;
  static const muted = Color(0xFF5F6F86);
  static const paper = cloud;
  static const line = Color(0xFFD8DFE3);
  static const coral = Color(0xFFE05A47);
  static const gold = meadow;
  static const green = forest;
}

class TudloTheme {
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [TudloColors.blue, TudloColors.meadow],
  );

  static final theme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: TudloColors.sky,
      primary: TudloColors.sky,
      secondary: TudloColors.forest,
      surface: TudloColors.paper,
    ),
    scaffoldBackgroundColor: TudloColors.paper,
    fontFamily: 'Arial',
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: TudloColors.ink,
        fontSize: 28,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: TextStyle(
        color: TudloColors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      bodyMedium: TextStyle(
        color: TudloColors.muted,
        fontSize: 15,
        height: 1.35,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: TudloColors.ink,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
  );
}

class TudloCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const TudloCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TudloColors.line),
        boxShadow: [
          BoxShadow(
            color: TudloColors.ink.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class TudloPageBackground extends StatelessWidget {
  final Widget child;

  const TudloPageBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(gradient: TudloTheme.gradient),
      child: SafeArea(child: child),
    );
  }
}
