import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeSettingsButton extends StatelessWidget {
  const HomeSettingsButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Settings',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('home-settings-button'),
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SvgPicture.asset(
            'assets/images/home_settings_button.svg',
            width: 47,
            height: 49,
            fit: BoxFit.contain,
            semanticsLabel: 'Settings',
          ),
        ),
      ),
    );
  }
}
