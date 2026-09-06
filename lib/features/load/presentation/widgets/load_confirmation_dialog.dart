import 'package:flutter/material.dart';

import 'package:tudlo/core/theme/app_colors.dart';

class LoadConfirmationDialog extends StatelessWidget {
  const LoadConfirmationDialog({
    required this.name,
    required this.previewColor,
    required this.previewAsset,
    required this.deleting,
    super.key,
  });

  final String name;
  final Color previewColor;
  final String previewAsset;
  final bool deleting;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 412,
            height: 917,
            child: MediaQuery.withNoTextScaling(
              child: Stack(
                children: [
                  Positioned(
                    key: const Key('load-confirmation-panel'),
                    left: 62,
                    top: 299,
                    width: 289,
                    height: 367,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 7,
                          width: 289,
                          height: 360,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          width: 289,
                          height: 360,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.lime,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 25,
                          top: 27,
                          width: 239,
                          height: 59,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              deleting
                                  ? 'are you sure to\ndelete this one?'
                                  : 'do you want to load\nthis one?',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 26,
                                height: 1.15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 61,
                          top: 106,
                          width: 168,
                          height: 143,
                          child: _ConfirmationSavePreview(
                            name: name,
                            previewColor: previewColor,
                            previewAsset: previewAsset,
                          ),
                        ),
                        Positioned(
                          left: 32,
                          top: 267,
                          child: _ConfirmationButton(
                            key: const Key('confirmation-no-button'),
                            label: 'no',
                            onPressed: () => Navigator.pop(context, false),
                          ),
                        ),
                        Positioned(
                          left: 166,
                          top: 267,
                          child: _ConfirmationButton(
                            key: const Key('confirmation-yes-button'),
                            label: 'yes',
                            labelColor: deleting
                                ? const Color(0xFFF13B4B)
                                : Colors.white,
                            onPressed: () => Navigator.pop(context, true),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmationSavePreview extends StatelessWidget {
  const _ConfirmationSavePreview({
    required this.name,
    required this.previewColor,
    required this.previewAsset,
  });

  final String name;
  final Color previewColor;
  final String previewAsset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 4,
          width: 168,
          height: 139,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF75D548),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          width: 168,
          height: 139,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF98EF6F),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Positioned(
          left: 11,
          top: 13,
          width: 146,
          height: 92,
          child: Stack(
            children: [
              Positioned.fill(
                top: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.lerp(previewColor, Colors.black, 0.28)!,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              Positioned.fill(
                bottom: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: previewColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    child: Image.asset(
                      previewAsset,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 11,
          top: 109,
          width: 146,
          height: 25,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              name,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfirmationButton extends StatelessWidget {
  const _ConfirmationButton({
    required this.label,
    required this.onPressed,
    this.labelColor = Colors.white,
    super.key,
  });

  final String label;
  final Color labelColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 54,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 5,
            width: 92,
            height: 49,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.darkGreen,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            width: 92,
            height: 49,
            child: Material(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onPressed,
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 30,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
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
