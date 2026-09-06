import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tudlo/core/navigation/fade_page_route.dart';
import 'package:tudlo/core/theme/app_colors.dart';
import 'package:tudlo/features/onboarding/presentation/screens/energy_setter_screen.dart';
import 'package:tudlo/shared/widgets/design_navigation_button.dart';

class GradeSelectionScreen extends StatefulWidget {
  const GradeSelectionScreen({
    required this.learnerName,
    this.introVoiceOverPlayer,
    this.gradeVoiceOverPlayer,
    super.key,
  });

  final String learnerName;
  final Future<void> Function()? introVoiceOverPlayer;
  final Future<void> Function(int grade)? gradeVoiceOverPlayer;

  @override
  State<GradeSelectionScreen> createState() => _GradeSelectionScreenState();
}

class _GradeSelectionScreenState extends State<GradeSelectionScreen> {
  static const _grades = <_GradeChoice>[
    _GradeChoice(
      number: 1,
      word: 'one',
      panel: Color(0xFF98EF6F),
      front: Color(0xFF42A32E),
      back: Color(0xFF417836),
      accent: Color(0xFF4E9F3E),
      buttonBack: Color(0xFF2C6121),
      image: 'assets/images/koka_green.png',
      headerImage: 'assets/images/grade_1_header.png',
    ),
    _GradeChoice(
      number: 2,
      word: 'two',
      panel: Color(0xFF6FB1EF),
      front: Color(0xFF235B8F),
      back: Color(0xFF214668),
      accent: Color(0xFF3E779F),
      buttonBack: Color(0xFF214661),
      image: 'assets/images/koka_blue.png',
      headerImage: 'assets/images/grade_2_header.png',
    ),
    _GradeChoice(
      number: 3,
      word: 'three',
      panel: Color(0xFFEF6F6F),
      front: Color(0xFF8F2323),
      back: Color(0xFF682121),
      accent: Color(0xFF9F3E3E),
      buttonBack: Color(0xFF612121),
      image: 'assets/images/koka_red.png',
      headerImage: 'assets/images/grade_3_header.png',
    ),
  ];

  int _selectedIndex = 0;
  bool _voiceOverPlaying = false;

  Future<void> _playVoiceOver(Future<void> Function()? player) async {
    if (_voiceOverPlaying) return;
    if (player == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('VO audio file is not installed yet')),
      );
      return;
    }
    setState(() => _voiceOverPlaying = true);
    try {
      await player();
    } finally {
      if (mounted) setState(() => _voiceOverPlaying = false);
    }
  }

  void _rotate(int direction) {
    setState(() {
      _selectedIndex = (_selectedIndex + direction) % _grades.length;
      if (_selectedIndex < 0) _selectedIndex += _grades.length;
    });
  }

  void _continue() {
    Navigator.of(context).push(
      FadePageRoute<void>(
        page: EnergySetterScreen(
          learnerName: widget.learnerName,
          grade: _grades[_selectedIndex].number,
        ),
      ),
    );
  }

  _CarouselSlot _slotFor(int gradeIndex) {
    if (gradeIndex == _selectedIndex) return _CarouselSlot.center;
    final next = (_selectedIndex + 1) % _grades.length;
    return gradeIndex == next ? _CarouselSlot.right : _CarouselSlot.left;
  }

  @override
  Widget build(BuildContext context) {
    final sideCards = <int>[
      for (var index = 0; index < _grades.length; index++)
        if (index != _selectedIndex) index,
    ];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.mint,
              child: SafeArea(
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      key: const Key('grade-selection-canvas'),
                      width: 412,
                      height: 917,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Positioned(
                            left: 38,
                            top: 125,
                            width: 336,
                            child: Text(
                              'gusto ni koka ma bal an\n'
                              'sa ano nga grade kana subong',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 22,
                                height: 1.35,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 29,
                            top: 200,
                            width: 352,
                            height: 79,
                            child: CustomPaint(
                              key: const Key('grade-intro-bubble'),
                              painter: const _BubblePainter(
                                tailCenter: 87,
                                bodyHeight: 71,
                              ),
                              child: Stack(
                                children: [
                                  const Positioned(
                                    left: 44,
                                    top: 18,
                                    width: 236,
                                    child: Text(
                                      'nice to meet you, ano na imo nga\n'
                                      'grade subong?',
                                      maxLines: 2,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        height: 1.35,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 12,
                                    top: 12,
                                    child: _GradeVoiceButton(
                                      key:
                                          const Key('grade-intro-voice-button'),
                                      size: 48,
                                      iconSize: 24,
                                      playing: _voiceOverPlaying,
                                      onPressed: () => _playVoiceOver(
                                        widget.introVoiceOverPlayer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 166,
                            top: 254,
                            width: 215,
                            height: 61,
                            child: CustomPaint(
                              key: const Key('grade-selection-bubble'),
                              painter: const _BubblePainter(
                                tailCenter: 153,
                                bodyHeight: 53,
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 29,
                                    top: 15,
                                    width: 151,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 250),
                                        child: Text(
                                          key: ValueKey(_selectedIndex),
                                          'Grade ${_grades[_selectedIndex].word} '
                                          'kana subong?',
                                          maxLines: 1,
                                          softWrap: false,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 5,
                                    top: 7,
                                    child: _GradeVoiceButton(
                                      key: const Key(
                                          'grade-selection-voice-button'),
                                      size: 40,
                                      iconSize: 16,
                                      playing: _voiceOverPlaying,
                                      onPressed: () {
                                        final grade =
                                            _grades[_selectedIndex].number;
                                        _playVoiceOver(
                                          widget.gradeVoiceOverPlayer == null
                                              ? null
                                              : () =>
                                                  widget.gradeVoiceOverPlayer!(
                                                    grade,
                                                  ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Positioned(
                            left: 175,
                            top: 400,
                            width: 64,
                            height: 18,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color(0x706B6B6B),
                                borderRadius:
                                    BorderRadius.all(Radius.elliptical(32, 9)),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 167,
                            top: 309,
                            width: 78,
                            height: 108,
                            child: Image.asset(
                              'assets/images/name_character.png',
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                          for (final index in sideCards)
                            _AnimatedGradeCard(
                              key: ValueKey('grade-card-${index + 1}'),
                              grade: _grades[index],
                              slot: _slotFor(index),
                              selected: false,
                              onSelected: null,
                            ),
                          _AnimatedGradeCard(
                            key: ValueKey('grade-card-${_selectedIndex + 1}'),
                            grade: _grades[_selectedIndex],
                            slot: _CarouselSlot.center,
                            selected: true,
                            onSelected: _continue,
                          ),
                          Positioned(
                            left: 46,
                            top: 800,
                            child: _ArrowButton(
                              key: const Key('grade-previous-button'),
                              direction: _ArrowDirection.left,
                              onPressed: () => _rotate(-1),
                            ),
                          ),
                          Positioned(
                            left: 224,
                            top: 800,
                            child: _ArrowButton(
                              key: const Key('grade-next-button'),
                              direction: _ArrowDirection.right,
                              onPressed: () => _rotate(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: AdaptiveBackButtonPlacement(
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

enum _CarouselSlot { left, center, right }

class _AnimatedGradeCard extends StatelessWidget {
  const _AnimatedGradeCard({
    required this.grade,
    required this.slot,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final _GradeChoice grade;
  final _CarouselSlot slot;
  final bool selected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final left = switch (slot) {
      _CarouselSlot.left => 24.0,
      _CarouselSlot.center => 92.0,
      _CarouselSlot.right => 208.0,
    };
    final top = slot == _CarouselSlot.center ? 468.0 : 460.0;
    final width = slot == _CarouselSlot.center ? 228.0 : 180.0;
    final height = slot == _CarouselSlot.center ? 311.57 : 249.0;
    final turn = switch (slot) {
      _CarouselSlot.left => -0.018,
      _CarouselSlot.center => 0.0,
      _CarouselSlot.right => 0.018,
    };

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutCubic,
      left: left,
      top: top,
      width: width,
      height: height,
      child: AnimatedRotation(
        duration: const Duration(milliseconds: 460),
        curve: Curves.easeOutCubic,
        turns: turn,
        child: _GradeCard(
          grade: grade,
          selected: selected,
          onSelected: onSelected,
        ),
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({
    required this.grade,
    required this.selected,
    required this.onSelected,
  });

  final _GradeChoice grade;
  final bool selected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final scale = selected ? 1.0 : 180 / 228;
    return Semantics(
      selected: selected,
      label: 'Grade ${grade.number}${selected ? ', selected' : ''}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 460),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x80F6FF00),
                    offset: Offset(0, 4),
                    blurRadius: 30,
                    spreadRadius: 7,
                  ),
                ]
              : const [],
        ),
        child: Material(
          key: selected ? Key('grade-selected-card-${grade.number}') : null,
          color: grade.panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: Colors.black),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.all(selected ? 11 : 8),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: selected ? 38.4 : 30.75,
                  child: Image.asset(
                    grade.headerImage,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                    filterQuality: FilterQuality.high,
                    semanticLabel: 'Grade ${grade.number}',
                  ),
                ),
                SizedBox(height: selected ? 15 : 11),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        top: selected ? 6 : 5,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: grade.back,
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        bottom: selected ? 6 : 5,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: grade.front,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(selected ? 13 : 10),
                            child: Image.asset(
                              grade.image,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: selected ? 18 : 13),
                SizedBox(
                  height: selected ? 65 : 52,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        top: selected ? 7 : 6,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: grade.buttonBack,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        bottom: selected ? 7 : 6,
                        child: Material(
                          color: grade.accent,
                          borderRadius: BorderRadius.circular(8),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            key: Key('grade-${grade.number}-select-button'),
                            onTap: selected ? onSelected : null,
                            child: Center(
                              child: Text(
                                'grade ${grade.number} na ako',
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18 * scale,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
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

enum _ArrowDirection { left, right }

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.direction,
    required this.onPressed,
    super.key,
  });

  final _ArrowDirection direction;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      height: 73,
      child: Stack(
        children: [
          Positioned.fill(
            top: 7.25,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF2C6121),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned.fill(
            bottom: 7.25,
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: const Color(0xFF4E9F3E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Transform.rotate(
                angle: direction == _ArrowDirection.left ? math.pi : 0,
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeChoice {
  const _GradeChoice({
    required this.number,
    required this.word,
    required this.panel,
    required this.front,
    required this.back,
    required this.accent,
    required this.buttonBack,
    required this.image,
    required this.headerImage,
  });

  final int number;
  final String word;
  final Color panel;
  final Color front;
  final Color back;
  final Color accent;
  final Color buttonBack;
  final String image;
  final String headerImage;
}

class _GradeVoiceButton extends StatelessWidget {
  const _GradeVoiceButton({
    required this.size,
    required this.iconSize,
    required this.playing,
    required this.onPressed,
    super.key,
  });

  final double size;
  final double iconSize;
  final bool playing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: playing ? 'Voice-over playing' : 'Play voice-over',
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: playing ? null : onPressed,
          radius: size / 2,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: SizedBox(
                width: iconSize,
                height: iconSize,
                child: CustomPaint(
                  painter: _GradeSpeakerPainter(
                    color: playing ? AppColors.green : const Color(0xFF222222),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradeSpeakerPainter extends CustomPainter {
  const _GradeSpeakerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 24;
    final sy = size.height / 24;
    canvas.save();
    canvas.scale(sx, sy);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final speaker = Path()
      ..moveTo(3.158, 13.931)
      ..cubicTo(2.445, 12.742, 2.445, 11.258, 3.158, 10.069)
      ..cubicTo(3.376, 9.707, 3.736, 9.453, 4.151, 9.37)
      ..lineTo(5.844, 9.031)
      ..cubicTo(5.945, 9.011, 6.036, 8.957, 6.102, 8.878)
      ..lineTo(8.171, 6.395)
      ..cubicTo(9.353, 4.976, 9.945, 4.266, 10.472, 4.457)
      ..cubicTo(11, 4.648, 11, 5.572, 11, 7.419)
      ..lineTo(11, 16.581)
      ..cubicTo(11, 18.428, 11, 19.352, 10.472, 19.543)
      ..cubicTo(9.945, 19.734, 9.353, 19.024, 8.171, 17.605)
      ..lineTo(6.102, 15.122)
      ..cubicTo(6.036, 15.043, 5.945, 14.989, 5.844, 14.969)
      ..lineTo(4.151, 14.63)
      ..cubicTo(3.736, 14.547, 3.376, 14.293, 3.158, 13.931)
      ..close();
    canvas.drawPath(speaker, paint);

    canvas.drawPath(
      Path()
        ..moveTo(15.536, 8.464)
        ..cubicTo(16.468, 9.397, 16.995, 10.661, 17, 11.98)
        ..cubicTo(17.005, 13.3, 16.489, 14.567, 15.563, 15.508),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(19.657, 6.343)
        ..cubicTo(21.149, 7.836, 21.992, 9.858, 22, 11.969)
        ..cubicTo(22.008, 14.079, 21.182, 16.108, 19.701, 17.612),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GradeSpeakerPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter({
    required this.tailCenter,
    required this.bodyHeight,
  });

  final double tailCenter;
  final double bodyHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFEBEBEB);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, bodyHeight),
        const Radius.circular(21),
      ),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(tailCenter - 15, bodyHeight - 3)
        ..lineTo(tailCenter + 7, size.height)
        ..quadraticBezierTo(
            tailCenter + 15, size.height + 2, tailCenter + 11, bodyHeight - 3)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) =>
      oldDelegate.tailCenter != tailCenter ||
      oldDelegate.bodyHeight != bodyHeight;
}
