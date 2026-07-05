import 'package:tudloapp/core/models/grade_level.dart';

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

/// Source-aligned lesson record for textbook-style content.
///
/// These records preserve the extracted lesson sections so they can be moved
/// into JSON, CSV, a database, or a richer lesson player without losing source
/// text that does not fit the quiz-oriented [LessonTerm] model.
class GradeLessonSource {
  final String unitTitle;
  final int lessonNumber;
  final String lessonTitle;
  final List<String> katuyuan;
  final List<String> nakahibaloKaSini;
  final List<String> pasanyugaIni;
  final List<String> pamatiITulukaBasaha;
  final List<String> readingText;
  final List<String> istoryahanNaton;
  final List<String> paminsaraIni;
  final List<String> masaranganKoIni;
  final List<GradeLessonActivity> activities;
  final String sourceNote;

  const GradeLessonSource({
    required this.unitTitle,
    required this.lessonNumber,
    required this.lessonTitle,
    this.katuyuan = const ['[not provided]'],
    this.nakahibaloKaSini = const ['[not provided]'],
    this.pasanyugaIni = const ['[not provided]'],
    this.pamatiITulukaBasaha = const ['[not provided]'],
    this.readingText = const ['[not provided]'],
    this.istoryahanNaton = const ['[not provided]'],
    this.paminsaraIni = const ['[not provided]'],
    this.masaranganKoIni = const ['[not provided]'],
    this.activities = const [],
    this.sourceNote = '',
  });
}

class GradeLessonActivity {
  final String activityType;
  final List<String> questions;
  final List<String> choices;
  final String correctAnswer;
  final String imageDescription;
  final List<String> updatedAssetPhotoFilenames;
  final String audioVoiceTextScript;

  const GradeLessonActivity({
    required this.activityType,
    this.questions = const ['[not provided]'],
    this.choices = const ['[not provided]'],
    this.correctAnswer = '[not provided]',
    this.imageDescription = '[not provided]',
    this.updatedAssetPhotoFilenames = const ['[not provided]'],
    this.audioVoiceTextScript = '[not provided]',
  });
}

enum QuestionType {
  translationChoice,
  arrangeWords,
  fillBlank,
  choice,
  matching,
  completeSentence,
  buildSentence,
  imageChoice,
}

/// Data model used by both map lessons and tests.
///
/// The named constructors keep each question type explicit while still letting
/// the UI render all questions through one model.
class LessonQuestion {
  final QuestionType type;
  final String prompt;
  final String answer;
  final List<String> choices;
  final List<String> leftItems;
  final List<String> rightItems;
  final List<String> sentenceWords;
  final List<LessonTerm> imageChoices;
  final String imagePath;
  final String sentenceMeaning;
  final Map<String, String> wordMeanings;
  final String targetPhrase;
  final String targetMeaning;
  final String directionLabel;

  const LessonQuestion.choice({
    required this.prompt,
    required this.answer,
    required this.choices,
    this.imagePath = '',
    this.sentenceMeaning = '',
    this.wordMeanings = const {},
    this.targetPhrase = '',
    this.targetMeaning = '',
    this.directionLabel = '',
  }) : type = QuestionType.choice,
       leftItems = const [],
       rightItems = const [],
       sentenceWords = const [],
       imageChoices = const [];

  const LessonQuestion.translationChoice({
    required this.prompt,
    required this.answer,
    required this.choices,
    this.imagePath = '',
    this.sentenceMeaning = '',
    this.wordMeanings = const {},
    this.targetPhrase = '',
    this.targetMeaning = '',
    this.directionLabel = '',
  }) : type = QuestionType.translationChoice,
       leftItems = const [],
       rightItems = const [],
       sentenceWords = const [],
       imageChoices = const [];

  const LessonQuestion.fillBlank({
    required this.prompt,
    required this.answer,
    required this.choices,
    this.imagePath = '',
    this.sentenceMeaning = '',
    this.wordMeanings = const {},
    this.targetPhrase = '',
    this.targetMeaning = '',
    this.directionLabel = '',
  }) : type = QuestionType.fillBlank,
       leftItems = const [],
       rightItems = const [],
       sentenceWords = const [],
       imageChoices = const [];

  const LessonQuestion.matching({
    required this.prompt,
    required this.leftItems,
    required this.rightItems,
    this.targetPhrase = '',
    this.targetMeaning = '',
    this.directionLabel = '',
  }) : type = QuestionType.matching,
       answer = '',
       choices = const [],
       sentenceWords = const [],
       imageChoices = const [],
       imagePath = '',
       sentenceMeaning = '',
       wordMeanings = const {};

  const LessonQuestion.completeSentence({
    required this.prompt,
    required this.answer,
    required this.choices,
    this.imagePath = '',
    this.sentenceMeaning = '',
    this.wordMeanings = const {},
    this.targetPhrase = '',
    this.targetMeaning = '',
    this.directionLabel = '',
  }) : type = QuestionType.completeSentence,
       leftItems = const [],
       rightItems = const [],
       sentenceWords = const [],
       imageChoices = const [];

  const LessonQuestion.buildSentence({
    required this.prompt,
    required this.answer,
    required this.sentenceWords,
    this.imagePath = '',
    this.sentenceMeaning = '',
    this.wordMeanings = const {},
    this.targetPhrase = '',
    this.targetMeaning = '',
    this.directionLabel = '',
  }) : type = QuestionType.buildSentence,
       choices = const [],
       leftItems = const [],
       rightItems = const [],
       imageChoices = const [];

  const LessonQuestion.arrangeWords({
    required this.prompt,
    required this.answer,
    required this.sentenceWords,
    this.imagePath = '',
    this.sentenceMeaning = '',
    this.wordMeanings = const {},
    this.targetPhrase = '',
    this.targetMeaning = '',
    this.directionLabel = '',
  }) : type = QuestionType.arrangeWords,
       choices = const [],
       leftItems = const [],
       rightItems = const [],
       imageChoices = const [];

  const LessonQuestion.imageChoice({
    required this.prompt,
    required this.answer,
    required this.imageChoices,
    this.imagePath = '',
    this.sentenceMeaning = '',
    this.wordMeanings = const {},
    this.targetPhrase = '',
    this.targetMeaning = '',
    this.directionLabel = '',
  }) : type = QuestionType.imageChoice,
       choices = const [],
       leftItems = const [],
       rightItems = const [],
       sentenceWords = const [];
}

class LessonExample {
  final String category;
  final String hiligaynon;
  final String english;
  final String note;
  final String? imageAsset;
  final String? audioAsset;

  const LessonExample({
    this.category = '',
    required this.hiligaynon,
    required this.english,
    this.note = '',
    this.imageAsset,
    this.audioAsset,
  });
}

class LessonConceptCard {
  final String title;
  final String hiligaynon;
  final String english;

  const LessonConceptCard({
    required this.title,
    required this.hiligaynon,
    required this.english,
  });
}

class LevelContent {
  final String id;
  final int gradeLevel;
  final int unitNumber;
  final int lessonNumber;
  final String title;
  final String? storyTitle;
  final String? story;
  final String lesson;
  final List<LessonExample> examples;
  final List<QuizItem> quizItems;
  final String? storyImageAsset;

  const LevelContent({
    required this.id,
    required this.gradeLevel,
    required this.unitNumber,
    required this.lessonNumber,
    required this.title,
    this.storyTitle,
    this.story,
    required this.lesson,
    required this.examples,
    required this.quizItems,
    this.storyImageAsset,
  });
}

enum QuizType {
  multipleChoice,
  pictureChoice,
  matching,
  arrangeWords,
  fillBlankChoice,
  listenAndChoose,
  tapCorrectWord,
}

class QuizItem {
  final String id;
  final QuizType type;
  final String question;
  final List<String> choices;
  final String answer;
  final String? audioAsset;
  final String? imageAsset;
  final List<String> leftItems;
  final List<String> rightItems;
  final Map<String, String> matchingPairs;

  const QuizItem({
    required this.id,
    required this.type,
    required this.question,
    required this.choices,
    required this.answer,
    this.audioAsset,
    this.imageAsset,
    this.leftItems = const [],
    this.rightItems = const [],
    this.matchingPairs = const {},
  });
}

class LessonLevelContent {
  final String title;
  final String storyTitle;
  final String story;
  final String shortLesson;
  final List<LessonConceptCard> concepts;
  final List<LessonExample> examples;

  const LessonLevelContent({
    required this.title,
    required this.storyTitle,
    required this.story,
    required this.shortLesson,
    this.concepts = const [],
    required this.examples,
  });
}

/// High-level content type for lesson bank entries.
///
/// LessonBank can hold words, phrases, and full sentences because it powers
/// games, map previews, and tests.
enum LessonContentType { word, phrase, sentence }

/// One unit-based lesson item used by lessons, previews, and tests.
///
/// Dictionary lookup uses DictionaryData instead of this lesson dataset.
class LessonTerm {
  final int unitNumber;
  final String unitTitle;
  final int gradeLevel;
  final LessonContentType? type;
  final String hil;
  final String eng;
  final String? pronunciation;
  final String? exampleSentenceHiligaynon;
  final String? exampleSentenceEnglish;
  final String? missingSentence;
  final String? missingAnswer;
  final List<String> choices;
  final List<String> wordBlocks;
  final String? imagePath;
  final String? audioPath;
  final Map<String, String> wordMeanings;
  final int? lessonNumber;

  const LessonTerm({
    required this.unitNumber,
    required this.unitTitle,
    required this.gradeLevel,
    this.type,
    required this.hil,
    required this.eng,
    this.pronunciation,
    this.exampleSentenceHiligaynon,
    this.exampleSentenceEnglish,
    this.missingSentence,
    this.missingAnswer,
    this.choices = const [],
    this.wordBlocks = const [],
    this.imagePath,
    this.audioPath,
    this.wordMeanings = const {},
    this.lessonNumber,
  });

  String get hiligaynonSentence => hil;
  String get englishSentence => eng;
}
