import 'package:flutter/material.dart';

import 'package:tudlo/features/dictionary/domain/dictionary_entry.dart';
import 'package:tudlo/features/dictionary/presentation/dictionary_colors.dart';

/// The "featured words" banner: one bento tray with a fixed 5 compartments
/// (1 hero + 4 smaller), separated by thin divider lines like a real bento
/// box. Filled with the first 5 [entries]; any remaining slots render as
/// blank, non-interactive placeholder compartments instead of being
/// omitted, so the tray always reads as a full banner regardless of how
/// much featured content exists yet. Compartments are plain placeholder
/// boxes (word label only, no art).
class DictionaryBentoGrid extends StatelessWidget {
  const DictionaryBentoGrid({
    required this.entries,
    required this.onTap,
    super.key,
  });

  static const _slotCount = 5;

  final List<DictionaryEntry> entries;
  final ValueChanged<DictionaryEntry> onTap;

  static final _dividerColor = DictionaryColors.ink.withValues(alpha: 0.14);

  @override
  Widget build(BuildContext context) {
    final hero = entries.isNotEmpty ? entries.first : null;
    final rest = entries.length > 1
        ? entries.sublist(1, entries.length.clamp(0, _slotCount))
        : <DictionaryEntry>[];
    final blankSlots = _slotCount - 1 - rest.length;

    return DecoratedBox(
      key: const Key('dictionary-bento-grid'),
      decoration: BoxDecoration(
        color: DictionaryColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _BentoCompartment(entry: hero, height: 150, onTap: onTap),
          Container(height: 1.5, color: _dividerColor),
          IntrinsicHeight(
            child: Row(
              children: [
                for (var i = 0; i < rest.length; i++) ...[
                  if (i > 0) Container(width: 1.5, color: _dividerColor),
                  Expanded(
                    child: _BentoCompartment(
                      entry: rest[i],
                      height: 90,
                      onTap: onTap,
                    ),
                  ),
                ],
                for (var i = 0; i < blankSlots; i++) ...[
                  if (rest.isNotEmpty || i > 0)
                    Container(width: 1.5, color: _dividerColor),
                  Expanded(
                    child: _BentoCompartment(
                      entry: null,
                      height: 90,
                      onTap: onTap,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BentoCompartment extends StatelessWidget {
  const _BentoCompartment({
    required this.entry,
    required this.height,
    required this.onTap,
  });

  /// Null renders a blank, non-interactive placeholder compartment.
  final DictionaryEntry? entry;
  final double height;
  final ValueChanged<DictionaryEntry> onTap;

  @override
  Widget build(BuildContext context) {
    final entry = this.entry;
    final content = SizedBox(
      height: height,
      child: Center(
        child: entry != null
            ? Text(
                entry.word,
                style: const TextStyle(
                  fontFamily: 'ComicRelief',
                  fontWeight: FontWeight.bold,
                  color: DictionaryColors.ink,
                ),
              )
            : null,
      ),
    );
    if (entry == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('dictionary-bento-tile-${entry.id}'),
        onTap: () => onTap(entry),
        child: content,
      ),
    );
  }
}
