import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/mascot_widget.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank.dart';
import 'package:tudloapp/core/widgets/word_tooltip.dart';
import 'package:tudloapp/features/energy/widgets/energy_indicator.dart';
import 'package:tudloapp/features/navigation/app_shell.dart';

/// Main lesson gameplay screen opened from the Home Map.
///
/// A level receives generated questions from LessonBank. Difficulty is based
/// on the level's position inside its unit: 1-2 easy, 3-4 mid, 5-6 hard.
class LevelGamePage extends StatefulWidget {
  final int level;

  const LevelGamePage({super.key, required this.level});

  @override
  State<LevelGamePage> createState() => _LevelGamePageState();
}

class _LevelGamePageState extends State<LevelGamePage> {
  late final List<LessonQuestion> questions;
  int score = 0;
  int questionIndex = 0;
  late final DateTime _levelStartedAt;

  // Shared answer state. Only one of these groups is active at a time,
  // depending on the current question type.
  String? selectedAnswer;
  String? selectedMatchLeft;
  String? wrongMatchLeft;
  String? wrongMatchRight;
  Timer? _wrongMatchClearTimer;
  Timer? _matchedPulseTimer;
  final TextEditingController typedAnswerController = TextEditingController();
  int wrongMatchAttempt = 0;
  String? newMatchLeft;
  String? newMatchRight;
  int matchPulseAttempt = 0;
  int answerFeedbackAttempt = 0;
  bool checked = false;
  bool lastCorrect = false;
  bool _levelFinished = false;
  bool _rewardsClaimed = false;
  final Map<String, String> matches = {};
  final List<String> builtWords = [];

  @override
  void initState() {
    super.initState();
    // Generate questions once for this level. Keeping them in a field prevents
    // the set from changing while the user answers.
    questions = LessonBank.questionsForLevel(widget.level);
    _levelStartedAt = DateTime.now();
  }

  @override
  void dispose() {
    _wrongMatchClearTimer?.cancel();
    _matchedPulseTimer?.cancel();
    typedAnswerController.dispose();
    super.dispose();
  }

  LessonQuestion get currentQuestion => questions[questionIndex];

  bool get canContinue {
    final q = currentQuestion;
    // CHECK stays disabled until the user has done the required interaction
    // for the active question type.
    return switch (q.type) {
      QuestionType.matching => matches.length == q.leftItems.length,
      QuestionType.typedTranslation =>
        typedAnswerController.text.trim().isNotEmpty,
      QuestionType.fillBlank => builtWords.length >= q.answer.split(' ').length,
      QuestionType.arrangeWords =>
        builtWords.length >= q.answer.split(' ').length,
      QuestionType.buildSentence =>
        builtWords.length >= q.answer.split(' ').length,
      _ => selectedAnswer != null,
    };
  }

  bool get isCorrect {
    final q = currentQuestion;
    // Each question type stores its answer differently, so correctness is
    // centralized here instead of spread across the UI widgets.
    return switch (q.type) {
      QuestionType.matching => _matchingCorrect(q),
      QuestionType.typedTranslation =>
        _normalizeAnswer(typedAnswerController.text) ==
            _normalizeAnswer(q.answer),
      QuestionType.fillBlank =>
        _normalizeAnswer(builtWords.join(' ')) == _normalizeAnswer(q.answer),
      QuestionType.arrangeWords =>
        _normalizeAnswer(builtWords.join(' ')) == _normalizeAnswer(q.answer),
      QuestionType.buildSentence =>
        _normalizeAnswer(builtWords.join(' ')) == _normalizeAnswer(q.answer),
      _ => selectedAnswer == q.answer,
    };
  }

  bool _matchingCorrect(LessonQuestion q) {
    // Matching answers are checked against LessonBank terms because the
    // question only stores Hiligaynon left-side values.
    for (final left in q.leftItems) {
      final term = LessonBank.terms.firstWhere((term) => term.hil == left);
      if (matches[left] != term.eng) return false;
    }
    return true;
  }

  Future<void> nextQuestion() async {
    if (!checked) {
      // Each question costs one energy when CHECK is pressed. Energy spending
      // happens once per question before feedback appears, independent of
      // whether the answer is correct.
      final spent = await AppData.spendQuestionEnergy();
      if (!spent) {
        if (mounted) await showLowEnergyDialog(context);
        return;
      }
      // First press validates the answer and shows feedback.
      setState(() {
        lastCorrect = isCorrect;
        checked = true;
        answerFeedbackAttempt++;
        if (lastCorrect) score++;
      });
      return;
    }

    if (questionIndex < questions.length - 1) {
      // Second press advances to the next question and resets type-specific UI
      // state so selections do not leak between questions.
      setState(() {
        questionIndex++;
        selectedAnswer = null;
        selectedMatchLeft = null;
        _clearWrongMatch();
        _clearMatchedPulse();
        checked = false;
        lastCorrect = false;
        answerFeedbackAttempt = 0;
        matches.clear();
        builtWords.clear();
        typedAnswerController.clear();
      });
      return;
    }

    if (_levelFinished) return;
    _levelFinished = true;
    _showCompleteDialog();
  }

  void _claimRewardsOnce() {
    if (_rewardsClaimed) return;
    _rewardsClaimed = true;

    // Progress is saved only when the learner taps the completion button.
    // This prevents repeated FINISH/dialog interactions from saving twice.
    AppData.saveLevelScore(widget.level, score, questions.length);
    if (AppData.unlockedLevel <= widget.level &&
        widget.level < AppData.maxLevel) {
      AppData.unlockedLevel = widget.level + 1;
    }
  }

  void _showCompleteDialog() {
    // The completion dialog shows lesson results. Progress updates only after
    // the learner taps Continue.
    final accuracy = questions.isEmpty
        ? 0
        : ((score / questions.length) * 100).round();
    final durationLabel = _formatDuration(
      DateTime.now().difference(_levelStartedAt),
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: TudloColors.ink.withValues(alpha: .62),
      builder: (_) => _LessonCompleteDialog(
        level: widget.level,
        accuracy: accuracy,
        mistakes: questions.length - score,
        durationLabel: durationLabel,
        onClaim: () {
          // Continue button:
          // Claims rewards once, then directs the learner back to the Home Map
          // tab inside AppShell.
          _claimRewardsOnce();
          Navigator.pop(context);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AppShell(initialIndex: 0)),
            (route) => false,
          );
        },
      ),
    );
  }

  String _feedbackPhraseFor(LessonQuestion question) {
    // For missing-word questions, show the full completed sentence in the
    // feedback area instead of only the clue word.
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
      if (index >= answers.length) return answers.last;
      return answers[index++];
    });
  }

  String _feedbackMeaningFor(LessonQuestion question) {
    // These translations are used only for the feedback box after answering.
    // The question prompt still uses the shorter blank sentence.
    if (question.sentenceMeaning.trim().isNotEmpty) {
      return question.sentenceMeaning.trim();
    }
    final phrase = _feedbackPhraseFor(question);
    const meanings = {
      'Kumusta ka?': 'How are you',
      'Salamat gid.': 'Thank you',
      'Palihog, gusto ko sang tubig.': 'Please, I want water',
      'Nagkaon ako sang kan-on': 'I am eating rice',
      'Palihog hatag sang tubig': 'Please give the water',
      'Nagabasa ako sang libro': 'I am reading a book',
      'Nagakadto ako sa eskwelahan': 'I am going to school',
    };
    return meanings[_meaningKey(phrase)] ?? question.targetMeaning.trim();
  }

  String _meaningKey(String value) {
    return value.trim().replaceAll(RegExp(r'[.!?]+$'), '');
  }

  Future<void> _showPauseMenu() async {
    // Back icon button:
    // Opens a leave confirmation before discarding the current lesson attempt.
    // Exiting from this menu does not save level progress.
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierColor: TudloColors.ink.withValues(alpha: .55),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
            decoration: BoxDecoration(
              color: TudloColors.paper,
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: TudloColors.ink.withValues(alpha: .20),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -4,
                  top: -4,
                  child: IconButton(
                    tooltip: 'Stay here',
                    onPressed: () => Navigator.pop(dialogContext, false),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: TudloColors.muted,
                      size: 30,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    const TudloMascot(size: 138),
                    const SizedBox(height: 12),
                    const Text(
                      'Oh, you want to leave?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: TudloColors.ink,
                        fontSize: 29,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Finish your lesson, or you will lose all learning progress.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: TudloColors.muted,
                        fontSize: 18,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 58,
                            child: ElevatedButton(
                              // Leave button:
                              // Discards this attempt and returns to the
                              // previous page without saving progress.
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TudloColors.softGreen,
                                foregroundColor: TudloColors.green,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              child: const Text('Leave'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: SizedBox(
                            height: 58,
                            child: ElevatedButton(
                              // Stay here button:
                              // Closes the popup and resumes the lesson.
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TudloColors.green,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              child: const Text('Stay here'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || shouldExit != true) return;
    Navigator.pop(context);
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
                  IconButton(
                    // Back button:
                    // Opens the pause menu before leaving the game.
                    onPressed: _showPauseMenu,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: TudloColors.muted,
                      size: 34,
                    ),
                  ),
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
                  const SizedBox(width: 10),
                  const EnergyIndicator(),
                ],
              ),
              const SizedBox(height: 26),
              Align(
                alignment: currentQuestion.type == QuestionType.fillBlank
                    ? Alignment.centerLeft
                    : Alignment.center,
                child: Text(
                  currentQuestion.type == QuestionType.imageChoice
                      ? currentQuestion.prompt
                      : _titleFor(currentQuestion.type),
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
              Expanded(child: _questionContentArea(currentQuestion)),
              if (checked) ...[
                const SizedBox(height: 12),
                _AnswerFeedbackPanel(
                  correct: lastCorrect,
                  phrase: feedbackPhrase,
                  meaning: feedbackMeaning,
                  showDetails: showMeaning,
                ),
              ],
              const SizedBox(height: 16),
              _FeedbackMotion(
                key: ValueKey('continue-$answerFeedbackAttempt'),
                correct: checked && lastCorrect,
                wrong: checked && !lastCorrect,
                child: SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: checked
                          ? TudloColors.green
                          : const Color.fromARGB(255, 81, 167, 0),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: TudloColors.line,
                      disabledForegroundColor: TudloColors.muted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    // Check/Continue button:
                    // First tap checks the current answer. After feedback is
                    // shown, the next tap moves to the next question or finishes.
                    onPressed: canContinue ? () => nextQuestion() : null,
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
      QuestionType.typedTranslation => 'Translate the sentence',
      QuestionType.arrangeWords => 'Arrange the words',
      QuestionType.fillBlank => 'Complete the sentence',
      QuestionType.choice => 'Choose the translation',
      QuestionType.matching => 'Match the words',
      QuestionType.completeSentence => 'Choose the translation',
      QuestionType.buildSentence => 'Arrange the words',
      QuestionType.imageChoice => 'Choose the picture',
    };
  }

  Widget _buildQuestionBody(LessonQuestion q) {
    // Pick the exercise widget from the data model. This keeps the main page
    // layout stable while allowing very different interactions inside the body.
    return switch (q.type) {
      QuestionType.fillBlank => _ScenarioFillBlankExercise(
        question: q,
        builtWords: builtWords,
        checked: checked,
        answer: q.answer,
        feedbackAttempt: answerFeedbackAttempt,
        onAdd: (value) {
          if (checked) return;
          if (builtWords.length >= q.answer.split(' ').length) return;
          setState(() => builtWords.add(value));
        },
        onRemove: (index) => setState(() => builtWords.removeAt(index)),
      ),
      QuestionType.translationChoice ||
      QuestionType.choice ||
      QuestionType.completeSentence => _ChoiceList(
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
      ),
      QuestionType.typedTranslation => _TypedTranslationExercise(
        controller: typedAnswerController,
        checked: checked,
        correct: checked && lastCorrect,
        answer: q.answer,
        onChanged: (_) => setState(() {}),
      ),
      QuestionType.matching => _MatchingExercise(
        question: q,
        matches: matches,
        selectedLeft: selectedMatchLeft,
        wrongLeft: wrongMatchLeft,
        wrongRight: wrongMatchRight,
        wrongAttempt: wrongMatchAttempt,
        newMatchLeft: newMatchLeft,
        newMatchRight: newMatchRight,
        matchPulseAttempt: matchPulseAttempt,
        onSelectLeft: (left) {
          if (matches.containsKey(left)) return;
          setState(() {
            selectedMatchLeft = selectedMatchLeft == left ? null : left;
            _clearWrongMatch();
          });
        },
        onSelectRight: (right) {
          if (selectedMatchLeft == null || matches.containsValue(right)) {
            return;
          }
          final left = selectedMatchLeft!;
          final expected = _expectedMatch(left);
          setState(() {
            if (expected == right) {
              // Correct pairs are stored permanently and briefly pulse green.
              matches[left] = right;
              _clearWrongMatch();
              newMatchLeft = left;
              newMatchRight = right;
              matchPulseAttempt++;
              _scheduleMatchedPulseClear(matchPulseAttempt);
            } else {
              // Wrong pairs shake red, then return to normal after one second.
              wrongMatchLeft = left;
              wrongMatchRight = right;
              wrongMatchAttempt++;
              _scheduleWrongMatchClear(wrongMatchAttempt);
            }
            selectedMatchLeft = null;
          });
        },
      ),
      QuestionType.arrangeWords ||
      QuestionType.buildSentence => _BuildSentenceExercise(
        question: q,
        builtWords: builtWords,
        checked: checked,
        correct: checked && lastCorrect,
        feedbackAttempt: answerFeedbackAttempt,
        onAdd: (word) => setState(() => builtWords.add(word)),
        onRemove: (index) => setState(() => builtWords.removeAt(index)),
      ),
      QuestionType.imageChoice => _ImageChoiceGrid(
        question: q,
        selected: selectedAnswer,
        checked: checked,
        feedbackAttempt: answerFeedbackAttempt,
        onSelected: (value) {
          if (checked) return;
          setState(() => selectedAnswer = value);
        },
      ),
    };
  }

  Widget _questionContentArea(LessonQuestion question) {
    if (question.type == QuestionType.matching ||
        question.type == QuestionType.imageChoice ||
        question.type == QuestionType.fillBlank) {
      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildQuestionBody(question),
      );
    }

    if (question.type == QuestionType.buildSentence ||
        question.type == QuestionType.arrangeWords) {
      if (checked) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PromptCard(question: question),
              const SizedBox(height: 18),
              _buildQuestionBody(question),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PromptCard(question: question),
          const SizedBox(height: 18),
          Expanded(child: _buildQuestionBody(question)),
        ],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PromptCard(question: question),
          const SizedBox(height: 26),
          _buildQuestionBody(question),
        ],
      ),
    );
  }

  String _expectedMatch(String left) {
    // Converts the selected Hiligaynon term into its English match.
    return LessonBank.terms.firstWhere((term) => term.hil == left).eng;
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
      // Ignore old timers if the user has already made another attempt.
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
      // Ignore old timers if a newer matched-pair animation started.
      if (!mounted || attempt != matchPulseAttempt) return;
      setState(_clearMatchedPulse);
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _normalizeAnswer(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[.!?"]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}

//scoreboard pop-up
class _LessonCompleteDialog extends StatelessWidget {
  final int level;
  final int accuracy;
  final int mistakes;
  final String durationLabel;
  final VoidCallback onClaim;

  const _LessonCompleteDialog({
    required this.level,
    required this.accuracy,
    required this.mistakes,
    required this.durationLabel,
    required this.onClaim,
  });

  /// Star count is based on accuracy so the reward screen reflects performance.
  int get starCount {
    if (accuracy >= 90) return 3;
    if (accuracy >= 70) return 2;
    if (accuracy > 0) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final modalWidth = (MediaQuery.sizeOf(context).width * .84)
        .clamp(300.0, 390.0)
        .toDouble();
    final bannerWidth = modalWidth * 1.08;

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
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 92),
                padding: const EdgeInsets.fromLTRB(18, 74, 18, 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFCF2),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: TudloColors.green.withValues(alpha: .24),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .18),
                      blurRadius: 28,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 4,
                      right: 4,
                      child: _Sparkle(color: TudloColors.green, size: 12),
                    ),
                    Positioned(
                      top: 90,
                      left: 2,
                      child: _Sparkle(color: TudloColors.meadow, size: 9),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'LEVEL COMPLETE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: TudloColors.forest,
                            fontSize: 29,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const TudloMascot(size: 74),
                        const SizedBox(height: 6),
                        const Text(
                          'Great Job!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: TudloColors.forest,
                            fontSize: 32,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mistakes == 0
                              ? 'Lesson completed perfectly!'
                              : 'Lesson completed!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: TudloColors.muted,
                            fontSize: 15,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _RewardStatRow(
                          label: 'TIME',
                          value: durationLabel,
                          icon: Icons.timer_rounded,
                        ),
                        const SizedBox(height: 10),
                        _RewardStatRow(
                          label: 'ACCURACY',
                          value: '$accuracy%',
                          icon: Icons.track_changes_rounded,
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TudloColors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .3,
                              ),
                            ),
                            onPressed: onClaim,
                            child: const Text('CONTINUE'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 58,
                child: _RewardBanner(width: bannerWidth, level: level),
              ),
              Positioned(top: 0, child: _RewardStars(count: starCount)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardBanner extends StatelessWidget {
  final double width;
  final int level;

  const _RewardBanner({required this.width, required this.level});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * .34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/banner.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0, .40),
            ),
          ),
          Positioned(
            top: width * .13,
            left: 0,
            right: 0,
            child: Text(
              'LEVEL $level',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: (width * .045).clamp(16.0, 20.0),
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardStars extends StatelessWidget {
  final int count;

  const _RewardStars({required this.count});

  //star size
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 162,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 6,
            top: 27,
            child: Transform.rotate(
              angle: -.18,
              child: _RewardStar(active: count >= 1, size: 70),
            ),
          ),
          Positioned(
            right: 6,
            top: 27,
            child: Transform.rotate(
              angle: .18,
              child: _RewardStar(active: count >= 3, size: 70),
            ),
          ),
          Positioned(
            top: 0,
            child: Transform.rotate(
              angle: .05,
              child: _RewardStar(active: count >= 2, size: 90),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardStar extends StatelessWidget {
  final bool active;
  final double size;

  const _RewardStar({required this.active, required this.size});

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFFFFD84D) : TudloColors.line;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: active
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD84D).withValues(alpha: .42),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.star_rounded, color: color, size: size),
          if (active)
            Positioned(
              top: size * .23,
              right: size * .27,
              child: Icon(
                Icons.circle,
                color: Colors.white.withValues(alpha: .72),
                size: size * .12,
              ),
            ),
        ],
      ),
    );
  }
}

class _RewardStatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _RewardStatRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .76),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TudloColors.green.withValues(alpha: .12)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: TudloColors.green.withValues(alpha: .14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: TudloColors.green, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: TudloColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: .5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: TudloColors.forest,
                  fontSize: 24,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  final Color color;
  final double size;

  const _Sparkle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.auto_awesome_rounded,
      color: color.withValues(alpha: .28),
      size: size,
    );
  }
}

class _PromptCard extends StatelessWidget {
  final LessonQuestion question;

  const _PromptCard({required this.question});

  @override
  Widget build(BuildContext context) {
    // Shared prompt layout for all Level Game question types.
    // The mascot makes the prompt feel like a spoken message, while the rounded
    // bubble keeps the question readable and consistent across exercises.
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

    // Build-sentence prompts show the whole quoted sentence as one clean text
    // block so quotation marks do not split away from the sentence.
    if (question.type == QuestionType.buildSentence ||
        question.type == QuestionType.arrangeWords) {
      return Text(promptText, style: style);
    }

    // Only render the tap-to-translate behavior when the question defines a
    // target phrase. Otherwise this is plain text.
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
    // The bubble only shows the actual phrase/sentence in quotation marks.
    // Example: Complete the sentence "___ ka?" becomes "___ ka?".
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

class _ScenarioFillBlankExercise extends StatelessWidget {
  final LessonQuestion question;
  final List<String> builtWords;
  final bool checked;
  final String answer;
  final int feedbackAttempt;
  final ValueChanged<String> onAdd;
  final ValueChanged<int> onRemove;

  const _ScenarioFillBlankExercise({
    required this.question,
    required this.builtWords,
    required this.checked,
    required this.answer,
    required this.feedbackAttempt,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final sentence = _missingSentenceFrom(question.prompt);
    final remaining = [...question.choices];
    for (final word in builtWords) {
      remaining.remove(word);
    }

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
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 500,
                    maxHeight: imageHeight,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Image.asset(
                    question.imagePath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => const _ImageChoiceFallback(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _ScenarioSentenceText(
                sentence: sentence,
                builtWords: builtWords,
                checked: checked,
                correct:
                    checked &&
                    _normalizeWords(builtWords) ==
                        _normalizeWords(answer.split(' ')),
                wordMeanings: question.wordMeanings,
                onRemove: onRemove,
              ),
            ),
            if (!checked) ...[
              const SizedBox(height: 24),
              _ScenarioWordChoices(
                choices: remaining,
                checked: checked,
                answerWords: answer.split(' '),
                feedbackAttempt: feedbackAttempt,
                wordMeanings: question.wordMeanings,
                onAdd: onAdd,
              ),
            ],
          ],
        );
      },
    );
  }

  String _missingSentenceFrom(String prompt) {
    final match = RegExp(r'"([^"]+)"').firstMatch(prompt);
    return match?.group(1) ?? prompt;
  }

  String _normalizeWords(List<String> words) {
    return words.join(' ').trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}

class _ScenarioSentenceText extends StatelessWidget {
  final String sentence;
  final List<String> builtWords;
  final bool checked;
  final bool correct;
  final Map<String, String> wordMeanings;
  final ValueChanged<int> onRemove;

  const _ScenarioSentenceText({
    required this.sentence,
    required this.builtWords,
    required this.checked,
    required this.correct,
    required this.wordMeanings,
    required this.onRemove,
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
                : () => onRemove(currentBlank),
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
        if (meaning.isEmpty) return text;
        return WordMeaningTooltipTarget(
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
  final int feedbackAttempt;
  final Map<String, String> wordMeanings;
  final ValueChanged<String> onAdd;

  const _ScenarioWordChoices({
    required this.choices,
    required this.checked,
    required this.answerWords,
    required this.feedbackAttempt,
    required this.wordMeanings,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return _FeedbackMotion(
      key: ValueKey('scenario-choices-$feedbackAttempt'),
      correct: false,
      wrong: false,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: choices.map((choice) {
          final canRevealMeaning = !answerWords.any(
            (answer) => answer.toLowerCase() == choice.toLowerCase(),
          );
          final chip = ActionChip(
            label: Text(choice),
            labelPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 8,
            ),
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
            onPressed: checked ? null : () => onAdd(choice),
          );
          final meaning = canRevealMeaning ? wordMeanings[choice] ?? '' : '';
          return meaning.isEmpty
              ? chip
              : WordMeaningTooltipTarget(meaning: meaning, child: chip);
        }).toList(),
      ),
    );
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

class _TypedTranslationExercise extends StatelessWidget {
  final TextEditingController controller;
  final bool checked;
  final bool correct;
  final String answer;
  final ValueChanged<String> onChanged;

  const _TypedTranslationExercise({
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
    final backgroundColor = checked
        ? correct
              ? TudloColors.green.withValues(alpha: .10)
              : TudloColors.coral.withValues(alpha: .08)
        : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor, width: 4),
          ),
          child: TextField(
            controller: controller,
            readOnly: checked,
            autofocus: true,
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TudloColors.softGreen,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              'Correct answer: $answer',
              style: const TextStyle(
                color: TudloColors.forest,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ],
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
    // Matched right-side answers are tracked by value so each English meaning
    // can only be used once.
    final usedRight = matches.values.toSet();
    final maxRows = question.leftItems.length > question.rightItems.length
        ? question.leftItems.length
        : question.rightItems.length;

    return Column(
      children: List.generate(maxRows, (index) {
        final left = index < question.leftItems.length
            ? question.leftItems[index]
            : null;
        final right = index < question.rightItems.length
            ? question.rightItems[index]
            : null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
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
              const SizedBox(width: 8),
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
    // Matching tiles have four visual states: default, selected, wrong, and
    // completed. Right-column tiles intentionally stay active until matched.
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
          borderRadius: BorderRadius.circular(16),
          onTap: matched ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
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
                  fontSize: compact ? 16 : 18,
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

class _BuildSentenceExercise extends StatelessWidget {
  final LessonQuestion question;
  final List<String> builtWords;
  final bool checked;
  final bool correct;
  final int feedbackAttempt;
  final ValueChanged<String> onAdd;
  final ValueChanged<int> onRemove;

  const _BuildSentenceExercise({
    required this.question,
    required this.builtWords,
    required this.checked,
    required this.correct,
    required this.feedbackAttempt,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // Start with all word blocks, then remove the ones already placed in the
    // answer box. This supports repeated words because remove() only removes
    // one matching value at a time.
    final remaining = [...question.sentenceWords];
    for (final word in builtWords) {
      remaining.remove(word);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasImage = question.imagePath.trim().isNotEmpty;
        final imageHeight = hasImage
            ? (constraints.maxHeight * .50).clamp(160.0, 300.0).toDouble()
            : 0.0;
        const answerHeight = 120.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage) ...[
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 520,
                    maxHeight: imageHeight,
                  ),
                  child: Image.asset(
                    question.imagePath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => const _ImageChoiceFallback(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _FeedbackMotion(
              key: ValueKey('build-$feedbackAttempt'),
              correct: checked && correct,
              wrong: checked && !correct,
              child: Container(
                width: double.infinity,
                height: answerHeight,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: answerHeight * .38,
                      child: _BuildSentenceLine(
                        color: checked && !correct
                            ? TudloColors.coral
                            : TudloColors.line,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: answerHeight * .76,
                      child: _BuildSentenceLine(
                        color: checked && !correct
                            ? TudloColors.coral
                            : TudloColors.line,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
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
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
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
                                : () => onRemove(entry.key),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!checked) ...[
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    runAlignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: remaining.map((word) {
                      return WordMeaningTooltipTarget(
                        meaning: translatedMeaningFor(word),
                        child: ActionChip(
                          label: Text(word),
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 7,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
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
                          onPressed: () => onAdd(word),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BuildSentenceLine extends StatelessWidget {
  final Color color;

  const _BuildSentenceLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 4,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .78),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _ImageChoiceGrid extends StatelessWidget {
  final LessonQuestion question;
  final String? selected;
  final bool checked;
  final int feedbackAttempt;
  final ValueChanged<String> onSelected;

  const _ImageChoiceGrid({
    required this.question,
    required this.selected,
    required this.checked,
    required this.feedbackAttempt,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Image activities use Duolingo-style picture cards: four visual choices,
    // each with the Hiligaynon label below the image.
    final cards = question.imageChoices.map((term) {
      final active = selected == term.hil;
      final correct = checked && active && term.hil == question.answer;
      final wrong = checked && active && term.hil != question.answer;
      return _ImageChoiceCard(
        term: term,
        active: active,
        correct: correct,
        wrong: wrong,
        feedbackKey: active ? feedbackAttempt : 0,
        onTap: checked ? null : () => onSelected(term.hil),
      );
    }).toList();

    return SizedBox(
      height: 520,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 14),
                Expanded(child: cards[1]),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: 14),
                Expanded(child: cards[3]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageChoiceCard extends StatelessWidget {
  final LessonTerm term;
  final bool active;
  final bool correct;
  final bool wrong;
  final int feedbackKey;
  final VoidCallback? onTap;

  const _ImageChoiceCard({
    required this.term,
    required this.active,
    required this.correct,
    required this.wrong,
    required this.feedbackKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = correct
        ? TudloColors.green
        : wrong
        ? TudloColors.coral
        : active
        ? TudloColors.brightGreen
        : TudloColors.line;
    final backgroundColor = correct
        ? TudloColors.green.withValues(alpha: .12)
        : wrong
        ? TudloColors.coral.withValues(alpha: .08)
        : active
        ? TudloColors.softGreen
        : Colors.white;
    final labelColor = active || correct
        ? TudloColors.green
        : wrong
        ? TudloColors.coral
        : TudloColors.ink;

    return _FeedbackMotion(
      key: ValueKey('${term.hil}-$feedbackKey'),
      correct: correct,
      wrong: wrong,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: active ? 4 : 3),
            boxShadow: [
              BoxShadow(
                color: (active ? TudloColors.green : TudloColors.ink)
                    .withValues(alpha: active ? .15 : .05),
                blurRadius: active ? 18 : 10,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: term.imagePath == null
                        ? const _ImageChoiceFallback()
                        : Image.asset(
                            term.imagePath!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const _ImageChoiceFallback(),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  term.hil,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
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

class _ImageChoiceFallback extends StatelessWidget {
  const _ImageChoiceFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TudloColors.softGreen,
      child: const Center(
        child: Icon(Icons.image_rounded, color: TudloColors.green, size: 42),
      ),
    );
  }
}

class _AnswerFeedbackPanel extends StatelessWidget {
  final bool correct;
  final String phrase;
  final String meaning;
  final bool showDetails;

  const _AnswerFeedbackPanel({
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

    // Feedback panel shown after checking an answer. Correct answers use a
    // soft green sheet with the mascot and answer details.
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
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        phrase,
                        softWrap: true,
                        style: const TextStyle(
                          color: TudloColors.ink,
                          fontSize: 23,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Icon(Icons.volume_up_rounded, color: accent, size: 26),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (meaning.trim().isNotEmpty)
                    Text(
                      meaning,
                      softWrap: true,
                      style: const TextStyle(
                        color: TudloColors.muted,
                        fontSize: 17,
                        height: 1.2,
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
    //Word meaning for long press word option
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

//Animation for button
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
