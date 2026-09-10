import 'package:flutter/material.dart';

import 'package:tudlo/features/home/presentation/widgets/home_lesson_panel.dart';

Future<void> showHomeLessonPreviewDialog({
  required BuildContext context,
  required HomeLessonPreview lesson,
  required VoidCallback onStart,
  required VoidCallback onBrowseLessons,
  required VoidCallback onSetGoal,
}) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close lesson preview',
    barrierColor: const Color(0xCC000000),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, _, __) => SafeArea(
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 18,
            child: Center(
              child: _HomeLessonPreviewDialog(
                lesson: lesson,
                onStart: onStart,
                onBrowseLessons: onBrowseLessons,
                onSetGoal: onSetGoal,
              ),
            ),
          ),
        ],
      ),
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: ScaleTransition(
          scale: Tween<double>(begin: .96, end: 1).animate(curve),
          child: child,
        ),
      );
    },
  );
}

class _HomeLessonPreviewDialog extends StatelessWidget {
  const _HomeLessonPreviewDialog({
    required this.lesson,
    required this.onStart,
    required this.onBrowseLessons,
    required this.onSetGoal,
  });

  final HomeLessonPreview lesson;
  final VoidCallback onStart;
  final VoidCallback onBrowseLessons;
  final VoidCallback onSetGoal;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = (screenWidth - 80).clamp(260.0, 320.0).toDouble();
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    offset: Offset(0, 9),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: SizedBox(
                height: 124,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 8, 12, 9),
                  child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            '10',
                            style: TextStyle(
                              color: Color(0xFF6C7176),
                              fontFamily: 'ComicRelief',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(Icons.bolt_rounded,
                              color: Color(0xFFF6B917), size: 18),
                        ],
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/home_lesson_category.png',
                            width: 36,
                            height: 36,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            lesson.unitTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF151515),
                              fontFamily: 'ComicRelief',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'lesson mo subong nga adlaw',
                            style: const TextStyle(
                              color: Color(0xFF55575A),
                              fontFamily: 'ComicRelief',
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                        ),
                      ),
                    ),
                  ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _LessonPreviewAction(
                  icon: Icons.flag_rounded,
                  label: 'goal',
                  color: const Color(0xFFEF7855),
                  size: 44,
                  emoji: '🎯',
                  showSurface: false,
                  verticalOffset: 8,
                  onTap: onSetGoal,
                ),
                _LessonPreviewAction(
                  icon: Icons.play_arrow_rounded,
                  label: 'sugodan ta',
                  color: const Color(0xFF68B84D),
                  size: 56,
                  width: 66,
                  emoji: '▶',
                  showSurface: true,
                  verticalOffset: 0,
                  onTap: onStart,
                ),
                _LessonPreviewAction(
                  icon: Icons.menu_book_rounded,
                  label: 'silawon ta',
                  color: const Color(0xFF55A7D0),
                  size: 44,
                  emoji: '📚',
                  showSurface: false,
                  verticalOffset: 8,
                  onTap: onBrowseLessons,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Semantics(
              button: true,
              label: 'Close lesson preview',
              child: InkResponse(
                key: const Key('home-lesson-preview-close'),
                onTap: () => Navigator.of(context).pop(),
                radius: 28,
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Center(
                    child: CircleAvatar(
                      radius: 11,
                      backgroundColor: Color(0xFF5A5D60),
                      child: Text(
                        '✖️',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1,
                        ),
                      ),
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

class _LessonPreviewAction extends StatelessWidget {
  const _LessonPreviewAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.size,
    this.width,
    this.emoji,
    required this.showSurface,
    required this.verticalOffset,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double size;
  final double? width;
  final String? emoji;
  final bool showSurface;
  final double verticalOffset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, verticalOffset),
      child: Column(
        children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          child: InkResponse(
            onTap: onTap,
            radius: size / 2,
            child: SizedBox(
              width: width ?? size,
              height: size,
              child: showSurface
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFFB7B7B7),
                            offset: Offset(0, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: emoji == null
                          ? Icon(icon, color: color, size: size * .53)
                          : Center(
                              child: Text(
                                emoji!,
                                style: TextStyle(
                                  color: color,
                                  fontSize: size * .48,
                                ),
                              ),
                            ),
                    )
                  : Center(
                      child: Text(
                        emoji ?? '',
                        style: TextStyle(fontSize: size * .72),
                      ),
                    ),
            ),
          ),
        ),
          const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'ComicRelief',
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        ],
      ),
    );
  }
}
