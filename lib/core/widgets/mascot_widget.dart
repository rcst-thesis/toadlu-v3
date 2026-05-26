import 'package:flutter/material.dart';

/// Shared mascot image wrapper.
///
/// Keeping the asset path in one place makes it easier to swap the mascot later
/// without hunting through every screen.
class TudloMascot extends StatelessWidget {
  final double size;
  final bool happy;
  final String? asset;

  const TudloMascot({
    super.key,
    this.size = 118,
    this.happy = true,
    this.asset,
  });

  @override
  Widget build(BuildContext context) {
    final imageAsset =
        asset ??
        (happy ? 'assets/images/mascot1.png' : 'assets/images/mascot2.png');
    return Image.asset(
      imageAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
