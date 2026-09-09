import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Artwork from the Figma card with the readable card copy rendered by Flutter.
class HomeWordOfTheDay extends StatefulWidget {
  const HomeWordOfTheDay({
    this.word = 'balay',
    this.definition = 'naga istar ako sa akong balay',
    this.initiallyFavorited = false,
    this.onFavoriteChanged,
    this.onPronunciationRequested = _placeholderPronunciation,
    super.key,
  });

  final String word;
  final String definition;
  final bool initiallyFavorited;
  final ValueChanged<bool>? onFavoriteChanged;

  /// Inject the real pronunciation player here when its VO is available.
  final Future<void> Function() onPronunciationRequested;

  static Future<void> _placeholderPronunciation() async {}

  @override
  State<HomeWordOfTheDay> createState() => _HomeWordOfTheDayState();
}

class _HomeWordOfTheDayState extends State<HomeWordOfTheDay> {
  static const _backgroundColor = Color(0xFF8F6A42);
  static const _artboardWidth = 378.0;
  static const _artboardHeight = 216.0;
  static const _heartColor = Color(0xFFEB5050);
  static const _feedbackDuration = Duration(milliseconds: 160);

  Timer? _heartFeedbackTimer;
  Timer? _speakerFeedbackTimer;
  late bool _isFavorited = widget.initiallyFavorited;
  var _heartPopped = false;
  var _speakerPressed = false;

  void _toggleFavorite() {
    setState(() {
      _isFavorited = !_isFavorited;
      _heartPopped = true;
    });
    widget.onFavoriteChanged?.call(_isFavorited);
    _heartFeedbackTimer?.cancel();
    _heartFeedbackTimer = Timer(_feedbackDuration, () {
      if (mounted) setState(() => _heartPopped = false);
    });
  }

  void _requestPronunciation() {
    setState(() => _speakerPressed = true);
    _speakerFeedbackTimer?.cancel();
    _speakerFeedbackTimer = Timer(_feedbackDuration, () {
      if (mounted) setState(() => _speakerPressed = false);
    });

    unawaited(widget.onPronunciationRequested());
  }

  @override
  void dispose() {
    _heartFeedbackTimer?.cancel();
    _speakerFeedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('home-word-of-the-day'),
      label: 'Word of the day: ${widget.word}. ${widget.definition}',
      child: AspectRatio(
        aspectRatio: _artboardWidth / _artboardHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = constraints.maxWidth / _artboardWidth;
            return Stack(
              children: [
                Positioned.fill(
                  child: SvgPicture.asset(
                    'assets/images/home_word_of_the_day.svg',
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                ),
                // The supplied SVG turns its labels into paths. These masks
                // keep its card artwork while Flutter owns readable text.
                _TextMask(
                    left: 40, top: 5, width: 300, height: 46, scale: scale),
                _TextMask(
                    left: 80, top: 92, width: 218, height: 78, scale: scale),
                _TextMask(
                    left: 76, top: 174, width: 226, height: 24, scale: scale),
                _CardText(
                  text: 'word of the day',
                  left: 40,
                  top: 9,
                  width: 300,
                  height: 38,
                  scale: scale,
                  fontSize: 29,
                ),
                _CardText(
                  text: widget.word,
                  left: 80,
                  top: 94,
                  width: 218,
                  height: 74,
                  scale: scale,
                  fontSize: 58,
                  autoFit: true,
                ),
                _CardText(
                  text: widget.definition,
                  left: 76,
                  top: 176,
                  width: 226,
                  height: 20,
                  scale: scale,
                  fontSize: 11,
                ),
                // Replace the SVG's static heart with an interactive Flutter
                // control while preserving the card's original location.
                _TextMask(
                    left: 304, top: 158, width: 58, height: 48, scale: scale),
                Positioned(
                  left: 306 * scale,
                  top: 157 * scale,
                  width: 54 * scale,
                  height: 54 * scale,
                  child: _WordCardIconButton(
                    key: const Key('home-word-favorite-button'),
                    semanticLabel: _isFavorited
                        ? 'Remove ${widget.word} from favorites'
                        : 'Add ${widget.word} to favorites',
                    toggled: _isFavorited,
                    onTap: _toggleFavorite,
                    child: AnimatedScale(
                      scale: _heartPopped ? 1.12 : 1,
                      duration: _feedbackDuration,
                      curve: Curves.easeOutBack,
                      child: AnimatedSwitcher(
                        duration: _feedbackDuration,
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(
                          scale: animation,
                          child: child,
                        ),
                        child: Icon(
                          _isFavorited
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          key: ValueKey(_isFavorited),
                          color: _heartColor,
                          size: 34 * scale,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 163 * scale,
                  top: 49 * scale,
                  width: 53 * scale,
                  height: 53 * scale,
                  child: _WordCardIconButton(
                    key: const Key('home-word-speaker-button'),
                    semanticLabel: 'Play pronunciation for ${widget.word}',
                    onTap: _requestPronunciation,
                    child: AnimatedScale(
                      scale: _speakerPressed ? .9 : 1,
                      duration: _feedbackDuration,
                      curve: Curves.easeOutCubic,
                      // Keep the visual circle at the SVG's original 35 x 35
                      // size; the surrounding 53 x 53 area remains tappable.
                      child: SizedBox(
                        width: 35 * scale,
                        height: 35 * scale,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            color: Color(0xFFB88956),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.volume_up_rounded,
                            color: Colors.white,
                            size: 20 * scale,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TextMask extends StatelessWidget {
  const _TextMask({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.scale,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left * scale,
      top: top * scale,
      width: width * scale,
      height: height * scale,
      child: const ColoredBox(color: _HomeWordOfTheDayState._backgroundColor),
    );
  }
}

class _WordCardIconButton extends StatelessWidget {
  const _WordCardIconButton({
    required this.semanticLabel,
    required this.onTap,
    required this.child,
    this.toggled,
    super.key,
  });

  final String semanticLabel;
  final VoidCallback onTap;
  final Widget child;
  final bool? toggled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      toggled: toggled,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: onTap,
          radius: 28,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          containedInkWell: true,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _CardText extends StatelessWidget {
  const _CardText({
    required this.text,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.scale,
    required this.fontSize,
    this.autoFit = false,
  });

  final String text;
  final double left;
  final double top;
  final double width;
  final double height;
  final double scale;
  final double fontSize;
  final bool autoFit;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left * scale,
      top: top * scale,
      width: width * scale,
      height: height * scale,
      child: autoFit
          ? FittedBox(
              fit: BoxFit.scaleDown,
              child: _textWidget(),
            )
          : Center(child: _textWidget()),
    );
  }

  Widget _textWidget() {
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.white,
        fontFamily: 'ComicRelief',
        fontSize: fontSize * scale,
        fontWeight: FontWeight.w700,
        height: 1,
      ),
    );
  }
}
