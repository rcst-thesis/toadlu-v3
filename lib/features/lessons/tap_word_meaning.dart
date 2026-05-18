import 'package:flutter/material.dart';
import 'package:tudloapp/core/style/app_theme.dart';

/// Text shown inside the tap-to-translate tooltip.
class WordMeaning {
  final String word;
  final String meaning;
  final String note;

  const WordMeaning({
    required this.word,
    required this.meaning,
    this.note = 'Vocabulary hint',
  });
}

/// Renders a question sentence while making only one target phrase tappable.
///
/// This avoids turning normal instruction words into hints. The widget splits
/// `fullQuestionText` into before/target/after spans, underlines the target,
/// and shows a small overlay tooltip when that target is tapped.
class TapWordMeaningText extends StatefulWidget {
  final String fullQuestionText;
  final String targetPhrase;
  final String targetMeaning;
  final String directionLabel;
  final TextStyle? style;
  final TextAlign textAlign;

  const TapWordMeaningText({
    super.key,
    required this.fullQuestionText,
    required this.targetPhrase,
    required this.targetMeaning,
    required this.directionLabel,
    this.style,
    this.textAlign = TextAlign.start,
  });

  @override
  State<TapWordMeaningText> createState() => _TapWordMeaningTextState();
}

class _TapWordMeaningTextState extends State<TapWordMeaningText> {
  OverlayEntry? _entry;

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }

  void _hideTooltip() {
    _entry?.remove();
    _entry = null;
  }

  void _showTooltip(BuildContext wordContext) {
    _hideTooltip();

    // The tooltip is placed in the root overlay so it can float above cards,
    // choices, and scrollable content without changing the page layout.
    final overlay = Overlay.of(context);
    final wordBox = wordContext.findRenderObject() as RenderBox?;
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (wordBox == null || overlayBox == null) return;

    final wordTopLeft = wordBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final wordSize = wordBox.size;
    final screenSize = overlayBox.size;
    final meaning = WordMeaning(
      word: widget.targetPhrase,
      meaning: widget.targetMeaning,
      note: widget.directionLabel,
    );
    const tooltipWidth = 226.0;
    const gap = 12.0;
    const tooltipHeight = 116.0;
    // If the word is near the top of the screen, show the tooltip below it;
    // otherwise show it above to avoid covering answer choices.
    final showBelow = wordTopLeft.dy < tooltipHeight + 40;
    final left = (wordTopLeft.dx + wordSize.width / 2 - tooltipWidth / 2)
        .clamp(14.0, screenSize.width - tooltipWidth - 14)
        .toDouble();
    final top = showBelow
        ? wordTopLeft.dy + wordSize.height + gap
        : wordTopLeft.dy - tooltipHeight - gap;
    final arrowCenter = (wordTopLeft.dx + wordSize.width / 2 - left)
        .clamp(22.0, tooltipWidth - 22)
        .toDouble();

    _entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideTooltip,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: .92, end: 1),
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Opacity(
                    opacity: ((scale - .92) / .08).clamp(0, 1),
                    child: Transform.scale(scale: scale, child: child),
                  );
                },
                child: _WordMeaningTooltip(
                  meaning: meaning,
                  width: tooltipWidth,
                  arrowCenter: arrowCenter,
                  arrowOnTop: showBelow,
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_entry!);
  }

  @override
  Widget build(BuildContext context) {
    final style =
        widget.style ??
        const TextStyle(
          color: TudloColors.ink,
          fontSize: 20,
          height: 1.25,
          fontWeight: FontWeight.w900,
        );

    final targetRange = _targetRange();
    if (targetRange == null) {
      return Text(
        widget.fullQuestionText,
        style: style,
        textAlign: widget.textAlign,
      );
    }

    final before = widget.fullQuestionText.substring(0, targetRange.start);
    final target = widget.fullQuestionText.substring(
      targetRange.start,
      targetRange.end,
    );
    final after = widget.fullQuestionText.substring(targetRange.end);

    return RichText(
      textAlign: widget.textAlign,
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: before),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Builder(
              builder: (wordContext) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showTooltip(wordContext),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 120),
                    style: style.copyWith(
                      decoration: TextDecoration.underline,
                      decorationStyle: TextDecorationStyle.dotted,
                      decorationColor: TudloColors.brightGreen,
                      decorationThickness: 2,
                      backgroundColor: TudloColors.softGreen.withValues(
                        alpha: .42,
                      ),
                    ),
                    child: Text(target),
                  ),
                );
              },
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }

  TextRange? _targetRange() {
    final target = widget.targetPhrase.trim();
    if (target.isEmpty) return null;

    final fullTextLower = widget.fullQuestionText.toLowerCase();
    final targetLower = target.toLowerCase();
    final start = fullTextLower.indexOf(targetLower);
    if (start < 0) return null;

    return TextRange(start: start, end: start + target.length);
  }
}

/// Duolingo-style tooltip card with a small arrow pointing back to the word.
class _WordMeaningTooltip extends StatelessWidget {
  final WordMeaning meaning;
  final double width;
  final double arrowCenter;
  final bool arrowOnTop;

  const _WordMeaningTooltip({
    required this.meaning,
    required this.width,
    required this.arrowCenter,
    required this.arrowOnTop,
  });

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: TudloColors.forest,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .20),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    meaning.word,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meaning.meaning,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    meaning.note,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .74),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.volume_up_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (arrowOnTop) _TooltipArrow(center: arrowCenter, pointsDown: false),
        card,
        if (!arrowOnTop) _TooltipArrow(center: arrowCenter, pointsDown: true),
      ],
    );
  }
}

class _TooltipArrow extends StatelessWidget {
  final double center;
  final bool pointsDown;

  const _TooltipArrow({required this.center, required this.pointsDown});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 226,
      height: 10,
      child: CustomPaint(
        painter: _TooltipArrowPainter(center: center, pointsDown: pointsDown),
      ),
    );
  }
}

class _TooltipArrowPainter extends CustomPainter {
  final double center;
  final bool pointsDown;

  const _TooltipArrowPainter({required this.center, required this.pointsDown});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = TudloColors.forest
      ..style = PaintingStyle.fill;
    final path = Path();
    if (pointsDown) {
      path
        ..moveTo(center - 10, 0)
        ..lineTo(center + 10, 0)
        ..lineTo(center, size.height)
        ..close();
    } else {
      path
        ..moveTo(center, 0)
        ..lineTo(center - 10, size.height)
        ..lineTo(center + 10, size.height)
        ..close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TooltipArrowPainter oldDelegate) {
    return oldDelegate.center != center || oldDelegate.pointsDown != pointsDown;
  }
}
