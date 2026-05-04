import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';

class TudloSky extends StatelessWidget {
  final Widget child;
  final bool dense;

  const TudloSky({super.key, required this.child, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFEAF9FF),
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
    return CustomPaint(size: Size.square(size), painter: _MascotPainter(happy));
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
        colors: [Color(0xFFBFEFFF), Color(0xFFF8FEFF)],
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

    final hillPaint = Paint()..color = const Color(0xFF8DD866);
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
    canvas.drawPath(nearHill, Paint()..color = const Color(0xFF57BE49));

    _tree(canvas, Offset(size.width * .14, size.height * .69), 1.0);
    _tree(canvas, Offset(size.width * .83, size.height * .66), .92);
    _tree(canvas, Offset(size.width * .92, size.height * .74), .72);
  }

  void _cloud(Canvas canvas, Offset center, double width) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .92);
    final shade = Paint()
      ..color = const Color(0xFFDDF4FA).withValues(alpha: .75);
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
    final trunk = Paint()..color = const Color(0xFF9A6638);
    final leaves = Paint()..color = const Color(0xFF2F9B4D);
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

class _MascotPainter extends CustomPainter {
  final bool happy;

  const _MascotPainter(this.happy);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 120;
    final center = Offset(size.width / 2, size.height / 2);
    final orange = Paint()..color = const Color(0xFFFF914D);
    final orangeDark = Paint()..color = const Color(0xFFE86F28);
    final cream = Paint()..color = const Color(0xFFFFDDBB);
    final ink = Paint()..color = TudloColors.ink;
    final white = Paint()..color = Colors.white;

    canvas.drawCircle(center + Offset(-32 * s, -34 * s), 17 * s, orangeDark);
    canvas.drawCircle(center + Offset(32 * s, -34 * s), 17 * s, orangeDark);
    canvas.drawCircle(center, 48 * s, orange);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, 17 * s),
        width: 64 * s,
        height: 48 * s,
      ),
      cream,
    );
    canvas.drawCircle(center + Offset(-18 * s, -10 * s), 8 * s, white);
    canvas.drawCircle(center + Offset(18 * s, -10 * s), 8 * s, white);
    canvas.drawCircle(center + Offset(-18 * s, -9 * s), 4 * s, ink);
    canvas.drawCircle(center + Offset(18 * s, -9 * s), 4 * s, ink);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, 4 * s),
        width: 16 * s,
        height: 11 * s,
      ),
      ink,
    );

    final mouth = Path()
      ..moveTo(center.dx - 12 * s, center.dy + 17 * s)
      ..quadraticBezierTo(
        center.dx,
        center.dy + (happy ? 30 : 12) * s,
        center.dx + 12 * s,
        center.dy + 17 * s,
      );
    canvas.drawPath(
      mouth,
      Paint()
        ..color = TudloColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * s
        ..strokeCap = StrokeCap.round,
    );

    final shine = Paint()..color = Colors.white.withValues(alpha: .24);
    canvas.drawArc(
      Rect.fromCenter(
        center: center + Offset(-10 * s, -14 * s),
        width: 70 * s,
        height: 58 * s,
      ),
      math.pi,
      math.pi / 2.8,
      false,
      shine
        ..strokeWidth = 8 * s
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) =>
      oldDelegate.happy != happy;
}
