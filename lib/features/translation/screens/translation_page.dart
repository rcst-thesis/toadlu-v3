import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudloapp/data/dictionary/dictionary_data.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/language_toggle.dart';

class _TranslateStyle {
  static const softBg = TudloColors.paper;
}

/// Simple local translation screen.
///
/// It uses the word-based DictionaryData source, plus a few simple phrase
/// mappings. It does not depend on lesson question data.
class TranslationPage extends StatefulWidget {
  const TranslationPage({super.key});

  @override
  State<TranslationPage> createState() => _TranslationPageState();
}

class _TranslationPageState extends State<TranslationPage> {
  final TextEditingController topController = TextEditingController();
  final TextEditingController bottomController = TextEditingController();

  String fromLanguage = 'Hiligaynon';
  String toLanguage = 'English';
  bool showHelpOverlay = !AppData.translateHelpDone;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    topController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    // The input listener updates the translation field immediately as the user
    // types. `_isUpdating` prevents controller changes from causing loops.
    if (_isUpdating) return;

    final input = topController.text;
    final result = _translate(input);
    _isUpdating = true;
    bottomController.text = result.translation;
    _isUpdating = false;

    if (input.trim().isNotEmpty && !AppData.translateHelpDone) {
      setState(() {
        showHelpOverlay = false;
        AppData.translateHelpDone = true;
      });
    } else {
      setState(() {});
    }
  }

  _TranslationResult _translate(String value) {
    // Detect direction by scoring both dictionaries, then use the dictionary
    // with the stronger match.
    final clean = DictionaryData.normalizeForSearch(value);
    if (clean.isEmpty) {
      return const _TranslationResult('', 'Hiligaynon', 'English');
    }

    final hilScore = _score(clean, DictionaryData.hiligaynonToEnglish);
    final engScore = _score(clean, DictionaryData.englishToHiligaynon);
    final fromHil = hilScore >= engScore;
    final dictionary = fromHil
        ? DictionaryData.hiligaynonToEnglish
        : DictionaryData.englishToHiligaynon;
    final translation = _lookup(clean, dictionary);

    fromLanguage = fromHil ? 'Hiligaynon' : 'English';
    toLanguage = fromHil ? 'English' : 'Hiligaynon';

    return _TranslationResult(translation, fromLanguage, toLanguage);
  }

  int _score(String value, Map<String, String> dictionary) {
    // Exact phrase matches score higher than individual word matches.
    final normalized = DictionaryData.normalizeForSearch(value);
    var score =
        dictionary.containsKey(normalized) ||
            DictionaryData.phraseTranslations.containsKey(normalized)
        ? 5
        : 0;
    final words = _words(value);
    for (final word in words) {
      if (dictionary.containsKey(word)) score++;
    }
    return score;
  }

  String _lookup(String value, Map<String, String> dictionary) {
    // Try an exact phrase first. If it is missing, translate known words one by
    // one while preserving spaces and basic punctuation.
    final normalized = DictionaryData.normalizeForSearch(value);
    final exact =
        DictionaryData.phraseTranslations[normalized] ?? dictionary[normalized];
    if (exact != null) return _matchCase(exact, value);

    final translatedWords = value.split(RegExp(r'(\s+)')).map((part) {
      if (part.trim().isEmpty) return part;
      final punctuation = RegExp(r'(^[^\w]+|[^\w]+$)');
      final edge = punctuation.allMatches(part).map((m) => m.group(0)!).join();
      final core = part
          .replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '')
          .toLowerCase();
      final translated = dictionary[DictionaryData.normalizeForSearch(core)];
      if (translated == null) return part;
      return edge.startsWith(part[0]) ? '$edge$translated' : '$translated$edge';
    }).join();

    return translatedWords == value
        ? 'Translation not found yet.'
        : translatedWords;
  }

  List<String> _words(String value) {
    return DictionaryData.normalizeForSearch(value)
        .split(RegExp(r'[^a-zA-Z\-]+'))
        .where((word) => word.trim().isNotEmpty)
        .toList();
  }

  String _matchCase(String translation, String source) {
    if (source.isEmpty) return translation;
    return source[0].toUpperCase() == source[0]
        ? translation[0].toUpperCase() + translation.substring(1)
        : translation;
  }

  void swapLanguages() {
    // Swap both the language labels and the text fields so users can reverse a
    // translation quickly.
    setState(() {
      final tempLang = fromLanguage;
      fromLanguage = toLanguage;
      toLanguage = tempLang;

      final tempText = topController.text;
      _isUpdating = true;
      topController.text = bottomController.text;
      bottomController.text = tempText;
      _isUpdating = false;
    });
  }

  @override
  void dispose() {
    topController.dispose();
    bottomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _TranslateStyle.softBg,
      body: Stack(
        children: [
          const Positioned.fill(child: _TranslateBackground()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 34, 24, 154),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Translate',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.archivoBlack(
                          color: TudloColors.forest,
                          fontSize: 52,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 38),
                      _TranslationLanguageCard(
                        language: fromLanguage,
                        controller: topController,
                        hint: fromLanguage == 'Hiligaynon'
                            ? 'Type Hiligaynon'
                            : 'Type English',
                        readOnly: false,
                      ),
                      const SizedBox(height: 14),
                      Center(child: _VerticalSwapButton(onTap: swapLanguages)),
                      const SizedBox(height: 14),
                      _TranslationLanguageCard(
                        language: toLanguage,
                        controller: bottomController,
                        hint: toLanguage == 'Hiligaynon'
                            ? 'Hiligaynon translation'
                            : 'English translation',
                        readOnly: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (showHelpOverlay)
            Positioned.fill(
              child: _TranslateHelpOverlay(
                onTap: () => setState(() => showHelpOverlay = false),
              ),
            ),
        ],
      ),
    );
  }
}

class _TranslateHelpOverlay extends StatelessWidget {
  final VoidCallback onTap;

  const _TranslateHelpOverlay({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final mascotWidth = (size.width * .55).clamp(190.0, 270.0);
    final bubbleWidth = (size.width * .58).clamp(200.0, 280.0);
    final mascotBottom = (size.height * .14).clamp(104.0, 150.0);
    final mascotLeft = (size.width * .07).clamp(16.0, 34.0);
    final mascotTop = size.height - mascotBottom - mascotWidth;
    final mascotVisibleTop = mascotTop + mascotWidth * .158;
    final bubbleVisibleBottom = bubbleWidth * 1.234;
    final bubbleTop = (mascotVisibleTop - bubbleVisibleBottom - 12).clamp(
      MediaQuery.paddingOf(context).top + 86,
      size.height * .46,
    );
    final bubbleLeft = (mascotLeft + mascotWidth * .5 - bubbleWidth * .5).clamp(
      12.0,
      size.width - bubbleWidth - 12,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        color: Colors.black.withValues(alpha: .34),
        child: Stack(
          children: [
            Positioned(
              left: mascotLeft,
              bottom: mascotBottom,
              child: Image.asset(
                'assets/images/dialogue/mascot2.png',
                width: mascotWidth,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            Positioned(
              left: bubbleLeft,
              top: bubbleTop,
              child: _TranslateDialogueBubble(
                width: bubbleWidth,
                message: 'Testingan ta mag type',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TranslateDialogueBubble extends StatelessWidget {
  final double width;
  final String message;

  const _TranslateDialogueBubble({required this.width, required this.message});

  @override
  Widget build(BuildContext context) {
    final bubbleHeight = width * 1920 / 1080;
    return SizedBox(
      width: width,
      height: bubbleHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/dialogue/dialoguebox.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          Positioned(
            left: width * .20,
            right: width * .20,
            top: width * .59,
            height: width * .46,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width * .58),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: TudloColors.ink,
                    fontSize: 22,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
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

class _TranslateBackground extends StatelessWidget {
  const _TranslateBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF9FFFB), TudloColors.paper, TudloColors.softGreen],
        ),
      ),
      child: CustomPaint(painter: _TranslateBackgroundPainter()),
    );
  }
}

class _TranslateBackgroundPainter extends CustomPainter {
  const _TranslateBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = TudloColors.brightGreen.withValues(alpha: .055);
    canvas.drawCircle(Offset(size.width * .10, size.height * .10), 96, paint);
    canvas.drawCircle(Offset(size.width * .96, size.height * .30), 132, paint);

    paint.color = TudloColors.forest.withValues(alpha: .045);
    canvas.drawCircle(Offset(size.width * .04, size.height * .78), 150, paint);
    canvas.drawCircle(Offset(size.width * .82, size.height * .88), 92, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TranslationResult {
  final String translation;
  final String fromLanguage;
  final String toLanguage;

  const _TranslationResult(
    this.translation,
    this.fromLanguage,
    this.toLanguage,
  );
}

class _TranslationLanguageCard extends StatelessWidget {
  final String language;
  final TextEditingController controller;
  final String hint;
  final bool readOnly;

  const _TranslationLanguageCard({
    required this.language,
    required this.controller,
    required this.hint,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    final text = controller.text.trim();
    return Container(
      constraints: const BoxConstraints(minHeight: 176),
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .13),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(_flagFor(language), style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  language,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF6B86A8),
                    fontSize: 26,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Listen',
                onPressed: text.isEmpty
                    ? null
                    : () => TudloVoiceButton.speak(context, text),
                icon: Icon(
                  Icons.volume_up_rounded,
                  color: text.isEmpty
                      ? TudloColors.muted.withValues(alpha: .35)
                      : const Color(0xFF5576A3),
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          readOnly
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
                  child: Text(
                    text.isEmpty ? hint : controller.text,
                    style: GoogleFonts.nunito(
                      color: text.isEmpty
                          ? TudloColors.muted.withValues(alpha: .60)
                          : Colors.black,
                      fontSize: 34,
                      height: 1.14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              : TextField(
                  controller: controller,
                  maxLines: null,
                  minLines: 1,
                  style: GoogleFonts.nunito(
                    color: Colors.black,
                    fontSize: 34,
                    height: 1.14,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.nunito(
                      color: TudloColors.muted.withValues(alpha: .58),
                      fontWeight: FontWeight.w900,
                    ),
                    contentPadding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
                    border: InputBorder.none,
                  ),
                ),
        ],
      ),
    );
  }

  String _flagFor(String language) {
    return language == 'English' ? '🇺🇸' : '🇵🇭';
  }
}

class _VerticalSwapButton extends StatefulWidget {
  final VoidCallback onTap;

  const _VerticalSwapButton({required this.onTap});

  @override
  State<_VerticalSwapButton> createState() => _VerticalSwapButtonState();
}

class _VerticalSwapButtonState extends State<_VerticalSwapButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? .92 : 1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: TudloColors.forest.withValues(alpha: .42),
              blurRadius: 24,
              spreadRadius: 4,
            ),
            BoxShadow(
              color: TudloColors.forest.withValues(alpha: .28),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: TudloColors.forest,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) => setState(() => _pressed = false),
            child: const SizedBox(
              width: 52,
              height: 52,
              child: Icon(
                Icons.swap_vert_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
