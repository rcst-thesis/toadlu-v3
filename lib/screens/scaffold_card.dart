import 'package:flutter/material.dart';
import '../forest_art.dart';

class OnboardingColors {
  static const bg = Color(0xFFEDEDED);
  static const panel = Colors.white;
  static const panel2 = Color(0xFFF8F8F8);
  static const border = Color(0xFFD8DFE3);
  static const text = Color(0xFF1D2A62);
  static const muted = Color(0xFF5F6F86);
  static const green = Color(0xFF437118);
  static const blue = Color(0xFF87AECE);
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
            colors: [Color(0xFF87AECE), Color(0xFFEDEDED)],
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
                  ],
                ),
                const SizedBox(height: 72),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const TudloMascot(size: 126),
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
