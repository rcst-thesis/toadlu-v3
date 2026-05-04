import 'package:flutter/material.dart';

class TudloSky extends StatelessWidget {
  final Widget child;
  final bool dense;

  const TudloSky({super.key, required this.child, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFEDEDED),
      child: CustomPaint(
        painter: _SkyPainter(dense: dense),
        child: SafeArea(child: child),
      ),
    );
  }
}

class TudloMascot extends StatelessWidget {
  final double size;
  final bool happy;

  const TudloMascot({super.key, this.size = 118, this.happy = true});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/mascot1.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class _SkyPainter extends CustomPainter {
  final bool dense;

  const _SkyPainter({required this.dense});

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF87AECE), Color(0xFFEDEDED)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    _cloud(
      canvas,
      Offset(size.width * .18, size.height * .09),
      size.width * .18,
    );
    _cloud(
      canvas,
      Offset(size.width * .72, size.height * .13),
      size.width * .15,
    );
    if (dense) {
      _cloud(
        canvas,
        Offset(size.width * .46, size.height * .23),
        size.width * .12,
      );
      _cloud(
        canvas,
        Offset(size.width * .06, size.height * .31),
        size.width * .10,
      );
    }

    final hillPaint = Paint()..color = const Color(0xFFAFD06E);
    final farHill = Path()
      ..moveTo(0, size.height * .70)
      ..quadraticBezierTo(
        size.width * .27,
        size.height * .58,
        size.width * .52,
        size.height * .70,
      )
      ..quadraticBezierTo(
        size.width * .78,
        size.height * .80,
        size.width,
        size.height * .67,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(farHill, hillPaint);

    final nearHill = Path()
      ..moveTo(0, size.height * .78)
      ..quadraticBezierTo(
        size.width * .24,
        size.height * .68,
        size.width * .52,
        size.height * .78,
      )
      ..quadraticBezierTo(
        size.width * .76,
        size.height * .88,
        size.width,
        size.height * .76,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(nearHill, Paint()..color = const Color(0xFF437118));

    _tree(canvas, Offset(size.width * .14, size.height * .69), 1.0);
    _tree(canvas, Offset(size.width * .83, size.height * .66), .92);
    _tree(canvas, Offset(size.width * .92, size.height * .74), .72);
  }

  void _cloud(Canvas canvas, Offset center, double width) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .92);
    final shade = Paint()
      ..color = const Color(0xFFEDEDED).withValues(alpha: .75);
    final h = width * .42;
    for (final item in [
      Offset(-.42, .10),
      Offset(-.18, -.06),
      Offset(.08, -.12),
      Offset(.32, .04),
      Offset(.50, .12),
    ]) {
      canvas.drawCircle(
        center + Offset(item.dx * width, item.dy * h),
        h * .38,
        shade,
      );
    }
    for (final item in [
      Offset(-.46, .02),
      Offset(-.22, -.15),
      Offset(.03, -.20),
      Offset(.28, -.05),
      Offset(.50, .02),
    ]) {
      canvas.drawCircle(
        center + Offset(item.dx * width, item.dy * h),
        h * .36,
        paint,
      );
    }
  }

  void _tree(Canvas canvas, Offset root, double scale) {
    final trunk = Paint()..color = const Color(0xFF1D2A62);
    final leaves = Paint()..color = const Color(0xFF437118);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          root.dx - 7 * scale,
          root.dy - 50 * scale,
          14 * scale,
          55 * scale,
        ),
        Radius.circular(7 * scale),
      ),
      trunk,
    );
    for (final p in [
      Offset(-22, -54),
      Offset(0, -68),
      Offset(24, -53),
      Offset(0, -42),
    ]) {
      canvas.drawCircle(root + p * scale, 24 * scale, leaves);
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPainter oldDelegate) =>
      oldDelegate.dense != dense;
}
