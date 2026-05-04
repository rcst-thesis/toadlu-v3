enum QuestionType { choice, matching, completeSentence, buildSentence }

class LessonQuestion {
  final QuestionType type;
  final String prompt;
  final String answer;
  final List<String> choices;
  final List<String> leftItems;
  final List<String> rightItems;
  final List<String> sentenceWords;

  const LessonQuestion.choice({
    required this.prompt,
    required this.answer,
    required this.choices,
  }) : type = QuestionType.choice,
       leftItems = const [],
       rightItems = const [],
       sentenceWords = const [];

  const LessonQuestion.matching({
    required this.prompt,
    required this.leftItems,
    required this.rightItems,
  }) : type = QuestionType.matching,
       answer = '',
       choices = const [],
       sentenceWords = const [];

  const LessonQuestion.completeSentence({
    required this.prompt,
    required this.answer,
    required this.choices,
  }) : type = QuestionType.completeSentence,
       leftItems = const [],
       rightItems = const [],
       sentenceWords = const [];

  const LessonQuestion.buildSentence({
    required this.prompt,
    required this.answer,
    required this.sentenceWords,
  }) : type = QuestionType.buildSentence,
       choices = const [],
       leftItems = const [],
       rightItems = const [];
}

class LessonTerm {
  final String hil;
  final String eng;

  const LessonTerm(this.hil, this.eng);
}

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
    final difficulty = ((level - 1) ~/ 10).clamp(0, 4);
    final start = ((level - 1) * 3) % (terms.length - 12);
    final active = terms.sublist(start, start + 12);
    final distractors = terms.where((term) => !active.contains(term)).toList();

    List<String> options(String answer, int seed) {
      final values = <String>{answer};
      var i = seed;
      while (values.length < 4) {
        values.add(distractors[i % distractors.length].eng);
        i += 7;
      }
      return values.toList()..sort();
    }

    final q = <LessonQuestion>[
      LessonQuestion.choice(
        prompt: 'What is the English of "${active[0].hil}"?',
        answer: active[0].eng,
        choices: options(active[0].eng, level),
      ),
      LessonQuestion.choice(
        prompt: 'Choose the Hiligaynon for "${active[1].eng}".',
        answer: active[1].hil,
        choices: [active[1].hil, active[2].hil, active[3].hil, active[4].hil]
          ..sort(),
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
      LessonQuestion.completeSentence(
        prompt: 'Complete: "${active[5].hil}" means ___.',
        answer: active[5].eng,
        choices: options(active[5].eng, level + 4),
      ),
      LessonQuestion.buildSentence(
        prompt: 'Build this sentence: ${active[6].eng}',
        answer: active[6].hil,
        sentenceWords: _shuffledWords(active[6].hil, level),
      ),
      LessonQuestion.choice(
        prompt: 'What is the English of "${active[7].hil}"?',
        answer: active[7].eng,
        choices: options(active[7].eng, level + 8),
      ),
      LessonQuestion.matching(
        prompt: 'Match the harder set.',
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
      LessonQuestion.completeSentence(
        prompt: difficulty < 2
            ? 'Pick the meaning: "${active[11].hil}" = ___.'
            : 'In a sentence, "${active[11].hil}" is closest to ___.',
        answer: active[11].eng,
        choices: options(active[11].eng, level + 12),
      ),
      LessonQuestion.buildSentence(
        prompt: 'Create the Hiligaynon phrase: ${active[0].eng}',
        answer: active[0].hil,
        sentenceWords: _shuffledWords(active[0].hil, level + 3),
      ),
      LessonQuestion.choice(
        prompt: difficulty < 3
            ? 'Review: "${active[3].hil}" means what?'
            : 'Final challenge: translate "${active[3].hil}" quickly.',
        answer: active[3].eng,
        choices: options(active[3].eng, level + 18),
      ),
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

  static List<LessonQuestion> questionsForTest(int test) {
    final pool = <LessonQuestion>[
      ...questionsForLevel(1),
      ...questionsForLevel(2),
      ...questionsForLevel(3),
    ];
    if (test <= 1) return pool.take(30).toList();
    return [...pool.skip((test - 1) * 5), ...pool].take(30).toList();
  }

  static List<String> _shuffledWords(String phrase, int seed) {
    final words = phrase.split(' ');
    if (words.length == 1) return [words.first, 'ko', 'na', 'ang'];
    return [...words.reversed];
  }
}
