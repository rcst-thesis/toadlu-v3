import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_data.dart';
import '../app_theme.dart';

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
  bool showTutorial = !AppData.translateTutorialDone;
  bool _isUpdating = false;

  static const Map<String, String> _hiligaynonToEnglish = {
    'maayong aga': 'good morning',
    'maayong hapon': 'good afternoon',
    'maayong gab-i': 'good evening',
    'kumusta': 'how are you',
    'salamat': 'thank you',
    'palihog': 'please',
    'huo': 'yes',
    'indi': 'no',
    'balay': 'house',
    'eskwelahan': 'school',
    'tubig': 'water',
    'pagkaon': 'food',
    'kaon': 'eat',
    'inom': 'drink',
    'adlaw': 'day',
    'gab-i': 'night',
    'bata': 'child',
    'nanay': 'mother',
    'tatay': 'father',
    'abyan': 'friend',
    'libro': 'book',
    'maestro': 'teacher',
    'maestra': 'teacher',
    'gwapa': 'beautiful',
    'gwapo': 'handsome',
    'daku': 'big',
    'gamay': 'small',
    'dalan': 'road',
    'kahoy': 'tree',
    'iro': 'dog',
    'iring': 'cat',
    'ngalan': 'name',
    'ako': 'i',
    'ikaw': 'you',
    'kami': 'we',
    'sila': 'they',
  };

  late final Map<String, String> _englishToHiligaynon = {
    for (final entry in _hiligaynonToEnglish.entries) entry.value: entry.key,
    'good morning': 'maayong aga',
    'good afternoon': 'maayong hapon',
    'good evening': 'maayong gab-i',
    'how are you': 'kumusta',
    'thank you': 'salamat',
    'please': 'palihog',
    'yes': 'huo',
    'no': 'indi',
    'house': 'balay',
    'school': 'eskwelahan',
    'water': 'tubig',
    'food': 'pagkaon',
    'eat': 'kaon',
    'drink': 'inom',
    'day': 'adlaw',
    'night': 'gab-i',
    'child': 'bata',
    'mother': 'nanay',
    'father': 'tatay',
    'friend': 'abyan',
    'book': 'libro',
    'teacher': 'maestro',
    'beautiful': 'gwapa',
    'handsome': 'gwapo',
    'big': 'daku',
    'small': 'gamay',
    'road': 'dalan',
    'tree': 'kahoy',
    'dog': 'iro',
    'cat': 'iring',
    'name': 'ngalan',
    'i': 'ako',
    'you': 'ikaw',
    'we': 'kami',
    'they': 'sila',
  };

  @override
  void initState() {
    super.initState();
    topController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    if (_isUpdating) return;

    final input = topController.text;
    final result = _translate(input);
    _isUpdating = true;
    bottomController.text = result.translation;
    _isUpdating = false;

    if (input.trim().isNotEmpty && !AppData.translateTutorialDone) {
      setState(() {
        showTutorial = false;
        AppData.translateTutorialDone = true;
      });
    } else {
      setState(() {});
    }
  }

  _TranslationResult _translate(String value) {
    final clean = value.trim().toLowerCase();
    if (clean.isEmpty) {
      return const _TranslationResult('', 'Hiligaynon', 'English');
    }

    final hilScore = _score(clean, _hiligaynonToEnglish);
    final engScore = _score(clean, _englishToHiligaynon);
    final fromHil = hilScore >= engScore;
    final dictionary = fromHil ? _hiligaynonToEnglish : _englishToHiligaynon;
    final translation = _lookup(clean, dictionary);

    fromLanguage = fromHil ? 'Hiligaynon' : 'English';
    toLanguage = fromHil ? 'English' : 'Hiligaynon';

    return _TranslationResult(translation, fromLanguage, toLanguage);
  }

  int _score(String value, Map<String, String> dictionary) {
    var score = dictionary.containsKey(value) ? 5 : 0;
    final words = _words(value);
    for (final word in words) {
      if (dictionary.containsKey(word)) score++;
    }
    return score;
  }

  String _lookup(String value, Map<String, String> dictionary) {
    final exact = dictionary[value];
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
      backgroundColor: TudloColors.cloud,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 112),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: TudloColors.line, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: TudloColors.ink.withValues(alpha: .12),
                        blurRadius: 28,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _TranslateHeader(),
                      const SizedBox(height: 18),
                      _LanguageBar(
                        fromLanguage: fromLanguage,
                        toLanguage: toLanguage,
                        onSwap: swapLanguages,
                      ),
                      const SizedBox(height: 18),
                      _TranslationCard(
                        controller: topController,
                        hint: fromLanguage == 'Hiligaynon'
                            ? 'Type Hiligaynon here...'
                            : 'Type English here...',
                        readOnly: false,
                        minLines: 5,
                      ),
                      const SizedBox(height: 14),
                      _TranslationCard(
                        controller: bottomController,
                        hint: 'Translation appears here...',
                        readOnly: true,
                        minLines: 5,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (showTutorial)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => showTutorial = false),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.38),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 30),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Type any English or Hiligaynon word.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: TudloColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
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

class _TranslateHeader extends StatelessWidget {
  const _TranslateHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.translate_rounded, color: TudloColors.sky),
        const Expanded(
          child: Text(
            'Quick Translate',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF171C2A),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 24),
      ],
    );
  }
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: TudloColors.navy,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(child: _LanguageChoice(label: fromLanguage)),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onSwap,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: TudloColors.blue.withValues(alpha: .22),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
            ),
          ),
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

class _LanguageChoice extends StatelessWidget {
  final String label;
  final bool alignRight;

  const _LanguageChoice({required this.label, this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    final short = label == 'English' ? 'EN' : 'HI';
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignRight
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              short,
              style: const TextStyle(
                color: TudloColors.navy,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Colors.white,
          size: 16,
        ),
      ],
    );
  }
}

class _TranslationCard extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool readOnly;
  final int minLines;

  const _TranslationCard({
    required this.controller,
    required this.hint,
    required this.readOnly,
    required this.minLines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: readOnly ? TudloColors.cloud : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TudloColors.line, width: 2),
        boxShadow: [
          BoxShadow(
            color: TudloColors.ink.withValues(alpha: .06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
              fontSize: 20,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9AA5B1)),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
          const Divider(color: TudloColors.line),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Copy',
                onPressed: controller.text.trim().isEmpty
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: controller.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied translation')),
                        );
                      },
                icon: const Icon(Icons.copy_rounded),
                color: const Color(0xFF8C96A3),
              ),
              IconButton(
                tooltip: 'Listen',
                onPressed: controller.text.trim().isEmpty
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Audio playback coming soon'),
                          ),
                        );
                      },
                icon: const Icon(Icons.volume_up_rounded),
                color: const Color(0xFF8C96A3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
