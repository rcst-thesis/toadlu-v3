import 'package:flutter/material.dart';

/// The interactive visual shell for one Home sticker thumbnail.
///
/// It intentionally owns only presentation motion. Collection state and the
/// image/locked overlay remain in [HomeStickerGrid], so this tile can be
/// reused unchanged by the future full sticker screen.
class HomeStickerThumbnailTile extends StatefulWidget {
  const HomeStickerThumbnailTile({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<HomeStickerThumbnailTile> createState() =>
      _HomeStickerThumbnailTileState();
}

class _HomeStickerThumbnailTileState extends State<HomeStickerThumbnailTile>
    with SingleTickerProviderStateMixin {
  static const _tiltDuration = Duration(milliseconds: 850);
  // The learner card is far larger than a 62 px thumbnail. Keep its motion
  // profile while scaling only the rendered angle so the same response reads.
  static const _thumbnailTiltMultiplier = 2.4;

  late final AnimationController _tiltController = AnimationController(
    vsync: this,
    duration: _tiltDuration,
  );

  double _targetTiltX = 0;
  double _targetTiltY = 0;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _tiltController
        ..stop()
        ..value = 0;
    }
  }

  void _tilt(Offset localPosition) {
    if (_reduceMotion) return;
    final box = context.findRenderObject()! as RenderBox;
    final normalizedX =
        (localPosition.dx / box.size.width - .5).clamp(-.5, .5);
    final normalizedY =
        (localPosition.dy / box.size.height - .5).clamp(-.5, .5);
    // Match the learner card's touch-to-tilt contract exactly.
    _targetTiltX = normalizedY * .12;
    _targetTiltY = -normalizedX * .16;
    _tiltController.forward(from: 0);
  }

  double get _tiltStrength {
    final value = _tiltController.value;
    if (value <= .24) {
      return Curves.easeOutCubic.transform(value / .24);
    }
    return 1 - Curves.elasticOut.transform((value - .24) / .76);
  }

  @override
  void dispose() {
    _tiltController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) => _tilt(event.localPosition),
        child: AnimatedBuilder(
          animation: _tiltController,
          child: widget.child,
          builder: (context, child) {
            final strength = _tiltStrength;
            final tiltTransform = Matrix4.identity();
            if (strength.abs() > .0001) {
              tiltTransform
                ..setEntry(3, 2, .0012)
                ..rotateX(_targetTiltX * strength * _thumbnailTiltMultiplier)
                ..rotateY(_targetTiltY * strength * _thumbnailTiltMultiplier);
            }
            return Transform(
              alignment: Alignment.center,
              transform: tiltTransform,
              child: child,
            );
          },
        ),
      ),
    );
  }
}
