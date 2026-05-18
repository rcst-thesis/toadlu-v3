import 'package:flutter/material.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/style/app_theme.dart';
import 'package:tudloapp/core/style/forest_art.dart';
import 'package:tudloapp/features/lessons/lesson_bank.dart';
import 'package:tudloapp/features/lessons/tap_word_meaning.dart';

enum _TestQuestionKind { multipleChoice, identification }

class TestPage extends StatefulWidget {
  const TestPage({super.key});

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
    setState(() {
      selectedTest = null;
      selectedAnswers.clear();
      submitted = false;
      currentQuestion = 0;
      score = 0;
    });
  }

  void _submitTest() {
    final finalScore = List.generate(questions.length, (index) {
      final answer = selectedAnswers[index]?.trim().toLowerCase() ?? '';
      return answer == questions[index].answer.trim().toLowerCase() ? 1 : 0;
    }).fold<int>(0, (sum, value) => sum + value);

    setState(() {
      score = finalScore;
      submitted = true;
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Test complete'),
        content: Text('You scored $score out of ${questions.length}.'),
        actions: [
          TextButton(
            onPressed: () {
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
    return switch (test) {
      1 => const _TestMeta(
        range: 'Levels 1-3',
        label: 'Beginner',
        description: 'Start here and review your first lessons.',
        progress: .12,
        tag: 'Recommended',
        icon: Icons.spa_rounded,
      ),
      2 => const _TestMeta(
        range: 'Levels 4-6',
        label: 'Basic',
        description: 'Build confidence with familiar words.',
        progress: 0,
        tag: 'Next step',
        icon: Icons.local_florist_rounded,
      ),
      _ => const _TestMeta(
        range: 'Levels 7-9',
        label: 'Intermediate',
        description: 'Challenge yourself with stronger recall.',
        progress: 0,
        tag: 'Challenge',
        icon: Icons.emoji_events_rounded,
      ),
    };
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
          const _PracticeHeader(),
          const SizedBox(height: 18),
          for (var test = 1; test <= 3; test++) ...[
            _TestCard(
              test: test,
              meta: _metaForTest(test),
              onTap: () => _startTest(test),
            ),
            const SizedBox(height: 14),
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
    final startLevel = ((test - 1) * 3) + 1;
    final terms = <LessonTerm>[
      for (var level = startLevel; level <= startLevel + 2; level++)
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
    const bank = [
      _MissingWordSeed(
        prompt: 'Complete the sentence "Maayong ___".',
        answer: 'aga',
        choices: ['aga', 'puno', 'tubig', 'libro'],
        targetPhrase: 'Maayong',
        targetMeaning: 'Good',
        directionLabel: 'Hiligaynon to English',
      ),
      _MissingWordSeed(
        prompt: 'Complete the sentence "Maayong ___".',
        answer: 'hapon',
        choices: ['balay', 'hapon', 'kaon', 'iro'],
        targetPhrase: 'Maayong',
        targetMeaning: 'Good',
        directionLabel: 'Hiligaynon to English',
      ),
      _MissingWordSeed(
        prompt: 'Complete the sentence "Maayong ___".',
        answer: 'gab-i',
        choices: ['gab-i', 'puno', 'libro', 'tubig'],
        targetPhrase: 'Maayong',
        targetMeaning: 'Good',
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
        choices: ['libro', 'tubig', 'iro', 'dalan'],
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
    const bank = [
      _TranslationSentenceSeed(
        prompt: 'Translate: "Maayong aga."',
        answer: 'Good morning',
        choices: ['Good morning', 'Good evening', 'Thank you', 'Please'],
        targetPhrase: 'Maayong aga',
        targetMeaning: 'Good morning',
        directionLabel: 'Hiligaynon to English',
      ),
      _TranslationSentenceSeed(
        prompt: 'Translate: "Nagakaon ako."',
        answer: 'I am eating',
        choices: [
          'I am eating',
          'I am sleeping',
          'I am reading',
          'I am walking',
        ],
        targetPhrase: 'Nagakaon ako',
        targetMeaning: 'I am eating',
        directionLabel: 'Hiligaynon to English',
      ),
      _TranslationSentenceSeed(
        prompt: 'Translate: "Salamat gid."',
        answer: 'Thank you very much',
        choices: [
          'Thank you very much',
          'Good afternoon',
          'I am eating',
          'Where are you',
        ],
        targetPhrase: 'Salamat gid',
        targetMeaning: 'Thank you very much',
        directionLabel: 'Hiligaynon to English',
      ),
      _TranslationSentenceSeed(
        prompt: 'Translate: "Good evening."',
        answer: 'Maayong gab-i',
        choices: ['Maayong gab-i', 'Maayong aga', 'Palihog', 'Indi'],
        targetPhrase: 'Good evening',
        targetMeaning: 'Maayong gab-i',
        directionLabel: 'English to Hiligaynon',
      ),
      _TranslationSentenceSeed(
        prompt: 'Translate: "I am reading."',
        answer: 'Nagabasa ako',
        choices: ['Nagabasa ako', 'Nagakaon ako', 'Nagainom ako', 'Dagan ako'],
        targetPhrase: 'I am reading',
        targetMeaning: 'Nagabasa ako',
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
  const _PracticeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TudloColors.softGreen, Colors.white],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: TudloColors.forest.withValues(alpha: .08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .85),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: TudloColors.brightGreen.withValues(alpha: .13),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(child: TudloMascot(size: 58)),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Practice Test',
                  style: TextStyle(
                    color: TudloColors.ink,
                    fontSize: 28,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Test your Hiligaynon skills by level.',
                  style: TextStyle(
                    color: TudloColors.muted,
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      key: ValueKey(value),
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
  final VoidCallback onTap;

  const _TestCard({
    required this.test,
    required this.meta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
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
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: test == 1
                          ? TudloColors.brightGreen
                          : TudloColors.softGreen,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      meta.icon,
                      color: test == 1 ? Colors.white : TudloColors.forest,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Test $test',
                                style: const TextStyle(
                                  color: TudloColors.ink,
                                  fontSize: 23,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (test == 1) ...[
                              const SizedBox(width: 8),
                              _SoftBadge(label: meta.tag),
                            ],
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '${meta.range} • 30 questions',
                          style: const TextStyle(
                            color: TudloColors.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _SoftBadge(label: meta.label),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      meta.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TudloColors.muted,
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: meta.progress,
                  minHeight: 10,
                  backgroundColor: TudloColors.line,
                  color: TudloColors.brightGreen,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: TudloColors.brightGreen,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: TudloColors.brightGreen.withValues(alpha: .22),
                        blurRadius: 14,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Start',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
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
  final String range;
  final String label;
  final String description;
  final double progress;
  final String tag;
  final IconData icon;

  const _TestMeta({
    required this.range,
    required this.label,
    required this.description,
    required this.progress,
    required this.tag,
    required this.icon,
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
