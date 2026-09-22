import 'package:flutter/material.dart';

import 'package:tudlo/shared/audio/tudlo_audio_scope.dart';
import 'package:tudlo/shared/widgets/sticker_press_button.dart';

enum OnboardingPrimaryButtonStyle { green, white }

class OnboardingBottomActions extends StatelessWidget {
  const OnboardingBottomActions({
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimaryPressed,
    required this.onSecondaryPressed,
    required this.primaryKey,
    required this.secondaryKey,
    this.primaryStyle = OnboardingPrimaryButtonStyle.green,
    super.key,
  });

  static const width = 352.295;
  static const height = 94.0;
  static const primaryHeight = 52.0;

  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimaryPressed;
  final VoidCallback onSecondaryPressed;
  final Key primaryKey;
  final Key secondaryKey;
  final OnboardingPrimaryButtonStyle primaryStyle;

  @override
  Widget build(BuildContext context) {
    final white = primaryStyle == OnboardingPrimaryButtonStyle.white;
    final frontColor = Colors.white;
    final depthColor = const Color(0xFFB8C3AF);
    final foregroundColor = Colors.black;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          SizedBox(
            key: primaryKey,
            width: width,
            height: primaryHeight,
            child: StickerPressButton(
              label: primaryLabel,
              onPressed: onPrimaryPressed,
              frontColor: white ? frontColor : const Color(0xFF4E9F3E),
              depthColor: white ? depthColor : const Color(0xFF2C6121),
              labelColor: white ? foregroundColor : Colors.white,
              height: white ? 44 : primaryHeight,
              fontSize: 15,
            ),
          ),
          Positioned(
            left: (width - 120) / 2,
            top: 50,
            width: 120,
            height: 44,
            child: TextButton(
              key: secondaryKey,
              onPressed: () {
                TudloAudioScope.maybeOf(context)?.playButtonTapSound();
                onSecondaryPressed();
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xB3000000),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationThickness: 1.2,
                ),
              ),
              child: Text(secondaryLabel),
            ),
          ),
        ],
      ),
    );
  }
}
