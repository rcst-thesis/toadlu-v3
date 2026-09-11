import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Responsive Home lesson preview using the supplied PNG artwork.
class HomeLessonPanel extends StatefulWidget {
  const HomeLessonPanel({
    required this.energy,
    this.lesson = const HomeLessonPreview(
      unitTitle: 'yunit 1',
      category: 'ALPHABETO KAG NUMERO',
      status: HomeLessonStatus.completed,
    ),
    this.additionalLessons = const [],
    this.onLessonTap,
    this.onCollapsedChanged,
    super.key,
  });

  final int energy;
  final HomeLessonPreview lesson;
  final List<HomeLessonPreview> additionalLessons;
  final ValueChanged<HomeLessonPreview>? onLessonTap;
  final ValueChanged<bool>? onCollapsedChanged;

  /// The Home scene uses this to reserve enough scroll height for every lesson
  /// Energy currently makes available.
  static double designHeightForEnergy(
    int energy, {
    required bool isCollapsed,
  }) {
    final lessonCount = (energy.clamp(0, 60) ~/ 10).clamp(0, 6);
    if (isCollapsed && lessonCount > 1) {
      return _HomeLessonPanelLayout.headingIconSize +
          _HomeLessonPanelLayout.headingToSectionGap +
          _HomeLessonPanelLayout.cardHeight +
          _HomeLessonPanelLayout.deckVerticalOffset;
    }
    final sectionHeight = lessonCount > 1
        ? _HomeLessonPanelLayout.headingToSectionGap +
            _HomeLessonPanelLayout.sectionChevronSize +
            _HomeLessonPanelLayout.sectionToCardGap
        : _HomeLessonPanelLayout.headingToSectionGap;
    final cardsHeight = lessonCount * _HomeLessonPanelLayout.cardHeight;
    final gapsHeight = lessonCount > 1
        ? (lessonCount - 1) * _HomeLessonPanelLayout.lessonCardGap
        : 0.0;
    return _HomeLessonPanelLayout.headingIconSize + sectionHeight +
        cardsHeight + gapsHeight;
  }

  @override
  State<HomeLessonPanel> createState() => _HomeLessonPanelState();
}

class _HomeLessonPanelState extends State<HomeLessonPanel> {
  bool _isExpanded = true;

  int get _availableLessons =>
      (widget.energy.clamp(0, 60) ~/ 10).clamp(0, 6);

  List<HomeLessonPreview> get _visibleLessons {
    final configuredLessons = [widget.lesson, ...widget.additionalLessons];
    return List.generate(_availableLessons, (index) {
      if (index < configuredLessons.length) return configuredLessons[index];
      return HomeLessonPreview(
        unitTitle: 'yunit ${index + 1}',
        category: widget.lesson.category,
        status: HomeLessonStatus.available,
      );
    });
  }

  /// Collapse is based on lesson panels currently made available by Energy.
  bool get _canCollapse => _visibleLessons.length > 1;

  String get _summaryCategories {
    final categories = _visibleLessons.map((lesson) => lesson.category).toSet();
    return categories.join(', ');
  }

  void _setExpanded(bool expanded) {
    if (_isExpanded == expanded) return;
    setState(() => _isExpanded = expanded);
    widget.onCollapsedChanged?.call(!expanded);
  }

  @override
  Widget build(BuildContext context) {
    final lessonLabel = _availableLessons == 1 ? 'lesson' : 'lessons';
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / _HomeLessonPanelLayout.designWidth;
        return AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Padding(
              padding: EdgeInsets.only(
                left: _HomeLessonPanelLayout.headingLeftInset * scale,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/home_bookshelf_outline_white.png',
                    width: _HomeLessonPanelLayout.headingIconSize * scale,
                    height: _HomeLessonPanelLayout.headingIconSize * scale,
                    fit: BoxFit.contain,
                    semanticLabel: 'Available lessons',
                  ),
                  SizedBox(width: _HomeLessonPanelLayout.headingGap * scale),
                  Flexible(
                    child: Text(
                      '$_availableLessons $lessonLabel subong nga adlaw!',
                      key: const Key('home-lesson-availability'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'ComicRelief',
                        fontSize:
                            _HomeLessonPanelLayout.headingFontSize * scale,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isExpanded && _canCollapse) ...[
              SizedBox(
                height: _HomeLessonPanelLayout.headingToSectionGap * scale,
              ),
              Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Collapse lessons',
                    child: InkResponse(
                      key: const Key('home-lesson-collapse-toggle'),
                      onTap: () => _setExpanded(false),
                      radius: 14 * scale,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'umpisahan ta subong adlaw',
                            key: const Key('home-lesson-section-label'),
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'ComicRelief',
                              fontSize:
                                  _HomeLessonPanelLayout.sectionLabelFontSize *
                                      scale,
                              fontWeight: FontWeight.w400,
                              height: 1,
                            ),
                          ),
                          SizedBox(
                            width: _HomeLessonPanelLayout.sectionChevronSize *
                                scale,
                            height:
                                _HomeLessonPanelLayout.sectionChevronSize *
                                    scale,
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                              size: _HomeLessonPanelLayout.sectionChevronSize *
                                  scale,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width:
                        _HomeLessonPanelLayout.sectionLabelToLineGap * scale,
                  ),
                  Expanded(
                    child: SvgPicture.asset(
                      'assets/images/home_lesson_divider.svg',
                      height: _HomeLessonPanelLayout.dividerHeight * scale,
                      fit: BoxFit.fill,
                      excludeFromSemantics: true,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: _HomeLessonPanelLayout.sectionToCardGap * scale,
              ),
            ] else
              SizedBox(
                height: _HomeLessonPanelLayout.headingToSectionGap * scale,
              ),
            if (_isExpanded)
              _LessonList(
                lessons: _visibleLessons,
                scale: scale,
                onLessonTap: widget.onLessonTap,
              )
            else
              _LessonDeck(
              lesson: _visibleLessons.first,
              summaryCategories: _summaryCategories,
              // A collapsed section becomes a deck only when there is more
              // than one available lesson.
              stackDepth: !_isExpanded && _canCollapse ? 2 : 1,
              scale: scale,
                onTap: !_canCollapse
                    ? null
                    : () => _setExpanded(true),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Shows every currently available lesson while the section is expanded.
class _LessonList extends StatelessWidget {
  const _LessonList({
    required this.lessons,
    required this.scale,
    required this.onLessonTap,
  });

  final List<HomeLessonPreview> lessons;
  final double scale;
  final ValueChanged<HomeLessonPreview>? onLessonTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < lessons.length; index++) ...[
          SizedBox(
            height: _HomeLessonPanelLayout.cardHeight * scale,
            width: double.infinity,
            child: GestureDetector(
              key: Key('home-lesson-card-$index'),
              onTap: onLessonTap == null ? null : () => onLessonTap!(lessons[index]),
              behavior: HitTestBehavior.opaque,
              child: _LessonPreviewCard(lesson: lessons[index]),
            ),
          ),
          if (index < lessons.length - 1)
            SizedBox(height: _HomeLessonPanelLayout.lessonCardGap * scale),
        ],
      ],
    );
  }
}

/// Keeps the collapsed summary readable while one soft card peeks beneath it.
class _LessonDeck extends StatelessWidget {
  const _LessonDeck({
    required this.lesson,
    required this.summaryCategories,
    required this.stackDepth,
    required this.scale,
    required this.onTap,
  });

  final HomeLessonPreview lesson;
  final String summaryCategories;
  final int stackDepth;
  final double scale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cardHeight = _HomeLessonPanelLayout.cardHeight * scale;
    final peekOffset = _HomeLessonPanelLayout.deckVerticalOffset * scale;
    final backCardHeight = _HomeLessonPanelLayout.deckCardHeight * scale;
    final deckHeight = cardHeight + ((stackDepth - 1) * peekOffset);
    return Semantics(
      button: onTap != null,
      label: onTap == null ? null : 'Expand lessons',
      child: GestureDetector(
        key: onTap == null
            ? null
            : const Key('home-lesson-collapsed-deck-toggle'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: deckHeight,
          width: double.infinity,
          child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var layer = stackDepth - 1; layer >= 1; layer--)
            Positioned(
              top: layer * peekOffset,
              left: (layer * _HomeLessonPanelLayout.deckSideInset +
                      _HomeLessonPanelLayout.deckHorizontalOffset) *
                  scale,
              right: (layer * _HomeLessonPanelLayout.deckSideInset -
                      _HomeLessonPanelLayout.deckHorizontalOffset) *
                  scale,
              height: backCardHeight,
              child: DecoratedBox(
                key: Key('home-lesson-deck-layer-$layer'),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(
                    _HomeLessonPanelLayout.cardRadius * scale,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x22000000),
                      offset: Offset(0, 1 * scale),
                      blurRadius: 1 * scale,
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: cardHeight,
            child: _LessonPreviewCard(
              key: const Key('home-lesson-card'),
              lesson: lesson,
              isElevated: stackDepth > 1,
              isSummary: onTap != null,
              summaryCategories: summaryCategories,
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}

class HomeLessonPreview {
  const HomeLessonPreview({
    required this.unitTitle,
    required this.category,
    required this.status,
  });

  final String unitTitle;
  final String category;
  final HomeLessonStatus status;
}

enum HomeLessonStatus { completed, available, locked }

class _LessonPreviewCard extends StatelessWidget {
  const _LessonPreviewCard({
    required this.lesson,
    this.isElevated = false,
    this.isSummary = false,
    this.summaryCategories,
    super.key,
  });

  final HomeLessonPreview lesson;
  final bool isElevated;
  final bool isSummary;
  final String? summaryCategories;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / _HomeLessonPanelLayout.designWidth;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              _HomeLessonPanelLayout.cardRadius * scale,
            ),
            boxShadow: isElevated
                ? [
                    BoxShadow(
                      color: const Color(0x16000000),
                      offset: Offset(0, 2 * scale),
                      blurRadius: 7 * scale,
                    ),
                  ]
                : null,
          ),
          child: isSummary
              ? _CollapsedLessonSummaryContent(
                  categories: summaryCategories ?? lesson.category,
                  scale: scale,
                )
              : Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _HomeLessonPanelLayout.cardHorizontalPadding * scale,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: _HomeLessonPanelLayout.dotsWidth * scale,
                  height: _HomeLessonPanelLayout.dotsHeight * scale,
                  child: Transform.translate(
                    offset: Offset(
                      _HomeLessonPanelLayout.dotsOffsetX * scale,
                      _HomeLessonPanelLayout.dotsOffsetY * scale,
                    ),
                    child: SvgPicture.asset(
                      'assets/images/home_lesson_more_dots.svg',
                      fit: BoxFit.contain,
                      semanticsLabel: 'Lesson options',
                    ),
                  ),
                ),
                SizedBox(width: _HomeLessonPanelLayout.dotsToIconGap * scale),
                Image.asset(
                  'assets/images/home_lesson_category.png',
                  width: _HomeLessonPanelLayout.categoryIconSize * scale,
                  height: _HomeLessonPanelLayout.categoryIconSize * scale,
                  fit: BoxFit.contain,
                  semanticLabel: 'Alphabeto kag numero',
                ),
                SizedBox(
                  width: _HomeLessonPanelLayout.categoryToTextGap * scale,
                ),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: _HomeLessonPanelLayout.unitTextWidth * scale,
                        child: FittedBox(
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.scaleDown,
                          child: Text(
                            lesson.unitTitle,
                            maxLines: 1,
                            style: TextStyle(
                              color: const Color(0xFF151515),
                              fontFamily: 'ComicRelief',
                              fontSize:
                                  _HomeLessonPanelLayout.unitFontSize * scale,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width:
                            _HomeLessonPanelLayout.textColumnsGap * scale,
                      ),
                      Expanded(
                        child: Text(
                          lesson.category,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF151515),
                            fontFamily: 'ComicRelief',
                            fontSize: _HomeLessonPanelLayout.categoryFontSize *
                                scale,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: _HomeLessonPanelLayout.statusGap * scale),
                _LessonStatusIndicator(status: lesson.status, scale: scale),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The collapsed panel describes the day's lessons instead of repeating the
/// first lesson's options and completion state.
class _CollapsedLessonSummaryContent extends StatelessWidget {
  const _CollapsedLessonSummaryContent({
    required this.categories,
    required this.scale,
  });

  final String categories;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _HomeLessonPanelLayout.cardHorizontalPadding * scale,
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/home_lesson_category.png',
            width: _HomeLessonPanelLayout.categoryIconSize * scale,
            height: _HomeLessonPanelLayout.categoryIconSize * scale,
            fit: BoxFit.contain,
            semanticLabel: 'Lessons for today',
          ),
          SizedBox(width: _HomeLessonPanelLayout.summaryIconToTextGap * scale),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'mga lesson ta subong nga adlaw',
                  key: const Key('home-lesson-summary-title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF151515),
                    fontFamily: 'ComicRelief',
                    fontSize:
                        _HomeLessonPanelLayout.summaryTitleFontSize * scale,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                SizedBox(height: _HomeLessonPanelLayout.summaryTextGap * scale),
                Text(
                  categories,
                  key: const Key('home-lesson-summary-categories'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF515151),
                    fontFamily: 'ComicRelief',
                    fontSize:
                        _HomeLessonPanelLayout.summaryCategoryFontSize * scale,
                    fontWeight: FontWeight.w400,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonStatusIndicator extends StatelessWidget {
  const _LessonStatusIndicator({required this.status, required this.scale});

  final HomeLessonStatus status;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final (background, icon, iconColor) = switch (status) {
      HomeLessonStatus.completed => (
          const Color(0xFFEBEAEA),
          Icons.check_rounded,
          const Color(0xFF56C84D),
        ),
      HomeLessonStatus.available => (
          const Color(0xFFFFE7A1),
          Icons.play_arrow_rounded,
          const Color(0xFFB87926),
        ),
      HomeLessonStatus.locked => (
          const Color(0xFFEBEAEA),
          Icons.lock_rounded,
          const Color(0xFFB7B4B4),
        ),
    };

    return Semantics(
      label: 'Lesson ${status.name}',
      child: Container(
        width: _HomeLessonPanelLayout.statusWidth * scale,
        height: _HomeLessonPanelLayout.statusHeight * scale,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(
            _HomeLessonPanelLayout.statusRadius * scale,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB7B4B4),
              offset: Offset(0, _HomeLessonPanelLayout.statusDepth * scale),
              blurRadius: 0,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: _HomeLessonPanelLayout.statusIconSize * scale,
        ),
      ),
    );
  }
}

/// Editable measurements from the original 378-wide lesson-panel artwork.
abstract final class _HomeLessonPanelLayout {
  static const double designWidth = 378;
  static const double headingLeftInset = 2;
  static const double headingIconSize = 20;
  static const double headingGap = 6;
  static const double headingFontSize = 13;
  static const double headingToSectionGap = 6;
  static const double sectionLabelFontSize = 11;
  static const double sectionLabelToLineGap = 12;
  static const double sectionChevronSize = 16;
  static const double dividerHeight = 1;
  static const double sectionToCardGap = 8;
  // Collapsed deck tuning. Edit these four values to position or resize only
  // the quiet lower card behind the lesson panel.
  static const double deckVerticalOffset = 9;
  static const double deckHorizontalOffset = 0;
  static const double deckSideInset = 10;
  static const double deckCardHeight = 63;
  static const double cardHeight = 63;
  static const double lessonCardGap = 8;
  static const double cardRadius = 11;
  static const double cardHorizontalPadding = 16;
  static const double dotsWidth = 10;
  static const double dotsHeight = 17;
  static const double dotsOffsetX = -10;
  static const double dotsOffsetY = 0;
  static const double dotsToIconGap = 4;
  static const double categoryIconSize = 46;
  static const double summaryIconToTextGap = 10;
  static const double summaryTitleFontSize = 17;
  static const double summaryCategoryFontSize = 11;
  static const double summaryTextGap = 5;
  static const double categoryToTextGap = 10;
  static const double unitTextWidth = 100;
  static const double textColumnsGap = 10;
  static const double unitFontSize = 30;
  static const double categoryFontSize = 14;
  static const double statusGap = 8;
  static const double statusWidth = 24;
  static const double statusHeight = 22.4;
  static const double statusRadius = 5;
  static const double statusDepth = 1.6;
  static const double statusIconSize = 18;
}
