import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/mascot_widget.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank.dart';
import 'package:tudloapp/core/widgets/word_tooltip.dart';
import 'package:tudloapp/features/navigation/app_shell.dart';

/// Placement evaluation shown before the main Home Map.
///
/// Questions are randomly generated from the Lesson Bank. The final score is
/// stored in AppState and mapped to an internal Home Map dataset.
class EvaluationTestScreen extends StatefulWidget {
  const EvaluationTestScreen({super.key});

  @override
  State<EvaluationTestScreen> createState() => _EvaluationTestScreenState();
}

class _EvaluationTestScreenState extends State<EvaluationTestScreen> {
  // Generated once when the screen opens so the evaluation does not change
  // while the user is answering.
  late final List<LessonQuestion> questions =
      LessonBank.tutorialEvaluationQuestions();
  final Map<int, bool> _earnedPointByQuestion = {};
  final TextEditingController typedAnswerController = TextEditingController();
  int questionIndex = 0;
  int score = 0;

  String? selectedAnswer;
  final List<String> builtWords = [];
  String? selectedMatchLeft;
  String? wrongMatchLeft;
  String? wrongMatchRight;
  String? newMatchLeft;
  String? newMatchRight;
  Timer? _wrongMatchClearTimer;
  Timer? _matchedPulseTimer;
  int wrongMatchAttempt = 0;
  int matchPulseAttempt = 0;
  int answerFeedbackAttempt = 0;
  bool checked = false;
  bool lastCorrect = false;
  bool hadWrongMatchAttempt = false;
  final Map<String, String> matches = {};

  LessonQuestion get currentQuestion => questions[questionIndex];

  bool get canContinue {
    final q = currentQuestion;
    if (checked) return true;
    return switch (q.type) {
      QuestionType.matching => matches.length == q.leftItems.length,
      QuestionType.typedTranslation =>
        typedAnswerController.text.trim().isNotEmpty,
      QuestionType.arrangeWords || QuestionType.fillBlank =>
        builtWords.length >= _answerWords(q.answer).length,
      _ => selectedAnswer != null,
    };
  }

  bool get isCorrect {
    final q = currentQuestion;
    if (q.type == QuestionType.matching) {
      return !hadWrongMatchAttempt && _matchingCorrect(q);
    }
    if (q.type == QuestionType.typedTranslation) {
      return _normalizeAnswer(typedAnswerController.text) ==
          _normalizeAnswer(q.answer);
    }
    if (q.type == QuestionType.arrangeWords ||
        q.type == QuestionType.fillBlank) {
      return _normalizeAnswer(builtWords.join(' ')) ==
          _normalizeAnswer(q.answer);
    }
    return selectedAnswer == q.answer;
  }

  @override
  void dispose() {
    _wrongMatchClearTimer?.cancel();
    _matchedPulseTimer?.cancel();
    typedAnswerController.dispose();
    super.dispose();
  }

  void _nextQuestion() {
    if (!checked) {
      // First tap checks the answer and awards at most one point for the
      // current question.
      setState(() {
        lastCorrect = isCorrect;
        checked = true;
        answerFeedbackAttempt++;
        if (lastCorrect && _earnedPointByQuestion[questionIndex] != true) {
          score++;
          _earnedPointByQuestion[questionIndex] = true;
        }
      });
      return;
    }

    if (questionIndex < questions.length - 1) {
      setState(() {
        questionIndex++;
        _resetQuestionState();
      });
      return;
    }

    // After the last question, save the score so AppState can choose easy,
    // medium, or hard lesson content internally.
    AppStateScope.of(context).saveEvaluationScore(score);
    showEvaluationResultDialog(context: context);
  }

  void _resetQuestionState() {
    selectedAnswer = null;
    selectedMatchLeft = null;
    builtWords.clear();
    typedAnswerController.clear();
    _clearWrongMatch();
    _clearMatchedPulse();
    wrongMatchAttempt = 0;
    matchPulseAttempt = 0;
    answerFeedbackAttempt = 0;
    checked = false;
    lastCorrect = false;
    hadWrongMatchAttempt = false;
    matches.clear();
  }

  bool _matchingCorrect(LessonQuestion q) {
    for (var index = 0; index < q.leftItems.length; index++) {
      final left = q.leftItems[index];
      final expected = LessonBank.terms
          .firstWhere((term) => term.hil == left)
          .eng;
      if (matches[left] != expected) return false;
    }
    return true;
  }

  List<String> _answerWords(String answer) {
    return answer
        .replaceAll(RegExp(r'[.!?"]'), '')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  String _normalizeAnswer(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[.!?"]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void _selectMatchLeft(String left) {
    if (checked || matches.containsKey(left)) return;
    setState(() {
      selectedMatchLeft = selectedMatchLeft == left ? null : left;
      _clearWrongMatch();
    });
  }

  void _selectMatchRight(String right) {
    if (checked || selectedMatchLeft == null || matches.containsValue(right)) {
      return;
    }

    final left = selectedMatchLeft!;
    final expected = LessonBank.terms
        .firstWhere((term) => term.hil == left)
        .eng;
    setState(() {
      // Matching questions immediately store correct pairs. A wrong pair marks
      // the whole matching question wrong for scoring.
      if (expected == right) {
        matches[left] = right;
        _clearWrongMatch();
        newMatchLeft = left;
        newMatchRight = right;
        matchPulseAttempt++;
        _scheduleMatchedPulseClear(matchPulseAttempt);
      } else {
        hadWrongMatchAttempt = true;
        wrongMatchLeft = left;
        wrongMatchRight = right;
        wrongMatchAttempt++;
        _scheduleWrongMatchClear(wrongMatchAttempt);
      }
      selectedMatchLeft = null;
    });
  }

  void _clearWrongMatch() {
    _wrongMatchClearTimer?.cancel();
    _wrongMatchClearTimer = null;
    wrongMatchLeft = null;
    wrongMatchRight = null;
  }

  void _scheduleWrongMatchClear(int attempt) {
    _wrongMatchClearTimer?.cancel();
    _wrongMatchClearTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted || attempt != wrongMatchAttempt) return;
      setState(_clearWrongMatch);
    });
  }

  void _clearMatchedPulse() {
    _matchedPulseTimer?.cancel();
    _matchedPulseTimer = null;
    newMatchLeft = null;
    newMatchRight = null;
  }

  void _scheduleMatchedPulseClear(int attempt) {
    _matchedPulseTimer?.cancel();
    _matchedPulseTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted || attempt != matchPulseAttempt) return;
      setState(_clearMatchedPulse);
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (questionIndex + 1) / questions.length;
    final feedbackPhrase = _feedbackPhraseFor(currentQuestion);
    final feedbackMeaning = _feedbackMeaningFor(currentQuestion);
    final showMeaning = currentQuestion.type != QuestionType.matching;

    return Scaffold(
      backgroundColor: TudloColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 18,
                        backgroundColor: TudloColors.line,
                        color: TudloColors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '${questionIndex + 1}/${questions.length}',
                    style: const TextStyle(
                      color: TudloColors.forest,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Align(
                alignment: currentQuestion.type == QuestionType.fillBlank
                    ? Alignment.centerLeft
                    : Alignment.center,
                child: Text(
                  _titleFor(currentQuestion.type),
                  textAlign: currentQuestion.type == QuestionType.fillBlank
                      ? TextAlign.left
                      : TextAlign.center,
                  style: const TextStyle(
                    color: TudloColors.ink,
                    fontSize: 31,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Expanded(child: _exerciseArea(currentQuestion)),
              if (checked) ...[
                const SizedBox(height: 12),
                _FeedbackBanner(
                  correct: lastCorrect,
                  phrase: feedbackPhrase,
                  meaning: feedbackMeaning,
                  showDetails: showMeaning,
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: checked
                        ? TudloColors.green
                        : TudloColors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: TudloColors.line,
                    disabledForegroundColor: TudloColors.muted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: canContinue ? _nextQuestion : null,
                  child: Text(
                    checked
                        ? (questionIndex == questions.length - 1
                              ? 'FINISH'
                              : 'CONTINUE')
                        : 'CHECK',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _titleFor(QuestionType type) {
    return switch (type) {
      QuestionType.translationChoice => 'Choose the translation',
      QuestionType.imageChoice => currentQuestion.prompt,
      QuestionType.typedTranslation => 'Translate the sentence',
      QuestionType.arrangeWords => 'Arrange the words',
      QuestionType.matching => 'Match the words',
      QuestionType.fillBlank => 'Complete the sentence',
      _ => 'Choose the answer',
    };
  }

  String _feedbackPhraseFor(LessonQuestion question) {
    // Missing-word tutorial questions show the completed sentence after CHECK,
    // matching the real lesson game feedback.
    final match = RegExp(r'"([^"]+)"').firstMatch(question.prompt);
    final sentence = match?.group(1) ?? question.prompt;
    if (sentence.contains('___')) {
      return _fillBlanks(sentence, question.answer.split(' '));
    }
    return question.targetPhrase;
  }

  String _fillBlanks(String sentence, List<String> answers) {
    var index = 0;
    return sentence.replaceAllMapped(RegExp(r'_{3,}'), (_) {
      if (answers.isEmpty) return '';
      if (index >= answers.length) return answers.last;
      return answers[index++];
    });
  }

  String _feedbackMeaningFor(LessonQuestion question) {
    if (question.sentenceMeaning.trim().isNotEmpty) {
      return question.sentenceMeaning.trim();
    }
    return question.targetMeaning.trim();
  }

  Widget _buildQuestionBody(LessonQuestion q) {
    // Each evaluation question type uses a different interaction widget, but
    // all answers flow back into the same scoring state above.
    if (q.type == QuestionType.matching) {
      return _MatchingExercise(
        question: q,
        matches: matches,
        selectedLeft: selectedMatchLeft,
        wrongLeft: wrongMatchLeft,
        wrongRight: wrongMatchRight,
        wrongAttempt: wrongMatchAttempt,
        newMatchLeft: newMatchLeft,
        newMatchRight: newMatchRight,
        matchPulseAttempt: matchPulseAttempt,
        onSelectLeft: _selectMatchLeft,
        onSelectRight: _selectMatchRight,
      );
    }

    if (q.type == QuestionType.imageChoice) {
      return _ImageChoiceGrid(
        question: q,
        selected: selectedAnswer,
        checked: checked,
        onSelected: (value) {
          if (checked) return;
          setState(() => selectedAnswer = value);
        },
      );
    }

    if (q.type == QuestionType.typedTranslation) {
      return _TypedAnswerBox(
        controller: typedAnswerController,
        checked: checked,
        correct: checked && lastCorrect,
        answer: q.answer,
        onChanged: (_) => setState(() {}),
      );
    }

    if (q.type == QuestionType.arrangeWords ||
        q.type == QuestionType.fillBlank) {
      return _WordBuilderExercise(
        question: q,
        builtWords: builtWords,
        checked: checked,
        correct: checked && lastCorrect,
        onAddWord: (word) {
          if (checked) return;
          setState(() => builtWords.add(word));
        },
        onRemoveWord: (index) {
          if (checked) return;
          setState(() => builtWords.removeAt(index));
        },
      );
    }

    return _ChoiceList(
      choices: q.choices,
      selected: selectedAnswer,
      checked: checked,
      answer: q.answer,
      feedbackAttempt: answerFeedbackAttempt,
      choiceMeanings: {
        for (final choice in q.choices) choice: translatedMeaningFor(choice),
      },
      onSelected: (value) {
        if (checked) return;
        setState(() => selectedAnswer = value);
      },
    );
  }

  Widget _exerciseArea(LessonQuestion q) {
    if (q.type == QuestionType.matching) {
      return _buildQuestionBody(q);
    }

    if (q.type == QuestionType.imageChoice ||
        q.type == QuestionType.fillBlank) {
      return SingleChildScrollView(child: _buildQuestionBody(q));
    }

    if (q.type == QuestionType.arrangeWords) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PromptCard(question: q),
            const SizedBox(height: 18),
            _buildQuestionBody(q),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PromptCard(question: q),
          const SizedBox(height: 26),
          _buildQuestionBody(q),
        ],
      ),
    );
  }
}

Future<void> showEvaluationResultDialog({required BuildContext context}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: TudloColors.ink.withValues(alpha: .58),
    builder: (_) {
      return BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: const _EvaluationCompleteDialog(),
      );
    },
  );
}

class _EvaluationCompleteDialog extends StatelessWidget {
  const _EvaluationCompleteDialog();

  @override
  Widget build(BuildContext context) {
    final modalWidth = (MediaQuery.sizeOf(context).width * .86)
        .clamp(304.0, 384.0)
        .toDouble();
    final bannerWidth = (modalWidth * .64).clamp(210.0, 260.0).toDouble();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      backgroundColor: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: .92, end: 1),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Opacity(
            opacity: ((value - .92) / .08).clamp(0, 1),
            child: Transform.scale(scale: value, child: child),
          );
        },
        child: SizedBox(
          width: modalWidth,
          height: 350,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 54),
                padding: const EdgeInsets.fromLTRB(22, 82, 22, 22),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFCF7),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: TudloColors.green.withValues(alpha: .20),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .20),
                      blurRadius: 34,
                      offset: const Offset(0, 18),
                    ),
                    BoxShadow(
                      color: TudloColors.green.withValues(alpha: .12),
                      blurRadius: 22,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    const Positioned(
                      left: 8,
                      top: 8,
                      child: _SoftSparkle(size: 16, opacity: .28),
                    ),
                    const Positioned(
                      right: 18,
                      top: 34,
                      child: _SoftSparkle(size: 12, opacity: .22),
                    ),
                    Column(
                      children: [
                        const Spacer(),
                        const Text(
                          "Let's get started",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: TudloColors.ink,
                            fontSize: 30,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Your lessons are ready.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: TudloColors.muted.withValues(alpha: .92),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        _ResultContinueButton(
                          onPressed: () {
                            // Continue button:
                            // After the evaluation result is shown, this clears
                            // the onboarding routes and directs the user to the
                            // Home Map inside the main AppShell.
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AppShell(initialIndex: 0),
                              ),
                              (route) => false,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 18,
                top: 6,
                child: Transform.rotate(
                  angle: -.10,
                  child: const SizedBox(
                    width: 92,
                    height: 92,
                    child: TudloMascot(size: 92),
                  ),
                ),
              ),
              Positioned(
                top: 34,
                child: Container(
                  width: bannerWidth,
                  height: 72,
                  decoration: BoxDecoration(
                    color: TudloColors.green,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .70),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: TudloColors.green.withValues(alpha: .22),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Wow!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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

class _ResultContinueButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ResultContinueButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 66,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: TudloColors.green,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
        ),
        child: const Text('Continue'),
      ),
    );
  }
}

class _SoftSparkle extends StatelessWidget {
  final double size;
  final double opacity;

  const _SoftSparkle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.auto_awesome_rounded,
      color: TudloColors.green.withValues(alpha: opacity),
      size: size,
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  final bool correct;
  final String phrase;
  final String meaning;
  final bool showDetails;

  const _FeedbackBanner({
    required this.correct,
    required this.phrase,
    required this.meaning,
    required this.showDetails,
  });

  @override
  Widget build(BuildContext context) {
    final accent = correct ? TudloColors.green : TudloColors.coral;
    final title = correct ? 'Excellent!' : 'Try again';
    final subtitle = correct ? "You're correct!" : 'Check the answer below.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: correct
            ? TudloColors.softGreen.withValues(alpha: .92)
            : TudloColors.coral.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: .22), width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const TudloMascot(size: 92),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accent,
                    fontSize: 30,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: accent,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (showDetails) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          phrase,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: TudloColors.ink,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.volume_up_rounded, color: accent, size: 26),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (meaning.trim().isNotEmpty)
                    Text(
                      meaning,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TudloColors.muted,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  final LessonQuestion question;

  const _PromptCard({required this.question});

  @override
  Widget build(BuildContext context) {
    // Same prompt layout as the real lesson game: Koka speaks the question in
    // a rounded bubble, with a speaker icon at the start of the prompt.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(
            width: 108,
            height: 130,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: TudloMascot(size: 112),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 8, bottom: 10),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: TudloColors.line, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: TudloColors.ink.withValues(alpha: .08),
                    blurRadius: 18,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2, right: 12),
                    child: Icon(
                      Icons.volume_up_rounded,
                      color: TudloColors.green,
                      size: 34,
                    ),
                  ),
                  Expanded(child: _PromptText(question: question)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptText extends StatelessWidget {
  final LessonQuestion question;

  const _PromptText({required this.question});

  @override
  Widget build(BuildContext context) {
    final promptText = _displayPrompt(question.prompt);
    const style = TextStyle(
      color: TudloColors.ink,
      fontSize: 27,
      height: 1.2,
      fontWeight: FontWeight.w900,
    );

    if (question.type == QuestionType.arrangeWords) {
      return Text(promptText, style: style);
    }

    if (question.targetPhrase.trim().isEmpty ||
        question.targetMeaning.trim().isEmpty) {
      return Text(promptText, style: style);
    }

    return TapWordMeaningText(
      fullQuestionText: promptText,
      targetPhrase: question.targetPhrase,
      targetMeaning: question.targetMeaning,
      directionLabel: question.directionLabel,
      style: style,
      includeKnownWords: true,
    );
  }

  String _displayPrompt(String prompt) {
    final match = RegExp(r'"([^"]+)"').firstMatch(prompt);
    final quoted = match?.group(1);
    return quoted == null ? _quoteOnce(prompt) : _quoteOnce(quoted);
  }

  String _quoteOnce(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('"') && trimmed.endsWith('"')) return trimmed;
    return '"$trimmed"';
  }
}

class _ChoiceList extends StatelessWidget {
  final List<String> choices;
  final String? selected;
  final bool checked;
  final String answer;
  final int feedbackAttempt;
  final Map<String, String> choiceMeanings;
  final ValueChanged<String> onSelected;

  const _ChoiceList({
    required this.choices,
    required this.selected,
    required this.checked,
    required this.answer,
    required this.feedbackAttempt,
    required this.choiceMeanings,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: choices.map((choice) {
        final active = selected == choice;
        final correct = checked && active && choice == answer;
        final wrong = checked && active && choice != answer;
        return _AnswerTile(
          label: choice,
          active: active,
          correct: correct,
          wrong: wrong,
          feedbackKey: active ? feedbackAttempt : 0,
          longPressMeaning: choiceMeanings[choice] ?? choice,
          onTap: checked ? null : () => onSelected(choice),
        );
      }).toList(),
    );
  }
}

class _ImageChoiceGrid extends StatelessWidget {
  final LessonQuestion question;
  final String? selected;
  final bool checked;
  final ValueChanged<String> onSelected;

  const _ImageChoiceGrid({
    required this.question,
    required this.selected,
    required this.checked,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cards = question.imageChoices.take(4).map((choice) {
      final active = selected == choice.hil;
      final correct = checked && active && choice.hil == question.answer;
      final wrong = checked && active && choice.hil != question.answer;

      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: checked ? null : () => onSelected(choice.hil),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: correct
                  ? TudloColors.green.withValues(alpha: .10)
                  : wrong
                  ? TudloColors.coral.withValues(alpha: .08)
                  : active
                  ? TudloColors.green.withValues(alpha: .08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: correct || active
                    ? TudloColors.green
                    : wrong
                    ? TudloColors.coral
                    : TudloColors.line,
                width: correct || wrong || active ? 4 : 3,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Image.asset(
                    choice.imagePath ?? '',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  choice.hil,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: wrong ? TudloColors.coral : TudloColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();

    while (cards.length < 4) {
      cards.add(const Expanded(child: SizedBox.shrink()));
    }

    return SizedBox(
      height: 520,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [cards[0], const SizedBox(width: 14), cards[1]],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              children: [cards[2], const SizedBox(width: 14), cards[3]],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypedAnswerBox extends StatelessWidget {
  final TextEditingController controller;
  final bool checked;
  final bool correct;
  final String answer;
  final ValueChanged<String> onChanged;

  const _TypedAnswerBox({
    required this.controller,
    required this.checked,
    required this.correct,
    required this.answer,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = checked
        ? correct
              ? TudloColors.green
              : TudloColors.coral
        : TudloColors.line;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor, width: 4),
          ),
          child: TextField(
            controller: controller,
            readOnly: checked,
            minLines: 3,
            maxLines: 4,
            cursorColor: TudloColors.green,
            onChanged: onChanged,
            style: const TextStyle(
              color: TudloColors.ink,
              fontSize: 23,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Type the translation here',
              hintStyle: TextStyle(
                color: TudloColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        if (checked && !correct) ...[
          const SizedBox(height: 12),
          Text(
            'Correct answer: $answer',
            style: const TextStyle(
              color: TudloColors.forest,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
    );
  }
}

class _WordBuilderExercise extends StatelessWidget {
  final LessonQuestion question;
  final List<String> builtWords;
  final bool checked;
  final bool correct;
  final ValueChanged<String> onAddWord;
  final ValueChanged<int> onRemoveWord;

  const _WordBuilderExercise({
    required this.question,
    required this.builtWords,
    required this.checked,
    required this.correct,
    required this.onAddWord,
    required this.onRemoveWord,
  });

  @override
  Widget build(BuildContext context) {
    if (question.type == QuestionType.fillBlank) {
      return _ScenarioFillBlankExercise(
        question: question,
        builtWords: builtWords,
        checked: checked,
        correct: correct,
        onAddWord: onAddWord,
        onRemoveWord: onRemoveWord,
      );
    }

    return _BuildSentenceExercise(
      question: question,
      builtWords: builtWords,
      checked: checked,
      correct: correct,
      onAddWord: onAddWord,
      onRemoveWord: onRemoveWord,
    );
  }
}

class _ScenarioFillBlankExercise extends StatelessWidget {
  final LessonQuestion question;
  final List<String> builtWords;
  final bool checked;
  final bool correct;
  final ValueChanged<String> onAddWord;
  final ValueChanged<int> onRemoveWord;

  const _ScenarioFillBlankExercise({
    required this.question,
    required this.builtWords,
    required this.checked,
    required this.correct,
    required this.onAddWord,
    required this.onRemoveWord,
  });

  @override
  Widget build(BuildContext context) {
    final available = [...question.choices];
    for (final word in builtWords) {
      available.remove(word);
    }
    final sentence = _missingSentenceFrom(question.prompt);

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasImage = question.imagePath.trim().isNotEmpty;
        final imageHeight = hasImage
            ? (constraints.maxHeight * .46).clamp(260.0, 360.0).toDouble()
            : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasImage) ...[
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 500,
                    maxHeight: imageHeight,
                  ),
                  child: Image.asset(
                    question.imagePath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            _ScenarioSentenceText(
              sentence: sentence,
              builtWords: builtWords,
              checked: checked,
              correct: correct,
              wordMeanings: question.wordMeanings,
              onRemoveWord: onRemoveWord,
            ),
            const SizedBox(height: 24),
            _ScenarioWordChoices(
              choices: available,
              checked: checked,
              answerWords: question.answer.split(' '),
              wordMeanings: question.wordMeanings,
              onAdd: onAddWord,
            ),
          ],
        );
      },
    );
  }

  String _missingSentenceFrom(String prompt) {
    final match = RegExp(r'"([^"]+)"').firstMatch(prompt);
    return match?.group(1) ?? prompt;
  }
}

class _ScenarioSentenceText extends StatelessWidget {
  final String sentence;
  final List<String> builtWords;
  final bool checked;
  final bool correct;
  final Map<String, String> wordMeanings;
  final ValueChanged<int> onRemoveWord;

  const _ScenarioSentenceText({
    required this.sentence,
    required this.builtWords,
    required this.checked,
    required this.correct,
    required this.wordMeanings,
    required this.onRemoveWord,
  });

  @override
  Widget build(BuildContext context) {
    var blankIndex = 0;
    final words = sentence.split(RegExp(r'\s+'));

    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 9,
      runSpacing: 16,
      children: words.map((word) {
        if (word.contains('___')) {
          final currentBlank = blankIndex;
          final suffix = word.replaceFirst(RegExp(r'_{3,}'), '');
          final selectedWord = blankIndex < builtWords.length
              ? builtWords[blankIndex]
              : '';
          final chip = _ScenarioBlankChip(
            label: selectedWord,
            checked: checked,
            correct: correct,
            onTap: selectedWord.isEmpty || checked
                ? null
                : () => onRemoveWord(currentBlank),
          );
          blankIndex++;
          if (suffix.isEmpty) return chip;
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              chip,
              Text(
                suffix,
                style: const TextStyle(
                  color: TudloColors.ink,
                  fontSize: 25,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          );
        }

        final key = _meaningKeyFor(word);
        final meaning = wordMeanings[key] ?? '';
        final text = Text(
          word,
          style: TextStyle(
            color: TudloColors.ink,
            fontSize: 25,
            height: 1.15,
            fontWeight: FontWeight.w900,
            decoration: meaning.isEmpty ? null : TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dotted,
            decorationColor: TudloColors.brightGreen,
            decorationThickness: 2,
          ),
        );
        return meaning.isEmpty
            ? text
            : WordMeaningTooltipTarget(
                meaning: meaning,
                showOnTap: true,
                child: text,
              );
      }).toList(),
    );
  }

  String _meaningKeyFor(String word) {
    return word.replaceAll(RegExp(r'^[^\w-]+|[^\w-]+$'), '');
  }
}

class _ScenarioBlankChip extends StatelessWidget {
  final String label;
  final bool checked;
  final bool correct;
  final VoidCallback? onTap;

  const _ScenarioBlankChip({
    required this.label,
    required this.checked,
    required this.correct,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasWord = label.trim().isNotEmpty;
    final color = checked
        ? correct
              ? TudloColors.green
              : TudloColors.coral
        : TudloColors.green;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 82, minHeight: 38),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: hasWord ? color.withValues(alpha: .12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: hasWord
              ? Border.all(color: color.withValues(alpha: .72), width: 2.5)
              : Border(
                  bottom: BorderSide(
                    color: TudloColors.muted.withValues(alpha: .55),
                    width: 3,
                  ),
                ),
        ),
        child: Text(
          hasWord ? label : '',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: checked && !correct ? TudloColors.coral : TudloColors.ink,
            fontSize: 22,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ScenarioWordChoices extends StatelessWidget {
  final List<String> choices;
  final bool checked;
  final List<String> answerWords;
  final Map<String, String> wordMeanings;
  final ValueChanged<String> onAdd;

  const _ScenarioWordChoices({
    required this.choices,
    required this.checked,
    required this.answerWords,
    required this.wordMeanings,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: choices.map((choice) {
        final canRevealMeaning = !answerWords.any(
          (answer) => answer.toLowerCase() == choice.toLowerCase(),
        );
        final chip = ActionChip(
          label: Text(choice),
          labelPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: TudloColors.line, width: 2.5),
          ),
          labelStyle: const TextStyle(
            color: TudloColors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
          onPressed: checked ? () {} : () => onAdd(choice),
        );
        final meaning = canRevealMeaning ? wordMeanings[choice] ?? '' : '';
        return meaning.isEmpty
            ? chip
            : WordMeaningTooltipTarget(meaning: meaning, child: chip);
      }).toList(),
    );
  }
}

class _BuildSentenceExercise extends StatelessWidget {
  final LessonQuestion question;
  final List<String> builtWords;
  final bool checked;
  final bool correct;
  final ValueChanged<String> onAddWord;
  final ValueChanged<int> onRemoveWord;

  const _BuildSentenceExercise({
    required this.question,
    required this.builtWords,
    required this.checked,
    required this.correct,
    required this.onAddWord,
    required this.onRemoveWord,
  });

  @override
  Widget build(BuildContext context) {
    final available = [...question.sentenceWords];
    for (final word in builtWords) {
      available.remove(word);
    }

    const imageHeight = 170.0;
    final answerHeight = checked ? 150.0 : 120.0;
    final wordBlockHeight = checked ? 24.0 : 120.0;
    final hasImage = question.imagePath.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImage) ...[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 520,
                maxHeight: imageHeight,
              ),
              child: Image.asset(
                question.imagePath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          width: double.infinity,
          height: answerHeight,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: answerHeight * .38,
                child: const _BuildSentenceLine(),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: answerHeight * .76,
                child: const _BuildSentenceLine(),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 7,
                  children: builtWords.asMap().entries.map((entry) {
                    return ActionChip(
                      label: Text(entry.value),
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 7,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.white,
                      disabledColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(
                          color: TudloColors.line,
                          width: 2.5,
                        ),
                      ),
                      labelStyle: const TextStyle(
                        color: TudloColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                      onPressed: checked
                          ? () {}
                          : () => onRemoveWord(entry.key),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: wordBlockHeight,
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: available.map((word) {
                return WordMeaningTooltipTarget(
                  meaning: translatedMeaningFor(word),
                  child: ActionChip(
                    label: Text(word),
                    labelPadding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 7,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(
                        color: TudloColors.line,
                        width: 2.5,
                      ),
                    ),
                    labelStyle: const TextStyle(
                      color: TudloColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                    onPressed: checked ? () {} : () => onAddWord(word),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _BuildSentenceLine extends StatelessWidget {
  const _BuildSentenceLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 4,
      decoration: BoxDecoration(
        color: TudloColors.line.withValues(alpha: .78),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _MatchingExercise extends StatelessWidget {
  final LessonQuestion question;
  final Map<String, String> matches;
  final String? selectedLeft;
  final String? wrongLeft;
  final String? wrongRight;
  final int wrongAttempt;
  final String? newMatchLeft;
  final String? newMatchRight;
  final int matchPulseAttempt;
  final ValueChanged<String> onSelectLeft;
  final ValueChanged<String> onSelectRight;

  const _MatchingExercise({
    required this.question,
    required this.matches,
    required this.selectedLeft,
    required this.wrongLeft,
    required this.wrongRight,
    required this.wrongAttempt,
    required this.newMatchLeft,
    required this.newMatchRight,
    required this.matchPulseAttempt,
    required this.onSelectLeft,
    required this.onSelectRight,
  });

  @override
  Widget build(BuildContext context) {
    final leftItems = question.leftItems;
    final rightItems = question.rightItems;
    final usedRight = matches.values.toSet();
    final maxRows = leftItems.length > rightItems.length
        ? leftItems.length
        : rightItems.length;

    return Column(
      children: List.generate(maxRows, (index) {
        final left = index < leftItems.length ? leftItems[index] : null;
        final right = index < rightItems.length ? rightItems[index] : null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Expanded(
                child: left == null
                    ? const SizedBox(height: 76)
                    : _MatchTile(
                        label: left,
                        selected: selectedLeft == left,
                        matched: matches.containsKey(left),
                        wrong: wrongLeft == left,
                        justMatched: newMatchLeft == left,
                        shakeKey: wrongLeft == left ? wrongAttempt : 0,
                        jumpKey: newMatchLeft == left ? matchPulseAttempt : 0,
                        onTap: () => onSelectLeft(left),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: right == null
                    ? const SizedBox(height: 76)
                    : _MatchTile(
                        label: right,
                        selected: false,
                        matched: usedRight.contains(right),
                        wrong: wrongRight == right,
                        justMatched: newMatchRight == right,
                        shakeKey: wrongRight == right ? wrongAttempt : 0,
                        jumpKey: newMatchRight == right ? matchPulseAttempt : 0,
                        onTap: () => onSelectRight(right),
                        compact: true,
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _MatchTile extends StatelessWidget {
  final String label;
  final bool selected;
  final bool matched;
  final bool wrong;
  final bool justMatched;
  final int shakeKey;
  final int jumpKey;
  final bool compact;
  final VoidCallback onTap;

  const _MatchTile({
    required this.label,
    required this.selected,
    required this.matched,
    required this.wrong,
    required this.justMatched,
    required this.shakeKey,
    required this.jumpKey,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final active = selected || matched || wrong || justMatched;
    final borderColor = wrong
        ? TudloColors.coral
        : justMatched
        ? TudloColors.green
        : matched
        ? TudloColors.line
        : active
        ? TudloColors.green
        : TudloColors.line;
    final textColor = justMatched
        ? TudloColors.green
        : matched
        ? TudloColors.muted
        : wrong
        ? TudloColors.coral
        : TudloColors.ink;
    final backgroundColor = wrong
        ? TudloColors.coral.withValues(alpha: .08)
        : justMatched
        ? TudloColors.green.withValues(alpha: .10)
        : matched
        ? TudloColors.paper
        : active
        ? TudloColors.green.withValues(alpha: .08)
        : Colors.white;
    final shadowColor = wrong ? TudloColors.coral : TudloColors.green;

    return WordMeaningTooltipTarget(
      meaning: translatedMeaningFor(label),
      child: TweenAnimationBuilder<double>(
        key: ValueKey('$label-$shakeKey-$jumpKey'),
        tween: Tween(begin: 0, end: (wrong || justMatched) ? 1 : 0),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          final shakeOffset = wrong
              ? math.sin(value * math.pi * 6) * (1 - value) * 9
              : 0.0;
          final jumpOffset = justMatched
              ? -math.sin(value * math.pi) * (1 - value * .25) * 10
              : 0.0;

          return Transform.translate(
            offset: Offset(shakeOffset, jumpOffset),
            child: child,
          );
        },
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: matched ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: active ? 4 : 3),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: shadowColor.withValues(alpha: .16),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: compact ? 17 : 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  final String label;
  final bool active;
  final bool correct;
  final bool wrong;
  final int feedbackKey;
  final String longPressMeaning;
  final VoidCallback? onTap;

  const _AnswerTile({
    required this.label,
    required this.active,
    required this.correct,
    required this.wrong,
    required this.feedbackKey,
    required this.longPressMeaning,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = correct
        ? TudloColors.green
        : wrong
        ? TudloColors.coral
        : active
        ? TudloColors.green
        : TudloColors.line;
    final backgroundColor = correct
        ? TudloColors.green.withValues(alpha: .10)
        : wrong
        ? TudloColors.coral.withValues(alpha: .08)
        : active
        ? TudloColors.sky.withValues(alpha: .12)
        : Colors.white;

    return WordMeaningTooltipTarget(
      meaning: longPressMeaning,
      child: _FeedbackMotion(
        key: ValueKey('$label-$feedbackKey'),
        correct: correct,
        wrong: wrong,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            constraints: const BoxConstraints(minHeight: 84),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 19),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: borderColor, width: 4),
            ),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: wrong ? TudloColors.coral : TudloColors.ink,
                  fontSize: 24,
                  fontWeight: active ? FontWeight.w900 : FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackMotion extends StatelessWidget {
  final bool correct;
  final bool wrong;
  final Widget child;

  const _FeedbackMotion({
    super.key,
    required this.correct,
    required this.wrong,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: (correct || wrong) ? 1 : 0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        final shakeOffset = wrong
            ? math.sin(value * math.pi * 6) * (1 - value) * 9
            : 0.0;
        final jumpOffset = correct
            ? -math.sin(value * math.pi) * (1 - value * .25) * 10
            : 0.0;

        return Transform.translate(
          offset: Offset(shakeOffset, jumpOffset),
          child: child,
        );
      },
      child: child,
    );
  }
}
