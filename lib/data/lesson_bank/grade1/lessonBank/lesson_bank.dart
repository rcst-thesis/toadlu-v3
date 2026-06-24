import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank_item.dart';
import 'units/unit1/leksyon1/dataset.dart';
import 'units/unit1/leksyon2/dataset.dart';
import 'units/unit1/leksyon3/dataset.dart';
import 'units/unit1/leksyon4/dataset.dart';
import 'units/unit1/leksyon5/dataset.dart';
export 'units/unit1/leksyon1/activities.dart';
export 'units/unit1/leksyon2/activities.dart';
export 'units/unit1/leksyon3/activities.dart';
export 'units/unit1/leksyon4/activities.dart';
export 'units/unit1/leksyon5/activities.dart';

const grade1LessonDataset = GradeLessonDataset(
  gradeLevel: GradeLevel.grade1,
  maxTermGrade: 1,
  storyTemplate:
      'You are learning {unitTitle}. Look, listen, and say the words {focusWords}. These are short words and phrases you can use right away.',
  lessonTemplate:
      'Read one Hiligaynon word or phrase at a time. Match it with the English meaning, then try the quiz slowly and carefully.',
);

const grade1Unit1SourceLessons = [
  grade1Unit1Leksyon1SourceLesson,
  grade1Unit1Leksyon2SourceLesson,
  grade1Unit1Leksyon3SourceLesson,
  grade1Unit1Leksyon4SourceLesson,
  grade1Unit1Leksyon5SourceLesson,
];

const List<LessonTerm> grade1LessonTerms = [
  ...grade1Unit1Leksyon1Terms,
  ...grade1Unit1Leksyon2Terms,
  ...grade1Unit1Leksyon3Terms,
  ...grade1Unit1Leksyon4Terms,
  ...grade1Unit1Leksyon5Terms,
];
