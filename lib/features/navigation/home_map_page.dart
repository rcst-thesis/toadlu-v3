import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/style/app_theme.dart';
import 'package:tudloapp/core/style/forest_art.dart';
import 'package:tudloapp/features/lessons/level_game_page.dart';
import 'package:tudloapp/features/lessons/lesson_bank.dart';

class HomeMapPage extends StatefulWidget {
  const HomeMapPage({super.key});

  @override
  State<HomeMapPage> createState() => _HomeMapPageState();
}

class _HomeMapPageState extends State<HomeMapPage> {
  /// Vertical spacing used by both the road painter and the level nodes.
  ///
  /// Keeping these constants shared prevents the buttons from drifting away
  /// from the path when the map height changes.
  static const double _levelGap = 148;
  static const double _unitMessageGap = 142;
  static const double _topPad = 250;
  static const double _bottomPad = 330;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollTopButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    final shouldShow = _scrollController.offset > 360;
    if (shouldShow == _showScrollTopButton) return;
    setState(() => _showScrollTopButton = shouldShow);
  }

  void _dismissTutorial() {
    setState(() => AppData.mapTutorialDone = true);
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }

  void _showUnitContentPreview(AppUnit unit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UnitContentPreviewSheet(unit: unit),
    );
  }

  void _openLevel(int level, Offset nodeCenter) {
    final dataset = AppStateScope.of(context).homeMapDataset;
    AppData.mapTutorialDone = true;
    showGeneralDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      barrierLabel: 'Close level selection',
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, animation, secondaryAnimation) =>
          _LevelStartDialog(
            level: level,
            nodeCenter: nodeCenter,
            onStart: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LevelGamePage(level: level, dataset: dataset),
                ),
              );
            },
          ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final showTutorial = !AppData.mapTutorialDone;
    final currentLevel = AppData.unlockedLevel.clamp(1, AppData.maxLevel);
    // The scrollable map needs a fixed content height so decorations, road,
    // stars, and level nodes can all be positioned in the same coordinate space.
    final mapHeight =
        _topPad +
        (AppData.maxLevel - 1) * _levelGap +
        ((AppData.maxLevel - 1) ~/ 5) * _unitMessageGap +
        40 +
        _bottomPad;
    final username = AppStateScope.of(context).displayUsername;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: TudloColors.meadow,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 110),
              child: Column(
                children: [
                  _MapHeader(currentLevel: currentLevel, username: username),
                  SizedBox(
                    height: mapHeight,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final road = _RoadGeometry(
                          width: constraints.maxWidth,
                          topPad: _topPad,
                          levelGap: _levelGap,
                          unitMessageGap: _unitMessageGap,
                        );

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _ScrollableMapPainter(road: road),
                              ),
                            ),
                            _MapDecorationLayer(
                              width: constraints.maxWidth,
                              height: mapHeight,
                              road: road,
                            ),
                            for (final unit in AppData.units)
                              _UnitMessageCard(
                                unit: unit,
                                point: road.pointForUnitStart(unit.startLevel),
                                onPreview: () => _showUnitContentPreview(unit),
                              ),
                            for (
                              var level = 1;
                              level <= AppData.maxLevel;
                              level++
                            )
                              // Each button uses the same road coordinates as
                              // the painter, which keeps nodes centered on the
                              // trail instead of manually guessing positions.
                              _LevelPositionedButton(
                                level: level,
                                point: road.pointForLevel(level),
                                unitColor: _MapUnitStyle.colorForLevel(level),
                                unlocked: AppData.isLevelUnlocked(level),
                                current: level == currentLevel,
                                stars: AppData.isLevelUnlocked(level)
                                    ? AppData.starsForLevel(level)
                                    : 0,
                                onTap: AppData.isLevelUnlocked(level)
                                    ? (nodeCenter) =>
                                          _openLevel(level, nodeCenter)
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
          Positioned(
            right: 24,
            bottom: 112,
            child: AnimatedScale(
              scale: _showScrollTopButton ? 1 : .72,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: AnimatedOpacity(
                opacity: _showScrollTopButton ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: IgnorePointer(
                  ignoring: !_showScrollTopButton,
                  child: _ScrollTopButton(onTap: _scrollToTop),
                ),
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
                        const _CenterMascotShowcase(),
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
        color: TudloColors.green,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(42)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/mapheader.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
            ),
          ),
          Positioned.fill(
            child: ColoredBox(color: TudloColors.forest.withValues(alpha: .12)),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 18, 30, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: _HeaderCounter(
                      icon: Icons.bolt_rounded,
                      value: '${AppData.energyPoints}',
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

class _LevelStartDialog extends StatefulWidget {
  final int level;
  final Offset nodeCenter;
  final VoidCallback onStart;

  const _LevelStartDialog({
    required this.level,
    required this.nodeCenter,
    required this.onStart,
  });

  @override
  State<_LevelStartDialog> createState() => _LevelStartDialogState();
}

class _LevelStartDialogState extends State<_LevelStartDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _cardScaleAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _nodeBounceAnimation;

  static const _cardGreen = TudloColors.brightGreen;
  static const _cardDark = TudloColors.forest;
  static const _nodeSize = 98.0;
  static const _cardHeight = 190.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(curved);
    _cardScaleAnimation = Tween<double>(
      begin: .92,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, .08),
      end: Offset.zero,
    ).animate(curved);
    _nodeBounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 1.12), weight: 45),
      TweenSequenceItem(tween: Tween<double>(begin: 1.12, end: 1), weight: 55),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final cardWidth = math.min(screen.width * .88, 430.0);
    const cardTopGap = 22.0;
    final cardLeft = (widget.nodeCenter.dx - cardWidth / 2)
        .clamp(16.0, screen.width - cardWidth - 16)
        .toDouble();
    final cardTop = (widget.nodeCenter.dy + _nodeSize / 2 + cardTopGap)
        .clamp(24.0, math.max(24.0, screen.height - _cardHeight - 112))
        .toDouble();
    final pointerLeft = (widget.nodeCenter.dx - cardLeft - 17)
        .clamp(18.0, cardWidth - 52)
        .toDouble();

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            left: widget.nodeCenter.dx - _nodeSize / 2,
            top: widget.nodeCenter.dy - _nodeSize / 2,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _nodeBounceAnimation,
                child: const _SelectedLevelNode(),
              ),
            ),
          ),
          Positioned(
            left: cardLeft,
            top: cardTop,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _cardScaleAnimation,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: pointerLeft,
                        top: -16,
                        child: CustomPaint(
                          size: const Size(34, 18),
                          painter: _LevelCardPointerPainter(color: _cardGreen),
                        ),
                      ),
                      _LevelStartCard(
                        width: cardWidth,
                        level: widget.level,
                        onStart: widget.onStart,
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

class _ScrollTopButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ScrollTopButton({required this.onTap});

  //back to the top button
  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(15));

    return Material(
      color: TudloColors.green,
      borderRadius: borderRadius,
      elevation: 8,
      shadowColor: TudloColors.forest.withValues(alpha: .18),
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(
              color: Colors.white.withValues(alpha: .36),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.keyboard_arrow_up_rounded,
            color: Colors.white,
            size: 42,
          ),
        ),
      ),
    );
  }
}

class _LevelStartCard extends StatelessWidget {
  final double width;
  final int level;
  final VoidCallback onStart;

  const _LevelStartCard({
    required this.width,
    required this.level,
    required this.onStart,
  });

  static const _cardGreen = _LevelStartDialogState._cardGreen;
  static const _cardDark = _LevelStartDialogState._cardDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: _LevelStartDialogState._cardHeight,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: _cardGreen,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: _cardDark, blurRadius: 0, offset: Offset(0, 7)),
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(left: 48, top: 44, child: _SparkleDot(size: 9)),
          const Positioned(right: 38, top: 36, child: _SparkleDot(size: 8)),
          const Positioned(right: 4, bottom: 0, child: _SparkleDot(size: 12)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Level $level',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 27,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              _StartLevelButton(onStart: onStart),
            ],
          ),
        ],
      ),
    );
  }
}

class _StartLevelButton extends StatefulWidget {
  final VoidCallback onStart;

  const _StartLevelButton({required this.onStart});

  @override
  State<_StartLevelButton> createState() => _StartLevelButtonState();
}

class _StartLevelButtonState extends State<_StartLevelButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? .97 : 1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: SizedBox(
        height: 62,
        child: GestureDetector(
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          child: ElevatedButton(
            onPressed: widget.onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _LevelStartDialogState._cardDark,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: .80),
                  width: 3,
                ),
              ),
              textStyle: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            child: const Text('START!'),
          ),
        ),
      ),
    );
  }
}

class _SelectedLevelNode extends StatelessWidget {
  const _SelectedLevelNode();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 98,
      height: 98,
      decoration: BoxDecoration(
        color: TudloColors.brightGreen,
        shape: BoxShape.circle,
        border: Border.all(color: TudloColors.softGreen, width: 8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55234810),
            blurRadius: 0,
            offset: Offset(0, 9),
          ),
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 18,
            top: 16,
            child: Container(
              width: 28,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .25),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const Icon(Icons.star_rounded, color: Colors.white, size: 58),
        ],
      ),
    );
  }
}

class _LevelCardPointerPainter extends CustomPainter {
  final Color color;

  const _LevelCardPointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _LevelCardPointerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _SparkleDot extends StatelessWidget {
  final double size;

  const _SparkleDot({required this.size});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(2),
        ),
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
        color: TudloColors.sky.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 30),
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

class _MapAsset extends StatelessWidget {
  final String asset;
  final double left;
  final double top;
  final double width;
  final double? height;
  final double rotation;
  final bool flip;

  const _MapAsset({
    required this.asset,
    required this.left,
    required this.top,
    required this.width,
    this.height,
    this.rotation = 0,
    this.flip = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: rotation,
          child: Transform.scale(
            scaleX: flip ? -1 : 1,
            child: Image.asset(
              asset,
              width: width,
              height: height,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapDecorationLayer extends StatelessWidget {
  final double width;
  final double height;
  final _RoadGeometry road;

  const _MapDecorationLayer({
    required this.width,
    required this.height,
    required this.road,
  });

  static const _assets = [
    'assets/images/tree1.png',
    'assets/images/tree2.png',
    'assets/images/tree1 (2).png',
    'assets/images/grass.png',
    'assets/images/rock.png',
    'assets/images/flower.png',
  ];

  @override
  Widget build(BuildContext context) {
    final decorations = <Widget>[];
    var index = 0;

    for (var y = 72.0; y < height - 120; y += 185) {
      decorations.add(_decoration(index, y, leftSide: index.isEven));
      if (index % 2 == 0) {
        decorations.add(
          _decoration(index + 7, y + 92, leftSide: false, compact: true),
        );
      } else {
        decorations.add(
          _decoration(index + 9, y + 96, leftSide: true, compact: true),
        );
      }
      index++;
    }

    return Positioned.fill(
      child: Stack(clipBehavior: Clip.none, children: decorations),
    );
  }

  Widget _decoration(
    int index,
    double y, {
    required bool leftSide,
    bool compact = false,
  }) {
    final asset = compact
        ? _assets[(index + 2) % _assets.length]
        : _assets[index % _assets.length];
    final isTree = asset.contains('tree');
    final baseWidth = switch (asset) {
      'assets/images/tree1.png' => compact ? 154.0 : 211.0,
      'assets/images/tree2.png' => compact ? 154.0 : 211.0,
      'assets/images/tree1 (2).png' => compact ? 154.0 : 211.0,
      'assets/images/grass.png' => compact ? 74.0 : 116.0,
      'assets/images/rock.png' => compact ? 62.0 : 92.0,
      _ => compact ? 32.0 : 44.0,
    };
    final assetHeight = isTree ? (compact ? 170.0 : 230.0) : null;
    final variation = math.sin(index * 1.73) * 20;
    final roadLevel = ((y - road.topPad) / road.levelGap) + 1;
    final roadX = road.xForLevel(roadLevel);
    final x = _xForSide(
      leftSide: leftSide,
      assetWidth: baseWidth,
      asset: asset,
      roadX: roadX,
      variation: variation,
    );
    final rotation = _rotationForAsset(asset, index);

    return _MapAsset(
      asset: asset,
      left: x,
      top: y,
      width: baseWidth,
      height: assetHeight,
      rotation: rotation,
      flip: !leftSide && (asset.contains('tree') || asset.contains('grass')),
    );
  }

  double _rotationForAsset(String asset, int index) {
    if (asset.contains('tree')) return 0;

    final wave = math.sin(index * .91);
    final maxDegrees = asset.contains('rock')
        ? 3.0
        : asset.contains('grass')
        ? 2.0
        : 5.0;
    return wave * maxDegrees * math.pi / 180;
  }

  double _xForSide({
    required bool leftSide,
    required double assetWidth,
    required String asset,
    required double roadX,
    required double variation,
  }) {
    final isTree = asset.contains('tree');
    final roadClearance = isTree
        ? 150.0
        : asset.contains('grass')
        ? 110.0
        : 98.0;
    if (leftSide) {
      final target = 14.0 + variation.abs();
      final maxSafe = roadX - roadClearance - assetWidth;
      if (isTree) {
        return math.min(target, maxSafe);
      }
      return target.clamp(0.0, math.max(0.0, maxSafe)).toDouble();
    }

    final target = width - assetWidth - 14.0 - variation.abs();
    final maxSafe = math.max(0.0, width - assetWidth);
    final minSafe = math.min(maxSafe, roadX + roadClearance);
    if (isTree) {
      return math.max(target, roadX + roadClearance);
    }
    return target.clamp(minSafe, maxSafe).toDouble();
  }
}

class _CenterMascotShowcase extends StatefulWidget {
  const _CenterMascotShowcase();

  @override
  State<_CenterMascotShowcase> createState() => _CenterMascotShowcaseState();
}

class _CenterMascotShowcaseState extends State<_CenterMascotShowcase>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _idleController;
  late final AnimationController _tapController;
  late final Animation<double> _entrance;
  late final Animation<double> _idle;
  late final Animation<double> _tapBounce;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    )..forward();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _entrance = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
    );
    _idle = CurvedAnimation(parent: _idleController, curve: Curves.easeInOut);
    _tapBounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 1.12), weight: 45),
      TweenSequenceItem(tween: Tween<double>(begin: 1.12, end: 1), weight: 55),
    ]).animate(CurvedAnimation(parent: _tapController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _idleController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _react() {
    _tapController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entranceController,
      child: ScaleTransition(
        scale: Tween<double>(begin: .7, end: 1).animate(_entrance),
        child: AnimatedBuilder(
          animation: Listenable.merge([_idle, _tapBounce]),
          builder: (context, child) {
            final lift = -5 * _idle.value;
            final breathing = 1 + (_idle.value * .026);
            return Transform.translate(
              offset: Offset(0, lift),
              child: Transform.scale(
                scale: breathing * _tapBounce.value,
                child: child,
              ),
            );
          },
          child: GestureDetector(
            onTap: _react,
            child: SizedBox(
              width: 238,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  AnimatedBuilder(
                    animation: _idle,
                    builder: (context, child) {
                      return Container(
                        width: 178 + (_idle.value * 14),
                        height: 178 + (_idle.value * 14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: .62),
                              Colors.white.withValues(alpha: .22),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: .42),
                              blurRadius: 42,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const _CenterSparkle(left: 24, top: 48, size: 18, delay: .1),
                  const _CenterSparkle(left: 58, top: 28, size: 8, delay: .5),
                  const _CenterSparkle(left: 190, top: 50, size: 15, delay: .8),
                  const _CenterSparkle(left: 34, top: 150, size: 10, delay: .3),
                  const _CenterSparkle(
                    left: 184,
                    top: 156,
                    size: 11,
                    delay: .6,
                  ),
                  const _CenterSparkle(left: 150, top: 24, size: 7, delay: .2),
                  const TudloMascot(size: 150),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterSparkle extends StatefulWidget {
  final double left;
  final double top;
  final double size;
  final double delay;

  const _CenterSparkle({
    required this.left,
    required this.top,
    required this.size,
    required this.delay,
  });

  @override
  State<_CenterSparkle> createState() => _CenterSparkleState();
}

class _CenterSparkleState extends State<_CenterSparkle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1800 + (widget.delay * 800).round()),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.left,
      top: widget.top,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final phase = (_controller.value + widget.delay) % 1;
          final opacity = .28 + (math.sin(phase * math.pi) * .52);
          final drift = math.sin(phase * math.pi * 2) * 2;
          return Transform.translate(
            offset: Offset(0, drift),
            child: Transform.rotate(
              angle: phase * math.pi * .18,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: widget.size,
                color: Colors.white.withValues(alpha: opacity.clamp(.18, .80)),
                shadows: [
                  Shadow(
                    color: Colors.white.withValues(alpha: .70),
                    blurRadius: 14,
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

class _MapUnitStyle {
  static const _unitColors = [
    TudloColors.brightGreen,
    Color(0xFF3D91E8),
    Color(0xFF8B5CF6),
    Color(0xFFE85D9E),
    Color(0xFFE05A47),
    Color(0xFFF59E0B),
  ];

  static Color colorForLevel(int level) {
    final unitIndex = ((level - 1) ~/ 5).clamp(0, _unitColors.length - 1);
    return _unitColors[unitIndex];
  }
}

class _UnitMessageCard extends StatelessWidget {
  final AppUnit unit;
  final Offset point;
  final VoidCallback onPreview;

  const _UnitMessageCard({
    required this.unit,
    required this.point,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 72,
      right: 72,
      top: point.dy,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .96),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: TudloColors.softGreen, width: 2),
            boxShadow: [
              BoxShadow(
                color: TudloColors.forest.withValues(alpha: .12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Unit ${unit.number}',
                      style: const TextStyle(
                        color: TudloColors.muted,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      unit.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TudloColors.ink,
                        fontSize: 22,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: onPreview,
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: TudloColors.green,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: TudloColors.green.withValues(alpha: .22),
                        blurRadius: 14,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitContentPreviewSheet extends StatelessWidget {
  final AppUnit unit;

  const _UnitContentPreviewSheet({required this.unit});

  List<LessonTerm> get _terms {
    final seen = <String>{};
    final terms = <LessonTerm>[];
    for (var level = unit.startLevel; level <= unit.endLevel; level++) {
      for (final term in LessonBank.termsForLevel(level)) {
        final key = '${term.hil}|${term.eng}'.toLowerCase();
        if (seen.add(key)) terms.add(term);
      }
    }
    return terms;
  }

  @override
  Widget build(BuildContext context) {
    final terms = _terms;
    final height = MediaQuery.sizeOf(context).height * .86;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: TudloColors.muted,
                  iconSize: 32,
                ),
                const Spacer(),
              ],
            ),
          ),
          const TudloMascot(size: 118),
          const SizedBox(height: 10),
          Text(
            'UNIT ${unit.number}',
            style: const TextStyle(
              color: TudloColors.muted,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            unit.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: TudloColors.ink,
              fontSize: 30,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 22),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: TudloColors.paper,
                border: Border(top: BorderSide(color: TudloColors.line)),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
                children: [
                  const Text(
                    'KEY PHRASES',
                    style: TextStyle(
                      color: TudloColors.green,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...terms.map((term) => _PreviewPhraseCard(term: term)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPhraseCard extends StatelessWidget {
  final LessonTerm term;

  const _PreviewPhraseCard({required this.term});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TudloColors.line, width: 2),
        boxShadow: [
          BoxShadow(
            color: TudloColors.forest.withValues(alpha: .05),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: TudloColors.softGreen,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.volume_up_rounded,
              color: TudloColors.green,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  term.hil,
                  style: const TextStyle(
                    color: TudloColors.ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  term.eng,
                  style: const TextStyle(
                    color: TudloColors.muted,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
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

class _LevelPositionedButton extends StatefulWidget {
  final int level;
  final Offset point;
  final Color unitColor;
  final bool unlocked;
  final bool current;
  final int stars;
  final ValueChanged<Offset>? onTap;

  const _LevelPositionedButton({
    required this.level,
    required this.point,
    required this.unitColor,
    required this.unlocked,
    required this.current,
    required this.stars,
    required this.onTap,
  });

  @override
  State<_LevelPositionedButton> createState() => _LevelPositionedButtonState();
}

class _LevelPositionedButtonState extends State<_LevelPositionedButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.current ? 104.0 : 92.0;
    const starClusterHeight = 50.0;
    const starNodeGap = 1.0;
    final nodeColor = widget.unlocked
        ? widget.unitColor
        : const Color(0xFFD6BA8C);
    final borderColor = widget.unlocked
        ? Colors.white.withValues(alpha: .78)
        : const Color(0xFFE7D2B0);
    final lockedIconColor = const Color(0xFF9A7B50);

    return Positioned(
      left: widget.point.dx - size / 2,
      top: widget.point.dy - size / 2 - starClusterHeight - starNodeGap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FloatingStarCluster(stars: widget.stars),
          const SizedBox(height: 1),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(size / 2),
            child: Builder(
              builder: (buttonContext) {
                return InkWell(
                  borderRadius: BorderRadius.circular(size / 2),
                  onTap: widget.onTap == null
                      ? null
                      : () {
                          final box =
                              buttonContext.findRenderObject() as RenderBox;
                          final center = box.localToGlobal(
                            box.size.center(Offset.zero),
                          );
                          widget.onTap!(center);
                        },
                  onTapDown: widget.onTap == null
                      ? null
                      : (_) => setState(() => _pressed = true),
                  onTapCancel: widget.onTap == null
                      ? null
                      : () => setState(() => _pressed = false),
                  onTapUp: widget.onTap == null
                      ? null
                      : (_) => setState(() => _pressed = false),
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) {
                      final glow = widget.current ? _pulse.value : 0.0;
                      return AnimatedScale(
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        scale: _pressed ? .94 : 1,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (widget.unlocked)
                              Container(
                                width: size + 24 + glow * 8,
                                height: size + 24 + glow * 8,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .36),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    if (widget.current)
                                      BoxShadow(
                                        color: widget.unitColor.withValues(
                                          alpha: .22 + glow * .12,
                                        ),
                                        blurRadius: 24 + glow * 18,
                                        spreadRadius: 4 + glow * 6,
                                      ),
                                  ],
                                ),
                              ),
                            Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                color: nodeColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: borderColor,
                                  width: 5,
                                ),
                                boxShadow: [
                                  if (widget.current)
                                    BoxShadow(
                                      color: Colors.white.withValues(
                                        alpha: .70,
                                      ),
                                      blurRadius: 22,
                                      spreadRadius: 7,
                                    ),
                                  BoxShadow(
                                    color: TudloColors.forest.withValues(
                                      alpha: widget.unlocked ? .24 : .18,
                                    ),
                                    blurRadius: widget.unlocked ? 16 : 10,
                                    offset: const Offset(0, 9),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  if (widget.unlocked)
                                    Positioned(
                                      right: 13,
                                      top: 10,
                                      child: Container(
                                        width: 24,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: .40,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  Center(
                                    child: widget.unlocked
                                        ? Text(
                                            '${_localLevelNumber(widget.level)}',
                                            style: GoogleFonts.nunito(
                                              color: Colors.white,
                                              fontSize: widget.current
                                                  ? 36
                                                  : 31,
                                              height: 1,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          )
                                        : Icon(
                                            Icons.lock_rounded,
                                            color: lockedIconColor,
                                            size: widget.current ? 42 : 37,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

int _localLevelNumber(int globalLevel) {
  return ((globalLevel - 1) % 5) + 1;
}

class _FloatingStarCluster extends StatefulWidget {
  final int stars;

  const _FloatingStarCluster({required this.stars});

  @override
  State<_FloatingStarCluster> createState() => _FloatingStarClusterState();
}

class _FloatingStarClusterState extends State<_FloatingStarCluster>
    with SingleTickerProviderStateMixin {
  static const _mainYellow = Color(0xFFFFD700);
  static const _highlightYellow = Color(0xFFFFF176);
  late final AnimationController _controller;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _float = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      height: 50,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildStar(
            index: 0,
            left: 14,
            top: 18,
            size: 31,
            rotationDegrees: -12,
          ),
          _buildStar(index: 1, left: 43, top: 0, size: 38, rotationDegrees: 4),
          _buildStar(
            index: 2,
            left: 76,
            top: 18,
            size: 31,
            rotationDegrees: 12,
          ),
        ],
      ),
    );
  }

  Widget _buildStar({
    required int index,
    required double left,
    required double top,
    required double size,
    required double rotationDegrees,
  }) {
    final earned = index < widget.stars;
    final color = earned ? _mainYellow : Colors.white.withValues(alpha: .72);
    final highlightColor = earned
        ? _highlightYellow
        : Colors.white.withValues(alpha: .88);

    return Positioned(
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: _float,
        builder: (context, child) {
          final offset = earned
              ? math.sin((_float.value * math.pi * 2) + index) * 2.5
              : 0.0;
          final sparkleOpacity = earned ? .20 + (_float.value * .22) : 0.0;
          return Transform.translate(
            offset: Offset(0, offset),
            child: Transform.rotate(
              angle:
                  (rotationDegrees +
                      (earned ? math.sin(_float.value * math.pi * 2) * 2 : 0)) *
                  math.pi /
                  180,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (earned)
                    Positioned(
                      right: -4,
                      top: -2,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 10,
                        color: _highlightYellow.withValues(
                          alpha: sparkleOpacity,
                        ),
                      ),
                    ),
                  Icon(
                    Icons.star_rounded,
                    size: size + 8,
                    color: Colors.black.withValues(alpha: .20),
                  ),
                  Icon(
                    Icons.star_rounded,
                    size: size + 5,
                    color: earned
                        ? _mainYellow.withValues(alpha: .35)
                        : Colors.black.withValues(alpha: .08),
                    shadows: earned
                        ? [
                            Shadow(
                              color: _mainYellow.withValues(alpha: .78),
                              blurRadius: 22,
                            ),
                            Shadow(
                              color: Colors.black.withValues(alpha: .18),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [
                            Shadow(
                              color: Colors.black.withValues(alpha: .12),
                              blurRadius: 5,
                            ),
                          ],
                  ),
                  Icon(
                    Icons.star_rounded,
                    size: size + 2,
                    color: const Color(
                      0xFF6B6B6B,
                    ).withValues(alpha: earned ? .34 : .20),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [highlightColor, color],
                      ).createShader(bounds);
                    },
                    child: Icon(
                      Icons.star_rounded,
                      size: size,
                      color: Colors.white,
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

class _RoadGeometry {
  final double width;
  final double topPad;
  final double levelGap;
  final double unitMessageGap;

  const _RoadGeometry({
    required this.width,
    required this.topPad,
    required this.levelGap,
    required this.unitMessageGap,
  });

  Offset pointForLevel(int level) {
    final y =
        topPad + (level - 1) * levelGap + ((level - 1) ~/ 5) * unitMessageGap;
    return Offset(xForLevel(level.toDouble()), y);
  }

  Offset pointForUnitStart(int level) {
    final levelPoint = pointForLevel(level);
    final offset = level == 1 ? 166.0 : 226.0;
    return Offset(levelPoint.dx, levelPoint.dy - offset);
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
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final previous = i == 0 ? points[i] : points[i - 1];
      final current = points[i];
      final next = points[i + 1];
      final afterNext = i + 2 < points.length ? points[i + 2] : next;

      final control1 = current + (next - previous) / 6;
      final control2 = next - (afterNext - current) / 6;
      path.cubicTo(
        control1.dx,
        control1.dy,
        control2.dx,
        control2.dy,
        next.dx,
        next.dy,
      );
    }
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
