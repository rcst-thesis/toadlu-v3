import 'package:flutter/material.dart';

import 'package:tudlo/features/dictionary/domain/dictionary_entry.dart';
import 'package:tudlo/features/dictionary/presentation/dictionary_colors.dart';

/// One catalog card: a placeholder box, the word, and a one-line
/// definition snippet. Used in the browse screen's category-grouped
/// catalog grid, in place of a bare text row.
class DictionaryWordGridCard extends StatelessWidget {
  const DictionaryWordGridCard({
    required this.entry,
    required this.onTap,
    super.key,
  });

  final DictionaryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DictionaryColors.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: Key('dictionary-catalog-card-${entry.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                entry.word,
                style: const TextStyle(
                  fontFamily: 'ComicRelief',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: DictionaryColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                entry.definition,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'ComicRelief',
                  fontSize: 11,
                  color: DictionaryColors.ink.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
