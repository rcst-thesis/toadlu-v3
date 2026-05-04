import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../app_data.dart';
import '../app_theme.dart';
import 'level_intro_page.dart';

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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LevelIntroPage(level: level)),
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
            color: const Color(0xFFDDF7FF),
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
                        child: _LessonBanner(currentLevel: currentLevel),
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
                    child: Container(
                      width: 260,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .14),
                            blurRadius: 22,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Scroll down to see 50 levels. Tap level 1 to begin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: TudloColors.ink,
                          fontSize: 17,
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
                  color: Color(0xFF172033),
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Container(
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
          icon: Icons.diamond_rounded,
          value: '${140 + currentLevel * 35}',
          color: TudloColors.sky,
        ),
        const SizedBox(width: 8),
        _PillCounter(
          icon: Icons.favorite_rounded,
          value: '${AppData.streakDays}',
          color: TudloColors.coral,
        ),
      ],
    );
  }
}

class _PillCounter extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _PillCounter({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _LessonBanner extends StatelessWidget {
  final int currentLevel;

  const _LessonBanner({required this.currentLevel});

  @override
  Widget build(BuildContext context) {
    final difficulty = ((currentLevel - 1) ~/ 10) + 1;

    return Container(
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
              color: Color(0xFFEFE2D6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hiking_rounded,
              color: Color(0xFF8D6140),
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level $currentLevel, Unit $difficulty',
                  style: const TextStyle(
                    color: TudloColors.sky,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '10 mixed questions',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: TudloColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F8FD),
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Icon(Icons.menu_rounded, color: TudloColors.sky),
          ),
        ],
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
      top: point.dy - size / 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          const SizedBox(height: 3),
          SizedBox(
            width: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Icon(
                  Icons.star_rounded,
                  size: 15,
                  color: index < stars ? TudloColors.gold : Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: .18),
                      blurRadius: 4,
                    ),
                  ],
                );
              }),
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
        ..color = const Color(0xFFB47B48)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 92
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFD19A61)
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

    _paintScenery(canvas, size);
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
    const skyHeight = 116.0;
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFC9F3FF), Color(0xFFEAFBFF)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, skyHeight));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, skyHeight), sky);

    final meadow = Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB7EA75), Color(0xFF42BC43)],
          ).createShader(
            Rect.fromLTWH(0, skyHeight, size.width, size.height - skyHeight),
          );
    canvas.drawRect(
      Rect.fromLTWH(0, skyHeight, size.width, size.height - skyHeight),
      meadow,
    );

    _cloud(canvas, Offset(size.width * .22, 58), size.width * .18);
    _cloud(canvas, Offset(size.width * .72, 112), size.width * .14);

    final hillPaint = Paint()..color = const Color(0xFF8FDC62);
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

  void _cloud(Canvas canvas, Offset center, double width) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .95);
    final shade = Paint()
      ..color = const Color(0xFFDDF4FA).withValues(alpha: .68);
    final h = width * .42;
    for (final item in [
      const Offset(-.42, .10),
      const Offset(-.18, -.06),
      const Offset(.08, -.12),
      const Offset(.32, .04),
      const Offset(.50, .12),
    ]) {
      canvas.drawCircle(
        center + Offset(item.dx * width, item.dy * h),
        h * .38,
        shade,
      );
    }
    for (final item in [
      const Offset(-.46, .02),
      const Offset(-.22, -.15),
      const Offset(.03, -.20),
      const Offset(.28, -.05),
      const Offset(.50, .02),
    ]) {
      canvas.drawCircle(
        center + Offset(item.dx * width, item.dy * h),
        h * .36,
        paint,
      );
    }
  }

  void _paintScenery(Canvas canvas, Size size) {
    final fence = Paint()
      ..color = const Color(0xFF9A6638)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    for (var y = 80.0; y < size.height; y += 720) {
      canvas.drawLine(
        Offset(0, y + 80),
        Offset(size.width * .30, y + 28),
        fence,
      );
      canvas.drawLine(
        Offset(size.width * .70, y + 26),
        Offset(size.width, y + 78),
        fence,
      );
      for (final x in [24.0, 92.0, size.width - 92, size.width - 24]) {
        canvas.drawLine(Offset(x, y + 6), Offset(x, y + 88), fence);
      }
    }

    final rock = Paint()..color = const Color(0xFFC8C6A5);
    final bush = Paint()..color = const Color(0xFF2FA149);
    for (var y = 260.0; y < size.height; y += 430) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * .14, y, 26, 17),
          const Radius.circular(4),
        ),
        rock,
      );
      canvas.drawCircle(Offset(size.width * .15, y + 150), 34, bush);
      canvas.drawCircle(Offset(size.width * .23, y + 142), 28, bush);
      canvas.drawCircle(Offset(size.width * .83, y + 240), 30, bush);
      canvas.drawCircle(Offset(size.width * .91, y + 235), 24, bush);
    }
  }

  @override
  bool shouldRepaint(covariant _ScrollableMapPainter oldDelegate) {
    return oldDelegate.road.width != road.width;
  }
}
