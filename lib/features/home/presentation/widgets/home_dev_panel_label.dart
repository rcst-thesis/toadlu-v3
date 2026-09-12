import 'package:flutter/material.dart';

/// The label that introduces the developer panel below the sticker section.
class HomeDevPanelLabel extends StatelessWidget {
  const HomeDevPanelLabel({super.key});

  static const double designWidth = 90;
  static const double designHeight = 22;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / designWidth;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20 * scale,
              height: 20 * scale,
              child: Image.asset(
                'assets/images/home_dev_panel_label_icon.png',
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ),
            SizedBox(width: 6 * scale),
            Text(
              'the dev',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'ComicRelief',
                fontSize: 13 * scale,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ],
        );
      },
    );
  }
}
