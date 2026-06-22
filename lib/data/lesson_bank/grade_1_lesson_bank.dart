import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/data/lesson_bank/grade_lesson_dataset.dart';

const grade1LessonDataset = GradeLessonDataset(
  gradeLevel: GradeLevel.grade1,
  maxTermGrade: 2,
  storyTemplate:
      'You are learning {unitTitle}. Look, listen, and say the words {focusWords}. These are short words and phrases you can use right away.',
  lessonTemplate:
      'Read one Hiligaynon word or phrase at a time. Match it with the English meaning, then try the quiz slowly and carefully.',
);
