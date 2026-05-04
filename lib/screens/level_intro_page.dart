import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../lesson_bank.dart';
import 'level_game_page.dart';

class LevelIntroPage extends StatelessWidget {
  final int level;

  const LevelIntroPage({super.key, required this.level});

  void _start(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LevelGamePage(level: level)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final difficulty = ((level - 1) ~/ 10) + 1;

    return Scaffold(
      body: TudloPageBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _start(context),
              child: TudloCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Level $level',
                      style: const TextStyle(
                        color: TudloColors.ink,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '10 questions - Difficulty $difficulty/5',
                      style: const TextStyle(
                        color: TudloColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _ExercisePreview(level: level),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _start(context),
                        child: const Text('Play'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExercisePreview extends StatelessWidget {
  final int level;

  const _ExercisePreview({required this.level});

  @override
  Widget build(BuildContext context) {
    final types = LessonBank.questionsForLevel(
      level,
    ).map((q) => q.type).toSet();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: types.map((type) {
        final label = switch (type) {
          QuestionType.choice => 'Choice',
          QuestionType.matching => 'Matching',
          QuestionType.completeSentence => 'Complete',
          QuestionType.buildSentence => 'Build',
        };
        return Chip(
          label: Text(label),
          backgroundColor: TudloColors.sky.withValues(alpha: .12),
          labelStyle: const TextStyle(
            color: TudloColors.ink,
            fontWeight: FontWeight.w800,
          ),
          side: BorderSide.none,
        );
      }).toList(),
    );
  }
}
