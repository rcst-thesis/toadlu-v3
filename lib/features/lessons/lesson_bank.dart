import 'dart:math' as math;

import 'package:tudloapp/core/models/proficiency.dart';

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

class EvaluationQuestion {
  final EvaluationQuestionType type;
  final String prompt;
  final String answer;
  final List<String> choices;
  final Map<String, String> pairs;
  final List<String> rightItems;
  final String targetPhrase;
  final String targetMeaning;
  final String directionLabel;

  const EvaluationQuestion.choice({
    required this.type,
    required this.prompt,
    required this.answer,
    required this.choices,
    this.targetPhrase = '',
    this.targetMeaning = '',
    this.directionLabel = '',
  }) : pairs = const {},
       rightItems = const [];

  const EvaluationQuestion.matching({
    required this.prompt,
    required this.pairs,
    required this.rightItems,
  }) : type = EvaluationQuestionType.matchingPair,
       answer = '',
       choices = const [],
       targetPhrase = '',
       targetMeaning = '',
       directionLabel = '';
}

class _MissingWordTemplate {
  final String prompt;
  final String answer;
  final List<String> choices;
  final String targetPhrase;
  final String targetMeaning;

  const _MissingWordTemplate({
    required this.prompt,
    required this.answer,
    required this.choices,
    required this.targetPhrase,
    required this.targetMeaning,
  });
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

  static const _missingWordTemplates = [
    _MissingWordTemplate(
      prompt: 'Complete the sentence "Maayong ___".',
      answer: 'aga',
      choices: ['aga', 'hapon', 'gab-i', 'adlaw'],
      targetPhrase: 'Maayong',
      targetMeaning: 'Good',
    ),
    _MissingWordTemplate(
      prompt: 'Complete the sentence "Maayong ___".',
      answer: 'hapon',
      choices: ['hapon', 'aga', 'gab-i', 'adlaw'],
      targetPhrase: 'Maayong',
      targetMeaning: 'Good',
    ),
    _MissingWordTemplate(
      prompt: 'Complete the sentence "Maayong ___".',
      answer: 'gab-i',
      choices: ['gab-i', 'aga', 'hapon', 'adlaw'],
      targetPhrase: 'Maayong',
      targetMeaning: 'Good',
    ),
    _MissingWordTemplate(
      prompt: 'Complete the sentence "Nagkaon ako sang ___".',
      answer: 'kan-on',
      choices: ['kan-on', 'pagkaon', 'tubig', 'libro'],
      targetPhrase: 'Nagkaon',
      targetMeaning: 'Ate or is eating',
    ),
    _MissingWordTemplate(
      prompt: 'Complete the sentence "Palihog hatag sang ___".',
      answer: 'tubig',
      choices: ['tubig', 'libro', 'pagkaon', 'balay'],
      targetPhrase: 'Palihog',
      targetMeaning: 'please',
    ),
    _MissingWordTemplate(
      prompt: 'Complete the sentence "Nagabasa ako sang ___".',
      answer: 'libro',
      choices: ['libro', 'dalan', 'ngalan', 'sulat'],
      targetPhrase: 'Nagabasa',
      targetMeaning: 'reading',
    ),
  ];

  static List<EvaluationQuestion> randomEvaluationQuestions({
    math.Random? random,
  }) {
    final rng = random ?? math.Random();
    final usedConcepts = <String>{};
    final easy = _evaluationQuestionsForRange(0, 20, rng, usedConcepts);
    final mid = _evaluationQuestionsForRange(20, 40, rng, usedConcepts);
    final hard = _evaluationQuestionsForRange(40, terms.length, rng, usedConcepts);
    return [...easy, ...mid, ...hard];
  }

  static List<EvaluationQuestion> _evaluationQuestionsForRange(
    int start,
    int end,
    math.Random rng,
    Set<String> usedConcepts,
  ) {
    final pool = terms.sublist(start, end).toList()..shuffle(rng);
    final questions = <EvaluationQuestion>[];
    final availableTypes = [
      EvaluationQuestionType.whatIsTheWord,
      EvaluationQuestionType.selectMissingWord,
      EvaluationQuestionType.translateSentence,
      EvaluationQuestionType.matchingPair,
    ]..shuffle(rng);

    var cursor = 0;
    while (questions.length < 5) {
      final type = availableTypes[questions.length % availableTypes.length];
      final question = _buildEvaluationQuestion(
        type: type,
        termsPool: pool,
        rng: rng,
        usedConcepts: usedConcepts,
        cursor: cursor,
      );
      cursor += 3;
      if (question != null) {
        questions.add(question);
      } else {
        questions.add(
          _buildEvaluationQuestion(
            type: EvaluationQuestionType.whatIsTheWord,
            termsPool: pool,
            rng: rng,
            usedConcepts: usedConcepts,
            cursor: cursor,
          )!,
        );
      }
    }

    questions.shuffle(rng);
    return questions;
  }

  static EvaluationQuestion? _buildEvaluationQuestion({
    required EvaluationQuestionType type,
    required List<LessonTerm> termsPool,
    required math.Random rng,
    required Set<String> usedConcepts,
    required int cursor,
  }) {
    return switch (type) {
      EvaluationQuestionType.whatIsTheWord => _randomEvaluationWordQuestion(
        termsPool,
        rng,
        usedConcepts,
        cursor,
      ),
      EvaluationQuestionType.selectMissingWord =>
        _randomEvaluationMissingWordQuestion(rng, usedConcepts),
      EvaluationQuestionType.translateSentence =>
        _randomEvaluationTranslateQuestion(termsPool, rng, usedConcepts, cursor),
      EvaluationQuestionType.matchingPair =>
        _randomEvaluationMatchingQuestion(termsPool, rng, usedConcepts, cursor),
    };
  }

  static EvaluationQuestion _randomEvaluationWordQuestion(
    List<LessonTerm> termsPool,
    math.Random rng,
    Set<String> usedConcepts,
    int cursor,
  ) {
    final term = _nextUnusedTerm(termsPool, usedConcepts, cursor);
    final englishToHiligaynon = rng.nextBool();
    usedConcepts.add(_conceptKey(term));
    if (englishToHiligaynon) {
      return EvaluationQuestion.choice(
        type: EvaluationQuestionType.whatIsTheWord,
        prompt: 'What is "${term.eng}" in Hiligaynon?',
        answer: term.hil,
        choices: _optionsFor(
          answer: term.hil,
          values: terms.map((term) => term.hil).toList(),
          rng: rng,
        ),
        targetPhrase: term.eng,
        targetMeaning: term.hil,
        directionLabel: 'English to Hiligaynon',
      );
    }

    return EvaluationQuestion.choice(
      type: EvaluationQuestionType.whatIsTheWord,
      prompt: 'What is "${term.hil}" in English?',
      answer: term.eng,
      choices: _optionsFor(
        answer: term.eng,
        values: terms.map((term) => term.eng).toList(),
        rng: rng,
      ),
      targetPhrase: term.hil,
      targetMeaning: term.eng,
      directionLabel: 'Hiligaynon to English',
    );
  }

  static EvaluationQuestion? _randomEvaluationMissingWordQuestion(
    math.Random rng,
    Set<String> usedConcepts,
  ) {
    final templates = _missingWordTemplates.toList()..shuffle(rng);
    for (final template in templates) {
      final key = template.answer.toLowerCase();
      if (usedConcepts.contains(key)) continue;
      usedConcepts.add(key);
      return EvaluationQuestion.choice(
        type: EvaluationQuestionType.selectMissingWord,
        prompt: template.prompt,
        answer: template.answer,
        choices: _missingWordChoices(template, rng),
        targetPhrase: template.targetPhrase,
        targetMeaning: template.targetMeaning,
        directionLabel: 'Hiligaynon to English',
      );
    }
    return null;
  }

  static List<String> _missingWordChoices(
    _MissingWordTemplate template,
    math.Random rng,
  ) {
    final choices = <String>{template.answer};
    for (final choice in template.choices) {
      if (!choice.trim().contains(' ')) choices.add(choice);
    }
    final shuffled = choices.toList()..shuffle(rng);
    return shuffled.take(4).toList();
  }

  static EvaluationQuestion _randomEvaluationTranslateQuestion(
    List<LessonTerm> termsPool,
    math.Random rng,
    Set<String> usedConcepts,
    int cursor,
  ) {
    final sentenceTerms = termsPool
        .where((term) => term.hil.contains(' ') || term.eng.contains(' '))
        .toList();
    final term = _nextUnusedTerm(
      sentenceTerms.isEmpty ? termsPool : sentenceTerms,
      usedConcepts,
      cursor,
    );
    final englishToHiligaynon = rng.nextBool();
    usedConcepts.add(_conceptKey(term));

    if (englishToHiligaynon) {
      return EvaluationQuestion.choice(
        type: EvaluationQuestionType.translateSentence,
        prompt: 'Translate: "${term.eng}."',
        answer: term.hil,
        choices: _optionsFor(
          answer: term.hil,
          values: terms.map((term) => term.hil).toList(),
          rng: rng,
        ),
        targetPhrase: term.eng,
        targetMeaning: term.hil,
        directionLabel: 'English to Hiligaynon',
      );
    }

    return EvaluationQuestion.choice(
      type: EvaluationQuestionType.translateSentence,
      prompt: 'Translate: "${term.hil}."',
      answer: term.eng,
      choices: _optionsFor(
        answer: term.eng,
        values: terms.map((term) => term.eng).toList(),
        rng: rng,
      ),
      targetPhrase: term.hil,
      targetMeaning: term.eng,
      directionLabel: 'Hiligaynon to English',
    );
  }

  static EvaluationQuestion? _randomEvaluationMatchingQuestion(
    List<LessonTerm> termsPool,
    math.Random rng,
    Set<String> usedConcepts,
    int cursor,
  ) {
    final selected = <LessonTerm>[];
    var index = cursor;
    while (selected.length < 3 && index < cursor + termsPool.length * 2) {
      final term = termsPool[index % termsPool.length];
      if (!usedConcepts.contains(_conceptKey(term)) && !selected.contains(term)) {
        selected.add(term);
      }
      index++;
    }
    if (selected.length < 3) return null;

    for (final term in selected) {
      usedConcepts.add(_conceptKey(term));
    }
    final rightItems = selected.map((term) => term.eng).toList()..shuffle(rng);
    return EvaluationQuestion.matching(
      prompt: 'Match each Hiligaynon word to English.',
      pairs: {for (final term in selected) term.hil: term.eng},
      rightItems: rightItems,
    );
  }

  static LessonTerm _nextUnusedTerm(
    List<LessonTerm> termsPool,
    Set<String> usedConcepts,
    int cursor,
  ) {
    for (var offset = 0; offset < termsPool.length; offset++) {
      final term = termsPool[(cursor + offset) % termsPool.length];
      if (!usedConcepts.contains(_conceptKey(term))) return term;
    }
    return termsPool[cursor % termsPool.length];
  }

  static String _conceptKey(LessonTerm term) {
    return '${term.hil.toLowerCase()}|${term.eng.toLowerCase()}';
  }

  static List<String> _optionsFor({
    required String answer,
    required List<String> values,
    required math.Random rng,
  }) {
    final options = <String>{answer};
    final shuffled = values.where((value) => value != answer).toList()
      ..shuffle(rng);
    for (final value in shuffled) {
      if (options.length >= 4) break;
      options.add(value);
    }
    return options.toList()..shuffle(rng);
  }

  static List<LessonQuestion> questionsForLevel(
    int level, {
    HomeMapDataset dataset = HomeMapDataset.easy,
  }) {
    final rng = math.Random();
    // Move through the vocabulary list in groups. The modulo keeps generation
    // valid even when the requested level is higher than the term list length.
    final start =
        (((level - 1) * 3) + _datasetOffset(dataset)) % (terms.length - 12);
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
      return values.toList()..shuffle(rng);
    }

    List<String> hiligaynonOptions(String answer, int seed) {
      final values = <String>{answer};
      var i = seed;
      while (values.length < 4) {
        values.add(distractors[i % distractors.length].hil);
        i += 5;
      }
      return values.toList()..shuffle(rng);
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
        rightItems: ([
          active[4].eng,
          active[6].eng,
          active[2].eng,
          active[5].eng,
          active[3].eng,
        ]..shuffle(rng)),
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
        rightItems: ([
          active[10].eng,
          active[8].eng,
          active[11].eng,
          active[7].eng,
          active[9].eng,
        ]..shuffle(rng)),
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

  static List<LessonTerm> termsForLevel(
    int level, {
    HomeMapDataset dataset = HomeMapDataset.easy,
  }) {
    final start =
        (((level - 1) * 3) + _datasetOffset(dataset)) % (terms.length - 12);
    return terms.sublist(start, start + 12);
  }

  static int _datasetOffset(HomeMapDataset dataset) {
    return switch (dataset) {
      HomeMapDataset.easy => 0,
      HomeMapDataset.medium => 18,
      HomeMapDataset.hard => 36,
    };
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
}
