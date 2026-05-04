import 'package:flutter/material.dart';

class TudloColors {
  static const sky = Color(0xFF44BDEB);
  static const mint = Color(0xFFA8E6CF);
  static const ink = Color(0xFF17324D);
  static const muted = Color(0xFF617589);
  static const paper = Color(0xFFF9FBFC);
  static const line = Color(0xFFE2EBF2);
  static const coral = Color(0xFFFF7F6E);
  static const gold = Color(0xFFFFC857);
  static const green = Color(0xFF35B779);
}

class TudloTheme {
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [TudloColors.sky, TudloColors.mint],
  );

  static final theme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: TudloColors.sky,
      primary: TudloColors.sky,
      secondary: TudloColors.coral,
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
