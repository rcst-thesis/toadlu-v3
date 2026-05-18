import 'package:flutter/material.dart';

/// Central color tokens for Tudlo.
///
/// Prefer using these constants instead of hard-coded colors so the app stays
/// visually consistent across onboarding, map, lessons, translation, and tests.
class TudloColors {
  static const navy = Color(0xFF253F0C);
  static const blue = Color(0xFF08C66B);
  static const cloud = Color(0xFFF5FAF5);
  static const meadow = Color(0xFFAFD06E);
  static const forest = Color(0xFF437118);
  static const brightGreen = Color(0xFF08C66B);
  static const softGreen = Color(0xFFDFF7EA);

  static const sky = brightGreen;
  static const mint = softGreen;
  static const ink = navy;
  static const muted = Color(0xFF7D8A7D);
  static const paper = cloud;
  static const line = Color(0xFFD8E6D8);
  static const coral = Color(0xFFE05A47);
  static const gold = Color(0xFFFFD700);
  static const green = brightGreen;
}

/// Global Flutter theme shared by the whole app.
///
/// Screen-specific designs can still customize layout, but base colors,
/// typography, and button defaults should start here.
class TudloTheme {
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [TudloColors.softGreen, TudloColors.paper],
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
        backgroundColor: TudloColors.brightGreen,
        foregroundColor: Colors.white,
        disabledBackgroundColor: TudloColors.line,
        disabledForegroundColor: TudloColors.muted,
        elevation: 0,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
  );
}

/// Reusable white card with Tudlo's border, radius, and soft shadow.
///
/// Use this for general content panels when a screen does not need a custom
/// card design.
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

/// Shared soft green page background used by simple form-like screens.
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
