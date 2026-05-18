enum QuestionType { choice, matching, completeSentence, buildSentence }

/// Data model used by both map lessons and tests.
///
/// The named constructors keep each question type explicit while still letting
/// the UI render all questions through one model.
/// 
/// might change the whole code since it should be randomized based on the difficulty
class LessonQuestion {
  final QuestionType type;
  final String prompt;
  final String answer;
  final List<String> choices;
  final List<String> leftItems;
  final List<String> rightItems;
  final List<String> sentenceWords;
  final String targetPhrase;
  final String targetMeaning;
  final String directionLabel;

  const LessonQuestion.choice({
    required this.prompt,
    required this.answer,
    required this.choices,
    this.targetPhrase = '',
    this.targetMeaning = '',
    this.directionLabel = '',
  }) : type = QuestionType.choice,
       leftItems = const [],
       rightItems = const [],
       sentenceWords = const [];

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
       sentenceWords = const [];

  const LessonQuestion.completeSentence({
    required this.prompt,
    required this.answer,
    required this.choices,
    this.targetPhrase = '',
    this.targetMeaning = '',
    this.directionLabel = '',
  }) : type = QuestionType.completeSentence,
       leftItems = const [],
       rightItems = const [],
       sentenceWords = const [];

  const LessonQuestion.buildSentence({
    required this.prompt,
    required this.answer,
    required this.sentenceWords,
    this.targetPhrase = '',
    this.targetMeaning = '',
    this.directionLabel = '',
  }) : type = QuestionType.buildSentence,
       choices = const [],
       leftItems = const [],
       rightItems = const [];
}

/// One vocabulary pair used to generate level questions and dictionary content.
class LessonTerm {
  final String hil;
  final String eng;

  const LessonTerm(this.hil, this.eng);
}

/// Central lesson content source.
///
/// `questionsForLevel` creates a mixed set of question types from a sliding
/// window of vocabulary terms, so later levels reuse the same formats with
/// different words.
class LessonBank {
  static const terms = [
    LessonTerm('Maayong aga', 'Good morning'),
    LessonTerm('Maayong hapon', 'Good afternoon'),
    LessonTerm('Maayong gab-i', 'Good evening'),
    LessonTerm('Kumusta', 'How are you'),
    LessonTerm('Salamat', 'Thank you'),
    LessonTerm('Palihog', 'Please'),
    LessonTerm('Huo', 'Yes'),
    LessonTerm('Indi', 'No'),
    LessonTerm('Balay', 'House'),
    LessonTerm('Eskwelahan', 'School'),
    LessonTerm('Tubig', 'Water'),
    LessonTerm('Pagkaon', 'Food'),
    LessonTerm('Kaon', 'Eat'),
    LessonTerm('Inom', 'Drink'),
    LessonTerm('Adlaw', 'Day'),
    LessonTerm('Gab-i', 'Night'),
    LessonTerm('Bata', 'Child'),
    LessonTerm('Nanay', 'Mother'),
    LessonTerm('Tatay', 'Father'),
    LessonTerm('Abyan', 'Friend'),
    LessonTerm('Libro', 'Book'),
    LessonTerm('Maestro', 'Teacher'),
    LessonTerm('Gwapa', 'Beautiful'),
    LessonTerm('Gwapo', 'Handsome'),
    LessonTerm('Daku', 'Big'),
    LessonTerm('Gamay', 'Small'),
    LessonTerm('Dalan', 'Road'),
    LessonTerm('Kahoy', 'Tree'),
    LessonTerm('Iro', 'Dog'),
    LessonTerm('Iring', 'Cat'),
    LessonTerm('Ngalan', 'Name'),
    LessonTerm('Ako', 'I'),
    LessonTerm('Ikaw', 'You'),
    LessonTerm('Kami', 'We'),
    LessonTerm('Sila', 'They'),
    LessonTerm('Diin', 'Where'),
    LessonTerm('San-o', 'When'),
    LessonTerm('Ngaa', 'Why'),
    LessonTerm('Pila', 'How much'),
    LessonTerm('Subong', 'Now'),
    LessonTerm('Buas', 'Tomorrow'),
    LessonTerm('Kaina', 'Earlier'),
    LessonTerm('Kadamo', 'Many'),
    LessonTerm('Kadasig', 'Fast'),
    LessonTerm('Hinay', 'Slow'),
    LessonTerm('Matam-is', 'Sweet'),
    LessonTerm('Mapait', 'Bitter'),
    LessonTerm('Mainit', 'Hot'),
    LessonTerm('Matugnaw', 'Cold'),
    LessonTerm('Masadya', 'Happy'),
    LessonTerm('Kapoy', 'Tired'),
    LessonTerm('Bakal', 'Buy'),
    LessonTerm('Hatag', 'Give'),
    LessonTerm('Basa', 'Read'),
    LessonTerm('Sulat', 'Write'),
    LessonTerm('Pamati', 'Listen'),
    LessonTerm('Hambal', 'Speak'),
    LessonTerm('Lakat', 'Walk'),
    LessonTerm('Dagan', 'Run'),
    LessonTerm('Bukas', 'Open'),
    LessonTerm('Sirado', 'Closed'),
  ];

  static List<LessonQuestion> questionsForLevel(int level) {
    // Move through the vocabulary list in groups. The modulo keeps generation
    // valid even when the requested level is higher than the term list length.
    final start = ((level - 1) * 3) % (terms.length - 12);
    final active = terms.sublist(start, start + 12);
    final distractors = terms.where((term) => !active.contains(term)).toList();

    // Option helpers always include the correct answer, then add distractors.
    // Sorting keeps the order stable so the app behaves predictably.
    List<String> englishOptions(String answer, int seed) {
      final values = <String>{answer};
      var i = seed;
      while (values.length < 4) {
        values.add(distractors[i % distractors.length].eng);
        i += 7;
      }
      return values.toList()..sort();
    }

    List<String> hiligaynonOptions(String answer, int seed) {
      final values = <String>{answer};
      var i = seed;
      while (values.length < 4) {
        values.add(distractors[i % distractors.length].hil);
        i += 5;
      }
      return values.toList()..sort();
    }

    final q = <LessonQuestion>[
      _missingWordQuestion(level),
      _wordQuestion(
        term: active[1],
        englishToHiligaynon: true,
        choices: hiligaynonOptions(active[1].hil, level),
      ),
      LessonQuestion.matching(
        prompt: 'Match each Hiligaynon word to English.',
        leftItems: [
          active[2].hil,
          active[3].hil,
          active[4].hil,
          active[5].hil,
          active[6].hil,
        ],
        rightItems: [
          active[4].eng,
          active[6].eng,
          active[2].eng,
          active[5].eng,
          active[3].eng,
        ],
      ),
      _translateSentenceQuestion(level),
      _wordQuestion(
        term: active[5],
        englishToHiligaynon: false,
        choices: englishOptions(active[5].eng, level + 4),
      ),
      _missingWordQuestion(level + 1),
      _wordQuestion(
        term: active[7],
        englishToHiligaynon: true,
        choices: hiligaynonOptions(active[7].hil, level + 8),
      ),
      LessonQuestion.matching(
        prompt: 'Match each Hiligaynon word to English.',
        leftItems: [
          active[7].hil,
          active[8].hil,
          active[9].hil,
          active[10].hil,
          active[11].hil,
        ],
        rightItems: [
          active[10].eng,
          active[8].eng,
          active[11].eng,
          active[7].eng,
          active[9].eng,
        ],
      ),
      _translateSentenceQuestion(level + 1),
      _wordQuestion(
        term: active[10],
        englishToHiligaynon: false,
        choices: englishOptions(active[10].eng, level + 12),
      ),
      _translateSentenceQuestion(level + 2),
    ];

    return q;
  }

  static List<LessonTerm> termsForLevel(int level) {
    final start = ((level - 1) * 3) % (terms.length - 12);
    return terms.sublist(start, start + 12);
  }

  static int unitForLevel(int level) {
    return ((level - 1) % 3) + 1;
  }

  static LessonQuestion _missingWordQuestion(int level) {
    // Missing-word questions must not reveal the blank answer in the tooltip.
    // The target phrase is a clue word from the sentence, not the missing word.
    final questions = [
      const LessonQuestion.choice(
        prompt: 'Complete the sentence "Maayong ___".',
        answer: 'aga',
        choices: ['aga', 'puno', 'tubig', 'libro'],
        targetPhrase: 'Maayong',
        targetMeaning: 'Good',
        directionLabel: 'Hiligaynon to English',
      ),
      const LessonQuestion.choice(
        prompt: 'Complete the sentence "Maayong ___".',
        answer: 'hapon',
        choices: ['balay', 'hapon', 'kaon', 'iro'],
        targetPhrase: 'Maayong',
        targetMeaning: 'Good',
        directionLabel: 'Hiligaynon to English',
      ),
      const LessonQuestion.choice(
        prompt: 'Complete the sentence "Maayong ___".',
        answer: 'gab-i',
        choices: ['gab-i', 'puno', 'libro', 'tubig'],
        targetPhrase: 'Maayong',
        targetMeaning: 'Good',
        directionLabel: 'Hiligaynon to English',
      ),
      const LessonQuestion.choice(
        prompt: 'Complete the sentence "Nagkaon ako sang ___".',
        answer: 'kan-on',
        choices: ['tubig', 'kan-on', 'libro', 'balay'],
        targetPhrase: 'Nagkaon',
        targetMeaning: 'Ate or is eating',
        directionLabel: 'Hiligaynon to English',
      ),
      const LessonQuestion.choice(
        prompt: 'Complete the sentence "Palihog hatag sang ___".',
        answer: 'tubig',
        choices: ['tubig', 'gab-i', 'daku', 'kumusta'],
        targetPhrase: 'Palihog',
        targetMeaning: 'please',
        directionLabel: 'Hiligaynon to English',
      ),
      const LessonQuestion.choice(
        prompt: 'Complete the sentence "Nagabasa ako sang ___".',
        answer: 'libro',
        choices: ['libro', 'tubig', 'iro', 'dalan'],
        targetPhrase: 'Nagabasa',
        targetMeaning: 'reading',
        directionLabel: 'Hiligaynon to English',
      ),
    ];

    return questions[(level - 1) % questions.length];
  }

  static LessonQuestion _wordQuestion({
    required LessonTerm term,
    required bool englishToHiligaynon,
    required List<String> choices,
  }) {
    // One-word translation questions can go in either direction.
    if (englishToHiligaynon) {
      return LessonQuestion.completeSentence(
        prompt: term.eng,
        answer: term.hil,
        choices: choices,
        targetPhrase: term.eng,
        targetMeaning: term.hil,
        directionLabel: 'English to Hiligaynon',
      );
    }

    return LessonQuestion.completeSentence(
      prompt: term.hil,
      answer: term.eng,
      choices: choices,
      targetPhrase: term.hil,
      targetMeaning: term.eng,
      directionLabel: 'Hiligaynon to English',
    );
  }

  static LessonQuestion _translateSentenceQuestion(int level) {
    // Build-sentence questions ask the user to arrange blocks into the answer.
    final questions = [
      const LessonQuestion.buildSentence(
        prompt: 'Translate: "Maayong aga."',
        answer: 'Good morning',
        sentenceWords: ['Good', 'morning', 'evening', 'thank', 'you'],
        targetPhrase: 'Maayong aga',
        targetMeaning: 'Good morning',
        directionLabel: 'Hiligaynon to English',
      ),
      const LessonQuestion.buildSentence(
        prompt: 'Translate: "Nagakaon ako."',
        answer: 'I am eating',
        sentenceWords: ['I', 'am', 'eating', 'sleeping', 'you'],
        targetPhrase: 'Nagakaon ako',
        targetMeaning: 'I am eating',
        directionLabel: 'Hiligaynon to English',
      ),
      const LessonQuestion.buildSentence(
        prompt: 'Translate: "Nagabasa ako."',
        answer: 'I am reading',
        sentenceWords: ['I', 'am', 'reading', 'walking', 'you'],
        targetPhrase: 'Nagabasa ako',
        targetMeaning: 'I am reading',
        directionLabel: 'Hiligaynon to English',
      ),
      const LessonQuestion.buildSentence(
        prompt: 'Translate: "Salamat gid."',
        answer: 'Thank you',
        sentenceWords: ['Thank', 'you', 'please', 'good', 'morning'],
        targetPhrase: 'Salamat gid',
        targetMeaning: 'Thank you',
        directionLabel: 'Hiligaynon to English',
      ),
      const LessonQuestion.buildSentence(
        prompt: 'Translate: "Palihog hatag sang tubig."',
        answer: 'Please give water',
        sentenceWords: ['Please', 'give', 'water', 'book', 'house'],
        targetPhrase: 'Palihog hatag sang tubig',
        targetMeaning: 'Please give water',
        directionLabel: 'Hiligaynon to English',
      ),
    ];

    return questions[(level - 1) % questions.length];
  }

  static List<LessonQuestion> questionsForTest(int test) {
    final pool = <LessonQuestion>[
      ...questionsForLevel(1),
      ...questionsForLevel(2),
      ...questionsForLevel(3),
    ];
    if (test <= 1) return pool.take(30).toList();
    return [...pool.skip((test - 1) * 5), ...pool].take(30).toList();
  }
}
