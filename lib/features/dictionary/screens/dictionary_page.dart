import 'package:flutter/material.dart';
import 'package:tudloapp/data/dictionary/dictionary_data.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/language_toggle.dart';

enum _DictionaryMode { englishToHiligaynon, hiligaynonToEnglish }

/// Dictionary screen built from word-based DictionaryData entries.
///
/// It supports language direction switching, search, voice playback, and
/// the fixed A-Z index on the right side.
class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _letterKeys = {};
  _DictionaryMode _mode = _DictionaryMode.englishToHiligaynon;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _englishMode => _mode == _DictionaryMode.englishToHiligaynon;

  List<DictionaryEntry> get _filteredTerms {
    // Search checks both languages and is case-insensitive, so "house" and
    // "balay" can find the same vocabulary pair.
    final terms = DictionaryData.entries.where((entry) {
      if (_query.isEmpty) return true;
      return entry.english.toLowerCase().contains(_query) ||
          entry.hiligaynon.toLowerCase().contains(_query);
    }).toList();

    terms.sort((a, b) {
      final first = _englishMode ? a.english : a.hiligaynon;
      final second = _englishMode ? b.english : b.hiligaynon;
      return first.toLowerCase().compareTo(second.toLowerCase());
    });
    return terms;
  }

  List<_DictionarySection> get _sections {
    // Group the filtered results by first letter based on the selected
    // language mode. English mode groups by English; Hiligaynon mode groups by
    // Hiligaynon.
    final grouped = <String, List<DictionaryEntry>>{};
    for (final entry in _filteredTerms) {
      final word = _englishMode ? entry.english : entry.hiligaynon;
      final letter = word.isEmpty ? '#' : word[0].toUpperCase();
      grouped
          .putIfAbsent(RegExp(r'[A-Z]').hasMatch(letter) ? letter : '#', () {
            return [];
          })
          .add(entry);
    }

    final letters = grouped.keys.toList()..sort();
    return letters
        .map((letter) => _DictionarySection(letter, grouped[letter]!))
        .toList();
  }

  void _jumpToLetter(String letter) {
    // The A-Z index scrolls to the requested section. If that letter is not in
    // the current filtered results, it jumps to the nearest next available
    // section, or the last section as a fallback.
    final sectionLetters = _sections.map((section) => section.letter).toList();
    if (sectionLetters.isEmpty) return;

    final targetLetter = sectionLetters.contains(letter)
        ? letter
        : sectionLetters.firstWhere(
            (sectionLetter) => sectionLetter.compareTo(letter) > 0,
            orElse: () => sectionLetters.last,
          );
    final key = _letterKeys[targetLetter];
    final context = key?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: .05,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections;

    return Scaffold(
      backgroundColor: TudloColors.paper,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Dictionary',
                          style: TextStyle(
                            color: TudloColors.ink,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SearchField(controller: _searchController),
                        const SizedBox(height: 14),
                        _ModeSwitch(
                          mode: _mode,
                          onChanged: (mode) => setState(() => _mode = mode),
                        ),
                      ],
                    ),
                  ),
                ),
                if (sections.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'No words found',
                        style: TextStyle(
                          color: TudloColors.muted,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 4, 42, 120),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: sections.map((section) {
                          // All current sections are mounted so ensureVisible
                          // can reliably scroll to any A-Z letter.
                          final key = _letterKeys.putIfAbsent(
                            section.letter,
                            GlobalKey.new,
                          );
                          return _DictionarySectionView(
                            key: key,
                            section: section,
                            englishMode: _englishMode,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
            Positioned(
              top: 190,
              right: 6,
              bottom: 118,
              child: _LetterIndex(onTap: _jumpToLetter),
            ),
          ],
        ),
      ),
    );
  }
}

class _DictionarySection {
  final String letter;
  final List<DictionaryEntry> terms;

  const _DictionarySection(this.letter, this.terms);
}

// This search field lets the user filter dictionary words.
// The controller is owned by the main Dictionary page so the page can rebuild
// the visible word list whenever the search text changes.
class _SearchField extends StatelessWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    // TextField is only responsible for the input UI.
    // The actual search/filter logic is handled in the parent widget.
    return TextField(
      controller: controller,
      cursorColor: TudloColors.green,
      style: const TextStyle(
        color: TudloColors.ink,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        hintText: 'Search word...',
        hintStyle: const TextStyle(
          color: TudloColors.muted,
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: const Icon(Icons.search_rounded, color: TudloColors.forest),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: TudloColors.line, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: TudloColors.line, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: TudloColors.green, width: 2.5),
        ),
      ),
    );
  }
}

// This switch controls the dictionary direction:
// English words first, or Hiligaynon words first.
// The selected mode also decides how words are sorted and grouped by letter.
class _ModeSwitch extends StatelessWidget {
  final _DictionaryMode mode;
  final ValueChanged<_DictionaryMode> onChanged;

  const _ModeSwitch({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: TudloColors.softGreen.withValues(alpha: .78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TudloColors.line),
      ),
      child: Row(
        children: [
          // Shows English as the main word and Hiligaynon as the translation.
          _ModePill(
            label: 'English',
            selected: mode == _DictionaryMode.englishToHiligaynon,
            onTap: () => onChanged(_DictionaryMode.englishToHiligaynon),
          ),
          // Shows Hiligaynon as the main word and English as the translation.
          _ModePill(
            label: 'Hiligaynon',
            selected: mode == _DictionaryMode.hiligaynonToEnglish,
            onTap: () => onChanged(_DictionaryMode.hiligaynonToEnglish),
          ),
        ],
      ),
    );
  }
}

// A single selectable option inside the dictionary mode switch.
// It uses a soft selected style instead of a full green fill so the toggle
// stays readable and matches the app's dictionary design.
class _ModePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        // Tapping the pill tells the parent Dictionary page to change modes.
        onTap: onTap,
        child: AnimatedContainer(
          // This short animation makes switching modes feel smoother.
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? TudloColors.green : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? TudloColors.forest : TudloColors.muted,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

// Displays one alphabet section in the dictionary, such as A, B, or C.
// Each section contains all visible words that start with that letter.
class _DictionarySectionView extends StatelessWidget {
  final _DictionarySection section;
  final bool englishMode;

  const _DictionarySectionView({
    super.key,
    required this.section,
    required this.englishMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 18, 0, 8),
          child: Text(
            section.letter,
            style: const TextStyle(
              color: TudloColors.forest,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        ...section.terms.map((term) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DictionaryCard(term: term, englishMode: englishMode),
          );
        }),
      ],
    );
  }
}

// A single dictionary word card.
// It shows the main word, its translation, and a speaker button for audio.
class _DictionaryCard extends StatelessWidget {
  final DictionaryEntry term;
  final bool englishMode;

  const _DictionaryCard({required this.term, required this.englishMode});

  @override
  Widget build(BuildContext context) {
    // The displayed order changes based on the selected dictionary mode.
    final mainWord = englishMode ? term.english : term.hiligaynon;
    final translatedWord = englishMode ? term.hiligaynon : term.english;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TudloColors.line, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: TudloColors.forest.withValues(alpha: .06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: TudloColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1.24,
                ),
                children: [
                  TextSpan(text: mainWord),
                  const TextSpan(
                    text: ' = ',
                    style: TextStyle(color: TudloColors.muted),
                  ),
                  TextSpan(
                    text: translatedWord,
                    style: const TextStyle(color: TudloColors.forest),
                  ),
                ],
              ),
            ),
          ),
          TudloVoiceButton(
            message: mainWord,
            tooltip: 'Play pronunciation',
            size: 48,
          ),
        ],
      ),
    );
  }
}

// Fixed A-Z index on the right side of the Dictionary page.
// Tapping a letter asks the parent page to scroll to that letter section.
class _LetterIndex extends StatelessWidget {
  final ValueChanged<String> onTap;

  const _LetterIndex({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return Container(
      width: 28,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: TudloColors.line.withValues(alpha: .72)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: letters.split('').map((letter) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              // The parent handles the scroll target because it owns the
              // ScrollController and the section GlobalKeys.
              onTap: () => onTap(letter),
              child: SizedBox(
                width: 26,
                height: 18,
                child: Center(
                  child: Text(
                    letter,
                    style: const TextStyle(
                      color: Color(0xFF4F5B4F),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
