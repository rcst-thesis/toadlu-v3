import 'package:flutter_test/flutter_test.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank.dart';

void main() {
  test('unit 1 level 1 generates a complete playable lesson', () {
    final questions = LessonBank.questionsForLevel(1);
    final counts = <QuestionType, int>{};
    for (final question in questions) {
      counts[question.type] = (counts[question.type] ?? 0) + 1;
    }

    expect(questions, hasLength(AppData.questionsPerUnit));
    expect(counts[QuestionType.translationChoice], 3);
    expect(counts[QuestionType.typedTranslation], 3);
    expect(counts[QuestionType.arrangeWords], 3);
    expect(counts[QuestionType.matching], 2);
    expect(counts[QuestionType.fillBlank], 2);
    expect(counts[QuestionType.imageChoice], 2);
  });
}
