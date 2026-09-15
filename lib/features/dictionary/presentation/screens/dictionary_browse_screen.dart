import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tudlo/core/navigation/app_bottom_tab_navigation.dart';
import 'package:tudlo/features/dictionary/domain/dictionary_entry.dart';
import 'package:tudlo/features/dictionary/domain/dictionary_words.dart';
import 'package:tudlo/features/dictionary/presentation/dictionary_colors.dart';
import 'package:tudlo/features/dictionary/presentation/dictionary_layout.dart';
import 'package:tudlo/features/dictionary/presentation/widgets/dictionary_bento_grid.dart';
import 'package:tudlo/features/dictionary/presentation/widgets/dictionary_category_chips.dart';
import 'package:tudlo/features/dictionary/presentation/widgets/dictionary_content_footer.dart';
import 'package:tudlo/features/dictionary/presentation/widgets/dictionary_header.dart';
import 'package:tudlo/features/dictionary/presentation/widgets/dictionary_letter_index.dart';
import 'package:tudlo/features/dictionary/presentation/widgets/dictionary_lookup_page.dart';
import 'package:tudlo/features/dictionary/presentation/widgets/dictionary_search_bar.dart';
import 'package:tudlo/features/dictionary/presentation/widgets/dictionary_stroked_text.dart';
import 'package:tudlo/features/dictionary/presentation/widgets/dictionary_word_grid_card.dart';
import 'package:tudlo/features/learner/domain/learner_scope.dart';

/// The real, functional dictionary browser: a "featured" bento tray
/// banner, a category filter, and a category-grouped catalog of every
/// word. Opened from [DictionaryScreen]'s decoy search bar. Selecting any
/// word shows its full flip card inline here, without leaving this screen.
///
/// Deliberately mirrors [DictionaryScreen]'s header/search-bar layout
/// (same header widget, same scale math, same [dictionaryTopOffset]) so
/// tapping the decoy bar doesn't look like a navigation at all -- the
/// search bar just appears to split into a "back" pill and a shorter,
/// now-real search bar.
class DictionaryBrowseScreen extends StatefulWidget {
  const DictionaryBrowseScreen({
    this.entries = DictionaryWords.all,
    this.initialEntry,
    super.key,
  });

  /// Override for tests; defaults to the real placeholder dataset.
  final List<DictionaryEntry> entries;

  /// When set, the screen opens straight to this entry's definition page
  /// (e.g. tapping a word in [DictionaryFavoritesCarousel]) instead of the
  /// tray/catalog list.
  final DictionaryEntry? initialEntry;

  static const _backgroundColor = Color(0xFFF9C4CE);
  static const _designWidth = 412.0;

  @override
  State<DictionaryBrowseScreen> createState() => _DictionaryBrowseScreenState();
}

class _DictionaryBrowseScreenState extends State<DictionaryBrowseScreen> {
  final _searchController = TextEditingController();
  var _query = '';
  String? _selectedCategory;
  DictionaryEntry? _selectedEntry;

  @override
  void initState() {
    super.initState();
    _selectedEntry = widget.initialEntry;
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (_selectedEntry != null) {
      setState(() => _selectedEntry = null);
    } else {
      Navigator.of(context).pop();
    }
  }

  List<DictionaryEntry> get _featured =>
      widget.entries.where((e) => e.featured).toList();

  List<String> get _categories =>
      {for (final e in widget.entries) e.category}.toList()..sort();

  List<DictionaryEntry> get _filtered {
    final category = _selectedCategory;
    return widget.entries.where((entry) {
      final matchesCategory = category == null || entry.category == category;
      final matchesQuery = _query.isEmpty ||
          entry.word.toLowerCase().contains(_query) ||
          entry.definition.toLowerCase().contains(_query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  Map<String, List<DictionaryEntry>> get _groupedByCategory {
    final grouped = <String, List<DictionaryEntry>>{};
    for (final entry in _filtered) {
      grouped.putIfAbsent(entry.category, () => []).add(entry);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedEntry;
    return Scaffold(
      key: const Key('dictionary-browse-screen'),
      backgroundColor: DictionaryBrowseScreen._backgroundColor,
      bottomNavigationBar: const AppBottomTabNavigation(currentIndex: 4),
      // Full-bleed, matching DictionaryScreen -- see dictionaryTopOffset.
      body: LayoutBuilder(
        builder: (context, viewport) {
          final canvasWidth = math.min(viewport.maxWidth, 720.0);
          final scale = canvasWidth / DictionaryBrowseScreen._designWidth;
          final footerHeight = 48 * scale;
          return SingleChildScrollView(
            key: const Key('dictionary-browse-scroll-view'),
            // ConstrainedBox(minHeight) + Stack/Positioned pins the footer
            // to the actual bottom of the screen even when content is
            // short (e.g. a single looked-up word), while still scrolling
            // normally when content is taller than the viewport.
            // (Deliberately not IntrinsicHeight here -- that combo crashes
            // when the subtree contains scrollables like GridView/
            // horizontal ListViews, which this screen's catalog/chips do.)
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewport.maxHeight),
              child: Stack(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: canvasWidth),
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 20 * scale,
                          right: 20 * scale,
                          top: dictionaryTopOffset(context, scale),
                          bottom: 24 * scale + footerHeight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (selected != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: _BackPill(
                                  key: const Key(
                                    'dictionary-browse-back-pill',
                                  ),
                                  onTap: _handleBack,
                                ),
                              )
                            else ...[
                              Center(
                                child: DictionaryHeader(width: 220 * scale),
                              ),
                              SizedBox(height: 20 * scale),
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _BackPill(
                                      key: const Key(
                                        'dictionary-browse-back-pill',
                                      ),
                                      onTap: _handleBack,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: DictionarySearchBar(
                                        controller: _searchController,
                                        fieldKey: const Key(
                                          'dictionary-browse-search-field',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            SizedBox(height: 20 * scale),
                            selected != null
                                ? _SelectedWordView(entry: selected)
                                : _BrowseListView(
                                    featured: _featured,
                                    categories: _categories,
                                    selectedCategory: _selectedCategory,
                                    onCategorySelected: (category) => setState(
                                      () => _selectedCategory = category,
                                    ),
                                    grouped: _groupedByCategory,
                                    isSearching: _query.isNotEmpty,
                                    onSelect: (entry) => setState(
                                      () => _selectedEntry = entry,
                                    ),
                                    allEntries: widget.entries,
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Edge-to-edge, matching Home/Me's content footer (never
                  // inset), but still width-capped on very wide screens.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: canvasWidth),
                        child: SizedBox(
                          height: footerHeight,
                          child: const DictionaryContentFooter(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Styled identically to [DictionarySearchBar]'s own pill (same fill color,
/// fully-rounded corners) so sitting beside the now-shorter search bar
/// reads as if one full-width bar simply got "cut" into two pieces. Sized
/// to fill the row's height (via the parent `IntrinsicHeight` +
/// `CrossAxisAlignment.stretch`) so it matches the search bar exactly.
class _BackPill extends StatelessWidget {
  const _BackPill({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DictionaryColors.background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Center(
            child: Text(
              'back',
              style: TextStyle(
                fontFamily: 'ComicRelief',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: DictionaryColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedWordView extends StatelessWidget {
  const _SelectedWordView({required this.entry});

  final DictionaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final controller = LearnerScope.of(context);
    final favoritedWords = controller.profile?.favoritedWords ?? const {};
    return Align(
      alignment: Alignment.topLeft,
      child: DictionaryLookupPage(
        entry: entry,
        isFavorited: favoritedWords.contains(entry.id),
        onFavoriteChanged: (_) => controller.toggleFavoriteWord(entry.id),
      ),
    );
  }
}

class _BrowseListView extends StatelessWidget {
  const _BrowseListView({
    required this.featured,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.grouped,
    required this.isSearching,
    required this.onSelect,
    required this.allEntries,
  });

  final List<DictionaryEntry> featured;
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;
  final Map<String, List<DictionaryEntry>> grouped;
  final bool isSearching;
  final ValueChanged<DictionaryEntry> onSelect;

  /// Full, unfiltered dataset -- the letter index browses everything,
  /// independent of the category filter/search above it.
  final List<DictionaryEntry> allEntries;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('dictionary-browse-list'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isSearching && featured.isNotEmpty) ...[
          const DictionaryStrokedText(
            'featured',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 8),
          DictionaryBentoGrid(entries: featured, onTap: onSelect),
          const SizedBox(height: 20),
        ],
        const DictionaryStrokedText(
          'all words',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        const SizedBox(height: 8),
        DictionaryCategoryChips(
          categories: categories,
          selected: selectedCategory,
          onSelected: onCategorySelected,
        ),
        const SizedBox(height: 12),
        if (grouped.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'no words found',
                style: TextStyle(
                  fontFamily: 'ComicRelief',
                  color: DictionaryColors.ink,
                ),
              ),
            ),
          )
        else
          for (final category in grouped.keys) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                category,
                style: const TextStyle(
                  fontFamily: 'ComicRelief',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: DictionaryColors.ink,
                ),
              ),
            ),
            _CategoryCardGrid(
              entries: grouped[category]!,
              onSelect: onSelect,
            ),
            const SizedBox(height: 16),
          ],
        const SizedBox(height: 8),
        const DictionaryStrokedText(
          'browse by letter',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        const SizedBox(height: 8),
        DictionaryLetterIndex(entries: allEntries, onSelect: onSelect),
      ],
    );
  }
}

class _CategoryCardGrid extends StatelessWidget {
  const _CategoryCardGrid({required this.entries, required this.onSelect});

  final List<DictionaryEntry> entries;
  final ValueChanged<DictionaryEntry> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      key: const Key('dictionary-catalog-grid'),
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: [
        for (final entry in entries)
          DictionaryWordGridCard(
            entry: entry,
            onTap: () => onSelect(entry),
          ),
      ],
    );
  }
}
