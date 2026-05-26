/// High-level content type for lesson bank entries.
///
/// LessonBank can hold words, phrases, and full sentences because it powers
/// games, map previews, tests, and evaluation activities.
enum LessonContentType { word, phrase, sentence }

/// One unit-based lesson item used by lessons, previews, and tests.
///
/// Dictionary lookup uses DictionaryData instead of this lesson dataset.
class LessonTerm {
  final int unitNumber;
  final String unitTitle;
  final int difficulty;
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
    required this.difficulty,
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
