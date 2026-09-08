import 'package:flutter/material.dart';

import 'package:tudlo/core/theme/app_colors.dart';

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
    final frontColor = white ? Colors.white : AppColors.green;
    final depthColor = white ? const Color(0xFFB8C3AF) : AppColors.darkGreen;
    final foregroundColor = white ? Colors.black : Colors.white;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          SizedBox(
            key: primaryKey,
            width: width,
            height: 44,
            child: Stack(
              children: [
                Positioned.fill(
                  top: 4.373,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: depthColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Positioned.fill(
                  bottom: 4.373,
                  child: FilledButton(
                    onPressed: onPrimaryPressed,
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: frontColor,
                      foregroundColor: foregroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        primaryLabel,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: (width - 120) / 2,
            top: 50,
            width: 120,
            height: 44,
            child: TextButton(
              key: secondaryKey,
              onPressed: onSecondaryPressed,
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
