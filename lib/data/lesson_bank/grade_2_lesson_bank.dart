import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/data/lesson_bank/grade_lesson_dataset.dart';

const grade2LessonDataset = GradeLessonDataset(
  gradeLevel: GradeLevel.grade2,
  maxTermGrade: 2,
  storyTemplate:
      'Practice {unitTitle}. Notice how the words {focusWords} can help you answer, ask, and join simple conversations.',
  lessonTemplate:
      'Connect each phrase to its meaning, then watch the word order. Some quiz items ask you to choose, match, arrange, or complete a sentence.',
);
