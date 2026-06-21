import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/data/lesson_bank/grade_lesson_dataset.dart';

const grade2LessonDataset = GradeLessonDataset(
  gradeLevel: GradeLevel.grade2,
  maxTermGrade: 2,
  storyTemplate:
      'Use {unitTitle} in a story-based lesson. Listen for {focusWords}, then think about how each word helps name a person, place, thing, animal, or event.',
  lessonTemplate:
      'Practice the meaning and sentence pattern together. Read the examples first, then answer each quiz item by checking the concept, translation, and word order.',
);
