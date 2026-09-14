import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Circular "exit fullscreen" control shown top-right of the map while it's
/// in landscape fullscreen mode, 1:1 copy of the exported X button. Tapping
/// it returns the map to normal portrait mode.
class MapExitLandscapeButton extends StatelessWidget {
  const MapExitLandscapeButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  static const size = 52.0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: SvgPicture.asset(
            'assets/images/map_exit_landscape_button.svg',
          ),
        ),
      ),
    );
  }
}
