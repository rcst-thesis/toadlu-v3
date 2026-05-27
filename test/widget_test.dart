import 'package:flutter_test/flutter_test.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank.dart';

void main() {
  test('every level generates the required playable lesson mix', () {
    // This test protects the lesson generator for all units and levels.
    // If any level loses the required question mix, this tells developers
    // which level and question type no longer matches the lesson plan.
    for (var level = 1; level <= AppData.maxLevel; level++) {
      final questions = LessonBank.questionsForLevel(level);

      // Count every generated question by type so the expectations below can
      // confirm that each lesson has the required mix of activities.
      final counts = <QuestionType, int>{};
      for (final question in questions) {
        counts[question.type] = (counts[question.type] ?? 0) + 1;
      }
      final fillBlankPrompts = questions
          .where((question) => question.type == QuestionType.fillBlank)
          .map((question) => '${question.prompt} => ${question.answer}')
          .join(' | ');

      // Unit lessons should always match the app-wide question count.
      expect(
        questions,
        hasLength(AppData.questionsPerUnit),
        reason:
            'Level $level should have ${AppData.questionsPerUnit} questions. '
            'Generated counts: $counts. Fill blanks: $fillBlankPrompts',
      );

      expect(
        counts[QuestionType.translationChoice],
        4,
        reason: 'Level $level translationChoice count',
      );
      expect(
        counts[QuestionType.typedTranslation],
        2,
        reason: 'Level $level typedTranslation count',
      );
      expect(
        counts[QuestionType.arrangeWords],
        2,
        reason: 'Level $level arrangeWords count',
      );
      expect(
        counts[QuestionType.matching],
        2,
        reason: 'Level $level matching count',
      );
      expect(
        counts[QuestionType.fillBlank],
        3,
        reason: 'Level $level fillBlank count',
      );
      expect(
        counts[QuestionType.imageChoice],
        2,
        reason: 'Level $level imageChoice count',
      );
    }
  });

  test('unit 1 level 1 questions do not leak into other levels', () {
    // Unit 1 Level 1 is a fixed showcase lesson. Later levels should not reuse
    // its exact generated questions, even when they need fallback content.
    final showcaseKeys = LessonBank.questionsForLevel(
      1,
    ).map(_questionKey).toSet();

    for (var level = 2; level <= AppData.maxLevel; level++) {
      for (final question in LessonBank.questionsForLevel(level)) {
        final key = _questionKey(question);
        expect(
          showcaseKeys.contains(key),
          isFalse,
          reason: 'Level $level reused a Unit 1 Level 1 question: $key',
        );
      }
    }
  });
}

String _questionKey(LessonQuestion question) {
  return [
    question.type.name,
    question.prompt.trim().toLowerCase(),
    question.answer.trim().toLowerCase(),
    question.leftItems.join('|').toLowerCase(),
    question.imageChoices.map((term) => term.hil).join('|').toLowerCase(),
  ].join('::');
}
