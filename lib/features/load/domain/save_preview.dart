import 'package:flutter/material.dart';

enum GradeLevel {
  grade1(
    frontColor: Color(0xFF42A32E),
    shadowColor: Color(0xFF417836),
    assetPath: 'assets/images/koka_green.png',
  ),
  grade2(
    frontColor: Color(0xFF235B8F),
    shadowColor: Color(0xFF214668),
    assetPath: 'assets/images/koka_blue.png',
  ),
  grade3(
    frontColor: Color(0xFF8F2020),
    shadowColor: Color(0xFF560E0E),
    assetPath: 'assets/images/koka_red.png',
  );

  const GradeLevel({
    required this.frontColor,
    required this.shadowColor,
    required this.assetPath,
  });

  final Color frontColor;
  final Color shadowColor;
  final String assetPath;
}

class SavePreview {
  const SavePreview({
    required this.name,
    required this.grade,
  });

  final String name;
  final GradeLevel grade;

  Color get previewColor => grade.frontColor;
  Color get previewShadowColor => grade.shadowColor;
  String get assetPath => grade.assetPath;
}
