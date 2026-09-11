import 'package:flutter/material.dart';

import 'package:tudlo/shared/widgets/rive_long_button.dart';

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
            height: RiveLongButton.height,
            child: white
                ? _WhitePrimaryButton(
                    label: primaryLabel,
                    onPressed: onPrimaryPressed,
                    frontColor: frontColor,
                    depthColor: depthColor,
                    foregroundColor: foregroundColor,
                  )
                : RiveLongButton(
                    label: primaryLabel,
                    onPressed: onPrimaryPressed,
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

class _WhitePrimaryButton extends StatelessWidget {
  const _WhitePrimaryButton({
    required this.label,
    required this.onPressed,
    required this.frontColor,
    required this.depthColor,
    required this.foregroundColor,
  });

  final String label;
  final VoidCallback onPressed;
  final Color frontColor;
  final Color depthColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
              onPressed: onPressed,
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
                  label,
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
    );
  }
}
