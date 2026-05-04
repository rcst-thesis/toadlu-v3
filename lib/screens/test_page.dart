import 'package:flutter/material.dart';
import '../app_data.dart';
import '../app_theme.dart';
import '../lesson_bank.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  int? selectedTest;
  int questionIndex = 0;
  int score = 0;
  String? selectedAnswer;
  bool checked = false;
  late List<_TestQuestion> questions = _buildTestQuestions(1);

  void _startTest(int test) {
    setState(() {
      selectedTest = test;
      questions = _buildTestQuestions(test);
      questionIndex = 0;
      score = 0;
      selectedAnswer = null;
      checked = false;
      AppData.testTutorialDone = true;
    });
  }

  void _next() {
    if (!checked) {
      setState(() {
        checked = true;
        if (selectedAnswer == questions[questionIndex].answer) score++;
      });
      return;
    }

    if (questionIndex < questions.length - 1) {
      setState(() {
        questionIndex++;
        selectedAnswer = null;
        checked = false;
      });
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Test complete'),
        content: Text('You scored $score out of ${questions.length}.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => selectedTest = null);
            },
            child: const Text('Choose another test'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TudloColors.cloud,
      body: SafeArea(
        child: selectedTest == null ? _buildPicker() : _buildQuiz(),
      ),
    );
  }

  Widget _buildPicker() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 112),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Practice Test',
            style: TextStyle(
              color: TudloColors.ink,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose one test. Each test has 30 questions from Level 1 to Level 3.',
            style: TextStyle(
              color: TudloColors.muted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          for (var test = 1; test <= 3; test++) ...[
            _TestCard(test: test, onTap: () => _startTest(test)),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildQuiz() {
    final question = questions[questionIndex];
    final progress = (questionIndex + 1) / questions.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 112),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => selectedTest = null),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: TudloColors.ink,
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 14,
                    backgroundColor: Colors.white,
                    color: TudloColors.forest,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Test $selectedTest - Question ${questionIndex + 1}/30',
            style: const TextStyle(
              color: TudloColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          TudloCard(
            padding: const EdgeInsets.all(20),
            child: Text(
              question.prompt,
              style: const TextStyle(
                color: TudloColors.ink,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(
              children: question.choices.map((choice) {
                final selected = selectedAnswer == choice;
                final correct = checked && choice == question.answer;
                final wrong = checked && selected && choice != question.answer;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: checked
                        ? null
                        : () => setState(() => selectedAnswer = choice),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: correct
                            ? TudloColors.green.withValues(alpha: .12)
                            : wrong
                            ? TudloColors.coral.withValues(alpha: .12)
                            : selected
                            ? TudloColors.sky.withValues(alpha: .12)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: correct
                              ? TudloColors.green
                              : wrong
                              ? TudloColors.coral
                              : selected
                              ? TudloColors.sky
                              : TudloColors.line,
                          width: 3,
                        ),
                      ),
                      child: Text(
                        choice,
                        style: const TextStyle(
                          color: TudloColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: selectedAnswer == null ? null : _next,
              child: Text(
                checked
                    ? questionIndex == questions.length - 1
                          ? 'FINISH'
                          : 'CONTINUE'
                    : 'CHECK',
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_TestQuestion> _buildTestQuestions(int test) {
    final terms = <LessonTerm>[
      ...LessonBank.termsForLevel(1),
      ...LessonBank.termsForLevel(2),
      ...LessonBank.termsForLevel(3),
    ];
    final unique = <String, LessonTerm>{
      for (final term in terms) term.hil: term,
    }.values.toList();
    final rotated = [
      ...unique.skip((test - 1) * 2),
      ...unique.take((test - 1) * 2),
    ];

    return List.generate(30, (index) {
      final term = rotated[index % rotated.length];
      final choices = <String>{term.eng};
      var i = index + test;
      while (choices.length < 4) {
        choices.add(unique[i % unique.length].eng);
        i += 3;
      }
      return _TestQuestion(
        prompt: 'What is the English meaning of "${term.hil}"?',
        answer: term.eng,
        choices: choices.toList()..sort(),
      );
    });
  }
}

class _TestCard extends StatelessWidget {
  final int test;
  final VoidCallback onTap;

  const _TestCard({required this.test, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: TudloCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: TudloColors.green.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.fact_check_rounded,
                color: TudloColors.green,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test $test',
                    style: const TextStyle(
                      color: TudloColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    '30 questions - Levels 1 to 3',
                    style: TextStyle(
                      color: TudloColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_arrow_rounded, color: TudloColors.sky),
          ],
        ),
      ),
    );
  }
}

class _TestQuestion {
  final String prompt;
  final String answer;
  final List<String> choices;

  const _TestQuestion({
    required this.prompt,
    required this.answer,
    required this.choices,
  });
}
