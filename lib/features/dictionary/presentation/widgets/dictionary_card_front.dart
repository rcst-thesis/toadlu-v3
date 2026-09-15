import 'package:flutter/material.dart';

import 'package:tudlo/features/dictionary/domain/dictionary_entry.dart';
import 'package:tudlo/features/dictionary/presentation/dictionary_colors.dart';
import 'package:tudlo/features/dictionary/presentation/widgets/dictionary_asset_image.dart';

/// Shared "image + word-label pill" composition used by both the big
/// word-of-the-day flip card and the small favorites-carousel tiles. When
/// [DictionaryEntry.favThumbImage] is set, that fully-designed thumbnail is
/// shown as-is instead (it already bakes in the word label).
class DictionaryCardFront extends StatelessWidget {
  const DictionaryCardFront({
    required this.entry,
    this.borderRadius = 24,
    this.wordFontSize = 20,
    super.key,
  });

  final DictionaryEntry entry;
  final double borderRadius;
  final double wordFontSize;

  static const _labelColor = Color(0xFF5C2233);

  @override
  Widget build(BuildContext context) {
    final favThumbImage = entry.favThumbImage;
    if (favThumbImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: DictionaryAssetImage(path: favThumbImage, fit: BoxFit.cover),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: ColoredBox(
        color: DictionaryColors.background,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Image.asset(entry.imageAsset, fit: BoxFit.contain),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Text(
                    entry.word,
                    style: TextStyle(
                      fontFamily: 'ComicRelief',
                      fontWeight: FontWeight.bold,
                      fontSize: wordFontSize,
                      color: _labelColor,
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
