import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudloapp/data/dictionary/dictionary_data.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/theme/app_theme.dart';

class _TranslateStyle {
  static const green = TudloColors.brightGreen;
  static const darkGreen = TudloColors.forest;
  static const softBg = TudloColors.paper;
  static const softGreen = TudloColors.softGreen;
  static const cardShadow = Color(0x2608C66B);
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
    final clean = value.trim().toLowerCase();
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
    var score = dictionary.containsKey(value) ? 5 : 0;
    final words = _words(value);
    for (final word in words) {
      if (dictionary.containsKey(word)) score++;
    }
    return score;
  }

  String _lookup(String value, Map<String, String> dictionary) {
    // Try an exact phrase first. If it is missing, translate known words one by
    // one while preserving spaces and basic punctuation.
    final exact = DictionaryData.phraseTranslations[value] ?? dictionary[value];
    if (exact != null) return _matchCase(exact, value);

    final translatedWords = value.split(RegExp(r'(\s+)')).map((part) {
      if (part.trim().isEmpty) return part;
      final punctuation = RegExp(r'(^[^\w]+|[^\w]+$)');
      final edge = punctuation.allMatches(part).map((m) => m.group(0)!).join();
      final core = part
          .replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '')
          .toLowerCase();
      final translated = dictionary[core];
      if (translated == null) return part;
      return edge.startsWith(part[0]) ? '$edge$translated' : '$translated$edge';
    }).join();

    return translatedWords == value
        ? 'Translation not found yet.'
        : translatedWords;
  }

  List<String> _words(String value) {
    return value
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

  void _useQuickPhrase(String phrase) {
    // Quick phrase chips simply fill the input field; the listener performs the
    // translation.
    topController.text = phrase;
    topController.selection = TextSelection.collapsed(offset: phrase.length);
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
                          color: TudloColors.green,
                          fontSize: 26,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 26),
                      _LanguageBar(
                        fromLanguage: fromLanguage,
                        toLanguage: toLanguage,
                        onSwap: swapLanguages,
                      ),
                      const SizedBox(height: 18),
                      _QuickPhraseChips(onSelected: _useQuickPhrase),
                      const SizedBox(height: 16),
                      _TranslationCard(
                        title: 'Input',
                        controller: topController,
                        hint: fromLanguage == 'Hiligaynon'
                            ? 'Type Hiligaynon here...'
                            : 'Type English here...',
                        readOnly: false,
                        minLines: 4,
                      ),
                      const SizedBox(height: 18),
                      _TranslationCard(
                        title: 'Translation',
                        controller: bottomController,
                        hint: 'Translation appears here...',
                        readOnly: true,
                        minLines: 4,
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

class _LanguageBar extends StatelessWidget {
  final String fromLanguage;
  final String toLanguage;
  final VoidCallback onSwap;

  const _LanguageBar({
    required this.fromLanguage,
    required this.toLanguage,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: TudloColors.forest.withValues(alpha: .07),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
          const BoxShadow(
            color: _TranslateStyle.cardShadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _LanguageChoice(label: fromLanguage)),
          // Swap button:
          // Reverses the source and target languages, then recalculates the
          // current translation.
          _SwapButton(onTap: onSwap),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: _LanguageChoice(label: toLanguage, alignRight: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwapButton extends StatefulWidget {
  final VoidCallback onTap;

  const _SwapButton({required this.onTap});

  @override
  State<_SwapButton> createState() => _SwapButtonState();
}

class _SwapButtonState extends State<_SwapButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? .92 : 1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        // Tapping this calls back to TranslationPage.swapLanguages().
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _TranslateStyle.green,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _TranslateStyle.green.withValues(alpha: .34),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: .90),
                blurRadius: 9,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

class _LanguageChoice extends StatelessWidget {
  final String label;
  final bool alignRight;

  const _LanguageChoice({required this.label, this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    final short = label == 'English' ? 'EN' : 'HI';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: alignRight
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: _TranslateStyle.softGreen,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                short,
                style: const TextStyle(
                  color: _TranslateStyle.darkGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: TudloColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 2),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: TudloColors.muted,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _QuickPhraseChips extends StatelessWidget {
  final ValueChanged<String> onSelected;

  const _QuickPhraseChips({required this.onSelected});

  static const phrases = ['Hello', 'Thank you', 'Good morning'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: phrases.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          return _QuickPhraseChip(
            label: phrases[index],
            onTap: () => onSelected(phrases[index]),
          );
        },
      ),
    );
  }
}

class _QuickPhraseChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickPhraseChip({required this.label, required this.onTap});

  @override
  State<_QuickPhraseChip> createState() => _QuickPhraseChipState();
}

class _QuickPhraseChipState extends State<_QuickPhraseChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? .96 : 1,
      duration: const Duration(milliseconds: 90),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: TudloColors.line),
            boxShadow: [
              BoxShadow(
                color: TudloColors.forest.withValues(alpha: .06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _TranslationCard extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final String hint;
  final bool readOnly;
  final int minLines;

  const _TranslationCard({
    required this.title,
    required this.controller,
    required this.hint,
    required this.readOnly,
    required this.minLines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: TudloColors.forest.withValues(alpha: .06),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
          const BoxShadow(
            color: _TranslateStyle.cardShadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: TudloColors.softGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  readOnly ? Icons.check_rounded : Icons.edit_note_rounded,
                  color: TudloColors.forest,
                  size: 19,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.nunito(
                    color: TudloColors.forest,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (!readOnly)
                const Text(
                  'Try a word or phrase',
                  style: TextStyle(
                    color: TudloColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: TudloColors.paper,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: TudloColors.line),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 4),
            child: Column(
              children: [
                TextField(
                  controller: controller,
                  readOnly: readOnly,
                  enableInteractiveSelection: true,
                  maxLines: minLines,
                  minLines: minLines,
                  style: const TextStyle(
                    color: TudloColors.ink,
                    fontSize: 18,
                    height: 1.32,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      color: TudloColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 6),
                const Divider(color: TudloColors.line, thickness: 1.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _ActionIconButton(
                      tooltip: 'Copy',
                      icon: Icons.copy_rounded,
                      enabled: controller.text.trim().isNotEmpty,
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: controller.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied text')),
                        );
                      },
                    ),
                    _ActionIconButton(
                      tooltip: 'Listen',
                      icon: Icons.volume_up_rounded,
                      enabled: controller.text.trim().isNotEmpty,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Audio playback coming soon'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.tooltip,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_ActionIconButton> createState() => _ActionIconButtonState();
}

class _ActionIconButtonState extends State<_ActionIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.enabled ? TudloColors.forest : TudloColors.muted;

    return AnimatedScale(
      scale: _pressed ? .88 : 1,
      duration: const Duration(milliseconds: 90),
      child: Tooltip(
        message: widget.tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.enabled ? widget.onTap : null,
          onTapDown: widget.enabled
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapCancel: widget.enabled
              ? () => setState(() => _pressed = false)
              : null,
          onTapUp: widget.enabled
              ? (_) => setState(() => _pressed = false)
              : null,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              widget.icon,
              color: widget.enabled
                  ? color
                  : TudloColors.muted.withValues(alpha: .45),
            ),
          ),
        ),
      ),
    );
  }
}
