import 'package:flutter/material.dart';
import 'package:tudloapp/core/style/app_theme.dart';
import 'package:tudloapp/features/lessons/lesson_bank.dart';

String translatedMeaningFor(String text) {
  final normalized = text.trim().toLowerCase();
  if (normalized.isEmpty) return '';

  for (final term in LessonBank.terms) {
    if (term.eng.toLowerCase() == normalized) return term.hil.toLowerCase();
    if (term.hil.toLowerCase() == normalized) return term.eng.toLowerCase();
  }

  const extra = {
    'aga': 'morning',
    'morning': 'aga',
    'hapon': 'afternoon',
    'afternoon': 'hapon',
    'gab-i': 'evening',
    'evening': 'gab-i',
    'puno': 'tree',
    'tree': 'puno',
    'kan-on': 'rice',
    'rice': 'kan-on',
    'maayong': 'good',
    'good': 'maayong',
    'nagkaon': 'ate',
    'ate': 'nagkaon',
    'nagabasa': 'reading',
    'reading': 'nagabasa',
    'sang': 'of',
    'of': 'sang',
    'hatag': 'give',
    'give': 'hatag',
    'basa': 'read',
    'read': 'basa',
    'sulat': 'write',
    'write': 'sulat',
    'pamati': 'listen',
    'listen': 'pamati',
    'hambal': 'speak',
    'speak': 'hambal',
    'bakal': 'buy',
    'buy': 'bakal',
    'thank you': 'salamat',
    'good morning': 'maayong aga',
    'good afternoon': 'maayong hapon',
    'good evening': 'maayong gab-i',
    'i am eating': 'nagakaon ako',
    'nagakaon ako': 'i am eating',
    'i am reading': 'nagabasa ako',
    'nagabasa ako': 'i am reading',
  };

  return extra[normalized] ?? '';
}

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

/// Renders a question sentence while making known vocabulary words tappable.
///
/// Normal instruction words stay plain unless they exist in the vocabulary
/// lookup. This lets Hiligaynon sentence words such as "ako" and "sang" each
/// show their own meaning without hand-authoring every target in LessonBank.
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
  @override
  void dispose() {
    _MeaningTooltipOverlay.hide();
    super.dispose();
  }

  void _showTooltip(BuildContext wordContext, String meaning) {
    _MeaningTooltipOverlay.show(
      context: context,
      anchorContext: wordContext,
      meaning: meaning,
    );
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

    final targets = _tappableTargets();
    if (targets.isEmpty) {
      return Text(
        widget.fullQuestionText,
        style: style,
        textAlign: widget.textAlign,
      );
    }

    final children = <InlineSpan>[];
    var cursor = 0;
    for (final target in targets) {
      if (target.start > cursor) {
        children.add(
          TextSpan(text: widget.fullQuestionText.substring(cursor, target.start)),
        );
      }
      children.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Builder(
            builder: (wordContext) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showTooltip(wordContext, target.meaning),
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
                  child: Text(
                    widget.fullQuestionText.substring(target.start, target.end),
                  ),
                ),
              );
            },
          ),
        ),
      );
      cursor = target.end;
    }
    if (cursor < widget.fullQuestionText.length) {
      children.add(TextSpan(text: widget.fullQuestionText.substring(cursor)));
    }

    return RichText(
      textAlign: widget.textAlign,
      text: TextSpan(style: style, children: children),
    );
  }

  List<_TappableTextTarget> _tappableTargets() {
    final targets = <_TappableTextTarget>[];
    final occupied = List<bool>.filled(widget.fullQuestionText.length, false);

    for (final phrase in _knownPhrases()) {
      final matches = _phraseMatches(phrase);
      for (final match in matches) {
        final overlaps = occupied
            .sublist(match.start, match.end)
            .any((isTaken) => isTaken);
        if (overlaps) continue;
        final meaning = translatedMeaningFor(match.text);
        if (meaning.isEmpty) continue;
        targets.add(
          _TappableTextTarget(
            start: match.start,
            end: match.end,
            meaning: meaning,
          ),
        );
        for (var i = match.start; i < match.end; i++) {
          occupied[i] = true;
        }
      }
    }
    targets.sort((a, b) => a.start.compareTo(b.start));
    return targets;
  }

  List<String> _knownPhrases() {
    final phrases = <String>{
      for (final term in LessonBank.terms) term.hil,
      for (final term in LessonBank.terms) term.eng,
      'maayong',
      'nagkaon',
      'nagabasa',
      'sang',
      'aga',
      'hapon',
      'gab-i',
      'kan-on',
      'hatag',
      'basa',
      'sulat',
      'pamati',
      'hambal',
      'bakal',
      'thank you',
      'good morning',
      'good afternoon',
      'good evening',
      'i am eating',
      'i am reading',
    };
    return phrases.toList()
      ..sort((a, b) {
        final wordCountCompare = _wordCount(b).compareTo(_wordCount(a));
        if (wordCountCompare != 0) return wordCountCompare;
        return b.length.compareTo(a.length);
      });
  }

  int _wordCount(String value) {
    return RegExp(r"[A-Za-z]+(?:[-'][A-Za-z]+)*")
        .allMatches(value)
        .length;
  }

  List<_PhraseMatch> _phraseMatches(String phrase) {
    final escaped = RegExp.escape(phrase);
    final regex = RegExp(
      r'(?<![A-Za-z])' + escaped + r'(?![A-Za-z])',
      caseSensitive: false,
    );
    return [
      for (final match in regex.allMatches(widget.fullQuestionText))
        _PhraseMatch(
          start: match.start,
          end: match.end,
          text: widget.fullQuestionText.substring(match.start, match.end),
        ),
    ];
  }
}

class _TappableTextTarget {
  final int start;
  final int end;
  final String meaning;

  const _TappableTextTarget({
    required this.start,
    required this.end,
    required this.meaning,
  });
}

class _PhraseMatch {
  final int start;
  final int end;
  final String text;

  const _PhraseMatch({
    required this.start,
    required this.end,
    required this.text,
  });
}

class WordMeaningTooltipTarget extends StatefulWidget {
  final String meaning;
  final Widget child;

  const WordMeaningTooltipTarget({
    super.key,
    required this.meaning,
    required this.child,
  });

  @override
  State<WordMeaningTooltipTarget> createState() =>
      _WordMeaningTooltipTargetState();
}

class _WordMeaningTooltipTargetState extends State<WordMeaningTooltipTarget> {
  @override
  void dispose() {
    _MeaningTooltipOverlay.hide();
    super.dispose();
  }

  void _showTooltip(BuildContext anchorContext) {
    _MeaningTooltipOverlay.show(
      context: context,
      anchorContext: anchorContext,
      meaning: widget.meaning,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (anchorContext) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPress: () => _showTooltip(anchorContext),
          child: widget.child,
        );
      },
    );
  }
}

enum _TooltipPlacement { left, below, above }

class _MeaningTooltipOverlay {
  static final List<OverlayEntry> _activeEntries = [];

  static void hide() {
    for (final entry in List<OverlayEntry>.from(_activeEntries)) {
      entry.remove();
    }
    _activeEntries.clear();
  }

  static void show({
    required BuildContext context,
    required BuildContext anchorContext,
    required String meaning,
  }) {
    hide();
    final cleanMeaning = meaning.trim().toLowerCase();
    if (cleanMeaning.isEmpty) return;

    final overlay = Overlay.of(context);
    final anchorBox = anchorContext.findRenderObject() as RenderBox?;
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (anchorBox == null || overlayBox == null) return;

    final anchorTopLeft = anchorBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final anchorSize = anchorBox.size;
    final screenSize = overlayBox.size;
    const tooltipWidth = 226.0;
    const tooltipHeight = 62.0;
    const gap = 10.0;
    const edge = 14.0;

    var placement = _TooltipPlacement.left;
    var left = anchorTopLeft.dx - tooltipWidth - gap;
    var top = anchorTopLeft.dy + (anchorSize.height - tooltipHeight) / 2;

    if (left < edge) {
      placement = anchorTopLeft.dy < tooltipHeight + 40
          ? _TooltipPlacement.below
          : _TooltipPlacement.above;
      left = anchorTopLeft.dx + anchorSize.width / 2 - tooltipWidth / 2;
      top = placement == _TooltipPlacement.below
          ? anchorTopLeft.dy + anchorSize.height + gap
          : anchorTopLeft.dy - tooltipHeight - gap;
    }

    left = left.clamp(edge, screenSize.width - tooltipWidth - edge).toDouble();
    top = top.clamp(edge, screenSize.height - tooltipHeight - edge).toDouble();
    final arrowCenter = (anchorTopLeft.dx + anchorSize.width / 2 - left)
        .clamp(22.0, tooltipWidth - 22)
        .toDouble();

    final entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: hide,
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
                  meaning: WordMeaning(word: cleanMeaning, meaning: cleanMeaning),
                  width: tooltipWidth,
                  arrowCenter: arrowCenter,
                  placement: placement,
                ),
              ),
            ),
          ],
        );
      },
    );
    _activeEntries.add(entry);
    overlay.insert(entry);
  }
}

/// Duolingo-style tooltip card with a small arrow pointing back to the word.
class _WordMeaningTooltip extends StatelessWidget {
  final WordMeaning meaning;
  final double width;
  final double arrowCenter;
  final _TooltipPlacement placement;

  const _WordMeaningTooltip({
    required this.meaning,
    required this.width,
    required this.arrowCenter,
    required this.placement,
  });

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: TudloColors.brightGreen,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .20),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  meaning.meaning,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.volume_up_rounded,
                color: Colors.white,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );

    if (placement == _TooltipPlacement.left) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          card,
          const _TooltipSideArrow(pointsRight: true),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (placement == _TooltipPlacement.below)
          _TooltipArrow(
            center: arrowCenter,
            pointsDown: false,
            width: width,
          ),
        card,
        if (placement == _TooltipPlacement.above)
          _TooltipArrow(center: arrowCenter, pointsDown: true, width: width),
      ],
    );
  }
}

class _TooltipSideArrow extends StatelessWidget {
  final bool pointsRight;

  const _TooltipSideArrow({required this.pointsRight});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10,
      height: 22,
      child: CustomPaint(
        painter: _TooltipSideArrowPainter(pointsRight: pointsRight),
      ),
    );
  }
}

class _TooltipSideArrowPainter extends CustomPainter {
  final bool pointsRight;

  const _TooltipSideArrowPainter({required this.pointsRight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = TudloColors.brightGreen
      ..style = PaintingStyle.fill;
    final path = Path();
    if (pointsRight) {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, size.height / 2)
        ..lineTo(0, size.height)
        ..close();
    } else {
      path
        ..moveTo(size.width, 0)
        ..lineTo(0, size.height / 2)
        ..lineTo(size.width, size.height)
        ..close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TooltipSideArrowPainter oldDelegate) {
    return oldDelegate.pointsRight != pointsRight;
  }
}

class _TooltipArrow extends StatelessWidget {
  final double center;
  final bool pointsDown;
  final double width;

  const _TooltipArrow({
    required this.center,
    required this.pointsDown,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
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
      ..color = TudloColors.brightGreen
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
