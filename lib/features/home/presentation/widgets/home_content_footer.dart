import 'package:flutter/material.dart';

/// Decorative closing edge for the bottom of Home's scrollable content.
class HomeContentFooter extends StatelessWidget {
  const HomeContentFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: CustomPaint(
        key: Key('home-content-footer'),
        painter: _HomeContentFooterPainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _HomeContentFooterPainter extends CustomPainter {
  const _HomeContentFooterPainter();

  static const _upperTan = Color(0xFFB88956);
  static const _waveTan = Color(0xFFBD8C57);
  static const _hillBrown = Color(0xFF9B672C);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _upperTan);

    final width = size.width;
    final height = size.height;
    final backWave = Path()
      ..moveTo(0, height * .36)
      ..cubicTo(
        width * .14,
        height * .20,
        width * .27,
        height * .19,
        width * .40,
        height * .28,
      )
      ..cubicTo(
        width * .54,
        height * .37,
        width * .68,
        height * .36,
        width * .79,
        height * .25,
      )
      ..cubicTo(
        width * .89,
        height * .16,
        width * .95,
        height * .21,
        width,
        height * .17,
      )
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();
    canvas.drawPath(backWave, Paint()..color = _waveTan);

    final frontWave = Path()
      ..moveTo(0, height * .52)
      ..cubicTo(
        width * .15,
        height * .39,
        width * .29,
        height * .45,
        width * .43,
        height * .53,
      )
      ..cubicTo(
        width * .58,
        height * .63,
        width * .70,
        height * .58,
        width * .81,
        height * .45,
      )
      ..cubicTo(
        width * .90,
        height * .34,
        width * .96,
        height * .35,
        width,
        height * .31,
      )
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();
    canvas.drawPath(frontWave, Paint()..color = _hillBrown);
  }

  @override
  bool shouldRepaint(_HomeContentFooterPainter oldDelegate) => false;
}
