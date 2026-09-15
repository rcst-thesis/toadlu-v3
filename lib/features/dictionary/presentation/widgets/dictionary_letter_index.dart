import 'package:flutter/material.dart';

import 'package:tudlo/features/dictionary/domain/dictionary_entry.dart';
import 'package:tudlo/features/dictionary/presentation/dictionary_colors.dart';

/// A collapsible A-Z index: a row of letter chips (only letters present in
/// [entries]) acts as the "filter" -- tapping one expands that letter's
/// word list below (accordion-style, one letter open at a time; tapping
/// the open letter again collapses it).
class DictionaryLetterIndex extends StatefulWidget {
  const DictionaryLetterIndex({
    required this.entries,
    required this.onSelect,
    super.key,
  });

  final List<DictionaryEntry> entries;
  final ValueChanged<DictionaryEntry> onSelect;

  @override
  State<DictionaryLetterIndex> createState() => _DictionaryLetterIndexState();
}

class _DictionaryLetterIndexState extends State<DictionaryLetterIndex> {
  String? _expandedLetter;

  Map<String, List<DictionaryEntry>> get _byLetter {
    final grouped = <String, List<DictionaryEntry>>{};
    final sorted = [...widget.entries]
      ..sort((a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()));
    for (final entry in sorted) {
      final letter = entry.word.isEmpty ? '#' : entry.word[0].toUpperCase();
      grouped.putIfAbsent(letter, () => []).add(entry);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final byLetter = _byLetter;
    final letters = byLetter.keys.toList();
    final expanded = _expandedLetter;

    return Column(
      key: const Key('dictionary-letter-index'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final letter in letters)
              _LetterChip(
                letter: letter,
                selected: expanded == letter,
                onTap: () => setState(
                  () => _expandedLetter = expanded == letter ? null : letter,
                ),
              ),
          ],
        ),
        if (expanded != null) ...[
          const SizedBox(height: 12),
          _LetterPanel(
            key: ValueKey(expanded),
            entries: byLetter[expanded] ?? const [],
            onSelect: widget.onSelect,
          ),
        ],
      ],
    );
  }
}

class _LetterChip extends StatelessWidget {
  const _LetterChip({
    required this.letter,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? DictionaryColors.ink : DictionaryColors.background,
      shape: const CircleBorder(),
      child: InkWell(
        key: Key('dictionary-letter-chip-$letter'),
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: Text(
              letter,
              style: TextStyle(
                fontFamily: 'ComicRelief',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: selected ? Colors.white : DictionaryColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LetterPanel extends StatelessWidget {
  const _LetterPanel({
    required this.entries,
    required this.onSelect,
    super.key,
  });

  final List<DictionaryEntry> entries;
  final ValueChanged<DictionaryEntry> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('dictionary-letter-panel'),
      decoration: BoxDecoration(
        color: DictionaryColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final entry in entries)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: Key('dictionary-letter-entry-${entry.id}'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onSelect(entry),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Text(
                      entry.word,
                      style: const TextStyle(
                        fontFamily: 'ComicRelief',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: DictionaryColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
