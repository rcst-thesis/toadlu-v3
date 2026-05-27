import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/mascot_widget.dart';
import 'package:tudloapp/features/navigation/app_shell.dart';
import 'package:tudloapp/features/evaluation/screens/evaluation_test_screen.dart';

/// Intro screen before the evaluation test.
///
/// "Let's Go!" starts the placement evaluation. "Skip" sends the user straight
/// to the Home Map using the default/easy dataset internally.
class EvaluationIntroScreen extends StatefulWidget {
  const EvaluationIntroScreen({super.key});

  @override
  State<EvaluationIntroScreen> createState() => _EvaluationIntroScreenState();
}

class _EvaluationIntroScreenState extends State<EvaluationIntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _float = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TudloColors.softGreen,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/evaluationbg.jpg',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) {
                return const _EvaluationFallbackBackground();
              },
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: .10),
                    TudloColors.softGreen.withValues(alpha: .18),
                    TudloColors.paper.withValues(alpha: .62),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 3),
                  AnimatedBuilder(
                    animation: _float,
                    builder: (context, child) {
                      final lift = -10 * _float.value;
                      final scale = 1 + (_float.value * .026);
                      return Transform.translate(
                        offset: Offset(0, lift),
                        child: Transform.scale(scale: scale, child: child),
                      );
                    },
                    child: Center(
                      child: SizedBox(
                        width: 230,
                        height: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedBuilder(
                              animation: _float,
                              builder: (context, child) {
                                return Container(
                                  width: 190 + (_float.value * 14),
                                  height: 190 + (_float.value * 14),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: .66),
                                        Colors.white.withValues(alpha: .24),
                                        Colors.white.withValues(alpha: 0),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withValues(
                                          alpha: .42,
                                        ),
                                        blurRadius: 42,
                                        spreadRadius: 8,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const _IntroSparkle(
                              left: 26,
                              top: 48,
                              size: 18,
                              delay: .1,
                            ),
                            const _IntroSparkle(
                              left: 64,
                              top: 30,
                              size: 8,
                              delay: .5,
                            ),
                            const _IntroSparkle(
                              left: 186,
                              top: 50,
                              size: 15,
                              delay: .8,
                            ),
                            const _IntroSparkle(
                              left: 42,
                              top: 156,
                              size: 10,
                              delay: .3,
                            ),
                            const _IntroSparkle(
                              left: 180,
                              top: 160,
                              size: 11,
                              delay: .6,
                            ),
                            const TudloMascot(size: 170),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Let's have a quick Tutorial",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: TudloColors.cloud,
                      fontSize: 40,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "We'll begin with a quick skill check.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: TudloColors.cloud,
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(flex: 4),
                  TextButton(
                    onPressed: () {
                      // Skip button:
                      // This directs the user straight to the Home Map page.
                      // Internally, it selects the easiest/default dataset,
                      // but the learner never sees the dataset name.
                      AppStateScope.of(context).skipEvaluation();
                      AppStateScope.of(context).completeOnboarding();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AppShell(initialIndex: 0),
                        ),
                        (route) => false,
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    child: const Text('Skip'),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 70,
                    child: ElevatedButton(
                      onPressed: () {
                        // Let's Go button:
                        // This directs the user to the Evaluation Test screen.
                        // The score from that test chooses the internal lesson
                        // dataset used later by the Home Map.
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EvaluationTestScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TudloColors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(45),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      child: const Text("Let's Go!"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvaluationFallbackBackground extends StatelessWidget {
  const _EvaluationFallbackBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _EvaluationFallbackPainter());
  }
}

class _IntroSparkle extends StatefulWidget {
  final double left;
  final double top;
  final double size;
  final double delay;

  const _IntroSparkle({
    required this.left,
    required this.top,
    required this.size,
    required this.delay,
  });

  @override
  State<_IntroSparkle> createState() => _IntroSparkleState();
}

class _IntroSparkleState extends State<_IntroSparkle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.left,
      top: widget.top,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final phase = (_controller.value + widget.delay) % 1;
          final opacity = .28 + (math.sin(phase * math.pi) * .52);
          final drift = math.sin(phase * math.pi * 2) * 2;
          return Transform.translate(
            offset: Offset(0, drift),
            child: Transform.rotate(
              angle: phase * math.pi * .18,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: widget.size,
                color: Colors.white.withValues(alpha: opacity.clamp(.18, .80)),
                shadows: [
                  Shadow(
                    color: Colors.white.withValues(alpha: .70),
                    blurRadius: 14,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EvaluationFallbackPainter extends CustomPainter {
  const _EvaluationFallbackPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFD8FFF2), Color(0xFFEAFBF2), Color(0xFFBFF1A0)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final hillPaint = Paint()..color = const Color(0xFFB7E982);
    final hill = Path()
      ..moveTo(0, size.height * .70)
      ..quadraticBezierTo(
        size.width * .28,
        size.height * .62,
        size.width * .55,
        size.height * .71,
      )
      ..quadraticBezierTo(
        size.width * .78,
        size.height * .79,
        size.width,
        size.height * .68,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hill, hillPaint);

    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: .78);
    for (final cloud in [
      Offset(size.width * .12, size.height * .12),
      Offset(size.width * .82, size.height * .16),
      Offset(size.width * .18, size.height * .32),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: cloud, width: 98, height: 24),
          const Radius.circular(999),
        ),
        cloudPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: cloud.translate(34, 16),
            width: 68,
            height: 18,
          ),
          const Radius.circular(999),
        ),
        cloudPaint,
      );
    }

    final flowerPaint = Paint()..color = Colors.white.withValues(alpha: .84);
    final centerPaint = Paint()..color = TudloColors.gold;
    for (final seed in [42.0, 120.0, 230.0, 316.0, 410.0]) {
      final x = (math.sin(seed) * .5 + .5) * size.width;
      final y = size.height * (.72 + ((seed % 18) / 100));
      for (var i = 0; i < 5; i++) {
        final angle = math.pi * 2 * i / 5;
        canvas.drawCircle(
          Offset(x + math.cos(angle) * 6, y + math.sin(angle) * 6),
          4,
          flowerPaint,
        );
      }
      canvas.drawCircle(Offset(x, y), 3, centerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
