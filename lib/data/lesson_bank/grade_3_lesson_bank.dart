import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/data/lesson_bank/grade_lesson_dataset.dart';

const grade3LessonDataset = GradeLessonDataset(
  gradeLevel: GradeLevel.grade3,
  maxTermGrade: 3,
  storyTemplate:
      'Use {unitTitle} in a fuller conversation. Listen for {focusWords}, then think about how each phrase changes the meaning of the whole message.',
  lessonTemplate:
      'Practice the meaning and sentence pattern together. Use the examples first, then answer each quiz item by checking both translation and word order.',
);
