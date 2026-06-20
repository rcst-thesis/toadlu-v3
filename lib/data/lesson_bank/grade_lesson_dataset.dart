import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank_item.dart';

class GradeLessonDataset {
  final GradeLevel gradeLevel;
  final int maxTermGrade;
  final String storyTemplate;
  final String lessonTemplate;

  const GradeLessonDataset({
    required this.gradeLevel,
    required this.maxTermGrade,
    required this.storyTemplate,
    required this.lessonTemplate,
  });

  bool includes(LessonTerm term) => term.gradeLevel <= maxTermGrade;
}
