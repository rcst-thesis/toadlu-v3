import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../app_data.dart';
import '../app_state.dart';
import '../app_theme.dart';
import '../forest_art.dart';
import 'level_game_page.dart';

class HomeMapPage extends StatefulWidget {
  const HomeMapPage({super.key});

  @override
  State<HomeMapPage> createState() => _HomeMapPageState();
}

class _HomeMapPageState extends State<HomeMapPage> {
  static const double _levelGap = 148;
  static const double _topPad = 115;
  static const double _bottomPad = 330;

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
            const TudloMascot(size: 112),
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
    final username = AppStateScope.of(context).username;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: TudloColors.meadow,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 110),
              child: Column(
                children: [
                  _MapHeader(
                    currentLevel: currentLevel,
                    username: username.isEmpty ? 'nicole' : username,
                  ),
                  SizedBox(
                    height: mapHeight,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final road = _RoadGeometry(
                          width: constraints.maxWidth,
                          topPad: _topPad,
                          levelGap: _levelGap,
                        );

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _ScrollableMapPainter(road: road),
                              ),
                            ),
                            _MapAsset(
                              asset: 'assets/images/cloud.jpg',
                              left: constraints.maxWidth * .10,
                              top: 62,
                              width: 92,
                            ),
                            _MapAsset(
                              asset: 'assets/images/cloud2.jpg',
                              left: constraints.maxWidth * .69,
                              top: 20,
                              width: 88,
                            ),
                            _MapAsset(
                              asset: 'assets/images/tree1.png',
                              left: constraints.maxWidth - 98,
                              top: _topPad + 30,
                              width: 118,
                            ),
                            _MapAsset(
                              asset: 'assets/images/stone1.png',
                              left: constraints.maxWidth - 110,
                              top: _topPad + 270,
                              width: 88,
                            ),
                            _MapAsset(
                              asset: 'assets/images/bush1.jpg',
                              left: 2,
                              top: _topPad + 430,
                              width: 128,
                            ),
                            _MapAsset(
                              asset: 'assets/images/stone2.png',
                              left: constraints.maxWidth - 112,
                              top: _topPad + 710,
                              width: 90,
                            ),
                            _MapAsset(
                              asset: 'assets/images/bush2.jpg',
                              left: 4,
                              top: _topPad + 940,
                              width: 128,
                            ),
                            _AccountReminder(top: _topPad + 900),
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
                ],
              ),
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
                        const TudloMascot(size: 140),
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
  final String username;

  const _MapHeader({required this.currentLevel, required this.username});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: TudloColors.forest,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(42)),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _HeaderForestPainter())),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 18, 30, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _HeaderCounter(
                          icon: Icons.diamond_rounded,
                          value: '${AppData.energyPoints}',
                        ),
                        const SizedBox(width: 12),
                        _HeaderCounter(
                          icon: Icons.local_fire_department_rounded,
                          value: '${AppData.streakDays}',
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Hello, $username!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Let's learn something today",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 34),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCounter extends StatelessWidget {
  final IconData icon;
  final String value;

  const _HeaderCounter({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: TudloColors.navy.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(icon, color: TudloColors.meadow, size: 28),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderForestPainter extends CustomPainter {
  const _HeaderForestPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()..color = TudloColors.navy.withValues(alpha: .16);
    final light = Paint()..color = TudloColors.blue.withValues(alpha: .18);
    final bush = Paint()..color = TudloColors.meadow.withValues(alpha: .24);

    canvas.drawCircle(Offset(size.width * .86, -26), size.width * .38, dark);
    canvas.drawCircle(Offset(size.width * .78, size.height * .72), 86, light);
    canvas.drawCircle(Offset(size.width * .34, size.height * .86), 74, bush);
    canvas.drawCircle(Offset(size.width * .62, size.height * .92), 68, bush);
    canvas.drawCircle(Offset(size.width * .92, size.height * .88), 84, bush);
  }

  @override
  bool shouldRepaint(covariant _HeaderForestPainter oldDelegate) => false;
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

class _AccountReminder extends StatelessWidget {
  final double top;

  const _AccountReminder({required this.top});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 22,
      right: 22,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {},
          child: Container(
            height: 104,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: TudloColors.forest.withValues(alpha: .15),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFFF6A3D),
                  size: 46,
                ),
                SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Don't lose your progress",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'ENTER YOUR ACCOUNT',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
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
    final size = current ? 86.0 : 74.0;
    final nodeColor = unlocked
        ? const Color(0xFF55BE78)
        : const Color(0xFFDDBB88);
    final borderColor = unlocked
        ? const Color(0xFFDDF4D6)
        : const Color(0xFFE8CFAB);
    final iconColor = unlocked ? Colors.white : const Color(0xFFB8925F);
    final icon = !unlocked
        ? Icons.lock_rounded
        : level.isEven
        ? Icons.translate_rounded
        : Icons.description_rounded;

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
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(size / 2),
            child: InkWell(
              borderRadius: BorderRadius.circular(size / 2),
              onTap: onTap,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (unlocked)
                    Container(
                      width: size + 24,
                      height: size + 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .42),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: nodeColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 5),
                      boxShadow: [
                        if (current)
                          BoxShadow(
                            color: Colors.white.withValues(alpha: .82),
                            blurRadius: 26,
                            spreadRadius: 9,
                          ),
                        BoxShadow(
                          color: TudloColors.forest.withValues(alpha: .20),
                          blurRadius: 12,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        if (unlocked)
                          Positioned(
                            right: 13,
                            top: 10,
                            child: Container(
                              width: 24,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .38),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        Center(child: Icon(icon, color: iconColor, size: 36)),
                      ],
                    ),
                  ),
                ],
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
    final amplitude = math.max(76.0, width * .22);
    final broad = math.sin((level - 1) * .86 + .40) * amplitude;
    final drift = math.sin((level - 1) * .24 + 1.4) * amplitude * .12;
    final x = center + broad + drift;
    return x.clamp(104.0, width - 104.0);
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
        ..color = TudloColors.forest.withValues(alpha: .12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 110
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFF9F1D1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 96
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFF8DE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 76
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final linePaint = Paint()
      ..color = const Color(0xFFD8C990).withValues(alpha: .78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var y = road.topPad - 8; y < size.height; y += 86) {
      final level = ((y - road.topPad) / road.levelGap) + 1;
      final x = road.xForLevel(level);
      canvas.drawLine(Offset(x - 10, y - 22), Offset(x + 10, y - 4), linePaint);
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
    final meadow = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFC9EA91), Color(0xFFAFD06E)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Offset.zero & size, meadow);

    final hillPaint = Paint()..color = const Color(0xFFD6F2A4);
    for (var y = -28.0; y < size.height; y += 640) {
      final hill = Path()
        ..moveTo(0, y + 120)
        ..quadraticBezierTo(size.width * .30, y + 18, size.width * .58, y + 120)
        ..quadraticBezierTo(size.width * .78, y + 195, size.width, y + 90)
        ..lineTo(size.width, y + 260)
        ..lineTo(0, y + 260)
        ..close();
      canvas.drawPath(hill, hillPaint);
    }

    final flowerPaint = Paint()..color = Colors.white;
    final flowerCenter = Paint()..color = const Color(0xFFFFDE5B);
    for (final seed in [70.0, 185.0, 355.0, 540.0, 720.0, 980.0, 1190.0]) {
      final x = (math.sin(seed) * .5 + .5) * (size.width - 70) + 35;
      final y = seed % size.height;
      for (var i = 0; i < 5; i++) {
        final angle = math.pi * 2 * i / 5;
        canvas.drawCircle(
          Offset(x + math.cos(angle) * 7, y + math.sin(angle) * 7),
          5,
          flowerPaint,
        );
      }
      canvas.drawCircle(Offset(x, y), 4, flowerCenter);
    }
  }

  @override
  bool shouldRepaint(covariant _ScrollableMapPainter oldDelegate) {
    return oldDelegate.road.width != road.width;
  }
}
