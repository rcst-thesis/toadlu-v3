import 'package:flutter/material.dart';

import 'package:tudlo/features/dictionary/domain/dictionary_entry.dart';
import 'package:tudlo/features/dictionary/presentation/dictionary_colors.dart';
import 'package:tudlo/features/dictionary/presentation/widgets/dictionary_card_front.dart';

/// Horizontal "my favorites" carousel: one card per page, dot indicator,
/// and a right-arrow control to advance.
class DictionaryFavoritesCarousel extends StatefulWidget {
  const DictionaryFavoritesCarousel({
    required this.entries,
    this.onSelect,
    super.key,
  });

  final List<DictionaryEntry> entries;

  /// Called with the tapped entry -- [DictionaryScreen] uses this to open
  /// that word's definition screen.
  final ValueChanged<DictionaryEntry>? onSelect;

  @override
  State<DictionaryFavoritesCarousel> createState() =>
      _DictionaryFavoritesCarouselState();
}

class _DictionaryFavoritesCarouselState
    extends State<DictionaryFavoritesCarousel> {
  late final PageController _pageController;
  var _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.6);
    _pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    final page = _pageController.page?.round() ?? 0;
    if (page != _page) setState(() => _page = page);
  }

  void _next() {
    final target = (_page + 1).clamp(0, widget.entries.length - 1);
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) {
      return Container(
        key: const Key('dictionary-favorites-empty-card'),
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: DictionaryColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: const Text(
          'No favorites yet -- tap the heart on a word to add one.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'ComicRelief',
            color: DictionaryColors.ink,
          ),
        ),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: Row(
            children: [
              Expanded(
                child: PageView.builder(
                  key: const Key('dictionary-favorites-page-view'),
                  controller: _pageController,
                  itemCount: widget.entries.length,
                  itemBuilder: (context, index) {
                    final entry = widget.entries[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: Key('dictionary-favorite-tile-${entry.id}'),
                          borderRadius: BorderRadius.circular(16),
                          onTap: widget.onSelect == null
                              ? null
                              : () => widget.onSelect!(entry),
                          child: DictionaryCardFront(
                            entry: entry,
                            wordFontSize: 14,
                            borderRadius: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (widget.entries.length > 1)
                IconButton(
                  key: const Key('dictionary-favorites-next-button'),
                  onPressed: _next,
                  icon: const Icon(Icons.arrow_forward_ios_rounded),
                  color: const Color(0xFF5C2233),
                ),
            ],
          ),
        ),
        if (widget.entries.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.entries.length, (index) {
                final active = index == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 10 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF5C2233)
                        : const Color(0xFFEB8FA0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
