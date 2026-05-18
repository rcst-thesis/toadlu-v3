import 'package:flutter/material.dart';
import 'package:tudloapp/core/style/forest_art.dart';

class OnboardingColors {
  static const bg = Colors.white;
  static const panel = Colors.white;
  static const panel2 = Color(0xFFF5FAF5);
  static const border = Color(0xFF08C66B);
  static const text = Color(0xFF437118);
  static const muted = Color(0xFF7D8A7D);
  static const green = Color(0xFF08C66B);
  static const blue = Color(0xFF08C66B);
  static const selected = Color(0xFFDFF7EA);
  static const shadow = Color(0x3308C66B);
}

class ScaffoldCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? bottomAction;

  const ScaffoldCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.bottomAction,
  });

  @override
  State<ScaffoldCard> createState() => _ScaffoldCardState();
}

class _ScaffoldCardState extends State<ScaffoldCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idleController;
  late final Animation<double> _floatAnimation;

  int get _step {
    if (widget.title.contains('call you')) return 1;
    if (widget.title.contains('old')) return 2;
    return 3;
  }

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _floatAnimation = CurvedAnimation(
      parent: _idleController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnboardingColors.bg,
      body: Theme(
        data: Theme.of(context).copyWith(
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: OnboardingColors.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: OnboardingColors.green.withValues(
                alpha: .28,
              ),
              disabledForegroundColor: OnboardingColors.muted.withValues(
                alpha: .75,
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
              minimumSize: const Size(240, 58),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: OnboardingColors.bg),
          child: SafeArea(
            child: Stack(
              children: [
                const Positioned.fill(child: _OnboardingBackground()),
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      28,
                      34,
                      28,
                      widget.bottomAction == null ? 36 : 126,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _StepProgress(step: _step),
                        const SizedBox(height: 42),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _floatAnimation,
                              builder: (context, child) {
                                final lift = -4 * _floatAnimation.value;
                                final scale =
                                    1 + (_floatAnimation.value * .018);
                                return Transform.translate(
                                  offset: Offset(6, lift),
                                  child: Transform.scale(
                                    scale: scale,
                                    child: child,
                                  ),
                                );
                              },
                              child: const SizedBox(
                                width: 70,
                                height: 70,
                                child: Center(child: TudloMascot(size: 76)),
                              ),
                            ),
                            Expanded(child: _SpeechBubble(text: widget.title)),
                          ],
                        ),
                        if (widget.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            widget.subtitle,
                            style: const TextStyle(
                              color: OnboardingColors.muted,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          child: widget.child,
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.bottomAction != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 34,
                    child: Center(child: widget.bottomAction!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  final int step;

  const _StepProgress({required this.step});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Step $step of 3',
          style: const TextStyle(
            color: OnboardingColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(3, (index) {
            final active = index < step;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                height: 8,
                margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                decoration: BoxDecoration(
                  color: active
                      ? OnboardingColors.green
                      : OnboardingColors.selected,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
      ],
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
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.fromLTRB(20, 12, 18, 12),
        decoration: BoxDecoration(
          color: OnboardingColors.green,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: OnboardingColors.green.withValues(alpha: .22),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
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
      ..color = OnboardingColors.green
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(6, size.height * .35)
      ..quadraticBezierTo(-18, size.height * .50, 6, size.height * .67)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OnboardingBackground extends StatelessWidget {
  const _OnboardingBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _OnboardingBackgroundPainter());
  }
}

class _OnboardingBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = OnboardingColors.selected.withValues(alpha: .42);
    canvas.drawCircle(Offset(size.width * .08, size.height * .16), 86, paint);
    canvas.drawCircle(Offset(size.width * .96, size.height * .10), 120, paint);

    paint.color = OnboardingColors.green.withValues(alpha: .06);
    canvas.drawCircle(Offset(size.width * .20, size.height * .82), 150, paint);
    canvas.drawCircle(Offset(size.width * .86, size.height * .72), 96, paint);

    paint.color = OnboardingColors.green.withValues(alpha: .08);
    final path = Path()
      ..moveTo(0, size.height * .64)
      ..quadraticBezierTo(
        size.width * .34,
        size.height * .58,
        size.width,
        size.height * .66,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
