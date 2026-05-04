import 'package:flutter/material.dart';

class OnboardingColors {
  static const bg = Color(0xFFEAF9FF);
  static const panel = Colors.white;
  static const panel2 = Color(0xFFF6FBFE);
  static const border = Color(0xFFD7E8F1);
  static const text = Color(0xFF17324D);
  static const muted = Color(0xFF617589);
  static const green = Color(0xFF35B779);
  static const blue = Color(0xFF44BDEB);
}

class ScaffoldCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const ScaffoldCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFC9F3FF), Color(0xFFF8FEFF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (Navigator.canPop(context)) Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: OnboardingColors.text,
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(
                        value: .72,
                        strokeWidth: 6,
                        backgroundColor: Colors.white,
                        color: OnboardingColors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 72),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const _BlueHelper(size: 126),
                    const SizedBox(width: 18),
                    Expanded(child: _SpeechBubble(text: title)),
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: OnboardingColors.muted,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 54),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  final String text;

  const _SpeechBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubbleTailPainter(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: OnboardingColors.border, width: 4),
          boxShadow: [
            BoxShadow(
              color: OnboardingColors.text.withValues(alpha: .08),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: OnboardingColors.text,
            fontSize: 27,
            height: 1.18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = OnboardingColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(3, size.height * .48)
      ..lineTo(-20, size.height * .58)
      ..lineTo(3, size.height * .70);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BlueHelper extends StatelessWidget {
  final double size;

  const _BlueHelper({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * .78),
      painter: _BlueHelperPainter(),
    );
  }
}

class _BlueHelperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blue = Paint()..color = const Color(0xFF4B85F2);
    final darkBlue = Paint()..color = const Color(0xFF2E67D9);
    final light = Paint()..color = const Color(0xFF8FC8FF);
    final white = Paint()..color = Colors.white;
    final ink = Paint()..color = const Color(0xFF172033);

    final body = Rect.fromLTWH(
      size.width * .10,
      size.height * .32,
      size.width * .62,
      size.height * .42,
    );
    canvas.drawOval(body, blue);
    canvas.drawCircle(
      Offset(size.width * .33, size.height * .28),
      size.width * .17,
      blue,
    );
    canvas.drawCircle(
      Offset(size.width * .20, size.height * .34),
      size.width * .09,
      light,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * .02,
        size.height * .55,
        size.width * .20,
        size.height * .09,
      ),
      darkBlue,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * .62,
        size.height * .54,
        size.width * .18,
        size.height * .08,
      ),
      darkBlue,
    );

    final laptop = Path()
      ..moveTo(size.width * .52, size.height * .42)
      ..lineTo(size.width * .98, size.height * .45)
      ..lineTo(size.width * .86, size.height * .72)
      ..lineTo(size.width * .45, size.height * .69)
      ..close();
    canvas.drawPath(laptop, Paint()..color = const Color(0xFFBFEFFF));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .18,
          size.height * .72,
          size.width * .84,
          size.height * .07,
        ),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFF4B5660),
    );

    for (final dx in [.30, .54]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * dx,
            size.height * .30,
            size.width * .21,
            size.height * .22,
          ),
          const Radius.circular(7),
        ),
        white,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * (dx + .03),
            size.height * .33,
            size.width * .12,
            size.height * .13,
          ),
          const Radius.circular(5),
        ),
        ink,
      );
      canvas.drawCircle(
        Offset(size.width * (dx + .07), size.height * .34),
        size.width * .035,
        white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
