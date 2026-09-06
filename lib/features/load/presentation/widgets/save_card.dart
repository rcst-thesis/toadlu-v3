import 'package:flutter/material.dart';

import 'package:tudlo/core/theme/app_colors.dart';

class SaveCard extends StatelessWidget {
  const SaveCard({
    required this.name,
    required this.previewColor,
    required this.previewShadowColor,
    required this.previewAsset,
    required this.onLoad,
    required this.onDelete,
    super.key,
  });

  final String name;
  final Color previewColor;
  final Color previewShadowColor;
  final String previewAsset;
  final VoidCallback onLoad;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(10));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // A solid offset layer matches the reference better than a blur.
        const Positioned(
          left: 2,
          top: 5,
          right: 0,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFF75D548),
              borderRadius: radius,
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          right: 2,
          bottom: 5,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFF98EF6F),
              borderRadius: radius,
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          top: 4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: previewShadowColor,
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
                  SizedBox(
                    height: 42,
                    child: Center(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: SaveCardButton(
                          label: 'load',
                          onPressed: onLoad,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SaveCardButton(
                          label: 'delete',
                          onPressed: onDelete,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SaveCardButton extends StatelessWidget {
  const SaveCardButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
