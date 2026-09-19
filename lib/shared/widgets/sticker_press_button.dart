import 'package:flutter/material.dart';

/// The app's standard interactive button: a chunky "sticker" that
/// physically presses down, not just a static 3D-looking bevel. A solid
/// front layer sits on top of a darker depth layer (faking a hard offset
/// shadow, `blurRadius: 0`, matching the app's flat sticker-card
/// convention elsewhere); on press the front layer slides down to meet the
/// depth layer, and springs back up on release.
///
/// Reach for this before reaching for a bare `FilledButton`/
/// `ElevatedButton`/`TextButton` -- this (or an `Expanded` pair of these
/// side by side) is meant to be the one button look used everywhere in the
/// app, not a one-off.
///
/// Sizing/geometry has sensible defaults; only [label], [onPressed],
/// [frontColor], and [depthColor] usually need to be supplied -- colors
/// are deliberately required rather than defaulted, since a good depth
/// shade genuinely depends on the front color chosen per call site.
class StickerPressButton extends StatefulWidget {
  const StickerPressButton({
    this.label,
    this.child,
    required this.onPressed,
    required this.frontColor,
    required this.depthColor,
    this.labelColor = Colors.white,
    this.height = 48,
    this.restLift = 5,
    this.borderRadius = 8,
    this.fontSize = 15,
    this.enabled = true,
    super.key,
  }) : assert(label != null || child != null);

  final String? label;

  /// Rendered in place of [label] when supplied -- e.g. an icon, for
  /// buttons that aren't a plain text CTA.
  final Widget? child;
  final VoidCallback onPressed;
  final Color frontColor;
  final Color depthColor;
  final Color labelColor;
  final double height;
  final double restLift;
  final double borderRadius;
  final double fontSize;

  /// When `false`, taps are ignored and both layers are dimmed -- same
  /// disabled treatment `DesignNavigationButton` used before adopting this
  /// widget.
  final bool enabled;

  @override
  State<StickerPressButton> createState() => _StickerPressButtonState();
}

class _StickerPressButtonState extends State<StickerPressButton> {
  static const _pressDuration = Duration(milliseconds: 80);

  var _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final frontColor = widget.enabled
        ? widget.frontColor
        : widget.frontColor.withValues(alpha: 0.35);
    final depthColor = widget.enabled
        ? widget.depthColor
        : widget.depthColor.withValues(alpha: 0.35);

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          // Offset down from the top by exactly `restLift` -- its own top
          // edge then lines up with the front layer's top edge in its
          // *pressed* position, so this can never peek out above the front
          // in either state, only below (the 3D "lip" at rest, fully
          // covered when pressed). Two wrong alternatives, for the record:
          // a `Positioned.fill` with no top offset shows a shadow band
          // above once pressed; a thin bottom-only strip sized to just
          // `restLift` is tall enough to avoid that, but can end up
          // shorter than its own corner radius, warping the rounded
          // corners into a squashed pill shape instead of a normal
          // rounded rectangle.
          Positioned(
            left: 0,
            right: 0,
            top: widget.restLift,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: depthColor,
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: _pressDuration,
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            top: _pressed ? widget.restLift : 0,
            bottom: _pressed ? 0 : widget.restLift,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: widget.enabled ? (_) => _setPressed(true) : null,
              onTapCancel: widget.enabled ? () => _setPressed(false) : null,
              onTapUp: widget.enabled ? (_) => _setPressed(false) : null,
              onTap: widget.enabled ? widget.onPressed : null,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: frontColor,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
                child: Center(
                  child: widget.child ??
                      Text(
                        widget.label!,
                        style: TextStyle(
                          color: widget.labelColor,
                          fontSize: widget.fontSize,
                          fontWeight: FontWeight.w700,
                        ),
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
