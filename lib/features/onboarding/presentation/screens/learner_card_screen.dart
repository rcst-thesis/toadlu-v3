import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tudlo/core/navigation/fade_page_route.dart';
import 'package:tudlo/core/theme/app_colors.dart';
import 'package:tudlo/features/onboarding/presentation/screens/name_screen.dart';

class LearnerCardScreen extends StatelessWidget {
  const LearnerCardScreen({
    required this.learnerName,
    required this.grade,
    required this.energy,
    this.earnedBadgeCount = 0,
    this.onContinue,
    super.key,
  });

  final String learnerName;
  final int grade;
  final int energy;
  final int earnedBadgeCount;
  final VoidCallback? onContinue;

  Color get _gradeColor => switch (grade) {
        2 => const Color(0xFF3E75A6),
        3 => const Color(0xFFB04444),
        _ => AppColors.green,
      };

  String get _kokaAsset => switch (grade) {
        2 => 'assets/images/koka_blue.png',
        3 => 'assets/images/koka_red.png',
        _ => 'assets/images/koka_green.png',
      };

  void _finish(BuildContext context) {
    if (onContinue case final callback?) {
      callback();
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _reset(BuildContext context) async {
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Reset learner confirmation',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const _ResetLearnerDialog(),
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
    if (confirmed != true || !context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      FadePageRoute<void>(page: const NameScreen()),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColoredBox(
        color: const Color(0xFFD9FF79),
        child: SafeArea(
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              child: SizedBox(
                key: const Key('learner-card-canvas'),
                width: 412,
                height: 917,
                child: Stack(
                  children: [
                    const Positioned.fill(child: _RotatingRays()),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 102,
                      height: 86,
                      child: FractionallySizedBox(
                        widthFactor: 0.50,
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/images/learner_card_earned.png',
                          key: const Key('learner-card-earned-heading'),
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 30,
                      top: 219,
                      child: _InteractiveFloatingCard(
                        child: _LearnerCard(
                          learnerName: learnerName,
                          grade: grade,
                          energy: energy,
                          earnedBadgeCount: earnedBadgeCount,
                          gradeColor: _gradeColor,
                          kokaAsset: _kokaAsset,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 30,
                      top: 811,
                      child: _ContinueButton(onPressed: () => _finish(context)),
                    ),
                    Positioned(
                      left: 146,
                      top: 861,
                      width: 120,
                      height: 44,
                      child: TextButton(
                        key: const Key('learner-card-reset-button'),
                        onPressed: () => _reset(context),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xB3000000),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationThickness: 1.2,
                          ),
                        ),
                        child: const Text('reset'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveFloatingCard extends StatefulWidget {
  const _InteractiveFloatingCard({required this.child});

  final Widget child;

  @override
  State<_InteractiveFloatingCard> createState() =>
      _InteractiveFloatingCardState();
}

class _InteractiveFloatingCardState extends State<_InteractiveFloatingCard>
    with TickerProviderStateMixin {
  late final AnimationController _floatController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  late final AnimationController _tiltController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );

  double _targetTiltX = 0;
  double _targetTiltY = 0;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion) {
      _floatController
        ..stop()
        ..value = 0;
      _tiltController
        ..stop()
        ..value = 0;
    } else if (!_floatController.isAnimating) {
      _floatController.repeat();
    }
  }

  void _tilt(Offset localPosition) {
    final box = context.findRenderObject()! as RenderBox;
    final normalizedX =
        (localPosition.dx / box.size.width - 0.5).clamp(-0.5, 0.5);
    final normalizedY =
        (localPosition.dy / box.size.height - 0.5).clamp(-0.5, 0.5);
    // Rotate the touched edge away from the viewer so it feels pressed down.
    _targetTiltX = normalizedY * 0.12;
    _targetTiltY = -normalizedX * 0.16;
    _tiltController.forward(from: 0);
  }

  double get _tiltStrength {
    final value = _tiltController.value;
    if (value <= 0.24) {
      return Curves.easeOutCubic.transform(value / 0.24);
    }
    return 1 - Curves.elasticOut.transform((value - 0.24) / 0.76);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _tiltController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Listener(
        key: const Key('learner-card-tilt-target'),
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) => _tilt(event.localPosition),
        child: AnimatedBuilder(
          animation: Listenable.merge([_floatController, _tiltController]),
          child: widget.child,
          builder: (context, child) {
            final bob = math.sin(_floatController.value * math.pi * 2) * 4;
            final strength = _tiltStrength;
            final tiltTransform = Matrix4.identity();
            if (strength.abs() > 0.0001) {
              tiltTransform
                ..setEntry(3, 2, 0.0012)
                ..rotateX(_targetTiltX * strength)
                ..rotateY(_targetTiltY * strength);
            }
            return Transform.translate(
              offset: Offset(0, bob),
              child: Transform(
                key: const Key('learner-card-tilt-transform'),
                alignment: Alignment.center,
                transform: tiltTransform,
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ResetLearnerDialog extends StatelessWidget {
  const _ResetLearnerDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          key: const Key('learner-reset-dialog'),
          width: 304,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
          decoration: BoxDecoration(
            color: const Color(0xFF98EF6F),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.darkGreen, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: AppColors.darkGreen,
                offset: Offset(0, 8),
                blurRadius: 0,
              ),
              BoxShadow(
                color: Color(0x33000000),
                offset: Offset(0, 12),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'reset learner?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                'balik kita sa name screen kag magsugod liwat?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.3),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _ResetDialogButton(
                      key: const Key('learner-reset-cancel-button'),
                      label: 'cancel',
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ResetDialogButton(
                      key: const Key('learner-reset-confirm-button'),
                      label: 'reset',
                      labelColor: const Color(0xFFFF5260),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResetDialogButton extends StatelessWidget {
  const _ResetDialogButton({
    required this.label,
    required this.onPressed,
    this.labelColor = Colors.white,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        children: [
          Positioned.fill(
            top: 5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.darkGreen,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned.fill(
            bottom: 5,
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearnerCard extends StatelessWidget {
  const _LearnerCard({
    required this.learnerName,
    required this.grade,
    required this.energy,
    required this.earnedBadgeCount,
    required this.gradeColor,
    required this.kokaAsset,
  });

  final String learnerName;
  final int grade;
  final int energy;
  final int earnedBadgeCount;
  final Color gradeColor;
  final String kokaAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('learner-card'),
      width: 352,
      height: 561,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(17),
        boxShadow: const [
          BoxShadow(
            color: Color(0xAAFFF176),
            spreadRadius: 4,
            blurRadius: 20,
          ),
          BoxShadow(
            color: Color(0x66FFD54F),
            spreadRadius: 9,
            blurRadius: 30,
          ),
          BoxShadow(
              color: Color(0x55000000), offset: Offset(0, 5), blurRadius: 6),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(
            left: 16,
            top: 14,
            width: 320,
            height: 36,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'LEARNER CARD',
                  key: Key('learner-card-header-text'),
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 32,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 64,
            width: 320,
            height: 217,
            child: DecoratedBox(
              key: const Key('learner-card-portrait-panel'),
              decoration: BoxDecoration(
                color: const Color(0xFFA2A1A1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 24, 13, 23),
                child: Image.asset(
                  kokaAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 292,
            width: 320,
            height: 169,
            child: _DetailsPanel(
              key: const Key('learner-card-details-panel'),
              learnerName: learnerName,
              grade: grade,
              energy: energy,
              gradeColor: gradeColor,
            ),
          ),
          Positioned(
            left: 1,
            top: 475,
            width: 350,
            height: 65,
            child: _BadgesPanel(
              earnedBadgeCount: earnedBadgeCount,
              earnedColor: gradeColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({
    required this.learnerName,
    required this.grade,
    required this.energy,
    required this.gradeColor,
    super.key,
  });

  final String learnerName;
  final int grade;
  final int energy;
  final Color gradeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFA2A1A1),
        borderRadius: BorderRadius.circular(7),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 18,
            top: 13,
            width: 205,
            height: 25,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                learnerName,
                key: const Key('learner-card-name'),
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            right: 17,
            top: 20,
            child: Text(
              'grade $grade',
              key: const Key('learner-card-grade'),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const Positioned(
            left: 13,
            top: 38,
            width: 294,
            child: Divider(height: 1, thickness: 1, color: Colors.black),
          ),
          const Positioned(
            left: 23,
            top: 47,
            child: Text('hil progress', style: TextStyle(fontSize: 12)),
          ),
          const Positioned(
            right: 20,
            top: 47,
            child: Text('eng progress', style: TextStyle(fontSize: 12)),
          ),
          Positioned(
            left: 23,
            top: 66,
            width: 282,
            height: 15,
            child: _SegmentedProgress(value: energy, color: gradeColor),
          ),
          const Positioned(
            left: 23,
            top: 89,
            child: _CounterTile(label: 'words saved'),
          ),
          const Positioned(
            left: 122,
            top: 89,
            child: _CounterTile(label: 'stickers'),
          ),
          const Positioned(
            left: 221,
            top: 89,
            child: _CounterTile(label: 'lessons finished'),
          ),
        ],
      ),
    );
  }
}

class _SegmentedProgress extends StatelessWidget {
  const _SegmentedProgress({required this.value, required this.color});

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value percent learning energy',
      child: Container(
        key: const Key('learner-card-energy'),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFD9D9D9),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            for (var index = 0; index < 20; index++) ...[
              Expanded(
                child: SizedBox.expand(
                  child: DecoratedBox(
                    key: Key('learner-card-progress-segment-$index'),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA2A1A1),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
              ),
              if (index != 19) const SizedBox(width: 1.25),
            ],
          ],
        ),
      ),
    );
  }
}

class _CounterTile extends StatelessWidget {
  const _CounterTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 16,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(
                    fontSize: 9,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(
                '0',
                style: TextStyle(
                  fontSize: 43,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgesPanel extends StatelessWidget {
  const _BadgesPanel({
    required this.earnedBadgeCount,
    required this.earnedColor,
  });

  static const _assets = <String>[
    'assets/images/badge_1.png',
    'assets/images/badge_2.png',
    'assets/images/badge_3.png',
    'assets/images/badge_4.png',
    'assets/images/badge_5.png',
    'assets/images/badge_6.png',
    'assets/images/badge_7.png',
    'assets/images/badge_8.png',
  ];

  final int earnedBadgeCount;
  final Color earnedColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFA2A1A1),
      child: Stack(
        children: [
          const Positioned(
            left: 17,
            top: 5,
            child: Text(
              "learner's badges",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          Positioned(
            left: 17,
            top: 27,
            right: 17,
            height: 33,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var index = 0; index < _assets.length; index++)
                  SizedBox(
                    width: 33,
                    height: 33,
                    child: Semantics(
                      label:
                          'badge ${index + 1}, ${index < earnedBadgeCount ? 'earned' : 'locked'}',
                      image: true,
                      child: index < earnedBadgeCount
                          ? ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                earnedColor,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                _assets[index],
                                key: Key('learner-badge-${index + 1}'),
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            )
                          : Image.asset(
                              _assets[index],
                              key: Key('learner-badge-${index + 1}'),
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('learner-card-continue-button'),
      width: 352.295,
      height: 44,
      child: Stack(
        children: [
          Positioned.fill(
            top: 4.373,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.darkGreen,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned.fill(
            bottom: 4.373,
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: AppColors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'hop. hop. hop. lets gooo',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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

class _RaysPainter extends CustomPainter {
  const _RaysPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = const Color(0x558EBF59);
    const rays = 16;
    for (var index = 0; index < rays; index += 2) {
      final start = index * 6.283185307179586 / rays;
      final end = (index + 1) * 6.283185307179586 / rays;
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(center.dx + 720 * math.cos(start),
              center.dy + 720 * math.sin(start))
          ..lineTo(
              center.dx + 720 * math.cos(end), center.dy + 720 * math.sin(end))
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RaysPainter oldDelegate) => false;
}

class _RotatingRays extends StatefulWidget {
  const _RotatingRays();

  @override
  State<_RotatingRays> createState() => _RotatingRaysState();
}

class _RotatingRaysState extends State<_RotatingRays>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.rotate(
          key: const Key('learner-card-rotating-rays'),
          angle: _controller.value * math.pi * 2,
          child: child,
        ),
        child: const CustomPaint(painter: _RaysPainter()),
      ),
    );
  }
}
