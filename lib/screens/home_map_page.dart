import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../app_data.dart';
import '../app_theme.dart';
import '../forest_art.dart';
import '../lesson_bank.dart';
import 'level_game_page.dart';

class HomeMapPage extends StatefulWidget {
  const HomeMapPage({super.key});

  @override
  State<HomeMapPage> createState() => _HomeMapPageState();
}

class _HomeMapPageState extends State<HomeMapPage> {
  static const double _levelGap = 118;
  static const double _topPad = 230;
  static const double _bottomPad = 210;

  void _dismissTutorial() {
    setState(() => AppData.mapTutorialDone = true);
  }

  void _openLevel(int level) {
    AppData.mapTutorialDone = true;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: TudloColors.sky.withValues(alpha: .13),
                shape: BoxShape.circle,
              ),
              child: const Center(child: TudloMascot(size: 88)),
            ),
            const SizedBox(height: 16),
            Text(
              'Level $level',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: TudloColors.ink,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LevelGamePage(level: level),
                    ),
                  );
                },
                child: const Text('Play'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showTutorial = !AppData.mapTutorialDone;
    final currentLevel = AppData.unlockedLevel.clamp(1, AppData.maxLevel);
    final mapHeight = _topPad + (AppData.maxLevel - 1) * _levelGap + _bottomPad;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            child: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                        child: _MapHeader(currentLevel: currentLevel),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                        child: _LessonBanner(
                          currentLevel: currentLevel,
                          onTap: () => _openLevel(currentLevel),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: SizedBox(
                      height: mapHeight,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final road = _RoadGeometry(
                            width: constraints.maxWidth,
                            topPad: _topPad,
                            levelGap: _levelGap,
                          );

                          return Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _ScrollableMapPainter(road: road),
                                ),
                              ),
                              _MapAsset(
                                asset: 'assets/images/cloud.jpg',
                                left: constraints.maxWidth * .04,
                                top: 2,
                                width: 155,
                              ),
                              _MapAsset(
                                asset: 'assets/images/cloud2.jpg',
                                left: constraints.maxWidth * .55,
                                top: 8,
                                width: 100,
                              ),
                              _MapAsset(
                                asset: 'assets/images/tree1.png',
                                left: 8,
                                top: _topPad + 150,
                                width: 135,
                              ),
                              _MapAsset(
                                asset: 'assets/images/stone1.png',
                                left: constraints.maxWidth - 112,
                                top: _topPad + 360,
                                width: 96,
                              ),
                              _MapAsset(
                                asset: 'assets/images/bush1.jpg',
                                left: constraints.maxWidth - 150,
                                top: _topPad + 620,
                                width: 140,
                              ),
                              _MapAsset(
                                asset: 'assets/images/stone2.png',
                                left: 4,
                                top: _topPad + 920,
                                width: 102,
                              ),
                              _MapAsset(
                                asset: 'assets/images/bush2.jpg',
                                left: 8,
                                top: _topPad + 1160,
                                width: 148,
                              ),
                              _MapAsset(
                                asset: 'assets/images/tree1.png',
                                left: constraints.maxWidth - 138,
                                top: _topPad + 1510,
                                width: 132,
                              ),
                              for (
                                var level = 1;
                                level <= AppData.maxLevel;
                                level++
                              )
                                _LevelPositionedButton(
                                  level: level,
                                  point: road.pointForLevel(level),
                                  unlocked: level <= AppData.unlockedLevel,
                                  current: level == currentLevel,
                                  stars: AppData.starsForLevel(level),
                                  onTap: level <= AppData.unlockedLevel
                                      ? () => _openLevel(level)
                                      : null,
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showTutorial)
            Positioned.fill(
              child: GestureDetector(
                onTap: _dismissTutorial,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.38),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: TudloColors.blue.withValues(alpha: .28),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(child: TudloMascot(size: 118)),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          "Let's start learning!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
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

class _MapHeader extends StatelessWidget {
  final int currentLevel;

  const _MapHeader({required this.currentLevel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good Morning',
                style: TextStyle(
                  color: TudloColors.ink,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hiligaynon course active')),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: TudloColors.line),
                      ),
                      child: const Text(
                        'PH',
                        style: TextStyle(
                          color: TudloColors.coral,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Hiligaynon',
                    style: TextStyle(
                      color: TudloColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: TudloColors.muted,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
        _PillCounter(
          icon: Icons.favorite_rounded,
          value: '${AppData.streakDays}',
          color: TudloColors.coral,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Streak tracker is open below.')),
          ),
        ),
      ],
    );
  }
}

class _PillCounter extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _PillCounter({
    required this.icon,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(19),
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: TudloColors.line),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 5),
            Text(
              value,
              style: const TextStyle(
                color: TudloColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonBanner extends StatelessWidget {
  final int currentLevel;
  final VoidCallback onTap;

  const _LessonBanner({required this.currentLevel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unit = LessonBank.unitForLevel(currentLevel);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: TudloColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: const BoxDecoration(
                color: TudloColors.cloud,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hiking_rounded,
                color: TudloColors.forest,
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level $currentLevel',
                    style: const TextStyle(
                      color: TudloColors.sky,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Unit $unit',
                    style: const TextStyle(
                      color: TudloColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '10 Mixed Questions',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: TudloColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(19),
              onTap: () {
                _showUnitDictionary(context, currentLevel);
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: TudloColors.blue.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: const CustomPaint(
                  painter: _DictionaryIconPainter(),
                  size: Size(25, 25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnitDictionary(BuildContext context, int level) {
    var selectedUnit = LessonBank.unitForLevel(level);

    showModalBottomSheet(
      context: context,
      backgroundColor: TudloColors.navy,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final unitLevel = _levelForUnit(level, selectedUnit);
            final unitTerms = LessonBank.termsForLevel(unitLevel);

            return Container(
              color: TudloColors.navy,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Textbook Dictionary',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 56),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final unit = index + 1;
                        final selected = selectedUnit == unit;
                        return ChoiceChip(
                          selected: selected,
                          label: Text('Unit $unit'),
                          onSelected: (_) {
                            setModalState(() => selectedUnit = unit);
                          },
                          selectedColor: TudloColors.sky,
                          backgroundColor: TudloColors.navy.withValues(
                            alpha: .72,
                          ),
                          side: BorderSide(
                            color: selected
                                ? TudloColors.sky
                                : TudloColors.blue.withValues(alpha: .35),
                            width: 2,
                          ),
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.w900,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 32),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
                          child: Column(
                            children: [
                              const TudloMascot(size: 184),
                              const SizedBox(height: 24),
                              Text(
                                'SECTION ${((unitLevel - 1) ~/ 3) + 1}, UNIT $selectedUnit',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: TudloColors.cloud,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _unitTitle(selectedUnit),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  height: 1.15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          color: TudloColors.blue.withValues(alpha: .35),
                          height: 1,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 30, 22, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'KEY PHRASES',
                                style: TextStyle(
                                  color: TudloColors.sky,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                _unitSubtitle(selectedUnit),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  height: 1.12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 24),
                              for (final term in unitTerms.take(8))
                                _TextbookPhraseCard(
                                  term: term,
                                  example: _exampleFor(term),
                                  onTap: () => _showDefinition(context, term),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  int _levelForUnit(int currentLevel, int unit) {
    final sectionStart = ((currentLevel - 1) ~/ 3) * 3 + 1;
    return (sectionStart + unit - 1).clamp(1, AppData.maxLevel);
  }

  String _exampleFor(LessonTerm term) {
    return 'Example: "${term.hil}" means "${term.eng}" in English.';
  }

  String _unitTitle(int unit) {
    return switch (unit) {
      1 => 'Build everyday phrases',
      2 => 'Use words in simple conversations',
      _ => 'Practice mixed vocabulary',
    };
  }

  String _unitSubtitle(int unit) {
    return switch (unit) {
      1 => 'Discuss everyday words',
      2 => 'Describe simple ideas',
      _ => 'Review useful phrases',
    };
  }

  void _showDefinition(BuildContext context, LessonTerm term) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: TudloColors.navy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          term.hil,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'English: ${term.eng}',
              style: const TextStyle(
                color: TudloColors.sky,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Definition: "${term.hil}" is the Hiligaynon word or phrase for "${term.eng}".',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _exampleFor(term),
              style: const TextStyle(
                color: TudloColors.cloud,
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: TudloColors.sky),
            ),
          ),
        ],
      ),
    );
  }
}

class _DictionaryIconPainter extends CustomPainter {
  const _DictionaryIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cover = Paint()..color = TudloColors.sky;
    final page = Paint()..color = Colors.white;
    final detail = Paint()
      ..color = TudloColors.sky.withValues(alpha: .55)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final left = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .08, h * .12, w * .40, h * .74),
      const Radius.circular(3),
    );
    final right = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .52, h * .12, w * .40, h * .74),
      const Radius.circular(3),
    );

    canvas.drawRRect(left, cover);
    canvas.drawRRect(right, cover);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .16, h * .20, w * .26, h * .58),
        const Radius.circular(2),
      ),
      page,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .58, h * .20, w * .26, h * .58),
        const Radius.circular(2),
      ),
      page,
    );
    canvas.drawLine(Offset(w * .50, h * .16), Offset(w * .50, h * .84), detail);

    for (final y in [h * .34, h * .46, h * .58]) {
      canvas.drawLine(Offset(w * .20, y), Offset(w * .38, y), detail);
      canvas.drawLine(Offset(w * .62, y), Offset(w * .80, y), detail);
    }
    canvas.drawCircle(Offset(w * .29, h * .69), w * .035, detail);
    canvas.drawCircle(Offset(w * .71, h * .69), w * .035, detail);
  }

  @override
  bool shouldRepaint(covariant _DictionaryIconPainter oldDelegate) => false;
}

class _TextbookPhraseCard extends StatelessWidget {
  final LessonTerm term;
  final String example;
  final VoidCallback onTap;

  const _TextbookPhraseCard({
    required this.term,
    required this.example,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18, left: 18),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: CustomPaint(
          painter: _SpeechCardPainter(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(48, 22, 20, 22),
            constraints: const BoxConstraints(minHeight: 106),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: TudloColors.sky,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${term.hil} means '),
                            TextSpan(
                              text: term.eng,
                              style: TextStyle(
                                color: Colors.white,
                                decoration: TextDecoration.underline,
                                decorationColor: TudloColors.sky,
                                backgroundColor: TudloColors.blue.withValues(
                                  alpha: .45,
                                ),
                              ),
                            ),
                          ],
                        ),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          height: 1.22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        example,
                        style: TextStyle(
                          color: TudloColors.cloud.withValues(alpha: .70),
                          fontSize: 18,
                          height: 1.28,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationStyle: TextDecorationStyle.dashed,
                          decorationColor: TudloColors.blue.withValues(
                            alpha: .55,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeechCardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = TudloColors.blue.withValues(alpha: .40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = TudloColors.navy
      ..style = PaintingStyle.fill;

    final bubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(22, 2, size.width - 24, size.height - 4),
      const Radius.circular(14),
    );
    final tail = Path()
      ..moveTo(23, size.height * .35)
      ..lineTo(0, size.height * .52)
      ..lineTo(23, size.height * .58)
      ..close();

    canvas.drawRRect(bubble, fill);
    canvas.drawPath(tail, fill);
    canvas.drawRRect(bubble, border);
    canvas.drawPath(
      Path()
        ..moveTo(23, size.height * .35)
        ..lineTo(0, size.height * .52)
        ..lineTo(23, size.height * .58),
      border,
    );
  }

  @override
  bool shouldRepaint(covariant _SpeechCardPainter oldDelegate) => false;
}

class _MapAsset extends StatelessWidget {
  final String asset;
  final double left;
  final double top;
  final double width;

  const _MapAsset({
    required this.asset,
    required this.left,
    required this.top,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Image.asset(
          asset,
          width: width,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _LevelPositionedButton extends StatelessWidget {
  final int level;
  final Offset point;
  final bool unlocked;
  final bool current;
  final int stars;
  final VoidCallback? onTap;

  const _LevelPositionedButton({
    required this.level,
    required this.point,
    required this.unlocked,
    required this.current,
    required this.stars,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = current ? 80.0 : 66.0;

    return Positioned(
      left: point.dx - size / 2,
      top: point.dy - size / 2 - 25,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 72,
            height: 22,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final earned = index < stars;
                return Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: earned ? TudloColors.gold : Colors.white,
                  shadows: earned
                      ? [
                          Shadow(
                            color: TudloColors.gold.withValues(alpha: .95),
                            blurRadius: 12,
                          ),
                          Shadow(
                            color: Colors.black.withValues(alpha: .18),
                            blurRadius: 4,
                          ),
                        ]
                      : [
                          Shadow(
                            color: Colors.black.withValues(alpha: .12),
                            blurRadius: 3,
                          ),
                        ],
                );
              }),
            ),
          ),
          const SizedBox(height: 3),
          InkWell(
            borderRadius: BorderRadius.circular(size / 2),
            onTap: onTap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: unlocked ? Colors.white : const Color(0xFFE8EEF2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: current ? TudloColors.gold : Colors.white,
                  width: current ? 7 : 4,
                ),
                boxShadow: [
                  if (current)
                    BoxShadow(
                      color: TudloColors.gold.withValues(alpha: .88),
                      blurRadius: 30,
                      spreadRadius: 8,
                    ),
                  BoxShadow(
                    color: TudloColors.ink.withValues(alpha: .18),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: unlocked
                    ? Text(
                        '$level',
                        style: TextStyle(
                          color: current ? TudloColors.gold : TudloColors.ink,
                          fontSize: current ? 24 : 18,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : const Icon(Icons.lock_rounded, color: TudloColors.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoadGeometry {
  final double width;
  final double topPad;
  final double levelGap;

  const _RoadGeometry({
    required this.width,
    required this.topPad,
    required this.levelGap,
  });

  Offset pointForLevel(int level) {
    final y = topPad + (level - 1) * levelGap;
    return Offset(xForLevel(level.toDouble()), y);
  }

  double xForLevel(double level) {
    final center = width / 2;
    final amplitude = math.max(102.0, width * .31);
    final broad = math.sin((level - 1) * .88 + .42) * amplitude;
    final drift = math.sin((level - 1) * .23 + 1.4) * amplitude * .18;
    final x = center + broad + drift;
    return x.clamp(92.0, width - 92.0);
  }

  List<Offset> anchors(Size size) {
    return [
      Offset(xForLevel(1.0), topPad - 38),
      for (var level = 1; level <= AppData.maxLevel; level++)
        pointForLevel(level),
      Offset(xForLevel(AppData.maxLevel.toDouble()), size.height + 95),
    ];
  }
}

class _ScrollableMapPainter extends CustomPainter {
  final _RoadGeometry road;

  const _ScrollableMapPainter({required this.road});

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);

    final path = _smoothPath(road.anchors(size));

    canvas.drawPath(
      path.shift(const Offset(0, 10)),
      Paint()
        ..color = Colors.black.withValues(alpha: .10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 98
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = TudloColors.forest
        ..style = PaintingStyle.stroke
        ..strokeWidth = 92
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = TudloColors.meadow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 58
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: .20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var y = road.topPad - 8; y < size.height; y += 86) {
      final level = ((y - road.topPad) / road.levelGap) + 1;
      final x = road.xForLevel(level);
      canvas.drawLine(
        Offset(x - 36, y - 18),
        Offset(x + 36, y + 18),
        linePaint,
      );
    }
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final mid = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(current.dx, current.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  void _paintBackground(Canvas canvas, Size size) {
    const skyHeight = 150.0;
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF87AECE), Color(0xFFEDEDED)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, skyHeight));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, skyHeight), sky);

    final meadow = Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFAFD06E), Color(0xFF437118)],
          ).createShader(
            Rect.fromLTWH(0, skyHeight, size.width, size.height - skyHeight),
          );
    canvas.drawRect(
      Rect.fromLTWH(0, skyHeight, size.width, size.height - skyHeight),
      meadow,
    );

    final hillPaint = Paint()..color = TudloColors.meadow;
    for (var y = skyHeight - 58; y < size.height; y += 620) {
      final hill = Path()
        ..moveTo(0, y + 120)
        ..quadraticBezierTo(size.width * .30, y + 18, size.width * .58, y + 120)
        ..quadraticBezierTo(size.width * .78, y + 195, size.width, y + 90)
        ..lineTo(size.width, y + 260)
        ..lineTo(0, y + 260)
        ..close();
      canvas.drawPath(hill, hillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScrollableMapPainter oldDelegate) {
    return oldDelegate.road.width != road.width;
  }
}
