import 'package:flutter/material.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank.dart';
import 'package:tudloapp/core/widgets/word_tooltip.dart';

enum _TestQuestionKind { multipleChoice, identification }

// Unit colors match the Home Map unit colors so tests feel connected to the
// same learning units.
const _testUnitColors = [
  TudloColors.brightGreen,
  Color(0xFF3D91E8),
  Color(0xFF8B5CF6),
  Color(0xFFE85D9E),
  Color(0xFFE05A47),
  Color(0xFFF59E0B),
];

Color _unitColorForTest(int test) {
  final index = (test - 1).clamp(0, _testUnitColors.length - 1);
  return _testUnitColors[index];
}

/// Test tab screen.
///
/// Each test represents one Home Map unit. Tests are always playable and pull
/// questions from the same LessonBank content used by that unit's levels.
class TestPage extends StatefulWidget {
  final VoidCallback? onBack;

  const TestPage({super.key, this.onBack});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  int? selectedTest;
  int score = 0;
  bool submitted = false;
  int currentQuestion = 0;
  final ScrollController _quizScrollController = ScrollController();
  final Map<int, String> selectedAnswers = {};
  late List<GlobalKey> questionKeys = [];
  late List<_TestQuestion> questions = _buildTestQuestions(1);

  @override
  void dispose() {
    _quizScrollController.dispose();
    super.dispose();
  }

  void _startTest(int test) {
    // Start a fresh 30-question test for the selected unit and clear any old
    // answers from a previous attempt.
    setState(() {
      selectedTest = test;
      questions = _buildTestQuestions(test);
      questionKeys = List.generate(30, (_) => GlobalKey());
      score = 0;
      submitted = false;
      currentQuestion = 0;
      selectedAnswers.clear();
      AppData.testTutorialDone = true;
    });
  }

  void _resetToPicker() {
    // Back button from the quiz:
    // Returns to the test picker list and clears the current attempt.
    setState(() {
      selectedTest = null;
      selectedAnswers.clear();
      submitted = false;
      currentQuestion = 0;
      score = 0;
    });
  }

  void _submitTest() {
    // Scoring compares the stored selected/typed answers with the answer key
    // after normalizing case and whitespace.
    final finalScore = List.generate(questions.length, (index) {
      final answer = selectedAnswers[index]?.trim().toLowerCase() ?? '';
      return answer == questions[index].answer.trim().toLowerCase() ? 1 : 0;
    }).fold<int>(0, (sum, value) => sum + value);

    setState(() {
      score = finalScore;
      submitted = true;
    });
    AppData.saveTestScore(selectedTest!, finalScore);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Test complete'),
        content: Text('You scored $score out of ${questions.length}.'),
        actions: [
          TextButton(
            onPressed: () {
              // After viewing the score, this button directs the user back to
              // the list of unit tests.
              Navigator.pop(context);
              _resetToPicker();
            },
            child: const Text('Choose another test'),
          ),
        ],
      ),
    );
  }

  void _scrollToQuestion(int index) {
    // The numbered chip header uses this to jump to a specific question card.
    final context = questionKeys[index].currentContext;
    if (context == null) return;
    setState(() => currentQuestion = index);
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      alignment: .08,
    );
  }

  _TestMeta _metaForTest(int test) {
    // Test titles stay synced with AppData.units, which is also used by the
    // Home Map message boxes.
    final unit = AppData.unitForNumber(test);
    return _TestMeta(
      unitTitle: unit.title,
      unitLabel: 'Unit ${unit.number}',
      range: 'Levels 1-${AppData.unitLevels}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TudloColors.paper,
      body: SafeArea(
        child: selectedTest == null ? _buildPicker() : _buildQuiz(),
      ),
    );
  }

  Widget _buildPicker() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 124),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PracticeHeader(onBack: widget.onBack),
          const SizedBox(height: 26),
          for (final unit in AppData.units) ...[
            _TestCard(
              test: unit.number,
              meta: _metaForTest(unit.number),
              unitColor: _unitColorForTest(unit.number),
              correctCount: AppData.bestScoreForTest(unit.number),
              // Play button on each card starts the test for that unit.
              onTap: () => _startTest(unit.number),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildQuiz() {
    final answered = selectedAnswers.length;
    final progress = answered / questions.length;
    final percent = (progress * 100).round();
    final meta = _metaForTest(selectedTest!);

    return CustomScrollView(
      controller: _quizScrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: _QuizHeader(
              test: selectedTest!,
              meta: meta,
              answered: answered,
              total: questions.length,
              percent: percent,
              progress: progress,
              onBack: _resetToPicker,
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _QuestionChipHeader(
            answered: selectedAnswers.keys.toSet(),
            current: currentQuestion,
            count: questions.length,
            onTap: _scrollToQuestion,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          sliver: SliverList.separated(
            itemCount: questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _QuestionCard(
                key: questionKeys[index],
                number: index + 1,
                question: questions[index],
                selectedAnswer: selectedAnswers[index],
                submitted: submitted,
                onSelect: (choice) {
                  // Tapping an answer stores it for this question. The score
                  // is not calculated until the Submit button is pressed.
                  if (submitted) return;
                  setState(() {
                    selectedAnswers[index] = choice;
                    currentQuestion = index;
                  });
                },
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: _QuizFooter(
            current: currentQuestion,
            total: questions.length,
            canSubmit: answered > 0 && !submitted,
            onPrevious: currentQuestion == 0
                ? null
                : () => _scrollToQuestion(currentQuestion - 1),
            onNext: currentQuestion >= questions.length - 1
                ? null
                : () => _scrollToQuestion(currentQuestion + 1),
            onSubmit: _submitTest,
          ),
        ),
      ],
    );
  }

  List<_TestQuestion> _buildTestQuestions(int test) {
    // A test covers one unit, which means five local levels. We gather the
    // terms from those five hidden global levels and generate mixed questions.
    final startLevel = ((test - 1) * 5) + 1;
    final terms = <LessonTerm>[
      for (var level = startLevel; level <= startLevel + 4; level++)
        ...LessonBank.termsForLevel(level),
    ];
    final unique = <String, LessonTerm>{
      for (final term in terms) term.hil: term,
    }.values.toList();

    final missingQuestions = _missingWordQuestions(test);
    final translationQuestions = _translationSentenceQuestions(test);

    return List.generate(30, (index) {
      final term = unique[index % unique.length];
      final typeIndex = index % 5;

      if (typeIndex == 0) {
        return missingQuestions[index % missingQuestions.length];
      }

      if (typeIndex == 1) {
        return translationQuestions[index % translationQuestions.length];
      }

      if (typeIndex == 2) {
        final choices = <String>{term.hil};
        var i = index + test;
        while (choices.length < 4) {
          choices.add(unique[i % unique.length].hil);
          i += 3;
        }
        return _TestQuestion.multipleChoice(
          instruction: 'Complete the sentence',
          prompt: term.eng,
          answer: term.hil,
          choices: choices.toList()..sort(),
          targetPhrase: term.eng,
          targetMeaning: term.hil,
          directionLabel: 'English to Hiligaynon',
        );
      }

      if (typeIndex == 4) {
        return _TestQuestion.identification(
          instruction: 'Identification',
          prompt: 'Type the English meaning of "${term.hil}".',
          answer: term.eng,
          targetPhrase: term.hil,
          targetMeaning: term.eng,
          directionLabel: 'Hiligaynon to English',
        );
      }

      final choices = <String>{term.eng};
      var i = index + test;
      while (choices.length < 4) {
        choices.add(unique[i % unique.length].eng);
        i += 3;
      }
      return _TestQuestion.multipleChoice(
        instruction: 'Complete the sentence',
        prompt: term.hil,
        answer: term.eng,
        choices: choices.toList()..sort(),
        targetPhrase: term.hil,
        targetMeaning: term.eng,
        directionLabel: 'Hiligaynon to English',
      );
    });
  }

  List<_TestQuestion> _missingWordQuestions(int test) {
    // Missing-word seeds rotate by test number so each unit starts at a
    // slightly different prompt.
    const bank = [
      _MissingWordSeed(
        prompt: 'Complete the sentence "___ ka subong?"',
        answer: 'Kumusta',
        choices: ['Kumusta', 'Salamat', 'Palihog', 'Huo'],
        targetPhrase: 'ka subong',
        targetMeaning: 'you now',
        directionLabel: 'Hiligaynon to English',
      ),
      _MissingWordSeed(
        prompt: 'Complete the sentence "___ gid sa imo."',
        answer: 'Salamat',
        choices: ['Salamat', 'Kumusta', 'Indi', 'Tubig'],
        targetPhrase: 'sa imo',
        targetMeaning: 'to you',
        directionLabel: 'Hiligaynon to English',
      ),
      _MissingWordSeed(
        prompt: 'Complete the sentence "___ hatag sang tubig."',
        answer: 'Palihog',
        choices: ['Palihog', 'Salamat', 'Huo', 'Indi'],
        targetPhrase: 'hatag sang tubig',
        targetMeaning: 'give water',
        directionLabel: 'Hiligaynon to English',
      ),
      _MissingWordSeed(
        prompt: 'Complete the sentence "Nagkaon ako sang ___".',
        answer: 'kan-on',
        choices: ['tubig', 'kan-on', 'libro', 'balay'],
        targetPhrase: 'Nagkaon',
        targetMeaning: 'Ate or is eating',
        directionLabel: 'Hiligaynon to English',
      ),
      _MissingWordSeed(
        prompt: 'Complete the sentence "Palihog hatag sang ___".',
        answer: 'tubig',
        choices: ['tubig', 'gab-i', 'daku', 'kumusta'],
        targetPhrase: 'Palihog',
        targetMeaning: 'please',
        directionLabel: 'Hiligaynon to English',
      ),
      _MissingWordSeed(
        prompt: 'Complete the sentence "Nagabasa ako sang ___".',
        answer: 'libro',
        choices: ['libro', 'tubig', 'ido', 'dalan'],
        targetPhrase: 'Nagabasa',
        targetMeaning: 'reading',
        directionLabel: 'Hiligaynon to English',
      ),
    ];

    return [
      for (var i = 0; i < bank.length; i++)
        _TestQuestion.multipleChoice(
          instruction: 'Select the missing word',
          prompt: bank[(i + test - 1) % bank.length].prompt,
          answer: bank[(i + test - 1) % bank.length].answer,
          choices: bank[(i + test - 1) % bank.length].choices,
          targetPhrase: bank[(i + test - 1) % bank.length].targetPhrase,
          targetMeaning: bank[(i + test - 1) % bank.length].targetMeaning,
          directionLabel: bank[(i + test - 1) % bank.length].directionLabel,
        ),
    ];
  }

  List<_TestQuestion> _translationSentenceQuestions(int test) {
    // Translation seeds add sentence-level questions to the generated test.
    const bank = [
      _TranslationSentenceSeed(
        prompt: 'Translate: "Nagakadto ako sa eskwelahan."',
        answer: 'I am going to school',
        choices: [
          'I am going to school',
          'I am reading a book',
          'Please give me water',
          'We are walking home',
        ],
        targetPhrase: 'Nagakadto ako sa eskwelahan',
        targetMeaning: 'I am going to school',
        directionLabel: 'Hiligaynon to English',
      ),
      _TranslationSentenceSeed(
        prompt: 'Translate: "Nagabasa ako sang libro."',
        answer: 'I am reading a book',
        choices: [
          'I am reading a book',
          'I am eating rice now',
          'You are drinking water',
          'They are going home',
        ],
        targetPhrase: 'Nagabasa ako sang libro',
        targetMeaning: 'I am reading a book',
        directionLabel: 'Hiligaynon to English',
      ),
      _TranslationSentenceSeed(
        prompt: 'Translate: "Palihog hatag sang tubig."',
        answer: 'Please give me water',
        choices: [
          'Please give me water',
          'Thank you very much',
          'Good morning to you',
          'I am going home',
        ],
        targetPhrase: 'Palihog hatag sang tubig',
        targetMeaning: 'Please give me water',
        directionLabel: 'Hiligaynon to English',
      ),
      _TranslationSentenceSeed(
        prompt: 'Translate: "Where are you going today?"',
        answer: 'Diin ka nagakadto subong',
        choices: [
          'Diin ka nagakadto subong',
          'Kumusta ka subong abyan',
          'Nagabasa ako sang libro',
          'Palihog hatag sang tubig',
        ],
        targetPhrase: 'Where are you going today',
        targetMeaning: 'Diin ka nagakadto subong',
        directionLabel: 'English to Hiligaynon',
      ),
      _TranslationSentenceSeed(
        prompt: 'Translate: "I am eating rice now."',
        answer: 'Nagakaon ako sang kan-on subong',
        choices: [
          'Nagakaon ako sang kan-on subong',
          'Nagabasa ako sang libro',
          'Nagakadto ako sa eskwelahan',
          'Nagainom ako sang tubig',
        ],
        targetPhrase: 'I am eating rice now',
        targetMeaning: 'Nagakaon ako sang kan-on subong',
        directionLabel: 'English to Hiligaynon',
      ),
    ];

    return [
      for (var i = 0; i < bank.length; i++)
        _TestQuestion.multipleChoice(
          instruction: 'Translate the sentence',
          prompt: bank[(i + test - 1) % bank.length].prompt,
          answer: bank[(i + test - 1) % bank.length].answer,
          choices: bank[(i + test - 1) % bank.length].choices,
          targetPhrase: bank[(i + test - 1) % bank.length].targetPhrase,
          targetMeaning: bank[(i + test - 1) % bank.length].targetMeaning,
          directionLabel: bank[(i + test - 1) % bank.length].directionLabel,
        ),
    ];
  }
}

class _PracticeHeader extends StatelessWidget {
  final VoidCallback? onBack;

  const _PracticeHeader({this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: TudloColors.softGreen,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onBack ?? () => Navigator.maybePop(context),
            child: const SizedBox(
              width: 50,
              height: 50,
              child: Icon(
                Icons.arrow_back_rounded,
                color: TudloColors.forest,
                size: 30,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: TudloColors.softGreen,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Center(
              child: Text(
                'Test',
                style: TextStyle(
                  color: TudloColors.forest,
                  fontSize: 24,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 64),
      ],
    );
  }
}

class _QuizHeader extends StatelessWidget {
  final int test;
  final _TestMeta meta;
  final int answered;
  final int total;
  final int percent;
  final double progress;
  final VoidCallback onBack;

  const _QuizHeader({
    required this.test,
    required this.meta,
    required this.answered,
    required this.total,
    required this.percent,
    required this.progress,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: TudloColors.line),
        boxShadow: [
          BoxShadow(
            color: TudloColors.forest.withValues(alpha: .08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: TudloColors.softGreen,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onBack,
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: TudloColors.forest,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test $test',
                      style: const TextStyle(
                        color: TudloColors.ink,
                        fontSize: 26,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      meta.range,
                      style: const TextStyle(
                        color: TudloColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              _SoftBadge(label: '$percent%'),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 14,
              backgroundColor: TudloColors.line,
              color: TudloColors.brightGreen,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '$answered/$total answered',
                style: const TextStyle(
                  color: TudloColors.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.auto_awesome_rounded,
                color: TudloColors.gold,
                size: 18,
              ),
              const SizedBox(width: 5),
              const Text(
                'Keep going',
                style: TextStyle(
                  color: TudloColors.forest,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestionChipHeader extends SliverPersistentHeaderDelegate {
  final Set<int> answered;
  final int current;
  final int count;
  final ValueChanged<int> onTap;

  const _QuestionChipHeader({
    required this.answered,
    required this.current,
    required this.count,
    required this.onTap,
  });

  @override
  double get minExtent => 78;

  @override
  double get maxExtent => 78;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // The sticky chip row shows progress and lets users jump around the long
    // test without scrolling manually.
    return Container(
      color: TudloColors.paper,
      padding: const EdgeInsets.fromLTRB(20, 12, 0, 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isAnswered = answered.contains(index);
          final isCurrent = current == index;
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: isCurrent ? 54 : 46,
              decoration: BoxDecoration(
                color: isCurrent
                    ? TudloColors.forest
                    : isAnswered
                    ? TudloColors.brightGreen
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isAnswered || isCurrent
                      ? Colors.transparent
                      : TudloColors.line,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: TudloColors.forest.withValues(
                      alpha: isCurrent ? .15 : .06,
                    ),
                    blurRadius: isCurrent ? 16 : 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isAnswered || isCurrent
                        ? Colors.white
                        : TudloColors.muted,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _QuestionChipHeader oldDelegate) {
    return answered != oldDelegate.answered ||
        current != oldDelegate.current ||
        count != oldDelegate.count;
  }
}

class _QuestionCard extends StatelessWidget {
  final int number;
  final _TestQuestion question;
  final String? selectedAnswer;
  final bool submitted;
  final ValueChanged<String> onSelect;

  const _QuestionCard({
    super.key,
    required this.number,
    required this.question,
    required this.selectedAnswer,
    required this.submitted,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isIdentification = question.kind == _TestQuestionKind.identification;
    final answeredCorrectly =
        submitted &&
        (selectedAnswer ?? '').trim().toLowerCase() ==
            question.answer.trim().toLowerCase();
    final feedbackPhrase = _feedbackPhraseFor(question);
    final feedbackMeaning = _feedbackMeaningFor(question);
    final icon = switch (question.instruction) {
      'Select the missing word' => Icons.extension_rounded,
      'Translate the sentence' => Icons.translate_rounded,
      'Complete the sentence' => Icons.text_fields_rounded,
      'Identification' => Icons.edit_note_rounded,
      _ => Icons.checklist_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: TudloColors.line),
        boxShadow: [
          BoxShadow(
            color: TudloColors.forest.withValues(alpha: .08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: TudloColors.softGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: TudloColors.forest, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Question $number',
                  style: const TextStyle(
                    color: TudloColors.forest,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _SoftBadge(label: question.instruction),
            ],
          ),
          const SizedBox(height: 14),
          TapWordMeaningText(
            fullQuestionText: question.prompt,
            targetPhrase: question.targetPhrase,
            targetMeaning: question.targetMeaning,
            directionLabel: question.directionLabel,
            style: const TextStyle(
              color: TudloColors.ink,
              fontSize: 21,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          if (isIdentification)
            _IdentificationAnswer(
              value: selectedAnswer ?? '',
              submitted: submitted,
              correct:
                  submitted &&
                  (selectedAnswer ?? '').trim().toLowerCase() ==
                      question.answer.trim().toLowerCase(),
              wrong:
                  submitted &&
                  selectedAnswer != null &&
                  (selectedAnswer ?? '').trim().toLowerCase() !=
                      question.answer.trim().toLowerCase(),
              onChanged: onSelect,
            )
          else
            ...question.choices.map((choice) {
              final selected = selectedAnswer == choice;
              final correct = submitted && choice == question.answer;
              final wrong = submitted && selected && choice != question.answer;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AnswerChoice(
                  label: choice,
                  selected: selected,
                  correct: correct,
                  wrong: wrong,
                  submitted: submitted,
                  onTap: () => onSelect(choice),
                ),
              );
            }),
          if (submitted && selectedAnswer != null) ...[
            const SizedBox(height: 6),
            _QuestionFeedback(
              correct: answeredCorrectly,
              targetPhrase: feedbackPhrase,
              targetMeaning: feedbackMeaning,
            ),
          ],
        ],
      ),
    );
  }

  String _feedbackPhraseFor(_TestQuestion question) {
    // Missing-word feedback should show the completed sentence, not only the
    // underlined clue word from the prompt.
    if (question.instruction != 'Select the missing word') {
      return question.targetPhrase;
    }

    final match = RegExp(r'"([^"]+)"').firstMatch(question.prompt);
    final sentence = match?.group(1) ?? question.prompt;
    return sentence.replaceAll('___', question.answer);
  }

  String _feedbackMeaningFor(_TestQuestion question) {
    final phrase = _feedbackPhraseFor(question);
    const meanings = {
      'Kumusta ka subong?': 'How are you now',
      'Salamat gid sa imo.': 'Thank you very much',
      'Palihog hatag sang tubig.': 'Please give water',
      'Nagkaon ako sang kan-on': 'I am eating rice',
      'Nagabasa ako sang libro': 'I am reading a book',
    };
    return meanings[phrase] ?? question.targetMeaning;
  }
}

class _QuestionFeedback extends StatelessWidget {
  final bool correct;
  final String targetPhrase;
  final String targetMeaning;

  const _QuestionFeedback({
    required this.correct,
    required this.targetPhrase,
    required this.targetMeaning,
  });

  @override
  Widget build(BuildContext context) {
    final color = correct ? TudloColors.green : TudloColors.coral;
    final message = correct ? 'Great job!' : 'Correct answer';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct ? Icons.check_circle_rounded : Icons.info_rounded,
                color: color,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                message,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Meaning:',
            style: TextStyle(
              color: TudloColors.forest,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            targetPhrase,
            style: const TextStyle(
              color: TudloColors.ink,
              fontSize: 16,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            targetMeaning,
            style: const TextStyle(
              color: TudloColors.muted,
              fontSize: 15,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentificationAnswer extends StatelessWidget {
  final String value;
  final bool submitted;
  final bool correct;
  final bool wrong;
  final ValueChanged<String> onChanged;

  const _IdentificationAnswer({
    required this.value,
    required this.submitted,
    required this.correct,
    required this.wrong,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = correct
        ? TudloColors.brightGreen
        : wrong
        ? TudloColors.coral
        : value.trim().isNotEmpty
        ? TudloColors.brightGreen
        : TudloColors.line;

    return TextFormField(
      initialValue: value,
      readOnly: submitted,
      onChanged: onChanged,
      style: const TextStyle(
        color: TudloColors.ink,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        hintText: 'Type your answer here',
        hintStyle: const TextStyle(
          color: TudloColors.muted,
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: TudloColors.paper,
        suffixIcon: submitted
            ? Icon(
                correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: correct ? TudloColors.brightGreen : TudloColors.coral,
              )
            : const Icon(Icons.keyboard_rounded, color: TudloColors.muted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor, width: 3),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

class _AnswerChoice extends StatefulWidget {
  final String label;
  final bool selected;
  final bool correct;
  final bool wrong;
  final bool submitted;
  final VoidCallback onTap;

  const _AnswerChoice({
    required this.label,
    required this.selected,
    required this.correct,
    required this.wrong,
    required this.submitted,
    required this.onTap,
  });

  @override
  State<_AnswerChoice> createState() => _AnswerChoiceState();
}

class _AnswerChoiceState extends State<_AnswerChoice> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final highlight = widget.correct || widget.selected;
    final borderColor = widget.correct
        ? TudloColors.brightGreen
        : widget.wrong
        ? TudloColors.coral
        : widget.selected
        ? TudloColors.brightGreen
        : TudloColors.line;
    final fillColor = widget.correct
        ? TudloColors.brightGreen.withValues(alpha: .14)
        : widget.wrong
        ? TudloColors.coral.withValues(alpha: .12)
        : widget.selected
        ? TudloColors.softGreen
        : TudloColors.paper;

    return AnimatedScale(
      scale: _pressed ? .98 : 1,
      duration: const Duration(milliseconds: 90),
      child: GestureDetector(
        onTapDown: widget.submitted
            ? null
            : (_) => setState(() => _pressed = true),
        onTapCancel: widget.submitted
            ? null
            : () => setState(() => _pressed = false),
        onTapUp: widget.submitted
            ? null
            : (_) => setState(() => _pressed = false),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.submitted ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: highlight ? 3 : 2),
            ),
            child: Row(
              children: [
                Icon(
                  widget.correct
                      ? Icons.check_circle_rounded
                      : widget.wrong
                      ? Icons.cancel_rounded
                      : widget.selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: borderColor,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      color: TudloColors.ink,
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizFooter extends StatelessWidget {
  final int current;
  final int total;
  final bool canSubmit;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onSubmit;

  const _QuizFooter({
    required this.current,
    required this.total,
    required this.canSubmit,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 128),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: TudloColors.forest.withValues(alpha: .10),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            _FooterButton(
              icon: Icons.chevron_left_rounded,
              label: 'Previous',
              onTap: onPrevious,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  // Submit button:
                  // Checks the saved answers and shows the final test score.
                  onPressed: canSubmit ? onSubmit : null,
                  child: Text('CHECK (${current + 1}/$total)'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _FooterButton(
              icon: Icons.chevron_right_rounded,
              label: 'Next',
              onTap: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _FooterButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: onTap == null ? TudloColors.line : TudloColors.softGreen,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 52,
            child: Icon(
              icon,
              color: onTap == null ? TudloColors.muted : TudloColors.forest,
            ),
          ),
        ),
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  final int test;
  final _TestMeta meta;
  final Color unitColor;
  final int correctCount;
  final VoidCallback? onTap;

  const _TestCard({
    required this.test,
    required this.meta,
    required this.unitColor,
    required this.correctCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        // Whole test card is tappable. It directs the user into the quiz for
        // this unit.
        onTap: onTap,
        child: Ink(
          height: 106,
          padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
          decoration: BoxDecoration(
            color: TudloColors.green.withValues(alpha: .72),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: unitColor.withValues(alpha: .20),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                // Left circle shows the test number only.
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: unitColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 6),
                ),
                child: Center(
                  child: Text(
                    '$test',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.unitTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${meta.unitLabel}  ${meta.range}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .92),
                        fontSize: 13,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: TudloColors.gold,
                          size: 25,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$correctCount/30',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .92),
                            fontSize: 15,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                // Right circle is the visual play/start button for the test.
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 46,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftBadge extends StatelessWidget {
  final String label;

  const _SoftBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: TudloColors.softGreen,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: TudloColors.forest,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TestMeta {
  final String unitTitle;
  final String unitLabel;
  final String range;

  const _TestMeta({
    required this.unitTitle,
    required this.unitLabel,
    required this.range,
  });
}

class _TestQuestion {
  final _TestQuestionKind kind;
  final String instruction;
  final String prompt;
  final String answer;
  final List<String> choices;
  final String targetPhrase;
  final String targetMeaning;
  final String directionLabel;

  const _TestQuestion.multipleChoice({
    required this.instruction,
    required this.prompt,
    required this.answer,
    required this.choices,
    required this.targetPhrase,
    required this.targetMeaning,
    required this.directionLabel,
  }) : kind = _TestQuestionKind.multipleChoice;

  const _TestQuestion.identification({
    required this.instruction,
    required this.prompt,
    required this.answer,
    required this.targetPhrase,
    required this.targetMeaning,
    required this.directionLabel,
  }) : kind = _TestQuestionKind.identification,
       choices = const [];
}

class _MissingWordSeed {
  final String prompt;
  final String answer;
  final List<String> choices;
  final String targetPhrase;
  final String targetMeaning;
  final String directionLabel;

  const _MissingWordSeed({
    required this.prompt,
    required this.answer,
    required this.choices,
    required this.targetPhrase,
    required this.targetMeaning,
    required this.directionLabel,
  });
}

class _TranslationSentenceSeed {
  final String prompt;
  final String answer;
  final List<String> choices;
  final String targetPhrase;
  final String targetMeaning;
  final String directionLabel;

  const _TranslationSentenceSeed({
    required this.prompt,
    required this.answer,
    required this.choices,
    required this.targetPhrase,
    required this.targetMeaning,
    required this.directionLabel,
  });
}
