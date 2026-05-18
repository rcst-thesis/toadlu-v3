import 'package:flutter/material.dart';

/// Shared mascot image wrapper.
///
/// Keeping the asset path in one place makes it easier to swap the mascot later
/// without hunting through every screen.
class TudloMascot extends StatelessWidget {
  final double size;
  final bool happy;

  const TudloMascot({super.key, this.size = 118, this.happy = true});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/mascot1.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
