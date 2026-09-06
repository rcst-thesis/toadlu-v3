import 'package:flutter/material.dart';

import 'package:tudlo/core/theme/app_colors.dart';

class AdaptiveBackButtonPlacement extends StatelessWidget {
  const AdaptiveBackButtonPlacement({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final widthScale = constraints.maxWidth / 412;
        final heightScale = constraints.maxHeight / 917;
        final scale = widthScale < heightScale ? widthScale : heightScale;
        final left = (constraints.maxWidth * 27 / 412).clamp(16.0, 32.0);
        final top = (constraints.maxHeight * 51 / 917).clamp(16.0, 32.0);

        return Padding(
          padding: EdgeInsets.only(left: left, top: top),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 93 * scale,
              height: 44 * scale,
              child: FittedBox(
                fit: BoxFit.fill,
                child: LoadBackButton(onPressed: onPressed),
              ),
            ),
          ),
        );
      },
    );
  }
}

class LoadBackButton extends StatelessWidget {
  const LoadBackButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DesignNavigationButton(
      key: const Key('load-back-button'),
      icon: Icons.undo_rounded,
      onPressed: onPressed,
    );
  }
}

class DesignNavigationButton extends StatelessWidget {
  const DesignNavigationButton({
    this.label,
    this.icon,
    this.onPressed,
    this.enabled = true,
    super.key,
  }) : assert(label != null || icon != null);

  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(8));

    return SizedBox(
      width: 93,
      height: 44,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 4.3732,
            height: 39.6269,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: enabled
                    ? AppColors.darkGreen
                    : AppColors.darkGreen.withValues(alpha: 0.35),
                borderRadius: radius,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 39.6269,
            child: FilledButton(
              onPressed: enabled ? onPressed : null,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: AppColors.green,
                disabledBackgroundColor:
                    AppColors.green.withValues(alpha: 0.35),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white70,
                shape: const RoundedRectangleBorder(borderRadius: radius),
              ),
              child: icon != null
                  ? const SizedBox(
                      width: 93,
                      height: 39.6269,
                      child: CustomPaint(painter: _BackArrowPainter()),
                    )
                  : Text(
                      label!,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 15,
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

class _BackArrowPainter extends CustomPainter {
  const _BackArrowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFBFB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(43.125, 12.625)
      ..lineTo(37.5, 18.25)
      ..lineTo(43.125, 23.875)
      ..moveTo(37.5, 18.25)
      ..lineTo(49.5, 18.25)
      ..cubicTo(52.814, 18.25, 55.5, 20.936, 55.5, 24.25)
      ..lineTo(55.5, 27.25);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BackArrowPainter oldDelegate) => false;
}
