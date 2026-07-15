import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/language_toggle.dart';
import 'package:tudloapp/core/widgets/mascot_widget.dart';
import 'package:tudloapp/data/dictionary/dictionary_data.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank.dart';
import 'package:tudloapp/core/widgets/word_tooltip.dart';
import 'package:tudloapp/features/energy/widgets/energy_indicator.dart';
import 'package:tudloapp/features/navigation/app_shell.dart';

Map<String, String> _matchingPairsFromItemOrder(QuizItem item) {
  if (item.leftItems.length != item.rightItems.length) return const {};
  return {
    for (var index = 0; index < item.leftItems.length; index++)
      item.leftItems[index]: item.rightItems[index],
  };
}

/// Main lesson gameplay screen opened from the Home Map.
///
/// A level receives grade-based content and generated questions from
/// LessonBank.
class LevelGamePage extends StatefulWidget {
  final int level;

  const LevelGamePage({super.key, required this.level});

  @override
  State<LevelGamePage> createState() => _LevelGamePageState();
}

class _LevelGamePageState extends State<LevelGamePage> {
  late final Future<LevelContent> _contentFuture;
  List<LessonQuestion> questions = const [];
  final Map<int, String> selectedAnswers = {};
  final Map<int, bool> checkedAnswers = {};
  final Map<int, bool> correctAnswers = {};
  final Map<int, List<String>> builtWords = {};
  final Map<int, Map<String, String>> matches = {};
  final Map<int, _Grade3QuestionAttempt> grade3QuestionAttempts = {};
  late final DateTime _levelStartedAt;
  bool _rewardsClaimed = false;
  bool _completeDialogShown = false;

  int get score => correctAnswers.values.where((correct) => correct).length;

  int get checkedCount =>
      checkedAnswers.values.where((checked) => checked).length;

  @override
  void initState() {
    super.initState();
    _contentFuture = () async {
      final contentFuture = LessonBank.loadLevelContentForLevel(widget.level);
      await DictionaryData.initialize();
      final content = await contentFuture;
      questions = content.quizItems.map(_questionFromQuizItem).toList();
      return content;
    }();
    _levelStartedAt = DateTime.now();
  }

  void _claimRewardsOnce() {
    if (_rewardsClaimed) return;
    _rewardsClaimed = true;

    // Progress is saved only when the learner taps the completion button.
    // This prevents repeated completion interactions from saving twice.
    AppData.saveLevelScore(widget.level, score, questions.length);
    if (AppData.unlockedLevel <= widget.level &&
        widget.level < AppData.maxLevel) {
      AppData.unlockedLevel = widget.level + 1;
    }
    AppStateScope.of(context).saveActiveProfileProgress();
  }

  void _handleQuestionChecked(
    int index,
    bool correct, {
    bool autoComplete = true,
  }) {
    if (_completeDialogShown) return;
    setState(() {
      checkedAnswers[index] = correct;
      correctAnswers[index] = correct;
    });

    final allCorrect =
        questions.isNotEmpty &&
        List.generate(
          questions.length,
          (itemIndex) => correctAnswers[itemIndex] == true,
        ).every((correct) => correct);

    if (autoComplete && allCorrect) {
      _completeDialogShown = true;
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _showCompleteDialog();
      });
    }
  }

  void _handleGradeThreeQuestionCompleted(
    int index, {
    required bool firstAttemptCorrect,
    required int attemptCount,
    required bool usedAudioSupport,
    required bool usedLookBackSupport,
  }) {
    if (_completeDialogShown) return;
    setState(() {
      checkedAnswers[index] = true;
      correctAnswers[index] = firstAttemptCorrect;
      grade3QuestionAttempts[index] = _Grade3QuestionAttempt(
        lessonId: 'level-${widget.level}',
        questionId: questions[index].directionLabel.isEmpty
            ? 'q$index'
            : questions[index].directionLabel,
        questionType: _grade3QuestionTypeFor(questions[index]),
        firstAttemptCorrect: firstAttemptCorrect,
        attemptCount: attemptCount,
        usedAudioSupport: usedAudioSupport,
        usedLookBackSupport: usedLookBackSupport,
        completedAt: DateTime.now(),
      );
    });
  }

  void _completeGradeThreeLesson() {
    if (_completeDialogShown) return;
    final allCompleted =
        questions.isEmpty ||
        List.generate(
          questions.length,
          (itemIndex) => checkedAnswers[itemIndex] == true,
        ).every((completed) => completed);
    if (!allCompleted) return;
    _completeDialogShown = true;
    _showCompleteDialog();
  }

  void _showCompleteDialog() {
    // The completion dialog shows lesson results. Progress updates only after
    // the learner returns to the map.
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
                    tooltip: 'Magpabilin',
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
                      'Mahalin ka na?',
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
                      'Tapusa ang leksiyon, ukon madula ang imo progreso.',
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
                              child: const Text('Halin'),
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
                              child: const Text('Magpabilin'),
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

  LessonQuestion _questionFromQuizItem(QuizItem item) {
    final choiceTypes = {
      QuizType.multipleChoice,
      QuizType.pictureChoice,
      QuizType.listenAndChoose,
      QuizType.tapCorrectWord,
    };
    if (item.type == QuizType.matching) {
      final matchingPairs = item.matchingPairs.isNotEmpty
          ? item.matchingPairs
          : _matchingPairsFromItemOrder(item);
      return LessonQuestion.matching(
        prompt: item.question,
        leftItems: item.leftItems,
        rightItems: item.rightItems,
        matchingPairs: matchingPairs,
        directionLabel: item.id,
      );
    }
    if (item.type == QuizType.fillBlankChoice) {
      return LessonQuestion.fillBlank(
        prompt: item.question,
        answer: item.answer,
        choices: item.choices,
        imagePath: item.imageAsset ?? '',
        targetPhrase: item.answer,
        targetMeaning: item.answer,
        directionLabel: item.id,
      );
    }
    if (item.type == QuizType.arrangeWords) {
      return LessonQuestion.arrangeWords(
        prompt: item.question,
        answer: item.answer,
        sentenceWords: item.choices,
        imagePath: item.imageAsset ?? '',
        targetPhrase: item.answer,
        targetMeaning: item.answer,
        directionLabel: item.id,
      );
    }
    if (choiceTypes.contains(item.type)) {
      return LessonQuestion.translationChoice(
        prompt: item.question,
        answer: item.answer,
        choices: item.choices,
        imagePath: item.imageAsset ?? '',
        targetPhrase: item.answer,
        targetMeaning: item.answer,
        directionLabel: item.id,
      );
    }
    return LessonQuestion.choice(
      prompt: item.question,
      answer: item.answer,
      choices: item.choices,
      imagePath: item.imageAsset ?? '',
      targetPhrase: item.answer,
      targetMeaning: item.answer,
      directionLabel: item.id,
    );
  }

  LessonLevelContent _displayContent(LevelContent levelContent) {
    return LessonLevelContent(
      title: levelContent.title,
      storyTitle: levelContent.storyTitle ?? '',
      story: levelContent.story ?? '',
      shortLesson: levelContent.lesson,
      examples: levelContent.examples,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 380 ? 10.0 : 18.0;
    final backButtonSize = screenWidth < 380 ? 48.0 : 56.0;
    final backIconSize = screenWidth < 380 ? 32.0 : 40.0;
    final progressHeight = screenWidth < 380 ? 14.0 : 18.0;

    return FutureBuilder<LevelContent>(
      future: _contentFuture,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState != ConnectionState.done;
        final levelContent = snapshot.data;
        final alphabetLesson =
            levelContent != null && _isGradeOneAlphabetContent(levelContent);
        final familyLesson =
            levelContent != null && _isGradeOneFamilyContent(levelContent);
        final helperLesson =
            levelContent != null && _isGradeOneHelperContent(levelContent);
        final animalLesson =
            levelContent != null && _isGradeOneAnimalContent(levelContent);
        final placeLesson =
            levelContent != null && _isGradeOnePlaceContent(levelContent);
        final gradeTwoLesson =
            levelContent != null && _isGradeTwoContent(levelContent);
        final gradeThreeLesson =
            levelContent != null && _isGradeThreeContent(levelContent);
        final progress = questions.isEmpty
            ? 0.0
            : checkedCount / questions.length;
        return Scaffold(
          backgroundColor: TudloColors.paper,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                18,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: backButtonSize,
                        height: backButtonSize,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          // Back button:
                          // Opens the pause menu before leaving the game.
                          onPressed: _showPauseMenu,
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: TudloColors.blue,
                            size: backIconSize,
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth < 380 ? 6 : 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: progressHeight,
                            backgroundColor: TudloColors.line,
                            color: TudloColors.green,
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth < 380 ? 6 : 12),
                      SizedBox(width: screenWidth < 380 ? 6 : 12),
                      Flexible(
                        flex: 0,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: const EnergyIndicator(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Expanded(
                    child: loading || levelContent == null
                        ? const _LessonLoadingCard()
                        : alphabetLesson ||
                              familyLesson ||
                              helperLesson ||
                              animalLesson ||
                              placeLesson ||
                              gradeTwoLesson ||
                              gradeThreeLesson
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _LevelIntroHeader(
                                level: widget.level,
                                title:
                                    familyLesson ||
                                        helperLesson ||
                                        animalLesson ||
                                        placeLesson ||
                                        gradeTwoLesson ||
                                        gradeThreeLesson
                                    ? ''
                                    : levelContent.title,
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: alphabetLesson
                                    ? _GradeOneAlphabetLesson(
                                        content: levelContent,
                                        onQuizCorrect: (index) =>
                                            _handleQuestionChecked(index, true),
                                      )
                                    : helperLesson
                                    ? _GradeOneHelperLesson(
                                        content: levelContent,
                                        onQuizCorrect: (index) =>
                                            _handleQuestionChecked(index, true),
                                      )
                                    : animalLesson
                                    ? _GradeOneAnimalLesson(
                                        content: levelContent,
                                        onQuizCorrect: (index) =>
                                            _handleQuestionChecked(index, true),
                                      )
                                    : placeLesson
                                    ? _GradeOnePlaceLesson(
                                        content: levelContent,
                                        onQuizCorrect: (index) =>
                                            _handleQuestionChecked(index, true),
                                      )
                                    : gradeTwoLesson
                                    ? _GradeTwoTalkBuildSolveLesson(
                                        content: levelContent,
                                        onQuizCorrect: (index) =>
                                            _handleQuestionChecked(index, true),
                                      )
                                    : gradeThreeLesson
                                    ? _GradeThreeLessonFlow(
                                        content: levelContent,
                                        questions: questions,
                                        onQuestionCompleted:
                                            _handleGradeThreeQuestionCompleted,
                                        onLessonComplete:
                                            _completeGradeThreeLesson,
                                      )
                                    : _GradeOneFamilyLesson(
                                        content: levelContent,
                                        onQuizCorrect: (index) =>
                                            _handleQuestionChecked(index, true),
                                      ),
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _LevelIntroHeader(
                                  level: widget.level,
                                  title: levelContent.title,
                                ),
                                if (levelContent.story?.trim().isNotEmpty ==
                                    true) ...[
                                  const SizedBox(height: 18),
                                  _StoryLessonSection(
                                    content: _displayContent(levelContent),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                _LearningSection(
                                  title: 'Mga Halimbawa',
                                  accentColor: TudloColors.blue,
                                  child: _ExampleCardGrid(
                                    examples: levelContent.examples,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const _QuizSectionHeader(),
                                const SizedBox(height: 12),
                                ...questions.asMap().entries.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _LevelQuizCard(
                                      key: ValueKey(
                                        '${widget.level}-${entry.key}-${entry.value.prompt}',
                                      ),
                                      number: entry.key + 1,
                                      question: entry.value,
                                      onChecked: (correct) =>
                                          _handleQuestionChecked(
                                            entry.key,
                                            correct,
                                          ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isGradeOneAlphabetContent(LevelContent content) {
    return content.gradeLevel == 1 &&
        content.unitNumber == 1 &&
        content.lessonNumber <= 6 &&
        content.title.toLowerCase().contains('letters');
  }

  bool _isGradeOneFamilyContent(LevelContent content) {
    return content.gradeLevel == 1 && content.unitNumber == 2;
  }

  bool _isGradeOneHelperContent(LevelContent content) {
    return content.gradeLevel == 1 && content.unitNumber == 3;
  }

  bool _isGradeOneAnimalContent(LevelContent content) {
    return content.gradeLevel == 1 && content.unitNumber == 4;
  }

  bool _isGradeOnePlaceContent(LevelContent content) {
    return content.gradeLevel == 1 && content.unitNumber == 5;
  }

  bool _isGradeTwoContent(LevelContent content) {
    return content.gradeLevel == 2;
  }

  bool _isGradeThreeContent(LevelContent content) {
    return content.gradeLevel == 3;
  }
}

class _LessonLoadingCard extends StatelessWidget {
  const _LessonLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TudloCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            TudloMascot(size: 110),
            SizedBox(height: 14),
            Text(
              'Ginakuha ang leksiyon...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: TudloColors.ink,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _Grade3QuestionCompleted =
    void Function(
      int index, {
      required bool firstAttemptCorrect,
      required int attemptCount,
      required bool usedAudioSupport,
      required bool usedLookBackSupport,
    });

class _Grade3QuestionAttempt {
  final String lessonId;
  final String questionId;
  final String questionType;
  final bool firstAttemptCorrect;
  final int attemptCount;
  final bool usedAudioSupport;
  final bool usedLookBackSupport;
  final DateTime completedAt;

  const _Grade3QuestionAttempt({
    required this.lessonId,
    required this.questionId,
    required this.questionType,
    required this.firstAttemptCorrect,
    required this.attemptCount,
    required this.usedAudioSupport,
    required this.usedLookBackSupport,
    required this.completedAt,
  });
}

String _grade3QuestionTypeFor(LessonQuestion question) {
  final text = '${question.prompt} ${question.directionLabel}'.toLowerCase();
  if (text.contains('who') || text.contains('sin-o')) return 'who';
  if (text.contains('where') || text.contains('diin')) return 'where';
  if (text.contains('when') || text.contains('san-o')) return 'when';
  if (text.contains('why') || text.contains('ngaa')) return 'why';
  if (text.contains('how many') || text.contains('pila')) return 'howMany';
  if (text.contains('how much') || text.contains('bili')) return 'howMuch';
  if (text.contains('predict') || text.contains('matabo')) return 'prediction';
  if (question.type == QuestionType.matching) return 'sequence';
  if (question.type == QuestionType.imageChoice) return 'imageChoice';
  if (question.type == QuestionType.buildSentence ||
      question.type == QuestionType.arrangeWords) {
    return 'tileBuilder';
  }
  return 'what';
}

enum _Grade3FlowStepType {
  intro,
  warmUp,
  review,
  vocabulary,
  storyPage,
  question,
  productive,
  consolidation,
  completion,
}

class _Grade3FlowStep {
  final _Grade3FlowStepType type;
  final int index;

  const _Grade3FlowStep(this.type, [this.index = -1]);
}

class _Grade3StoryPageData {
  final String id;
  final String imagePath;
  final List<String> sentences;

  const _Grade3StoryPageData({
    required this.id,
    required this.imagePath,
    required this.sentences,
  });
}

class _GradeThreeLessonFlow extends StatefulWidget {
  final LevelContent content;
  final List<LessonQuestion> questions;
  final _Grade3QuestionCompleted onQuestionCompleted;
  final VoidCallback onLessonComplete;

  const _GradeThreeLessonFlow({
    required this.content,
    required this.questions,
    required this.onQuestionCompleted,
    required this.onLessonComplete,
  });

  @override
  State<_GradeThreeLessonFlow> createState() => _GradeThreeLessonFlowState();
}

class _GradeThreeLessonFlowState extends State<_GradeThreeLessonFlow> {
  int _stepIndex = 0;
  final Set<int> _completedQuestions = {};
  late final List<_Grade3StoryPageData> _storyPages = _grade3StoryPagesFor(
    widget.content,
  );

  List<_Grade3FlowStep> get _steps {
    final steps = <_Grade3FlowStep>[
      const _Grade3FlowStep(_Grade3FlowStepType.intro),
      const _Grade3FlowStep(_Grade3FlowStepType.warmUp),
      const _Grade3FlowStep(_Grade3FlowStepType.review),
    ];
    if (widget.content.examples.isNotEmpty) {
      steps.add(const _Grade3FlowStep(_Grade3FlowStepType.vocabulary));
    }
    final maxStorySteps = math.max(_storyPages.length, widget.questions.length);
    for (var index = 0; index < maxStorySteps; index++) {
      if (index < _storyPages.length) {
        steps.add(_Grade3FlowStep(_Grade3FlowStepType.storyPage, index));
      }
      if (index < widget.questions.length) {
        steps.add(_Grade3FlowStep(_Grade3FlowStepType.question, index));
      }
    }
    steps.addAll(const [
      _Grade3FlowStep(_Grade3FlowStepType.productive),
      _Grade3FlowStep(_Grade3FlowStepType.consolidation),
      _Grade3FlowStep(_Grade3FlowStepType.completion),
    ]);
    return steps;
  }

  void _next() {
    final maxIndex = _steps.length - 1;
    if (_stepIndex >= maxIndex) return;
    setState(() => _stepIndex++);
  }

  void _previous() {
    if (_stepIndex <= 0) return;
    setState(() => _stepIndex--);
  }

  void _completeQuestion(
    int index, {
    required bool firstAttemptCorrect,
    required int attemptCount,
    required bool usedAudioSupport,
    required bool usedLookBackSupport,
  }) {
    if (_completedQuestions.add(index)) {
      widget.onQuestionCompleted(
        index,
        firstAttemptCorrect: firstAttemptCorrect,
        attemptCount: attemptCount,
        usedAudioSupport: usedAudioSupport,
        usedLookBackSupport: usedLookBackSupport,
      );
    }
    _next();
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final step = steps[_stepIndex.clamp(0, steps.length - 1)];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey('${step.type}-${step.index}-$_stepIndex'),
        child: switch (step.type) {
          _Grade3FlowStepType.intro => _Grade3IntroStep(
            content: widget.content,
            onNext: _next,
          ),
          _Grade3FlowStepType.warmUp => _Grade3SimpleActionStep(
            title: 'Balikid Anay',
            message: _grade3WarmUpText(widget.content),
            icon: Icons.history_edu_rounded,
            buttonLabel: 'Padayon',
            onNext: _next,
          ),
          _Grade3FlowStepType.review => _Grade3SimpleActionStep(
            title: 'Review',
            message: 'Pili-a kag pamatii ang isa ka natun-an nga tinaga.',
            icon: Icons.school_rounded,
            buttonLabel: 'Padayon',
            onNext: _next,
          ),
          _Grade3FlowStepType.vocabulary => _Grade3VocabularyStep(
            examples: widget.content.examples,
            onNext: _next,
          ),
          _Grade3FlowStepType.storyPage => _Grade3StoryScreen(
            page: _storyPages[step.index],
            pageNumber: step.index + 1,
            pageCount: _storyPages.length,
            canGoBack: _stepIndex > 0,
            canGoNext: true,
            onBack: _previous,
            onNext: _next,
          ),
          _Grade3FlowStepType.question => _Grade3QuestionScreen(
            question: widget.questions[step.index],
            questionIndex: step.index,
            storyPage: _evidencePageForQuestion(step.index),
            onCompleted: _completeQuestion,
          ),
          _Grade3FlowStepType.productive => _Grade3SimpleActionStep(
            title: 'Himuon Ta',
            message: 'Basaha liwat ang pinakanami nga linya.',
            icon: Icons.record_voice_over_rounded,
            buttonLabel: 'Nahimo Ko',
            onNext: _next,
          ),
          _Grade3FlowStepType.consolidation => _Grade3SimpleActionStep(
            title: 'Pangitaa ang Sabat',
            message: 'Baliki ang sugilanon kag dumduma ang natun-an.',
            icon: Icons.extension_rounded,
            buttonLabel: 'Tapos Na',
            onNext: _next,
          ),
          _Grade3FlowStepType.completion => _Grade3CompletionStep(
            content: widget.content,
            onComplete: widget.onLessonComplete,
          ),
        },
      ),
    );
  }

  _Grade3StoryPageData _evidencePageForQuestion(int questionIndex) {
    if (_storyPages.isEmpty) {
      return _grade3FallbackStoryPage(widget.content, 0);
    }
    return _storyPages[questionIndex.clamp(0, _storyPages.length - 1)];
  }
}

class _Grade3IntroStep extends StatelessWidget {
  final LevelContent content;
  final VoidCallback onNext;

  const _Grade3IntroStep({required this.content, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _Grade3Stage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const TudloMascot(size: 150),
          const SizedBox(height: 18),
          Text(
            'Pamati kag Basaha',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _grade3CleanTitle(content.title),
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: 27,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          _Grade3TipBubble(
            text: 'Basaha anay. Tap-a ang speaker kon gusto mo mamati.',
          ),
          const SizedBox(height: 28),
          _Grade3PrimaryButton(label: 'Sugdi', onTap: onNext),
        ],
      ),
    );
  }
}

class _Grade3SimpleActionStep extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String buttonLabel;
  final VoidCallback onNext;

  const _Grade3SimpleActionStep({
    required this.title,
    required this.message,
    required this.icon,
    required this.buttonLabel,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _Grade3Stage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: TudloColors.green, size: 96),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          _Grade3TipBubble(text: message),
          const SizedBox(height: 28),
          _Grade3PrimaryButton(label: buttonLabel, onTap: onNext),
        ],
      ),
    );
  }
}

class _Grade3VocabularyStep extends StatelessWidget {
  final List<LessonExample> examples;
  final VoidCallback onNext;

  const _Grade3VocabularyStep({required this.examples, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final visibleExamples = examples
        .where((example) => example.hiligaynon.trim().isNotEmpty)
        .take(4)
        .toList();
    return _Grade3Stage(
      child: Column(
        children: [
          Text(
            'Bag-o nga Tinaga',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 32,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          for (final example in visibleExamples) ...[
            _Grade3VocabularyCard(example: example),
            const SizedBox(height: 12),
          ],
          const Spacer(),
          _Grade3PrimaryButton(label: 'Padayon', onTap: onNext),
        ],
      ),
    );
  }
}

class _Grade3VocabularyCard extends StatelessWidget {
  final LessonExample example;

  const _Grade3VocabularyCard({required this.example});

  @override
  Widget build(BuildContext context) {
    final word = _grade3DisplayText(example.hiligaynon);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: TudloColors.forest.withValues(alpha: .08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              word,
              style: GoogleFonts.nunito(
                color: TudloColors.ink,
                fontSize: 24,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          TudloVoiceButton(
            message: word,
            tooltip: 'Pamatii',
            size: 48,
            hiligaynon: true,
          ),
        ],
      ),
    );
  }
}

class _Grade3StoryScreen extends StatelessWidget {
  final _Grade3StoryPageData page;
  final int pageNumber;
  final int pageCount;
  final bool canGoBack;
  final bool canGoNext;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final int? highlightedSentenceIndex;

  const _Grade3StoryScreen({
    required this.page,
    required this.pageNumber,
    required this.pageCount,
    required this.canGoBack,
    required this.canGoNext,
    required this.onBack,
    required this.onNext,
    this.highlightedSentenceIndex,
  });

  @override
  Widget build(BuildContext context) {
    return _Grade3Stage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Sugilanon',
                style: GoogleFonts.nunito(
                  color: TudloColors.forest,
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              Text(
                '$pageNumber / $pageCount',
                style: GoogleFonts.nunito(
                  color: TudloColors.green,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 1.25,
              child: Image.asset(
                page.imagePath,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => const _StoryImageFallback(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < page.sentences.length; index++) ...[
            _Grade3SentenceCard(
              sentence: page.sentences[index],
              highlighted: highlightedSentenceIndex == index,
            ),
            const SizedBox(height: 10),
          ],
          const Spacer(),
          _Grade3PageDots(current: pageNumber - 1, count: pageCount),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Grade3SecondaryButton(
                  label: 'Balik',
                  enabled: canGoBack,
                  onTap: onBack,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Grade3PrimaryButton(
                  label: canGoNext ? 'Sunod' : 'Tapos',
                  onTap: onNext,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Grade3SentenceCard extends StatefulWidget {
  final String sentence;
  final bool highlighted;

  const _Grade3SentenceCard({
    required this.sentence,
    required this.highlighted,
  });

  @override
  State<_Grade3SentenceCard> createState() => _Grade3SentenceCardState();
}

class _Grade3SentenceCardState extends State<_Grade3SentenceCard> {
  bool _usedAudio = false;

  Future<void> _speak() async {
    setState(() => _usedAudio = true);
    await TudloVoiceButton.speak(context, widget.sentence, hiligaynon: true);
    if (mounted) setState(() => _usedAudio = false);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _speak,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: widget.highlighted
              ? const Color(0xFFFFF3A6)
              : Colors.white.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (widget.highlighted ? TudloColors.gold : TudloColors.ink)
                  .withValues(alpha: widget.highlighted ? .22 : .07),
              blurRadius: widget.highlighted ? 18 : 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.sentence,
                style: GoogleFonts.nunito(
                  color: TudloColors.ink,
                  fontSize: 22,
                  height: 1.18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 120),
              child: Icon(
                _usedAudio ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
                key: ValueKey(_usedAudio),
                color: TudloColors.green,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Grade3QuestionScreen extends StatefulWidget {
  final LessonQuestion question;
  final int questionIndex;
  final _Grade3StoryPageData storyPage;
  final _Grade3QuestionCompleted onCompleted;

  const _Grade3QuestionScreen({
    required this.question,
    required this.questionIndex,
    required this.storyPage,
    required this.onCompleted,
  });

  @override
  State<_Grade3QuestionScreen> createState() => _Grade3QuestionScreenState();
}

class _Grade3QuestionScreenState extends State<_Grade3QuestionScreen> {
  int _attemptCount = 0;
  int _shakeAttempt = 0;
  bool _usedAudioSupport = false;
  bool _usedLookBackSupport = false;
  bool _showLookBack = false;
  bool _correct = false;
  String? _selected;

  List<String> get _choices {
    final choices = widget.question.choices.isNotEmpty
        ? widget.question.choices
        : [widget.question.answer];
    return choices.toSet().toList();
  }

  Future<void> _speakPrompt() async {
    setState(() => _usedAudioSupport = true);
    await TudloVoiceButton.speak(
      context,
      _grade3QuestionPrompt(widget.question),
      hiligaynon: true,
    );
  }

  Future<void> _choose(String choice) async {
    if (_correct || _showLookBack) return;
    _attemptCount++;
    final correct = choice == widget.question.answer;
    setState(() {
      _selected = choice;
      _correct = correct;
      if (!correct) {
        _shakeAttempt++;
        _usedLookBackSupport = true;
        _showLookBack = true;
      }
    });
    if (!correct) {
      await TudloVoiceButton.speak(
        context,
        'Balikan ta ang sugilanon.',
        hiligaynon: true,
      );
      if (!mounted) return;
      await TudloVoiceButton.speak(
        context,
        widget.storyPage.sentences.first,
        hiligaynon: true,
      );
      return;
    }
    widget.onCompleted(
      widget.questionIndex,
      firstAttemptCorrect: _attemptCount == 1,
      attemptCount: _attemptCount,
      usedAudioSupport: _usedAudioSupport,
      usedLookBackSupport: _usedLookBackSupport,
    );
  }

  Future<void> _retry() async {
    setState(() {
      _showLookBack = false;
      _selected = null;
    });
    await TudloVoiceButton.speak(
      context,
      'Liwata. Pangitaa ang sabat sa sugilanon.',
      hiligaynon: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showLookBack) {
      return Column(
        children: [
          Expanded(
            child: _Grade3StoryScreen(
              page: widget.storyPage,
              pageNumber: 1,
              pageCount: 1,
              canGoBack: false,
              canGoNext: true,
              onBack: () {},
              onNext: _retry,
              highlightedSentenceIndex: 0,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: _Grade3TipBubble(
              text: 'Liwata. Pangitaa ang sabat sa sugilanon.',
            ),
          ),
        ],
      );
    }

    return _Grade3Stage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pamangkot',
                  style: GoogleFonts.nunito(
                    color: TudloColors.forest,
                    fontSize: 31,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              IconButton.filled(
                tooltip: 'Pamatii',
                onPressed: _speakPrompt,
                style: IconButton.styleFrom(
                  backgroundColor: TudloColors.softGreen,
                  foregroundColor: TudloColors.green,
                ),
                icon: const Icon(Icons.volume_up_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Grade3TipBubble(text: _grade3QuestionPrompt(widget.question)),
          const SizedBox(height: 20),
          for (final choice in _choices) ...[
            _Grade3AnswerCard(
              label: _grade3ChoiceLabel(choice),
              selected: _selected == choice,
              correct: _correct && _selected == choice,
              shakeKey: _selected == choice ? _shakeAttempt : 0,
              onTap: () => _choose(choice),
            ),
            const SizedBox(height: 12),
          ],
          const Spacer(),
          _Grade3TipBubble(text: 'Kon indi sigurado, baliki ang sugilanon.'),
        ],
      ),
    );
  }
}

class _Grade3AnswerCard extends StatelessWidget {
  final String label;
  final bool selected;
  final bool correct;
  final int shakeKey;
  final VoidCallback onTap;

  const _Grade3AnswerCard({
    required this.label,
    required this.selected,
    required this.correct,
    required this.shakeKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FeedbackMotion(
      key: ValueKey('g3-$label-$shakeKey'),
      correct: correct,
      wrong: shakeKey > 0 && !correct,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: correct
                ? TudloColors.green
                : selected
                ? TudloColors.gold
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: TudloColors.forest.withValues(alpha: .10),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: correct || selected ? Colors.white : TudloColors.ink,
              fontSize: 23,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _Grade3CompletionStep extends StatelessWidget {
  final LevelContent content;
  final VoidCallback onComplete;

  const _Grade3CompletionStep({
    required this.content,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return _Grade3Stage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const TudloMascot(size: 150),
          const SizedBox(height: 16),
          Text(
            'Maayo Gid!',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 38,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          _Grade3TipBubble(
            text:
                'Na-unlock ang libro: ${_grade3CleanTitle(content.storyTitle ?? content.title)}.',
          ),
          const SizedBox(height: 26),
          _Grade3PrimaryButton(label: 'Kuh-a ang Ganti', onTap: onComplete),
        ],
      ),
    );
  }
}

class _Grade3Stage extends StatelessWidget {
  final Widget child;

  const _Grade3Stage({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
          child: child,
        ),
      ),
    );
  }
}

class _Grade3TipBubble extends StatelessWidget {
  final String text;

  const _Grade3TipBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: TudloColors.forest.withValues(alpha: .08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
          color: TudloColors.ink,
          fontSize: 21,
          height: 1.15,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _Grade3PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _Grade3PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: TudloColors.green,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: TudloColors.forest.withValues(alpha: .22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 22,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _Grade3SecondaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _Grade3SecondaryButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: TudloColors.green,
          side: const BorderSide(color: TudloColors.green, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _Grade3PageDots extends StatelessWidget {
  final int current;
  final int count;

  const _Grade3PageDots({required this.current, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: current == index ? 24 : 9,
            height: 9,
            decoration: BoxDecoration(
              color: current == index ? TudloColors.green : TudloColors.line,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

List<_Grade3StoryPageData> _grade3StoryPagesFor(LevelContent content) {
  final imagePath = content.storyImageAsset?.trim().isNotEmpty == true
      ? content.storyImageAsset!.trim()
      : _storyImagePathForActiveGrade();
  final sentences = _grade3SentencesFor(content);
  final pages = <_Grade3StoryPageData>[];
  for (var index = 0; index < sentences.length; index += 2) {
    pages.add(
      _Grade3StoryPageData(
        id: '${content.id}-page-${pages.length + 1}',
        imagePath: imagePath,
        sentences: sentences.skip(index).take(2).toList(),
      ),
    );
  }
  return pages.isEmpty ? [_grade3FallbackStoryPage(content, 0)] : pages;
}

_Grade3StoryPageData _grade3FallbackStoryPage(LevelContent content, int index) {
  return _Grade3StoryPageData(
    id: '${content.id}-fallback-$index',
    imagePath: content.storyImageAsset?.trim().isNotEmpty == true
        ? content.storyImageAsset!.trim()
        : _storyImagePathForActiveGrade(),
    sentences: [_grade3CleanTitle(content.title)],
  );
}

List<String> _grade3SentencesFor(LevelContent content) {
  final source = [
    content.story,
    content.lesson,
    for (final example in content.examples) example.hiligaynon,
  ].whereType<String>().join(' ');
  final quoted = RegExp(r'"([^"]+)"')
      .allMatches(source)
      .map((match) => _grade3DisplayText(match.group(1) ?? ''))
      .where((value) => value.isNotEmpty)
      .toList();
  final rawSentences = quoted.length >= 4
      ? quoted
      : RegExp(r'[^.!?\n]+[.!?]?')
            .allMatches(source)
            .map((match) => _grade3DisplayText(match.group(0) ?? ''))
            .where((value) => value.isNotEmpty)
            .toList();
  final cleaned = rawSentences
      .map(_grade3ShortenSentence)
      .where((value) => value.isNotEmpty)
      .toList();
  if (cleaned.isEmpty) return [_grade3CleanTitle(content.title)];
  return cleaned.take(8).toList();
}

String _grade3ShortenSentence(String value) {
  final cleaned = _grade3DisplayText(value)
      .replaceAll(RegExp(r'^\d+\.\s*'), '')
      .replaceAll(RegExp(r'^(Presentation|Warm-up|Productive):\s*'), '')
      .trim();
  final words = cleaned.split(RegExp(r'\s+'));
  if (words.length <= 9) return cleaned;
  return '${words.take(9).join(' ')}.';
}

String _grade3CleanTitle(String value) {
  return _grade3DisplayText(value)
      .replaceAll(RegExp(r'\s*\([^)]*\)'), '')
      .replaceAll(
        RegExp(r'\b(New|Presentation|Productive)\b:?', caseSensitive: false),
        '',
      )
      .trim();
}

String _grade3DisplayText(String value) {
  return value
      .replaceAll('â€œ', '"')
      .replaceAll('â€', '"')
      .replaceAll('â€“', '-')
      .replaceAll('â€”', '-')
      .replaceAll('Â·', '-')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _grade3WarmUpText(LevelContent content) {
  if (content.unitNumber == 1 && content.lessonNumber == 1) {
    return 'Dumduma ang numero isa tubtob napulo.';
  }
  return 'Dumduma ang natun-an sa nagligad nga leksiyon.';
}

String _grade3QuestionPrompt(LessonQuestion question) {
  final prompt = _grade3DisplayText(question.prompt);
  final quoted = RegExp(r'"([^"]+)"').firstMatch(prompt)?.group(1);
  final text = quoted ?? prompt;
  if (text.toLowerCase().contains('how many')) {
    return text.replaceAll(RegExp('how many', caseSensitive: false), 'Pila');
  }
  if (text.toLowerCase().contains('how much')) {
    return text.replaceAll(
      RegExp('how much', caseSensitive: false),
      'Pila ang bili sang',
    );
  }
  if (text.toLowerCase().startsWith('reverse')) {
    return 'Pamatii kag pili-a ang husto.';
  }
  return text;
}

String _grade3ChoiceLabel(String choice) {
  final cleaned = _grade3DisplayText(choice);
  final number = RegExp(r'\b([0-9]{1,2})\b').firstMatch(cleaned)?.group(1);
  if (number != null) return number;
  return cleaned
      .replaceAll(
        RegExp(r'^(tap|count, tap|tap the)\s+', caseSensitive: false),
        '',
      )
      .replaceAll(RegExp(r'\s+-\s+.*$'), '')
      .trim();
}

class _GradeTwoTalkBuildSolveLesson extends StatefulWidget {
  final LevelContent content;
  final ValueChanged<int> onQuizCorrect;

  const _GradeTwoTalkBuildSolveLesson({
    required this.content,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeTwoTalkBuildSolveLesson> createState() =>
      _GradeTwoTalkBuildSolveLessonState();
}

class _GradeTwoTalkBuildSolveLessonState
    extends State<_GradeTwoTalkBuildSolveLesson> {
  late final _GradeTwoPlan _plan = _gradeTwoPlanFor(widget.content);
  int _step = 0;
  int _reported = 0;
  bool _finished = false;

  void _advance() {
    _reportOne();
    if (!mounted) return;
    if (_step >= 2) {
      _finish();
      return;
    }
    setState(() => _step++);
  }

  void _reportOne() {
    if (_reported >= widget.content.quizItems.length) return;
    widget.onQuizCorrect(_reported);
    _reported++;
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    while (_reported < widget.content.quizItems.length) {
      widget.onQuizCorrect(_reported);
      _reported++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      widget.content.unitNumber == 1 && widget.content.lessonNumber == 2
          ? _GradeTwoBirthdayCandleCard(plan: _plan, onDone: _advance)
          : _GradeTwoSceneCard(plan: _plan, onDone: _advance),
      _GradeTwoSentenceBuilderCard(plan: _plan, onDone: _advance),
      _GradeTwoDialogueChoiceCard(plan: _plan, onDone: _advance),
    ];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(.04, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey(_step), child: cards[_step]),
    );
  }
}

class _GradeTwoPlan {
  final String sceneTitle;
  final String sceneLine;
  final String tapInstruction;
  final String phrase;
  final String phraseSpeech;
  final String buildPrompt;
  final String buildQuestion;
  final String? buildCharacterAsset;
  final String buildAnswer;
  final List<String> buildTiles;
  final String choicePrompt;
  final List<String> choices;
  final String answer;
  final String missionTitle;
  final String missionPrompt;
  final List<_GradeTwoMissionChoice> missionChoices;
  final String missionAnswer;
  final String reward;
  final String? imageAsset;
  final IconData icon;
  final Color color;

  const _GradeTwoPlan({
    required this.sceneTitle,
    required this.sceneLine,
    required this.tapInstruction,
    required this.phrase,
    required this.phraseSpeech,
    required this.buildPrompt,
    required this.buildQuestion,
    this.buildCharacterAsset,
    required this.buildAnswer,
    required this.buildTiles,
    required this.choicePrompt,
    required this.choices,
    required this.answer,
    required this.missionTitle,
    required this.missionPrompt,
    required this.missionChoices,
    required this.missionAnswer,
    required this.reward,
    this.imageAsset,
    required this.icon,
    required this.color,
  });
}

class _GradeTwoMissionChoice {
  final String label;
  final String? visualLabel;
  final String? imageAsset;
  final IconData icon;

  const _GradeTwoMissionChoice({
    required this.label,
    this.visualLabel,
    this.imageAsset,
    required this.icon,
  });
}

class _GradeTwoTileVisual {
  final String label;
  final String? imageAsset;
  final IconData icon;
  final Color color;

  const _GradeTwoTileVisual({
    required this.label,
    this.imageAsset,
    required this.icon,
    required this.color,
  });
}

class _GradeTwoSceneCard extends StatefulWidget {
  final _GradeTwoPlan plan;
  final VoidCallback onDone;

  const _GradeTwoSceneCard({required this.plan, required this.onDone});

  @override
  State<_GradeTwoSceneCard> createState() => _GradeTwoSceneCardState();
}

class _GradeTwoSceneCardState extends State<_GradeTwoSceneCard> {
  bool _tapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          widget.plan.tapInstruction,
          hiligaynon: true,
        ),
      );
    });
  }

  Future<void> _tapScene() async {
    if (_tapped) return;
    setState(() => _tapped = true);
    await TudloVoiceButton.speak(context, widget.plan.phraseSpeech);
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _GradeTwoStage(
      mascotMessage: _tapped
          ? 'Koka: ${widget.plan.phrase}'
          : 'Koka: ${widget.plan.tapInstruction}',
      child: Column(
        children: [
          Text(
            widget.plan.sceneTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: 32,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _tapScene,
            child: _AnimalBounce(
              active: _tapped,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  _GradeTwoArt(plan: widget.plan, size: 270),
                  if (_tapped) const _AnimalSparkles(size: 300),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _GradeTwoSpeechBubble(text: widget.plan.phrase, onTap: _tapScene),
        ],
      ),
    );
  }
}

class _GradeTwoBirthdayCandleCard extends StatefulWidget {
  final _GradeTwoPlan plan;
  final VoidCallback onDone;

  const _GradeTwoBirthdayCandleCard({required this.plan, required this.onDone});

  @override
  State<_GradeTwoBirthdayCandleCard> createState() =>
      _GradeTwoBirthdayCandleCardState();
}

class _GradeTwoBirthdayCandleCardState
    extends State<_GradeTwoBirthdayCandleCard> {
  int _candles = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          'Guyoda ang pito ka kandila pakadto sa cake.',
          hiligaynon: true,
        ),
      );
    });
  }

  Future<void> _addCandle() async {
    if (_done) return;
    setState(() => _candles = (_candles + 1).clamp(0, 7));
    if (_candles < 7) return;
    _done = true;
    await TudloVoiceButton.speak(
      context,
      'Husto! Pito ka kandila.',
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _GradeTwoStage(
      mascotMessage: 'Koka: Guyoda ang pito ka kandila pakadto sa cake.',
      child: Column(
        children: [
          Text(
            widget.plan.sceneTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: 32,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          _GradeTwoSpeechBubble(text: 'Pito ka kandila'),
          const SizedBox(height: 12),
          DragTarget<String>(
            onWillAcceptWithDetails: (_) => !_done,
            onAcceptWithDetails: (_) => _addCandle(),
            builder: (context, candidates, rejected) {
              return AnimatedScale(
                duration: const Duration(milliseconds: 160),
                scale: candidates.isNotEmpty ? 1.04 : 1,
                child: SizedBox(
                  width: 320,
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/images/level_game/Grade2/cake.png',
                        width: 280,
                        height: 220,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                      Positioned(
                        top: 26,
                        child: Wrap(
                          spacing: 4,
                          children: [
                            for (var index = 0; index < _candles; index++)
                              Image.asset(
                                'assets/images/level_game/Grade2/candle.png',
                                width: 28,
                                height: 54,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.local_fire_department_rounded,
                                  color: TudloColors.coral,
                                  size: 32,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            '$_candles / 7',
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          if (!_done)
            Draggable<String>(
              data: 'candle',
              feedback: Material(
                color: Colors.transparent,
                child: Image.asset(
                  'assets/images/level_game/Grade2/candle.png',
                  width: 52,
                  height: 92,
                  fit: BoxFit.contain,
                ),
              ),
              childWhenDragging: Opacity(
                opacity: .35,
                child: _CandleButton(color: widget.plan.color),
              ),
              child: _CandleButton(color: widget.plan.color),
            ),
        ],
      ),
    );
  }
}

class _CandleButton extends StatelessWidget {
  final Color color;

  const _CandleButton({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      height: 98,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/level_game/Grade2/candle.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.local_fire_department_rounded, color: color, size: 52),
      ),
    );
  }
}

class _GradeTwoSentenceBuilderCard extends StatefulWidget {
  final _GradeTwoPlan plan;
  final VoidCallback onDone;

  const _GradeTwoSentenceBuilderCard({
    required this.plan,
    required this.onDone,
  });

  @override
  State<_GradeTwoSentenceBuilderCard> createState() =>
      _GradeTwoSentenceBuilderCardState();
}

class _GradeTwoSentenceBuilderCardState
    extends State<_GradeTwoSentenceBuilderCard> {
  final List<String> _built = [];
  bool _done = false;

  Future<void> _addTile(String tile) async {
    if (_done || _built.contains(tile)) return;
    await TudloVoiceButton.speak(
      context,
      _gradeTwoTileVisualFor(tile).label,
      hiligaynon: true,
    );
    if (!mounted) return;
    setState(() => _built.add(tile));
    if (_normalizedSentence(_built.join(' ')) ==
        _normalizedSentence(widget.plan.buildAnswer)) {
      _done = true;
      await TudloVoiceButton.speak(
        context,
        widget.plan.phraseSpeech,
        hiligaynon: true,
      );
      if (!mounted) return;
      Future<void>.delayed(const Duration(milliseconds: 850), () {
        if (mounted) widget.onDone();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.plan.buildTiles
        .where((tile) => !_built.contains(tile))
        .toList();
    final focus = _gradeTwoBuildFocusFor(widget.plan);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 22),
          child: Column(
            children: [
              Text(
                widget.plan.buildPrompt,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: TudloColors.forest,
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 14),
              _GradeTwoQuestionCharacter(
                question: widget.plan.buildQuestion,
                imageAsset: widget.plan.buildCharacterAsset,
                color: widget.plan.color,
              ),
              if (focus != null) ...[
                const SizedBox(height: 10),
                _GradeTwoFocusPicture(visual: focus, color: widget.plan.color),
              ],
              const SizedBox(height: 16),
              _GradeTwoBuildTray(
                words: _built,
                target: widget.plan.buildAnswer,
                color: widget.plan.color,
                onRemove: (index) {
                  if (_done) return;
                  setState(() => _built.removeAt(index));
                },
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final tile in remaining)
                    _GradeTwoTile(
                      label: tile,
                      color: widget.plan.color,
                      onTap: () => _addTile(tile),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeTwoDialogueChoiceCard extends StatefulWidget {
  final _GradeTwoPlan plan;
  final VoidCallback onDone;

  const _GradeTwoDialogueChoiceCard({required this.plan, required this.onDone});

  @override
  State<_GradeTwoDialogueChoiceCard> createState() =>
      _GradeTwoDialogueChoiceCardState();
}

class _GradeTwoDialogueChoiceCardState
    extends State<_GradeTwoDialogueChoiceCard> {
  String? _selected;
  int _attempt = 0;

  Future<void> _choose(String choice) async {
    if (_selected == widget.plan.answer) return;
    await TudloVoiceButton.speak(context, choice, hiligaynon: true);
    if (!mounted) return;
    final correct = choice == widget.plan.answer;
    setState(() {
      _selected = choice;
      _attempt++;
    });
    if (!correct) {
      await TudloVoiceButton.speak(
        context,
        'Liwata. Pili-a ang husto nga sabat.',
        hiligaynon: true,
      );
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 22),
          child: Column(
            children: [
              _GradeTwoSpeechBubble(text: widget.plan.choicePrompt),
              const SizedBox(height: 18),
              _GradeTwoAnswerBubble(text: _selected ?? ''),
              const SizedBox(height: 8),
              const TudloMascot(size: 190),
              const SizedBox(height: 16),
              for (final choice in widget.plan.choices) ...[
                _GradeTwoChoiceButton(
                  key: ValueKey('$choice-$_attempt'),
                  label: choice,
                  selected: _selected == choice,
                  correct: choice == widget.plan.answer,
                  checked: _selected == choice,
                  color: widget.plan.color,
                  onTap: () => _choose(choice),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeTwoMissionCard extends StatefulWidget {
  final _GradeTwoPlan plan;
  final VoidCallback onDone;

  const _GradeTwoMissionCard({required this.plan, required this.onDone});

  @override
  State<_GradeTwoMissionCard> createState() => _GradeTwoMissionCardState();
}

class _GradeTwoMissionCardState extends State<_GradeTwoMissionCard> {
  String? _selected;
  int _attempt = 0;

  Future<void> _choose(_GradeTwoMissionChoice choice) async {
    if (_selected == widget.plan.missionAnswer) return;
    await TudloVoiceButton.speak(context, choice.label);
    if (!mounted) return;
    final correct = choice.label == widget.plan.missionAnswer;
    setState(() {
      _selected = choice.label;
      _attempt++;
    });
    if (!correct) {
      await TudloVoiceButton.speak(
        context,
        'Liwata. Tan-awa liwat ang sitwasyon.',
        hiligaynon: true,
      );
      return;
    }
    await TudloVoiceButton.speak(
      context,
      'Husto! ${widget.plan.reward}',
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 22),
          child: Column(
            children: [
              const TudloMascot(size: 148),
              const SizedBox(height: 12),
              _GradeTwoSpeechBubble(text: widget.plan.missionPrompt),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final choice in widget.plan.missionChoices)
                    _GradeTwoMissionOption(
                      key: ValueKey('${choice.label}-$_attempt'),
                      choice: choice,
                      color: widget.plan.color,
                      selected: _selected == choice.label,
                      correct: choice.label == widget.plan.missionAnswer,
                      checked: _selected == choice.label,
                      onTap: () => _choose(choice),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeTwoStage extends StatelessWidget {
  final Widget child;
  final String mascotMessage;

  const _GradeTwoStage({required this.child, required this.mascotMessage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 260),
                    child: child,
                  ),
                ),
                Positioned(
                  right: -22,
                  bottom: -18,
                  child: IgnorePointer(
                    child: _AlphabetMascotBubble(message: mascotMessage),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GradeTwoArt extends StatelessWidget {
  final _GradeTwoPlan plan;
  final double size;

  const _GradeTwoArt({required this.plan, required this.size});

  @override
  Widget build(BuildContext context) {
    if (plan.imageAsset != null) {
      return Image.asset(
        plan.imageAsset!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _GradeTwoIconArt(plan: plan, size: size),
      );
    }
    return _GradeTwoIconArt(plan: plan, size: size);
  }
}

class _GradeTwoIconArt extends StatelessWidget {
  final _GradeTwoPlan plan;
  final double size;

  const _GradeTwoIconArt({required this.plan, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: plan.color.withValues(alpha: .16),
        boxShadow: [
          BoxShadow(
            color: plan.color.withValues(alpha: .16),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Icon(plan.icon, color: plan.color, size: size * .54),
    );
  }
}

class _GradeTwoSpeechBubble extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _GradeTwoSpeechBubble({required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: TudloColors.forest.withValues(alpha: .10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
          color: TudloColors.ink,
          fontSize: 25,
          height: 1.08,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );

    if (onTap == null) return bubble;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: bubble,
      ),
    );
  }
}

class _GradeTwoAnswerBubble extends StatelessWidget {
  final String text;

  const _GradeTwoAnswerBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final hasText = text.trim().isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: hasText
            ? TudloColors.softGreen
            : Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: TudloColors.forest.withValues(alpha: hasText ? .20 : .10),
            blurRadius: hasText ? 22 : 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(
            hasText ? text : ' ',
            key: ValueKey(text),
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: hasText ? TudloColors.ink : TudloColors.muted,
              fontSize: 26,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _GradeTwoQuestionCharacter extends StatelessWidget {
  final String question;
  final String? imageAsset;
  final Color color;

  const _GradeTwoQuestionCharacter({
    required this.question,
    required this.imageAsset,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 142,
          height: 178,
          child: imageAsset == null
              ? Icon(Icons.face_rounded, color: color, size: 112)
              : Image.asset(
                  imageAsset!,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.face_rounded, color: color, size: 112),
                ),
        ),
        const SizedBox(width: 8),
        Expanded(child: _GradeTwoSpeechBubble(text: question)),
      ],
    );
  }
}

class _GradeTwoFocusPicture extends StatelessWidget {
  final _GradeTwoTileVisual visual;
  final Color color;

  const _GradeTwoFocusPicture({required this.visual, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 236,
      height: 194,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (visual.imageAsset != null)
            Image.asset(
              visual.imageAsset!,
              width: 166,
              height: 126,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) =>
                  Icon(visual.icon, color: color, size: 96),
            )
          else
            Icon(visual.icon, color: visual.color, size: 80),
          const SizedBox(height: 6),
          Text(
            visual.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: 24,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeTwoBuildTray extends StatelessWidget {
  final List<String> words;
  final String target;
  final Color color;
  final ValueChanged<int> onRemove;

  const _GradeTwoBuildTray({
    required this.words,
    required this.target,
    required this.color,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final complete =
        _normalizedSentence(words.join(' ')) == _normalizedSentence(target);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: complete
            ? TudloColors.softGreen.withValues(alpha: .90)
            : Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: words.isEmpty
          ? Center(
              child: Text(
                'Ibutang diri ang imo sabat',
                style: GoogleFonts.nunito(
                  color: TudloColors.muted,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            )
          : Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var index = 0; index < words.length; index++)
                  _GradeTwoBuiltWord(
                    label: words[index],
                    color: color,
                    onTap: () => onRemove(index),
                  ),
              ],
            ),
    );
  }
}

class _GradeTwoTile extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GradeTwoTile({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visual = _gradeTwoTileVisualFor(label);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: visual.imageAsset == null ? 144 : 138,
          height: visual.imageAsset == null ? 76 : 150,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: .28),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (visual.imageAsset != null) ...[
                Image.asset(
                  visual.imageAsset!,
                  width: 72,
                  height: 82,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) =>
                      Icon(visual.icon, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 6),
              ] else if (visual.icon != Icons.text_fields_rounded) ...[
                Icon(visual.icon, color: Colors.white, size: 38),
                const SizedBox(height: 4),
              ],
              FittedBox(
                child: Text(
                  visual.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 23,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
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

class _GradeTwoBuiltWord extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GradeTwoBuiltWord({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visual = _gradeTwoTileVisualFor(label);
    return ActionChip(
      onPressed: onTap,
      backgroundColor: color.withValues(alpha: .16),
      side: BorderSide.none,
      label: Text(
        visual.label,
        style: GoogleFonts.nunito(
          color: TudloColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _GradeTwoChoiceButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool correct;
  final bool checked;
  final Color color;
  final VoidCallback onTap;

  const _GradeTwoChoiceButton({
    super.key,
    required this.label,
    required this.selected,
    required this.correct,
    required this.checked,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final wrong = checked && !correct;
    final visual = _gradeTwoTileVisualFor(label);
    final hasArt =
        visual.imageAsset != null || visual.icon != Icons.text_fields_rounded;
    final activeColor = wrong
        ? const Color(0xFFE53935)
        : checked && correct
        ? TudloColors.green
        : color;
    return _FeedbackMotion(
      correct: checked && correct,
      wrong: wrong,
      child: SizedBox(
        width: double.infinity,
        height: hasArt ? 102 : 76,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: activeColor,
            foregroundColor: Colors.white,
            elevation: selected ? 8 : 4,
            shadowColor: activeColor.withValues(alpha: .24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            textStyle: GoogleFonts.nunito(
              fontSize: 23,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          child: hasArt
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (visual.imageAsset != null)
                      Image.asset(
                        visual.imageAsset!,
                        width: 58,
                        height: 58,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) =>
                            Icon(visual.icon, color: Colors.white, size: 44),
                      )
                    else
                      Icon(visual.icon, color: Colors.white, size: 42),
                    const SizedBox(width: 14),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(visual.label, textAlign: TextAlign.center),
                      ),
                    ),
                  ],
                )
              : FittedBox(
                  child: Text(visual.label, textAlign: TextAlign.center),
                ),
        ),
      ),
    );
  }
}

class _GradeTwoMissionOption extends StatelessWidget {
  final _GradeTwoMissionChoice choice;
  final Color color;
  final bool selected;
  final bool correct;
  final bool checked;
  final VoidCallback onTap;

  const _GradeTwoMissionOption({
    super.key,
    required this.choice,
    required this.color,
    required this.selected,
    required this.correct,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final wrong = checked && !correct;
    return _FeedbackMotion(
      correct: checked && correct,
      wrong: wrong,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 168,
          height: 194,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: wrong
                ? const Color(0xFFFFE7E7)
                : checked && correct
                ? TudloColors.softGreen
                : Colors.white.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: (selected ? color : TudloColors.forest).withValues(
                  alpha: selected ? .22 : .10,
                ),
                blurRadius: selected ? 22 : 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GradeTwoMissionArt(choice: choice, color: color, size: 112),
              const SizedBox(height: 12),
              Text(
                choice.visualLabel ?? choice.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  color: wrong ? const Color(0xFFE53935) : TudloColors.ink,
                  fontSize: 22,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeTwoMissionArt extends StatelessWidget {
  final _GradeTwoMissionChoice choice;
  final Color color;
  final double size;

  const _GradeTwoMissionArt({
    required this.choice,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (choice.imageAsset != null) {
      return Image.asset(
        choice.imageAsset!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) =>
            Icon(choice.icon, color: color, size: size * .72),
      );
    }
    return Icon(choice.icon, color: color, size: size * .72);
  }
}

String _normalizedSentence(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[.!?"]'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
}

_GradeTwoTileVisual? _gradeTwoBuildFocusFor(_GradeTwoPlan plan) {
  for (final tile in plan.buildTiles) {
    final visual = _gradeTwoTileVisualFor(tile);
    if (visual.imageAsset != null && plan.buildAnswer.contains(tile)) {
      return visual;
    }
  }
  for (final tile in plan.buildTiles) {
    final visual = _gradeTwoTileVisualFor(tile);
    if (visual.icon != Icons.text_fields_rounded &&
        plan.buildAnswer.contains(tile)) {
      return visual;
    }
  }
  return null;
}

_GradeTwoTileVisual _gradeTwoTileVisualFor(String value) {
  const grade2 = 'assets/images/level_game/Grade2';
  const grade1 = 'assets/images/level_game/Grade1/unit1';
  final key = value.trim().toLowerCase();
  return switch (key) {
    'my name is' => const _GradeTwoTileVisual(
      label: 'Ako si',
      icon: Icons.badge_rounded,
      color: TudloColors.green,
    ),
    'koka' => const _GradeTwoTileVisual(
      label: 'Koka',
      imageAsset: 'assets/images/dialogue/mascot2.png',
      icon: Icons.face_rounded,
      color: TudloColors.green,
    ),
    'hello' => const _GradeTwoTileVisual(
      label: 'Kumusta',
      icon: Icons.waving_hand_rounded,
      color: TudloColors.gold,
    ),
    'kumusta' || 'kumusta!' => const _GradeTwoTileVisual(
      label: 'Kumusta',
      icon: Icons.waving_hand_rounded,
      color: TudloColors.gold,
    ),
    'paalam' || 'paalam!' => const _GradeTwoTileVisual(
      label: 'Paalam',
      icon: Icons.waving_hand_rounded,
      color: TudloColors.blue,
    ),
    'goodbye' || 'goodbye!' => const _GradeTwoTileVisual(
      label: 'Paalam',
      icon: Icons.waving_hand_rounded,
      color: TudloColors.blue,
    ),
    'koka ang ngalan ko' || 'koka ang ngalan ko.' => const _GradeTwoTileVisual(
      label: 'Koka ang ngalan ko',
      imageAsset: 'assets/images/dialogue/mascot2.png',
      icon: Icons.face_rounded,
      color: TudloColors.green,
    ),
    'i am' => const _GradeTwoTileVisual(
      label: 'Ako',
      icon: Icons.person_rounded,
      color: TudloColors.green,
    ),
    'seven' => const _GradeTwoTileVisual(
      label: 'pito',
      icon: Icons.cake_rounded,
      color: TudloColors.coral,
    ),
    'six' => const _GradeTwoTileVisual(
      label: 'anum',
      icon: Icons.looks_6_rounded,
      color: TudloColors.orange,
    ),
    'years old' => const _GradeTwoTileVisual(
      label: 'ka tuig',
      icon: Icons.cake_rounded,
      color: TudloColors.coral,
    ),
    'pito ka tuig ako' || 'pito ka tuig ako.' => const _GradeTwoTileVisual(
      label: 'Pito ka tuig ako',
      imageAsset: '$grade2/cake.png',
      icon: Icons.cake_rounded,
      color: TudloColors.coral,
    ),
    'this is my' => const _GradeTwoTileVisual(
      label: 'Amo ini',
      icon: Icons.text_fields_rounded,
      color: TudloColors.blue,
    ),
    'this is a' => const _GradeTwoTileVisual(
      label: 'Ini ang',
      icon: Icons.text_fields_rounded,
      color: TudloColors.blue,
    ),
    'it is a' => const _GradeTwoTileVisual(
      label: 'Ini ang',
      icon: Icons.text_fields_rounded,
      color: TudloColors.blue,
    ),
    'touch your' => const _GradeTwoTileVisual(
      label: 'Tanduga ang',
      icon: Icons.touch_app_rounded,
      color: TudloColors.coral,
    ),
    'mother' => const _GradeTwoTileVisual(
      label: 'nanay',
      imageAsset: '$grade1/nanay.png',
      icon: Icons.woman_rounded,
      color: TudloColors.blue,
    ),
    'nanay' => const _GradeTwoTileVisual(
      label: 'nanay',
      imageAsset: '$grade1/nanay.png',
      icon: Icons.woman_rounded,
      color: TudloColors.blue,
    ),
    'father' => const _GradeTwoTileVisual(
      label: 'tatay',
      imageAsset: '$grade1/tatay.png',
      icon: Icons.man_rounded,
      color: TudloColors.green,
    ),
    'tatay' => const _GradeTwoTileVisual(
      label: 'tatay',
      imageAsset: '$grade1/tatay.png',
      icon: Icons.man_rounded,
      color: TudloColors.green,
    ),
    'amo ini ang akon nanay' ||
    'amo ini ang akon nanay.' => const _GradeTwoTileVisual(
      label: 'Amo ini ang akon nanay',
      imageAsset: '$grade1/nanay.png',
      icon: Icons.woman_rounded,
      color: TudloColors.blue,
    ),
    'book' => const _GradeTwoTileVisual(
      label: 'libro',
      imageAsset: '$grade2/book.png',
      icon: Icons.menu_book_rounded,
      color: TudloColors.green,
    ),
    'libro' => const _GradeTwoTileVisual(
      label: 'libro',
      imageAsset: '$grade2/book.png',
      icon: Icons.menu_book_rounded,
      color: TudloColors.green,
    ),
    'pencil' => const _GradeTwoTileVisual(
      label: 'lapis',
      imageAsset: '$grade2/pencil.png',
      icon: Icons.edit_rounded,
      color: TudloColors.gold,
    ),
    'lapis' => const _GradeTwoTileVisual(
      label: 'lapis',
      imageAsset: '$grade2/pencil.png',
      icon: Icons.edit_rounded,
      color: TudloColors.gold,
    ),
    'bag' => const _GradeTwoTileVisual(
      label: 'bag',
      imageAsset: '$grade2/bag.png',
      icon: Icons.backpack_rounded,
      color: TudloColors.coral,
    ),
    'chair' => const _GradeTwoTileVisual(
      label: 'pulungkuan',
      imageAsset: '$grade2/chair.png',
      icon: Icons.chair_rounded,
      color: TudloColors.blue,
    ),
    'pulungkuan' => const _GradeTwoTileVisual(
      label: 'pulungkuan',
      imageAsset: '$grade2/chair.png',
      icon: Icons.chair_rounded,
      color: TudloColors.blue,
    ),
    'plate' => const _GradeTwoTileVisual(
      label: 'plato',
      imageAsset: '$grade2/plate.png',
      icon: Icons.dinner_dining_rounded,
      color: TudloColors.coral,
    ),
    'plato' => const _GradeTwoTileVisual(
      label: 'plato',
      imageAsset: '$grade2/plate.png',
      icon: Icons.dinner_dining_rounded,
      color: TudloColors.coral,
    ),
    'glass' => const _GradeTwoTileVisual(
      label: 'baso',
      imageAsset: '$grade2/glass.png',
      icon: Icons.local_drink_rounded,
      color: TudloColors.blue,
    ),
    'baso' => const _GradeTwoTileVisual(
      label: 'baso',
      imageAsset: '$grade2/glass.png',
      icon: Icons.local_drink_rounded,
      color: TudloColors.blue,
    ),
    'spoon' => const _GradeTwoTileVisual(
      label: 'kutsara',
      imageAsset: '$grade2/spoon.png',
      icon: Icons.restaurant_rounded,
      color: TudloColors.orange,
    ),
    'kutsara' => const _GradeTwoTileVisual(
      label: 'kutsara',
      imageAsset: '$grade2/spoon.png',
      icon: Icons.restaurant_rounded,
      color: TudloColors.orange,
    ),
    'tree' => const _GradeTwoTileVisual(
      label: 'kahoy',
      icon: Icons.park_rounded,
      color: TudloColors.forest,
    ),
    'kahoy' => const _GradeTwoTileVisual(
      label: 'kahoy',
      icon: Icons.park_rounded,
      color: TudloColors.forest,
    ),
    'flower' => const _GradeTwoTileVisual(
      label: 'bulak',
      icon: Icons.local_florist_rounded,
      color: TudloColors.coral,
    ),
    'bulak' => const _GradeTwoTileVisual(
      label: 'bulak',
      icon: Icons.local_florist_rounded,
      color: TudloColors.coral,
    ),
    'rock' => const _GradeTwoTileVisual(
      label: 'bato',
      icon: Icons.landscape_rounded,
      color: TudloColors.muted,
    ),
    'good' => const _GradeTwoTileVisual(
      label: 'maayo',
      icon: Icons.thumb_up_rounded,
      color: TudloColors.green,
    ),
    'maayo man, salamat' || 'maayo man, salamat.' => const _GradeTwoTileVisual(
      label: 'Maayo man, salamat',
      icon: Icons.mood_rounded,
      color: TudloColors.green,
    ),
    "i'm fine" => const _GradeTwoTileVisual(
      label: 'Maayo man',
      icon: Icons.mood_rounded,
      color: TudloColors.green,
    ),
    'thank' => const _GradeTwoTileVisual(
      label: 'sala',
      icon: Icons.favorite_rounded,
      color: TudloColors.coral,
    ),
    'you' => const _GradeTwoTileVisual(
      label: 'mat',
      icon: Icons.favorite_rounded,
      color: TudloColors.coral,
    ),
    'thank you' => const _GradeTwoTileVisual(
      label: 'Salamat',
      icon: Icons.favorite_rounded,
      color: TudloColors.coral,
    ),
    'salamat' || 'salamat.' => const _GradeTwoTileVisual(
      label: 'Salamat',
      icon: Icons.favorite_rounded,
      color: TudloColors.coral,
    ),
    'please' => const _GradeTwoTileVisual(
      label: 'Palihog',
      icon: Icons.volunteer_activism_rounded,
      color: TudloColors.green,
    ),
    'sorry' => const _GradeTwoTileVisual(
      label: 'Pasensya',
      icon: Icons.sentiment_dissatisfied_rounded,
      color: TudloColors.orange,
    ),
    'morning' => const _GradeTwoTileVisual(
      label: 'aga',
      icon: Icons.wb_sunny_rounded,
      color: TudloColors.gold,
    ),
    'maayong aga' || 'maayong aga!' => const _GradeTwoTileVisual(
      label: 'Maayong aga',
      icon: Icons.wb_sunny_rounded,
      color: TudloColors.gold,
    ),
    'good morning' => const _GradeTwoTileVisual(
      label: 'Maayong aga',
      icon: Icons.wb_sunny_rounded,
      color: TudloColors.gold,
    ),
    'evening' => const _GradeTwoTileVisual(
      label: 'gab-i',
      icon: Icons.dark_mode_rounded,
      color: TudloColors.blue,
    ),
    'maayong gab-i' || 'maayong gab-i!' => const _GradeTwoTileVisual(
      label: 'Maayong gab-i',
      icon: Icons.dark_mode_rounded,
      color: TudloColors.blue,
    ),
    'head' || 'ulo' => const _GradeTwoTileVisual(
      label: 'ulo',
      icon: Icons.face_rounded,
      color: TudloColors.coral,
    ),
    'feet' || 'tiil' => const _GradeTwoTileVisual(
      label: 'tiil',
      icon: Icons.directions_walk_rounded,
      color: TudloColors.green,
    ),
    'eyes' || 'mata' => const _GradeTwoTileVisual(
      label: 'mata',
      icon: Icons.visibility_rounded,
      color: TudloColors.blue,
    ),
    'dog' || 'ido' => const _GradeTwoTileVisual(
      label: 'ido',
      imageAsset: '$grade1/dog.png',
      icon: Icons.pets_rounded,
      color: TudloColors.orange,
    ),
    'cat' || 'kuring' => const _GradeTwoTileVisual(
      label: 'kuring',
      imageAsset: '$grade1/cat.png',
      icon: Icons.pets_rounded,
      color: TudloColors.blue,
    ),
    'pig' || 'baboy' => const _GradeTwoTileVisual(
      label: 'baboy',
      icon: Icons.pets_rounded,
      color: TudloColors.coral,
    ),
    'mat' || 'banig' => const _GradeTwoTileVisual(
      label: 'banig',
      icon: Icons.crop_square_rounded,
      color: TudloColors.green,
    ),
    'fish' || 'isda' => const _GradeTwoTileVisual(
      label: 'isda',
      imageAsset: '$grade1/fish.png',
      icon: Icons.water_rounded,
      color: TudloColors.blue,
    ),
    'sun' || 'adlaw' => const _GradeTwoTileVisual(
      label: 'adlaw',
      icon: Icons.wb_sunny_rounded,
      color: TudloColors.gold,
    ),
    'jump' || 'lumpat' => const _GradeTwoTileVisual(
      label: 'lumpat',
      icon: Icons.keyboard_arrow_up_rounded,
      color: TudloColors.coral,
    ),
    'wave' || 'paypay' => const _GradeTwoTileVisual(
      label: 'paypay',
      icon: Icons.waving_hand_rounded,
      color: TudloColors.gold,
    ),
    'turn' || 'liko' => const _GradeTwoTileVisual(
      label: 'liko',
      icon: Icons.rotate_right_rounded,
      color: TudloColors.blue,
    ),
    'happy' || 'malipayon' => const _GradeTwoTileVisual(
      label: 'malipayon',
      icon: Icons.mood_rounded,
      color: TudloColors.green,
    ),
    'to my' => const _GradeTwoTileVisual(
      label: 'sa akon',
      icon: Icons.text_fields_rounded,
      color: TudloColors.green,
    ),
    'my' => const _GradeTwoTileVisual(
      label: 'akon',
      icon: Icons.text_fields_rounded,
      color: TudloColors.green,
    ),
    'sits' => const _GradeTwoTileVisual(
      label: 'nagapungko',
      icon: Icons.event_seat_rounded,
      color: TudloColors.blue,
    ),
    'i can' => const _GradeTwoTileVisual(
      label: 'Maka',
      icon: Icons.directions_run_rounded,
      color: TudloColors.coral,
    ),
    'is' => const _GradeTwoTileVisual(
      label: 'nga',
      icon: Icons.text_fields_rounded,
      color: TudloColors.green,
    ),
    'merkado' => const _GradeTwoTileVisual(
      label: 'merkado',
      icon: Icons.storefront_rounded,
      color: TudloColors.orange,
    ),
    _ => _GradeTwoTileVisual(
      label: value,
      icon: Icons.text_fields_rounded,
      color: TudloColors.green,
    ),
  };
}

_GradeTwoPlan _gradeTwoPlanFor(LevelContent content) {
  const grade2 = 'assets/images/level_game/Grade2';
  const grade1 = 'assets/images/level_game/Grade1/unit1';

  _GradeTwoPlan plan({
    required String sceneTitle,
    required String sceneLine,
    required String tapInstruction,
    required String phrase,
    required String phraseSpeech,
    required String buildPrompt,
    required String buildQuestion,
    String? buildCharacterAsset,
    required String buildAnswer,
    required List<String> buildTiles,
    required String choicePrompt,
    required List<String> choices,
    required String answer,
    required String missionTitle,
    required String missionPrompt,
    required List<_GradeTwoMissionChoice> missionChoices,
    required String missionAnswer,
    required String reward,
    String? imageAsset,
    required IconData icon,
    required Color color,
  }) {
    return _GradeTwoPlan(
      sceneTitle: sceneTitle,
      sceneLine: sceneLine,
      tapInstruction: tapInstruction,
      phrase: phrase,
      phraseSpeech: phraseSpeech,
      buildPrompt: buildPrompt,
      buildQuestion: buildQuestion,
      buildCharacterAsset: buildCharacterAsset,
      buildAnswer: buildAnswer,
      buildTiles: buildTiles,
      choicePrompt: choicePrompt,
      choices: choices,
      answer: answer,
      missionTitle: missionTitle,
      missionPrompt: missionPrompt,
      missionChoices: missionChoices,
      missionAnswer: missionAnswer,
      reward: reward,
      imageAsset: imageAsset,
      icon: icon,
      color: color,
    );
  }

  return switch ((content.unitNumber, content.lessonNumber)) {
    (1, 1) => plan(
      sceneTitle: 'Bag-o nga Abyan',
      sceneLine: 'May bag-o nga abyan sa eskwelahan.',
      tapInstruction: 'Ipindot ang Kumusta!',
      phrase: 'Kumusta!',
      phraseSpeech: 'Kumusta!',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ang ngalan mo?',
      buildCharacterAsset: '$grade2/girl-ana.png',
      buildAnswer: 'Koka ang ngalan ko',
      buildTiles: const ['Koka ang ngalan ko', 'Kumusta', 'Paalam'],
      choicePrompt: 'Ano ang imo ngalan?',
      choices: const ['Kumusta!', 'Koka ang ngalan ko.', 'Paalam!'],
      answer: 'Koka ang ngalan ko.',
      missionTitle: 'Kilalaha si Ana',
      missionPrompt: 'Pili-a ang sabat ni Koka.',
      missionChoices: const [
        _GradeTwoMissionChoice(
          label: 'Koka ang ngalan ko.',
          imageAsset: 'assets/images/dialogue/mascot2.png',
          icon: Icons.face_rounded,
        ),
        _GradeTwoMissionChoice(label: 'Paalam!', icon: Icons.waving_hand),
        _GradeTwoMissionChoice(label: 'Salamat!', icon: Icons.favorite),
      ],
      missionAnswer: 'Koka ang ngalan ko.',
      reward: 'Abyan na kamo!',
      imageAsset: '$grade2/school-entrance.png',
      icon: Icons.school_rounded,
      color: TudloColors.green,
    ),
    (1, 2) => plan(
      sceneTitle: 'Kaadlawan ni Juan',
      sceneLine: 'Tan-awa ang kandila.',
      tapInstruction: 'Ipindot ang pito ka kandila.',
      phrase: 'Pito ka tuig ako.',
      phraseSpeech: 'Pito ka tuig ako.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Pila ka tuig ka na?',
      buildCharacterAsset: '$grade2/boy-juan.png',
      buildAnswer: 'Pito ka tuig ako',
      buildTiles: const ['Pito', 'ka tuig', 'ako', 'anum'],
      choicePrompt: 'Pila ka tuig ka na?',
      choices: const [
        'Pito ka tuig ako.',
        'Koka ang ngalan ko.',
        'Maayong aga!',
      ],
      answer: 'Pito ka tuig ako.',
      missionTitle: 'Palupad Lobo',
      missionPrompt: 'Ano ang sabat?',
      missionChoices: const [
        _GradeTwoMissionChoice(
          label: 'Pito ka tuig ako.',
          visualLabel: '7',
          imageAsset: '$grade2/ballons.png',
          icon: Icons.celebration_rounded,
        ),
        _GradeTwoMissionChoice(
          label: 'Anum ka tuig ako.',
          visualLabel: '6',
          icon: Icons.looks_6,
        ),
        _GradeTwoMissionChoice(label: 'Kumusta!', icon: Icons.chat_bubble),
      ],
      missionAnswer: 'Pito ka tuig ako.',
      reward: 'Nagsaka ang mga lobo!',
      imageAsset: '$grade2/cake.png',
      icon: Icons.cake_rounded,
      color: TudloColors.coral,
    ),
    (1, 3) => plan(
      sceneTitle: 'Adlaw sang Pamilya',
      sceneLine: 'Kilalaha ang pamilya.',
      tapInstruction: 'Ipindot si Nanay.',
      phrase: 'Amo ini ang akon nanay.',
      phraseSpeech: 'Amo ini ang akon nanay.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Sin-o ini?',
      buildCharacterAsset: '$grade2/girl-ana.png',
      buildAnswer: 'Amo ini ang akon nanay',
      buildTiles: const ['Amo ini ang', 'akon nanay', 'akon tatay', 'Paalam'],
      choicePrompt: 'Sin-o ini?',
      choices: const [
        'Amo ini ang akon nanay.',
        'Pito ka tuig ako.',
        'Paalam!',
      ],
      answer: 'Amo ini ang akon nanay.',
      missionTitle: 'Album sang Pamilya',
      missionPrompt: 'Pangitaa si Nanay.',
      missionChoices: const [
        _GradeTwoMissionChoice(
          label: 'nanay',
          imageAsset: '$grade1/nanay.png',
          icon: Icons.woman_rounded,
        ),
        _GradeTwoMissionChoice(
          label: 'tatay',
          imageAsset: '$grade1/tatay.png',
          icon: Icons.man_rounded,
        ),
        _GradeTwoMissionChoice(
          label: 'bata',
          imageAsset: '$grade1/bata-nga-babayi.png',
          icon: Icons.child_care_rounded,
        ),
      ],
      missionAnswer: 'nanay',
      reward: 'Kompleto ang album.',
      imageAsset: '$grade1/pamilya.png',
      icon: Icons.family_restroom_rounded,
      color: TudloColors.blue,
    ),
    (2, 1) => plan(
      sceneTitle: 'Adlaw ni Koka',
      sceneLine: 'Magbati sa aga, hapon, kag gab-i.',
      tapInstruction: 'Ipindot ang adlaw.',
      phrase: 'Maayong aga!',
      phraseSpeech: 'Maayong aga!',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Aga na. Ano ang hambalon mo?',
      buildCharacterAsset: '$grade2/boy-juan.png',
      buildAnswer: 'Maayong aga',
      buildTiles: const ['Maayong', 'aga', 'gab-i', 'Kumusta'],
      choicePrompt: 'Aga na. Ano ang hambalon ni Koka?',
      choices: const ['Maayong aga!', 'Maayong gab-i!', 'Paalam!'],
      answer: 'Maayong aga!',
      missionTitle: 'Batia si Nanay',
      missionPrompt: 'Ano ang bati sa aga?',
      missionChoices: const [
        _GradeTwoMissionChoice(label: 'Maayong aga!', icon: Icons.wb_sunny),
        _GradeTwoMissionChoice(label: 'Maayong gab-i!', icon: Icons.dark_mode),
        _GradeTwoMissionChoice(
          label: 'Pasensya.',
          icon: Icons.sentiment_dissatisfied,
        ),
      ],
      missionAnswer: 'Maayong aga!',
      reward: 'Maayo nga aga!',
      imageAsset: '$grade2/school-entrance.png',
      icon: Icons.wb_sunny_rounded,
      color: TudloColors.gold,
    ),
    (2, 2) => plan(
      sceneTitle: 'Kamusta Ka?',
      sceneLine: 'Nangamusta si Koka.',
      tapInstruction: 'Ipindot ang malipayon nga nawong.',
      phrase: 'Maayo man, salamat.',
      phraseSpeech: 'Maayo man, salamat.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Kamusta ka?',
      buildCharacterAsset: '$grade2/girl1.png',
      buildAnswer: 'Maayo man salamat',
      buildTiles: const ['Maayo man', 'salamat', 'Paalam', 'Pasensya'],
      choicePrompt: 'Kamusta ka?',
      choices: const [
        'Maayo man, salamat.',
        'Maayong gab-i!',
        'Koka ang ngalan ko.',
      ],
      answer: 'Maayo man, salamat.',
      missionTitle: 'Magpaalam',
      missionPrompt: 'Magpaalam.',
      missionChoices: const [
        _GradeTwoMissionChoice(label: 'Paalam!', icon: Icons.waving_hand),
        _GradeTwoMissionChoice(label: 'Maayo man.', icon: Icons.mood),
        _GradeTwoMissionChoice(
          label: 'Palihog.',
          icon: Icons.volunteer_activism,
        ),
      ],
      missionAnswer: 'Paalam!',
      reward: 'Nagpaalam ka sing maayo.',
      imageAsset: '$grade2/girl1.png',
      icon: Icons.mood_rounded,
      color: TudloColors.green,
    ),
    (2, 3) => plan(
      sceneTitle: 'Sa Tinda',
      sceneLine: 'Gamita ang matinahuron nga tinaga.',
      tapInstruction: 'Ipindot ang mangga.',
      phrase: 'Palihog.',
      phraseSpeech: 'Palihog.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ginhatagan ka sang mangga.',
      buildCharacterAsset: '$grade2/girl-ana.png',
      buildAnswer: 'Salamat',
      buildTiles: const ['Salamat', 'Palihog', 'Pasensya', 'Paalam'],
      choicePrompt: 'Ginhatagan ka sang mangga. Ano ang hambalon mo?',
      choices: const ['Salamat.', 'Maayong aga!', 'Koka ang ngalan ko.'],
      answer: 'Salamat.',
      missionTitle: 'Pasensya',
      missionPrompt: 'Magsiling sang pasensya.',
      missionChoices: const [
        _GradeTwoMissionChoice(label: 'Pasensya.', icon: Icons.favorite),
        _GradeTwoMissionChoice(label: 'Paalam!', icon: Icons.waving_hand),
        _GradeTwoMissionChoice(label: 'Maayong gab-i!', icon: Icons.dark_mode),
      ],
      missionAnswer: 'Pasensya.',
      reward: 'Nagpatawad ang tindera.',
      imageAsset: '$grade2/mango.png',
      icon: Icons.storefront_rounded,
      color: TudloColors.orange,
    ),
    (3, 1) => plan(
      sceneTitle: 'Sa Klase',
      sceneLine: 'Pangitaa ang gamit sa klase.',
      tapInstruction: 'Pangitaa ang libro.',
      phrase: 'Ini ang libro.',
      phraseSpeech: 'Ini ang libro.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ini?',
      buildCharacterAsset: '$grade2/boy-juan.png',
      buildAnswer: 'Ini ang libro',
      buildTiles: const ['Ini ang', 'libro', 'lapis', 'pulungkuan'],
      choicePrompt: 'Pangitaa ang libro.',
      choices: const ['libro', 'lapis', 'bag'],
      answer: 'libro',
      missionTitle: 'Pangitaa ang Butang',
      missionPrompt: 'Pangitaa ang libro.',
      missionChoices: const [
        _GradeTwoMissionChoice(
          label: 'libro',
          imageAsset: '$grade2/book.png',
          icon: Icons.menu_book_rounded,
        ),
        _GradeTwoMissionChoice(
          label: 'lapis',
          imageAsset: '$grade2/pencil.png',
          icon: Icons.edit_rounded,
        ),
        _GradeTwoMissionChoice(
          label: 'bag',
          imageAsset: '$grade2/bag.png',
          icon: Icons.backpack_rounded,
        ),
      ],
      missionAnswer: 'libro',
      reward: 'Nakita mo ang libro.',
      imageAsset: '$grade2/classroom.png',
      icon: Icons.search_rounded,
      color: TudloColors.blue,
    ),
    (3, 2) => plan(
      sceneTitle: 'Sa Lamesa',
      sceneLine: 'Pangitaa ang gamit sa lamesa.',
      tapInstruction: 'Ipindot ang plato.',
      phrase: 'Ini ang plato.',
      phraseSpeech: 'Ini ang plato.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ini?',
      buildCharacterAsset: '$grade2/girl-ana.png',
      buildAnswer: 'Ini ang plato',
      buildTiles: const ['Ini ang', 'plato', 'baso', 'kutsara'],
      choicePrompt: 'Ano ang ibutang sa lamesa?',
      choices: const ['plato', 'libro', 'bag'],
      answer: 'plato',
      missionTitle: 'Bulig sa Lamesa',
      missionPrompt: 'Pangitaa ang kutsara.',
      missionChoices: const [
        _GradeTwoMissionChoice(
          label: 'plato',
          imageAsset: '$grade2/plate.png',
          icon: Icons.dinner_dining,
        ),
        _GradeTwoMissionChoice(
          label: 'baso',
          imageAsset: '$grade2/glass.png',
          icon: Icons.local_drink,
        ),
        _GradeTwoMissionChoice(
          label: 'kutsara',
          imageAsset: '$grade2/spoon.png',
          icon: Icons.restaurant,
        ),
      ],
      missionAnswer: 'kutsara',
      reward: 'Handa na ang lamesa.',
      imageAsset: '$grade2/table.png',
      icon: Icons.table_restaurant_rounded,
      color: TudloColors.green,
    ),
    (3, 3) => plan(
      sceneTitle: 'Himoa ang Parke',
      sceneLine: 'Dugangi ang parke.',
      tapInstruction: 'Ipindot ang kahoy.',
      phrase: 'Ini ang kahoy.',
      phraseSpeech: 'Ini ang kahoy.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ini?',
      buildCharacterAsset: '$grade2/boy1.png',
      buildAnswer: 'Ini ang kahoy',
      buildTiles: const ['Ini ang', 'kahoy', 'bulak', 'bato'],
      choicePrompt: 'Ano ang nagahatag landong?',
      choices: const ['kahoy', 'baso', 'kutsara'],
      answer: 'kahoy',
      missionTitle: 'Himoa ang Parke',
      missionPrompt: 'Pangitaa ang bulak.',
      missionChoices: const [
        _GradeTwoMissionChoice(label: 'kahoy', icon: Icons.park_rounded),
        _GradeTwoMissionChoice(label: 'bulak', icon: Icons.local_florist),
        _GradeTwoMissionChoice(label: 'bato', icon: Icons.landscape),
      ],
      missionAnswer: 'bulak',
      reward: 'Nami ang parke.',
      icon: Icons.park_rounded,
      color: TudloColors.forest,
    ),
    (4, 1) => plan(
      sceneTitle: 'Kanta kag Hulag',
      sceneLine: 'Nagakanta kag nagahulag si Koka.',
      tapInstruction: 'Ipindot ang ulo.',
      phrase: 'Tanduga ang imo ulo.',
      phraseSpeech: 'Tanduga ang imo ulo.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ang tandugon mo?',
      buildCharacterAsset: '$grade2/girl1.png',
      buildAnswer: 'Tanduga ang imo ulo',
      buildTiles: const ['Tanduga ang', 'imo ulo', 'imo tiil', 'imo mata'],
      choicePrompt: 'Ano ang imo tandugon?',
      choices: const ['ulo', 'libro', 'merkado'],
      answer: 'ulo',
      missionTitle: 'Tapik sa Ritmo',
      missionPrompt: 'Ipindot ang tambol.',
      missionChoices: const [
        _GradeTwoMissionChoice(label: 'tambol', icon: Icons.music_note_rounded),
        _GradeTwoMissionChoice(label: 'pulungkuan', icon: Icons.chair_rounded),
        _GradeTwoMissionChoice(label: 'bag', icon: Icons.backpack_rounded),
      ],
      missionAnswer: 'tambol',
      reward: 'Nagsayaw si Koka.',
      imageAsset: '$grade2/microphone.png',
      icon: Icons.music_note_rounded,
      color: TudloColors.coral,
    ),
    (4, 2) => plan(
      sceneTitle: 'Paktakon',
      sceneLine: 'Pamatii ang palatandaan kag sabta.',
      tapInstruction: 'Pamatii ang paktakon.',
      phrase: 'Ido ini.',
      phraseSpeech: 'Ido ini.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ang sabat sa paktakon?',
      buildCharacterAsset: '$grade2/boy2.png',
      buildAnswer: 'Ido ini',
      buildTiles: const ['Ido', 'ini', 'kuring', 'baboy'],
      choicePrompt: 'May apat ka tiil kag nagatahol.',
      choices: const ['ido', 'kuring', 'baboy'],
      answer: 'ido',
      missionTitle: 'Paktakon',
      missionPrompt: 'Pangitaa ang ido.',
      missionChoices: const [
        _GradeTwoMissionChoice(
          label: 'ido',
          imageAsset: '$grade1/dog.png',
          icon: Icons.pets,
        ),
        _GradeTwoMissionChoice(
          label: 'kuring',
          imageAsset: '$grade1/cat.png',
          icon: Icons.pets,
        ),
        _GradeTwoMissionChoice(label: 'baboy', icon: Icons.pets),
      ],
      missionAnswer: 'ido',
      reward: 'Nasabat mo ang paktakon.',
      imageAsset: '$grade1/dog.png',
      icon: Icons.psychology_rounded,
      color: TudloColors.orange,
    ),
    (4, 3) => plan(
      sceneTitle: 'Mini Konsyerto',
      sceneLine: 'Kantaha ang pagbati.',
      tapInstruction: 'Ipindot ang mikropono.',
      phrase: 'Maayong aga sa akon nanay.',
      phraseSpeech: 'Maayong aga sa akon nanay.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ang linya sang kanta?',
      buildCharacterAsset: '$grade2/girl-ana.png',
      buildAnswer: 'Maayong aga sa akon nanay',
      buildTiles: const ['Maayong aga', 'sa akon', 'nanay', 'tatay'],
      choicePrompt: 'Sin-o ang ara sa kanta?',
      choices: const ['nanay', 'kutsara', 'pulungkuan'],
      answer: 'nanay',
      missionTitle: 'Konsyerto',
      missionPrompt: 'Ipindot ang manugkanta.',
      missionChoices: const [
        _GradeTwoMissionChoice(
          label: 'manugkanta',
          imageAsset: '$grade2/microphone.png',
          icon: Icons.mic_rounded,
        ),
        _GradeTwoMissionChoice(label: 'libro', icon: Icons.menu_book),
        _GradeTwoMissionChoice(label: 'mangga', icon: Icons.storefront),
      ],
      missionAnswer: 'manugkanta',
      reward: 'Nagpalakpak ang klase.',
      imageAsset: '$grade2/school-stage.png',
      icon: Icons.mic_rounded,
      color: TudloColors.green,
    ),
    (5, 1) => plan(
      sceneTitle: 'Binalaybay',
      sceneLine: 'Pamatii ang pareho nga tunog.',
      tapInstruction: 'Ipindot ang kuring.',
      phrase: 'Nagapungko ang kuring.',
      phraseSpeech: 'Nagapungko ang kuring.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ang una nga linya?',
      buildCharacterAsset: '$grade2/girl1.png',
      buildAnswer: 'Nagapungko ang kuring',
      buildTiles: const ['Nagapungko ang', 'kuring', 'ido', 'isda'],
      choicePrompt: 'Ano ang kapareho tunog?',
      choices: const ['banig', 'isda', 'adlaw'],
      answer: 'banig',
      missionTitle: 'Pareho nga Tunog',
      missionPrompt: 'Pili-a ang kapareho tunog.',
      missionChoices: const [
        _GradeTwoMissionChoice(label: 'banig', icon: Icons.crop_square),
        _GradeTwoMissionChoice(
          label: 'isda',
          imageAsset: '$grade1/fish.png',
          icon: Icons.water,
        ),
        _GradeTwoMissionChoice(label: 'adlaw', icon: Icons.wb_sunny),
      ],
      missionAnswer: 'banig',
      reward: 'Pareho ang tunog.',
      imageAsset: '$grade1/cat.png',
      icon: Icons.auto_stories_rounded,
      color: TudloColors.blue,
    ),
    (5, 2) => plan(
      sceneTitle: 'Binalaybay nga May Hulag',
      sceneLine: 'Maghulag samtang nagabasa.',
      tapInstruction: 'Ipindot ang bata nga nagalumpat.',
      phrase: 'Makalumpat ako.',
      phraseSpeech: 'Makalumpat ako.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano nga hulag ang himuon?',
      buildCharacterAsset: '$grade2/boy1.png',
      buildAnswer: 'Makalumpat ako',
      buildTiles: const ['Makalumpat', 'ako', 'paypay', 'liko'],
      choicePrompt: 'Ano nga hulag ang ginpamati?',
      choices: const ['lumpat', 'libro', 'plato'],
      answer: 'lumpat',
      missionTitle: 'Hulaga ang Linya',
      missionPrompt: 'Pili-a ang paypay.',
      missionChoices: const [
        _GradeTwoMissionChoice(label: 'lumpat', icon: Icons.keyboard_arrow_up),
        _GradeTwoMissionChoice(label: 'paypay', icon: Icons.waving_hand),
        _GradeTwoMissionChoice(label: 'liko', icon: Icons.rotate_right),
      ],
      missionAnswer: 'paypay',
      reward: 'Handa ka na magbasa.',
      imageAsset: '$grade2/boy1.png',
      icon: Icons.directions_run_rounded,
      color: TudloColors.coral,
    ),
    _ => plan(
      sceneTitle: 'Himoa ang Binalaybay',
      sceneLine: 'Pili tinaga kag basahon ni Koka.',
      tapInstruction: 'Ipindot ang ido.',
      phrase: 'Malipayon ang akon ido.',
      phraseSpeech: 'Malipayon ang akon ido.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ang imo binalaybay?',
      buildCharacterAsset: '$grade2/girl-ana.png',
      buildAnswer: 'Malipayon ang akon ido',
      buildTiles: const ['Malipayon ang', 'akon ido', 'kuring', 'masubo'],
      choicePrompt: 'Diin ang pareho sa binalaybay?',
      choices: const [
        'Malipayon ang akon ido.',
        'Pulungkuan kutsara baso.',
        'Paalam merkado.',
      ],
      answer: 'Malipayon ang akon ido.',
      missionTitle: 'Himoa ang Binalaybay',
      missionPrompt: 'Pili-a ang malipayon.',
      missionChoices: const [
        _GradeTwoMissionChoice(label: 'malipayon', icon: Icons.mood),
        _GradeTwoMissionChoice(label: 'pulungkuan', icon: Icons.chair),
        _GradeTwoMissionChoice(label: 'kutsara', icon: Icons.restaurant),
      ],
      missionAnswer: 'malipayon',
      reward: 'Nabasa ni Koka ang imo binalaybay.',
      imageAsset: '$grade1/dog.png',
      icon: Icons.auto_stories_rounded,
      color: TudloColors.forest,
    ),
  };
}

String _letterSoundText(String letter) {
  return switch (letter.trim().toUpperCase()) {
    'A' => 'a',
    'E' => 'e',
    'I' => 'i',
    'O' => 'o',
    'U' => 'u',
    'N' => 'n',
    'T' => 't',
    'Y' => 'y',
    'D' => 'd',
    'G' => 'g',
    'K' => 'k',
    'L' => 'l',
    'M' => 'm',
    'P' => 'p',
    'R' => 'r',
    'S' => 's',
    'W' => 'w',
    _ => letter.trim().toLowerCase(),
  };
}

class _GradeOneAlphabetLesson extends StatefulWidget {
  final LevelContent content;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOneAlphabetLesson({
    required this.content,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeOneAlphabetLesson> createState() =>
      _GradeOneAlphabetLessonState();
}

class _GradeOneAlphabetLessonState extends State<_GradeOneAlphabetLesson> {
  int _stepIndex = 0;

  void _goToStep(int index, int maxIndex) {
    final next = index.clamp(0, maxIndex);
    if (next == _stepIndex) return;
    setState(() => _stepIndex = next);
  }

  void _advanceAfterCorrect(int maxIndex) {
    final completedStep = _stepIndex;
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted || _stepIndex != completedStep) return;
      _goToStep(completedStep + 1, maxIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final anchors = _alphabetAnchorsFor(widget.content.lessonNumber);
    final targets = _targetLettersFor(widget.content);
    var maxIndex = 0;
    final quizActivities = widget.content.quizItems.asMap().entries.map((
      entry,
    ) {
      final target = _targetLetterForQuiz(entry.value, targets);
      final anchor = _bestAnchorForTarget(
        anchors,
        target,
        prompt: entry.value.question,
      );
      return _AlphabetMiniActivity(
        key: ValueKey('alphabet-quiz-${widget.content.id}-${entry.value.id}'),
        word: anchor.word,
        meaning: anchor.meaning,
        imageAsset: anchor.imageAsset,
        icon: anchor.icon,
        targetLetters: [target],
        instruction: _instructionForQuiz(entry.value, target),
        mascotMessage: 'Koka: Pamatii, dayon tap-a ang husto nga letra.',
        spendEnergy: true,
        onCorrect: () {
          widget.onQuizCorrect(entry.key);
          _advanceAfterCorrect(maxIndex);
        },
      );
    }).toList();

    final introTargets = targets
        .map((target) => target.toUpperCase())
        .toSet()
        .map(
          (target) => MapEntry(target, _bestAnchorForTarget(anchors, target)),
        )
        .toList();

    final steps = [
      for (final entry in introTargets)
        _AlphabetFadeStep(
          child: _AlphabetLetterIntroCard(
            key: ValueKey('alphabet-intro-${widget.content.id}-${entry.key}'),
            letter: entry.key,
            anchor: entry.value,
            onDone: () => _advanceAfterCorrect(maxIndex),
          ),
        ),
      for (final anchor in anchors)
        _AlphabetFadeStep(
          child: _AlphabetMiniActivity(
            key: ValueKey(
              'alphabet-lesson-${widget.content.id}-${anchor.word}',
            ),
            word: anchor.word,
            meaning: anchor.meaning,
            imageAsset: anchor.imageAsset,
            icon: anchor.icon,
            targetLetters: anchor.targets,
            instruction:
                'Tap-a ang tagsa ka letra ${anchor.targets.join(", ")} sa tinaga.',
            mascotMessage:
                'Koka: Ini ang tinaga ${anchor.word}. Tap-a ang tagsa ka letra.',
            onCorrect: () => _advanceAfterCorrect(maxIndex),
          ),
        ),
      for (final target in targets)
        _AlphabetFadeStep(
          child: Builder(
            builder: (context) {
              final anchor = _bestAnchorForTarget(anchors, target);
              return _AlphabetMiniActivity(
                key: ValueKey('alphabet-example-${widget.content.id}-$target'),
                word: anchor.word,
                meaning: anchor.meaning,
                imageAsset: anchor.imageAsset,
                icon: anchor.icon,
                targetLetters: [target],
                instruction:
                    'May $target sa ${anchor.word}. Pamatii ang tingog sang $target.',
                mascotMessage:
                    'Koka: Ang letra $target may tingog nga ${_letterSoundText(target)}.',
                onCorrect: () => _advanceAfterCorrect(maxIndex),
              );
            },
          ),
        ),
      _AlphabetFadeStep(
        child: _QuizTimeSplash(
          onDone: () => _goToStep(_stepIndex + 1, maxIndex),
        ),
      ),
      for (final card in quizActivities) _AlphabetFadeStep(child: card),
    ];
    maxIndex = steps.length - 1;
    final activeStep = steps[_stepIndex.clamp(0, maxIndex)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(390.0, constraints.maxWidth);
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 850),
                reverseDuration: const Duration(milliseconds: 650),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: .97, end: 1).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child: Align(
                  key: ValueKey('alphabet-step-$_stepIndex'),
                  alignment: Alignment.topCenter,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(width: width, child: activeStep.child),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<String> _targetLettersFor(LevelContent content) {
    final titleTargets = RegExp(
      r'\b[A-Z]\b',
    ).allMatches(content.title).map((match) => match.group(0)!).toList();
    if (titleTargets.isNotEmpty) return titleTargets;
    return _alphabetAnchorsFor(
      content.lessonNumber,
    ).expand((anchor) => anchor.targets).toSet().toList();
  }

  String _targetLetterForQuiz(QuizItem item, List<String> targets) {
    final combined = '${item.answer} ${item.question}'.toUpperCase();
    for (final target in targets) {
      if (RegExp('\\b$target\\b').hasMatch(combined) ||
          combined.contains('/$target/')) {
        return target;
      }
    }
    return targets.isEmpty
        ? item.answer.characters.first.toUpperCase()
        : targets.first;
  }

  String _instructionForQuiz(QuizItem item, String target) {
    final question = item.question.trim();
    final soundMatch = RegExp(r'/([^/]+)/').firstMatch(question);
    if (soundMatch != null) {
      return 'Tap-a ang letra nga may tingog nga ${_letterSoundText(soundMatch.group(1)!)}.';
    }
    if (question.toLowerCase().contains('diin')) return question;
    return 'Pamatii ang tingog kag tap-a ang letra $target.';
  }

  _AlphabetAnchor _bestAnchorForTarget(
    List<_AlphabetAnchor> anchors,
    String target, {
    String prompt = '',
  }) {
    final lowerPrompt = prompt.toLowerCase();
    for (final anchor in anchors) {
      if (lowerPrompt.contains(anchor.word.toLowerCase())) return anchor;
    }
    return anchors.firstWhere(
      (anchor) => anchor.word.contains(target),
      orElse: () => anchors.first,
    );
  }

  List<_AlphabetAnchor> _alphabetAnchorsFor(int lessonNumber) {
    switch (lessonNumber) {
      case 1:
        return const [
          _AlphabetAnchor(
            word: 'NANAY',
            meaning: 'nanay',
            targets: ['N', 'A', 'Y'],
            imageAsset: 'assets/images/level_game/Grade1/unit1/nanay.png',
            icon: Icons.family_restroom_rounded,
          ),
          _AlphabetAnchor(
            word: 'TATAY',
            meaning: 'tatay',
            targets: ['T', 'A', 'Y'],
            imageAsset: 'assets/images/level_game/Grade1/unit1/tatay.png',
            icon: Icons.family_restroom_rounded,
          ),
        ];
      case 2:
        return const [
          _AlphabetAnchor(
            word: 'IDO',
            meaning: 'ido',
            targets: ['I', 'D', 'O'],
            imageAsset: 'assets/images/level_game/Grade1/unit1/dog.png',
            icon: Icons.pets_rounded,
          ),
        ];
      case 3:
        return const [
          _AlphabetAnchor(
            word: 'MANOK',
            meaning: 'manok',
            targets: ['M', 'K'],
            icon: Icons.egg_alt_rounded,
          ),
          _AlphabetAnchor(
            word: 'KURING',
            meaning: 'kuring',
            targets: ['K', 'U'],
            imageAsset: 'assets/images/level_game/Grade1/unit1/cat.png',
            icon: Icons.pets_rounded,
          ),
        ];
      case 4:
        return const [
          _AlphabetAnchor(
            word: 'BALAY',
            meaning: 'balay',
            targets: ['B', 'L'],
            icon: Icons.home_rounded,
          ),
          _AlphabetAnchor(
            word: 'LOLA',
            meaning: 'lola',
            targets: ['L'],
            icon: Icons.elderly_woman_rounded,
          ),
          _AlphabetAnchor(
            word: 'ISDA',
            meaning: 'isda',
            targets: ['S'],
            icon: Icons.water_rounded,
          ),
        ];
      case 5:
        return const [
          _AlphabetAnchor(
            word: 'ESKWELAHAN',
            meaning: 'eskwelahan',
            targets: ['E'],
            icon: Icons.school_rounded,
          ),
          _AlphabetAnchor(
            word: 'GATAS',
            meaning: 'gatas',
            targets: ['G'],
            icon: Icons.local_drink_rounded,
          ),
          _AlphabetAnchor(
            word: 'PAMILYA',
            meaning: 'pamilya',
            targets: ['P'],
            icon: Icons.diversity_3_rounded,
          ),
        ];
      case 6:
      default:
        return const [
          _AlphabetAnchor(
            word: 'DOKTOR',
            meaning: 'doktor',
            targets: ['R'],
            icon: Icons.medical_services_rounded,
          ),
          _AlphabetAnchor(
            word: 'HOSPITAL',
            meaning: 'ospital',
            targets: ['H'],
            icon: Icons.local_hospital_rounded,
          ),
          _AlphabetAnchor(
            word: 'KARBAW',
            meaning: 'karbaw',
            targets: ['W'],
            imageAsset: 'assets/images/level_game/Grade1/unit1/lesson1/cow.png',
            icon: Icons.agriculture_rounded,
          ),
        ];
    }
  }
}

class _AlphabetAnchor {
  final String word;
  final String meaning;
  final List<String> targets;
  final String? imageAsset;
  final IconData icon;

  const _AlphabetAnchor({
    required this.word,
    required this.meaning,
    required this.targets,
    required this.icon,
    this.imageAsset,
  });
}

class _AlphabetFadeStep {
  final Widget child;

  const _AlphabetFadeStep({required this.child});
}

class _QuizTimeSplash extends StatefulWidget {
  final VoidCallback onDone;

  const _QuizTimeSplash({required this.onDone});

  @override
  State<_QuizTimeSplash> createState() => _QuizTimeSplashState();
}

class _QuizTimeSplashState extends State<_QuizTimeSplash> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1300), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 560,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TudloMascot(size: 150),
            const SizedBox(height: 18),
            Text(
              'Quiz Time',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: TudloColors.forest,
                fontSize: 44,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlphabetMiniActivity extends StatefulWidget {
  final String word;
  final String meaning;
  final String? imageAsset;
  final IconData icon;
  final List<String> targetLetters;
  final String instruction;
  final String mascotMessage;
  final bool spendEnergy;
  final VoidCallback? onCorrect;

  const _AlphabetMiniActivity({
    super.key,
    required this.word,
    required this.meaning,
    required this.icon,
    required this.targetLetters,
    required this.instruction,
    required this.mascotMessage,
    this.spendEnergy = false,
    this.imageAsset,
    this.onCorrect,
  });

  @override
  State<_AlphabetMiniActivity> createState() => _AlphabetMiniActivityState();
}

class _AlphabetMiniActivityState extends State<_AlphabetMiniActivity> {
  int? _selectedIndex;
  final Set<String> _completedTargets = {};
  bool _selectedCorrect = false;
  bool _wrong = false;
  bool _reported = false;
  int _motionKey = 0;

  Set<String> get _targets =>
      widget.targetLetters.map((letter) => letter.toUpperCase()).toSet();

  Future<void> _handleLetterTap(String letter, int index) async {
    if (_reported) return;
    if (widget.spendEnergy) {
      final spent = await AppData.spendQuestionEnergy();
      if (!spent) {
        if (mounted) await showLowEnergyDialog(context);
        return;
      }
    }
    if (!mounted) return;
    await TudloVoiceButton.speak(context, _soundFor(letter), hiligaynon: true);
    final normalizedLetter = letter.toUpperCase();
    final isCorrect = _targets.contains(normalizedLetter);
    final completed =
        isCorrect &&
        _completedTargets.union({normalizedLetter}).containsAll(_targets);
    setState(() {
      _selectedIndex = index;
      if (isCorrect) _completedTargets.add(normalizedLetter);
      _selectedCorrect = isCorrect;
      _wrong = !isCorrect;
      _motionKey++;
    });
    if (completed && !_reported) {
      _reported = true;
      widget.onCorrect?.call();
    }
    if (!isCorrect) {
      Future<void>.delayed(const Duration(milliseconds: 760), () {
        if (!mounted || _reported) return;
        setState(() {
          _wrong = false;
          _selectedCorrect = false;
        });
      });
    }
  }

  String _soundFor(String letter) => _letterSoundText(letter);

  String get _voiceMessage {
    return widget.targetLetters.map(_letterSoundText).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 370),
        child: SizedBox(
          height: 760,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 12,
                right: 12,
                top: 12,
                child: TappableWord(
                  word: widget.word,
                  targetLetters: widget.targetLetters,
                  selectedIndex: _selectedIndex,
                  selectedCorrect: _selectedCorrect,
                  wrong: _wrong,
                  motionKey: _motionKey,
                  onLetterTap: _handleLetterTap,
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                top: 140,
                child: _AlphabetAnchorImage(
                  imageAsset: widget.imageAsset,
                  icon: widget.icon,
                  word: _displayWord(widget.word),
                  meaning: widget.meaning,
                  voiceMessage: _voiceMessage,
                ),
              ),
              Positioned(
                right: -18,
                top: 500,
                child: IgnorePointer(
                  child: _AlphabetMascotBubble(
                    message: _selectedCorrect || _wrong
                        ? (_selectedCorrect ? _successMessage : 'Sulayi liwat.')
                        : widget.mascotMessage,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _displayWord(String word) {
    return word.isEmpty
        ? word
        : word[0].toUpperCase() + word.substring(1).toLowerCase();
  }

  String get _successMessage {
    if (_completedTargets.containsAll(_targets)) return 'Husto! Maayo gid.';
    final remaining = _targets.difference(_completedTargets).join(', ');
    return remaining.isEmpty ? 'Husto!' : 'Husto! Sunod: $remaining.';
  }
}

class TappableWord extends StatelessWidget {
  final String word;
  final List<String> targetLetters;
  final int? selectedIndex;
  final bool selectedCorrect;
  final bool wrong;
  final int motionKey;
  final void Function(String letter, int index) onLetterTap;

  const TappableWord({
    super.key,
    required this.word,
    required this.targetLetters,
    required this.onLetterTap,
    this.selectedIndex,
    this.selectedCorrect = false,
    this.wrong = false,
    this.motionKey = 0,
  });

  @override
  Widget build(BuildContext context) {
    final letters = word.characters.toList();
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < letters.length; index++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: _TappableLetterCard(
                  key: ValueKey('$word-$index-${letters[index]}-$motionKey'),
                  letter: letters[index],
                  imageAsset: _letterAssetFor(letters[index]),
                  selected: selectedIndex == index,
                  correct: selectedIndex == index && selectedCorrect,
                  wrong: selectedIndex == index && wrong,
                  onTap: () => onLetterTap(letters[index], index),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _letterAssetFor(String letter) {
    return const {
      'A': 'assets/images/level_game/Grade1/unit1/A.png',
      'B': 'assets/images/level_game/Grade1/unit1/B.png',
      'C': 'assets/images/level_game/Grade1/unit1/C.png',
      'D': 'assets/images/level_game/Grade1/unit1/D.png',
      'E': 'assets/images/level_game/Grade1/unit1/E.png',
      'F': 'assets/images/level_game/Grade1/unit1/F.png',
      'G': 'assets/images/level_game/Grade1/unit1/G.png',
      'H': 'assets/images/level_game/Grade1/unit1/H.png',
      'I': 'assets/images/level_game/Grade1/unit1/I.png',
      'N': 'assets/images/level_game/Grade1/unit1/N.png',
      'O': 'assets/images/level_game/Grade1/unit1/O.png',
      'T': 'assets/images/level_game/Grade1/unit1/T.png',
      'Y': 'assets/images/level_game/Grade1/unit1/Y.png',
    }[letter.toUpperCase()];
  }
}

class _AlphabetLetterIntroCard extends StatefulWidget {
  final String letter;
  final _AlphabetAnchor anchor;
  final VoidCallback onDone;

  const _AlphabetLetterIntroCard({
    super.key,
    required this.letter,
    required this.anchor,
    required this.onDone,
  });

  @override
  State<_AlphabetLetterIntroCard> createState() =>
      _AlphabetLetterIntroCardState();
}

class _AlphabetLetterIntroCardState extends State<_AlphabetLetterIntroCard> {
  bool _revealed = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          'Pamati! ${_letterSoundText(widget.letter)}...',
          hiligaynon: true,
        ),
      );
    });
  }

  Future<void> _handleTap() async {
    if (_done) return;
    setState(() => _revealed = true);
    await TudloVoiceButton.speak(
      context,
      '${_letterSoundText(widget.letter)}... ${widget.letter}! May ${widget.letter} sa ${widget.anchor.word}.',
      hiligaynon: true,
    );
    if (!mounted) return;
    _done = true;
    Future<void>.delayed(const Duration(milliseconds: 1050), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    final letter = widget.letter.toUpperCase();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 370),
        child: SizedBox(
          height: 760,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 10,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _handleTap,
                      child: _IntroLetterBounce(
                        active: !_revealed,
                        glow: true,
                        child: _IntroLetterArt(letter: letter, size: 190),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 420),
                      child: _revealed
                          ? Padding(
                              key: const ValueKey('word'),
                              padding: const EdgeInsets.only(top: 34),
                              child: Column(
                                children: [
                                  _HighlightedAlphabetWord(
                                    word: widget.anchor.word,
                                    highlightLetter: letter,
                                  ),
                                  const SizedBox(height: 20),
                                  _AlphabetAnchorImage(
                                    imageAsset: widget.anchor.imageAsset,
                                    icon: widget.anchor.icon,
                                    word: _titleCase(widget.anchor.word),
                                    meaning: widget.anchor.meaning,
                                    voiceMessage: widget.anchor.word,
                                    compact: true,
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox(key: ValueKey('empty'), height: 330),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: -18,
                top: 500,
                child: IgnorePointer(
                  child: _AlphabetMascotBubble(
                    message: _revealed
                        ? 'Koka: May $letter sa ${widget.anchor.word}!'
                        : 'Koka: Pamati! ${_letterSoundText(letter)}... Tap-a ang $letter.',
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

class _IntroLetterBounce extends StatelessWidget {
  final bool active;
  final bool glow;
  final Widget child;

  const _IntroLetterBounce({
    required this.active,
    required this.glow,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: active ? 1 : 0),
      duration: const Duration(milliseconds: 720),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final jump = active ? -math.sin(value * math.pi * 2) * 10 : 0.0;
        return Transform.translate(
          offset: Offset(0, jump),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: glow
                  ? [
                      BoxShadow(
                        color: TudloColors.green.withValues(alpha: .36),
                        blurRadius: 34,
                        spreadRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _IntroLetterArt extends StatelessWidget {
  final String letter;
  final double size;

  const _IntroLetterArt({required this.letter, required this.size});

  @override
  Widget build(BuildContext context) {
    final asset = const {
      'A': 'assets/images/level_game/Grade1/unit1/A.png',
      'B': 'assets/images/level_game/Grade1/unit1/B.png',
      'C': 'assets/images/level_game/Grade1/unit1/C.png',
      'D': 'assets/images/level_game/Grade1/unit1/D.png',
      'E': 'assets/images/level_game/Grade1/unit1/E.png',
      'F': 'assets/images/level_game/Grade1/unit1/F.png',
      'G': 'assets/images/level_game/Grade1/unit1/G.png',
      'H': 'assets/images/level_game/Grade1/unit1/H.png',
      'I': 'assets/images/level_game/Grade1/unit1/I.png',
      'N': 'assets/images/level_game/Grade1/unit1/N.png',
      'O': 'assets/images/level_game/Grade1/unit1/O.png',
      'T': 'assets/images/level_game/Grade1/unit1/T.png',
      'Y': 'assets/images/level_game/Grade1/unit1/Y.png',
    }[letter.toUpperCase()];
    if (asset == null) {
      return Text(
        letter,
        style: TextStyle(
          color: TudloColors.blue,
          fontSize: size * .72,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      );
    }
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class _HighlightedAlphabetWord extends StatelessWidget {
  final String word;
  final String highlightLetter;

  const _HighlightedAlphabetWord({
    required this.word,
    required this.highlightLetter,
  });

  @override
  Widget build(BuildContext context) {
    final letters = word.characters.toList();
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final letter in letters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 360),
                decoration: BoxDecoration(
                  boxShadow: letter.toUpperCase() == highlightLetter
                      ? [
                          BoxShadow(
                            color: TudloColors.green.withValues(alpha: .52),
                            blurRadius: 22,
                            spreadRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: _IntroLetterArt(letter: letter, size: 82),
              ),
            ),
        ],
      ),
    );
  }
}

class _TappableLetterCard extends StatelessWidget {
  final String letter;
  final String? imageAsset;
  final bool selected;
  final bool correct;
  final bool wrong;
  final VoidCallback onTap;

  const _TappableLetterCard({
    super.key,
    required this.letter,
    this.imageAsset,
    required this.selected,
    required this.correct,
    required this.wrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const wrongColor = Color(0xFFE53935);
    return _FeedbackMotion(
      correct: correct,
      wrong: wrong,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          scale: selected ? 1.07 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: imageAsset == null ? 92 : 104,
            height: 126,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              boxShadow: correct
                  ? [
                      BoxShadow(
                        color: TudloColors.green.withValues(alpha: .52),
                        blurRadius: 22,
                        spreadRadius: 4,
                      ),
                    ]
                  : wrong
                  ? [
                      BoxShadow(
                        color: wrongColor.withValues(alpha: .72),
                        blurRadius: 22,
                        spreadRadius: 5,
                      ),
                    ]
                  : selected
                  ? [
                      BoxShadow(
                        color: TudloColors.blue.withValues(alpha: .28),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: imageAsset == null
                ? Text(
                    letter,
                    style: TextStyle(
                      color: wrong ? wrongColor : TudloColors.blue,
                      fontSize: 94,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : Image.asset(
                    imageAsset!,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => Text(
                      letter,
                      style: TextStyle(
                        color: wrong ? wrongColor : TudloColors.blue,
                        fontSize: 94,
                        height: 1,
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

class _AlphabetMascotBubble extends StatelessWidget {
  final String message;

  const _AlphabetMascotBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 386,
      height: 260,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 90,
            top: 0,
            child: SizedBox(
              width: 286,
              height: 176,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/dialogue/dialoguebox.png',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 22, 28, 40),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: constraints.maxWidth,
                            child: Text(
                              message,
                              textAlign: TextAlign.center,
                              maxLines: 6,
                              style: const TextStyle(
                                color: TudloColors.ink,
                                fontSize: 19,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(right: 0, bottom: 0, child: TudloMascot(size: 198)),
        ],
      ),
    );
  }
}

class _AlphabetAnchorImage extends StatelessWidget {
  final String? imageAsset;
  final IconData icon;
  final String word;
  final String meaning;
  final String voiceMessage;
  final bool compact;

  const _AlphabetAnchorImage({
    required this.imageAsset,
    required this.icon,
    required this.word,
    required this.meaning,
    required this.voiceMessage,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 236 : 352,
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
      color: Colors.transparent,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: imageAsset == null
                      ? _AlphabetIconArt(icon: icon)
                      : Image.asset(
                          imageAsset!,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) =>
                              _AlphabetIconArt(icon: icon),
                        ),
                ),
                Positioned(
                  bottom: 2,
                  child: TudloVoiceButton(
                    message: voiceMessage,
                    tooltip: 'Pamatii ang tingog',
                    size: compact ? 54 : 62,
                    hiligaynon: true,
                  ),
                ),
              ],
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 14),
            Text(
              meaning,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: TudloColors.muted,
                fontSize: 19,
                height: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlphabetIconArt extends StatelessWidget {
  final IconData icon;

  const _AlphabetIconArt({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(child: Icon(icon, color: TudloColors.forest, size: 74));
  }
}

class _GradeOneFamilyLesson extends StatefulWidget {
  final LevelContent content;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOneFamilyLesson({
    required this.content,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeOneFamilyLesson> createState() => _GradeOneFamilyLessonState();
}

class _GradeOneFamilyLessonState extends State<_GradeOneFamilyLesson> {
  int _stepIndex = 0;

  void _goToStep(int index, int maxIndex) {
    final next = index.clamp(0, maxIndex);
    if (next == _stepIndex) return;
    setState(() => _stepIndex = next);
  }

  void _advanceAfterCorrect(int maxIndex) {
    final completedStep = _stepIndex;
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted || _stepIndex != completedStep) return;
      _goToStep(completedStep + 1, maxIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final words = _familyWordsFor(widget.content.lessonNumber);
    var maxIndex = 0;
    final quizTargets = words.take(math.min(3, words.length)).toList();
    final quizCards = [
      for (var index = 0; index < quizTargets.length; index++)
        _FamilyQuizCard(
          key: ValueKey(
            'family-quiz-${widget.content.id}-${quizTargets[index].hil}',
          ),
          target: quizTargets[index],
          choices: _familyChoicesFor(quizTargets[index], words, 3),
          onCorrect: () {
            widget.onQuizCorrect(index);
            _advanceAfterCorrect(maxIndex);
          },
        ),
    ];

    final steps = [
      _AlphabetFadeStep(
        child: _FamilyExploreCard(
          key: ValueKey('family-explore-${widget.content.id}'),
          words: quizTargets,
          onDone: () => _advanceAfterCorrect(maxIndex),
        ),
      ),
      for (var index = 0; index < words.length; index++)
        _AlphabetFadeStep(
          child: _FamilyWordLessonCard(
            key: ValueKey(
              'family-lesson-${widget.content.id}-${words[index].hil}',
            ),
            word: words[index],
            canGoBack: index > 0,
            onBack: () => _goToStep(_stepIndex - 1, maxIndex),
            onNext: () => _goToStep(_stepIndex + 1, maxIndex),
          ),
        ),
      _AlphabetFadeStep(
        child: _QuizTimeSplash(
          onDone: () => _goToStep(_stepIndex + 1, maxIndex),
        ),
      ),
      for (final card in quizCards) _AlphabetFadeStep(child: card),
      _AlphabetFadeStep(
        child: _FamilyMatchingCard(
          key: ValueKey('family-match-${widget.content.id}'),
          words: quizTargets,
          onCorrect: () {
            for (
              var index = quizTargets.length;
              index < widget.content.quizItems.length;
              index++
            ) {
              widget.onQuizCorrect(index);
            }
          },
        ),
      ),
    ];
    maxIndex = steps.length - 1;
    final activeStep = steps[_stepIndex.clamp(0, maxIndex)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(390.0, constraints.maxWidth);
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 850),
                reverseDuration: const Duration(milliseconds: 650),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: .97, end: 1).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child: Align(
                  key: ValueKey('family-step-$_stepIndex'),
                  alignment: Alignment.topCenter,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(width: width, child: activeStep.child),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FamilyWord {
  final String hil;
  final String eng;
  final String imageAsset;
  final IconData icon;

  const _FamilyWord({
    required this.hil,
    required this.eng,
    required this.imageAsset,
    required this.icon,
  });
}

class _FamilyExploreCard extends StatefulWidget {
  final List<_FamilyWord> words;
  final VoidCallback onDone;

  const _FamilyExploreCard({
    super.key,
    required this.words,
    required this.onDone,
  });

  @override
  State<_FamilyExploreCard> createState() => _FamilyExploreCardState();
}

class _FamilyExploreCardState extends State<_FamilyExploreCard> {
  final Set<String> _tapped = {};
  String _message = 'Koka: Tan-awa ang pamilya. Tap-a sila.';
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          'Tan-awa ang pamilya. Tap-a sila.',
          hiligaynon: true,
        ),
      );
    });
  }

  Future<void> _tapWord(_FamilyWord word) async {
    if (_reported) return;
    setState(() {
      _tapped.add(word.hil);
      _message = 'Koka: ${_titleCase(word.hil)}... ${_titleCase(word.eng)}.';
    });
    await TudloVoiceButton.speak(
      context,
      '${word.hil}... ${word.eng}.',
      hiligaynon: true,
    );
    if (!mounted) return;
    if (_tapped.length >= widget.words.length && !_reported) {
      _reported = true;
      Future<void>.delayed(const Duration(milliseconds: 850), () {
        if (mounted) widget.onDone();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FamilyStage(
      mascotMessage: _message,
      child: SizedBox(
        height: 520,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              child: Opacity(
                opacity: .42,
                child: Image.asset(
                  'assets/images/level_game/Grade1/unit1/house.png',
                  width: 330,
                  height: 240,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.home_rounded,
                    color: TudloColors.forest.withValues(alpha: .32),
                    size: 160,
                  ),
                ),
              ),
            ),
            for (var index = 0; index < widget.words.length; index++)
              Positioned(
                left: _familyExploreOffset(index, widget.words.length).dx,
                top: _familyExploreOffset(index, widget.words.length).dy,
                child: _FamilyExplorePerson(
                  word: widget.words[index],
                  tapped: _tapped.contains(widget.words[index].hil),
                  onTap: () => _tapWord(widget.words[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Offset _familyExploreOffset(int index, int count) {
    if (count <= 2) {
      return index == 0 ? const Offset(42, 210) : const Offset(198, 210);
    }
    return switch (index) {
      0 => const Offset(6, 210),
      1 => const Offset(128, 190),
      _ => const Offset(250, 214),
    };
  }
}

class _FamilyExplorePerson extends StatelessWidget {
  final _FamilyWord word;
  final bool tapped;
  final VoidCallback onTap;

  const _FamilyExplorePerson({
    required this.word,
    required this.tapped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: tapped ? 1.08 : 1,
        child: Container(
          width: 126,
          height: 190,
          decoration: BoxDecoration(
            boxShadow: tapped
                ? [
                    BoxShadow(
                      color: TudloColors.green.withValues(alpha: .36),
                      blurRadius: 28,
                      spreadRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Image.asset(
            word.imageAsset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) =>
                Icon(word.icon, color: TudloColors.forest, size: 96),
          ),
        ),
      ),
    );
  }
}

class _GradeOneHelperLesson extends StatefulWidget {
  final LevelContent content;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOneHelperLesson({
    required this.content,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeOneHelperLesson> createState() => _GradeOneHelperLessonState();
}

class _GradeOneHelperLessonState extends State<_GradeOneHelperLesson> {
  int _stepIndex = 0;
  bool _reportedComplete = false;

  void _goToStep(int index, int maxIndex) {
    final next = index.clamp(0, maxIndex);
    if (next == _stepIndex) return;
    setState(() => _stepIndex = next);
  }

  void _advanceAfterCorrect(int maxIndex) {
    final completedStep = _stepIndex;
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || _stepIndex != completedStep) return;
      _goToStep(completedStep + 1, maxIndex);
    });
  }

  void _markComplete() {
    if (_reportedComplete) return;
    _reportedComplete = true;
    for (var index = 0; index < widget.content.quizItems.length; index++) {
      widget.onQuizCorrect(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final helpers = _helpersForLesson(widget.content.lessonNumber);
    var maxIndex = 0;
    final steps = [
      for (final helper in helpers) ...[
        _AlphabetFadeStep(
          child: _HelperTapCard(
            key: ValueKey('helper-tap-${widget.content.id}-${helper.hil}'),
            helper: helper,
            onDone: () => _advanceAfterCorrect(maxIndex),
          ),
        ),
        _AlphabetFadeStep(
          child: _HelperWorkplaceDragCard(
            key: ValueKey('helper-work-${widget.content.id}-${helper.hil}'),
            helper: helper,
            onDone: () => _advanceAfterCorrect(maxIndex),
          ),
        ),
        _AlphabetFadeStep(
          child: _HelperToolDragCard(
            key: ValueKey('helper-tool-${widget.content.id}-${helper.hil}'),
            helper: helper,
            choices: _toolChoicesFor(helper, helpers),
            onDone: () => _advanceAfterCorrect(maxIndex),
          ),
        ),
      ],
      _AlphabetFadeStep(
        child: _QuizTimeSplash(
          onDone: () => _goToStep(_stepIndex + 1, maxIndex),
        ),
      ),
      _AlphabetFadeStep(
        child: _HelperReviewCard(
          key: ValueKey('helper-review-${widget.content.id}'),
          helpers: helpers.take(3).toList(),
          onDone: _markComplete,
        ),
      ),
    ];
    maxIndex = steps.length - 1;
    final activeStep = steps[_stepIndex.clamp(0, maxIndex)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(390.0, constraints.maxWidth);
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 850),
                reverseDuration: const Duration(milliseconds: 650),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: .97, end: 1).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child: Align(
                  key: ValueKey('helper-step-$_stepIndex'),
                  alignment: Alignment.topCenter,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(width: width, child: activeStep.child),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HelperWord {
  final String hil;
  final String eng;
  final String tapSpeech;
  final String workplaceLabel;
  final String workplaceSpeech;
  final String imageAsset;
  final String? workplaceAsset;
  final _HelperTool tool;
  final IconData icon;
  final IconData workplaceIcon;
  final Color color;

  const _HelperWord({
    required this.hil,
    required this.eng,
    required this.tapSpeech,
    required this.workplaceLabel,
    required this.workplaceSpeech,
    required this.imageAsset,
    required this.tool,
    required this.icon,
    required this.workplaceIcon,
    required this.color,
    this.workplaceAsset,
  });

  String get upperName => hil.toUpperCase();
  String get tapInstruction => 'Ipindot ang $hil.';
  String get workplaceInstruction =>
      'Guyoda ang $hil pakadto sa $workplaceLabel.';
  String get retryWorkplace =>
      'Liwata. Guyoda ang $hil pakadto sa $workplaceLabel.';
  String get toolInstruction => 'Guyoda ang gamit pakadto sa $hil.';
  String get toolSuccess => 'Husto! Ang $hil nagagamit sang ${tool.hil}.';
}

class _HelperTool {
  final String hil;
  final IconData icon;
  final Color color;

  const _HelperTool({
    required this.hil,
    required this.icon,
    required this.color,
  });
}

class _HelperTapCard extends StatefulWidget {
  final _HelperWord helper;
  final VoidCallback onDone;

  const _HelperTapCard({super.key, required this.helper, required this.onDone});

  @override
  State<_HelperTapCard> createState() => _HelperTapCardState();
}

class _HelperTapCardState extends State<_HelperTapCard> {
  bool _tapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          widget.helper.tapInstruction,
          hiligaynon: true,
        ),
      );
    });
  }

  Future<void> _tapHelper() async {
    if (_tapped) return;
    setState(() => _tapped = true);
    await TudloVoiceButton.speak(
      context,
      '${widget.helper.tool.hil}! ${widget.helper.tapSpeech}',
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _tapped
          ? widget.helper.tapSpeech
          : 'Koka: ${widget.helper.tapInstruction}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.helper.upperName,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: widget.helper.upperName.length > 9 ? 36 : 44,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: _tapHelper,
            child: _AnimalBounce(
              active: _tapped,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (_tapped)
                    Positioned(
                      right: -16,
                      top: 16,
                      child: _ToolArt(tool: widget.helper.tool, size: 92),
                    ),
                  _HelperArt(helper: widget.helper, size: 330),
                  if (_tapped) const _AnimalSparkles(size: 370),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelperWorkplaceDragCard extends StatefulWidget {
  final _HelperWord helper;
  final VoidCallback onDone;

  const _HelperWorkplaceDragCard({
    super.key,
    required this.helper,
    required this.onDone,
  });

  @override
  State<_HelperWorkplaceDragCard> createState() =>
      _HelperWorkplaceDragCardState();
}

class _HelperWorkplaceDragCardState extends State<_HelperWorkplaceDragCard> {
  bool _placed = false;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          widget.helper.workplaceInstruction,
          hiligaynon: true,
        ),
      );
    });
  }

  void _retry() {
    if (_placed) return;
    setState(() => _retrying = true);
    unawaited(
      TudloVoiceButton.speak(
        context,
        widget.helper.retryWorkplace,
        hiligaynon: true,
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _retrying = false);
    });
  }

  Future<void> _accept() async {
    if (_placed) return;
    setState(() => _placed = true);
    await TudloVoiceButton.speak(
      context,
      widget.helper.workplaceSpeech,
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _placed
          ? 'Koka: ${widget.helper.workplaceSpeech}'
          : _retrying
          ? 'Koka: ${widget.helper.retryWorkplace}'
          : 'Koka: ${widget.helper.workplaceInstruction}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.helper.upperName,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: widget.helper.upperName.length > 9 ? 34 : 40,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 445,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -8,
                  top: 18,
                  child: _HelperWorkplaceTarget(
                    helper: widget.helper,
                    size: 260,
                    placed: _placed,
                    onAccept: _accept,
                    onWrongDrop: _retry,
                  ),
                ),
                Positioned(
                  left: -2,
                  bottom: 18,
                  child: _placed
                      ? const SizedBox(width: 238, height: 238)
                      : _HelperDraggable(
                          helper: widget.helper,
                          size: 238,
                          onMissed: _retry,
                        ),
                ),
                if (_placed)
                  Positioned(
                    right: 50,
                    top: 104,
                    child: _AnimalBounce(
                      active: true,
                      child: _HelperArt(helper: widget.helper, size: 144),
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

class _HelperToolDragCard extends StatefulWidget {
  final _HelperWord helper;
  final List<_HelperTool> choices;
  final VoidCallback onDone;

  const _HelperToolDragCard({
    super.key,
    required this.helper,
    required this.choices,
    required this.onDone,
  });

  @override
  State<_HelperToolDragCard> createState() => _HelperToolDragCardState();
}

class _HelperToolDragCardState extends State<_HelperToolDragCard> {
  bool _matched = false;
  bool _retrying = false;

  void _retry() {
    if (_matched) return;
    setState(() => _retrying = true);
    unawaited(
      TudloVoiceButton.speak(
        context,
        'Liwata. Guyoda ang sakto nga gamit pakadto sa ${widget.helper.hil}.',
        hiligaynon: true,
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _retrying = false);
    });
  }

  Future<void> _acceptTool(_HelperTool tool) async {
    if (_matched) return;
    if (tool.hil != widget.helper.tool.hil) {
      _retry();
      return;
    }
    setState(() => _matched = true);
    await TudloVoiceButton.speak(
      context,
      widget.helper.toolSuccess,
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _matched
          ? 'Koka: ${widget.helper.toolSuccess}'
          : _retrying
          ? 'Koka: Liwata. Pangitaa ang sakto nga gamit.'
          : 'Koka: ${widget.helper.toolInstruction}',
      child: Column(
        children: [
          Text(
            widget.helper.upperName,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: widget.helper.upperName.length > 9 ? 34 : 40,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          DragTarget<_HelperTool>(
            onWillAcceptWithDetails: (_) => !_matched,
            onAcceptWithDetails: (details) => _acceptTool(details.data),
            builder: (context, candidates, rejected) {
              return SizedBox(
                width: 250,
                height: 250,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    _HelperArt(helper: widget.helper, size: 236),
                    if (candidates.isNotEmpty || _matched)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: TudloColors.green.withValues(alpha: .32),
                                blurRadius: 30,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_matched)
                      Positioned(
                        right: 6,
                        bottom: 0,
                        child: _ToolArt(tool: widget.helper.tool, size: 88),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final tool in widget.choices)
                _matched && tool.hil == widget.helper.tool.hil
                    ? const SizedBox(width: 102, height: 102)
                    : _ToolDraggable(tool: tool, size: 102, onMissed: _retry),
            ],
          ),
        ],
      ),
    );
  }
}

class _HelperReviewCard extends StatefulWidget {
  final List<_HelperWord> helpers;
  final VoidCallback onDone;

  const _HelperReviewCard({
    super.key,
    required this.helpers,
    required this.onDone,
  });

  @override
  State<_HelperReviewCard> createState() => _HelperReviewCardState();
}

class _HelperReviewCardState extends State<_HelperReviewCard> {
  final Set<String> _matched = {};
  String _message =
      'Koka: Guyoda ang kada community helper pakadto sa ila ginatrabahuan.';
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          'Guyoda ang kada community helper pakadto sa ila ginatrabahuan.',
          hiligaynon: true,
        ),
      );
    });
  }

  Future<void> _handleDrop(_HelperWord target, _HelperWord dragged) async {
    if (_reported || _matched.contains(dragged.hil)) return;
    if (target.hil != dragged.hil) {
      setState(() {
        _message =
            'Koka: Liwata. Pangitaa ang ginatrabahuan sang ${dragged.hil}.';
      });
      await TudloVoiceButton.speak(
        context,
        'Liwata. Pangitaa ang ginatrabahuan sang ${dragged.hil}.',
        hiligaynon: true,
      );
      return;
    }
    setState(() {
      _matched.add(dragged.hil);
      _message = 'Koka: Husto! ${_titleCase(dragged.hil)}.';
    });
    await TudloVoiceButton.speak(
      context,
      dragged.workplaceSpeech,
      hiligaynon: true,
    );
    if (!mounted) return;
    if (_matched.length == widget.helpers.length && !_reported) {
      _reported = true;
      setState(() {
        _message =
            'Koka: Maayo gid! Kabalo ka na sang mga community helpers kag ila ginahimo!';
      });
      await TudloVoiceButton.speak(
        context,
        'Maayo gid! Kabalo ka na sang mga community helpers kag ila ginahimo!',
        hiligaynon: true,
      );
      if (mounted) widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _message,
      child: Column(
        children: [
          Text(
            'Ipares ang Trabaho',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final helper in widget.helpers)
                _HelperReviewWorkplace(
                  helper: helper,
                  matched: _matched.contains(helper.hil),
                  onDrop: (dragged) => _handleDrop(helper, dragged),
                ),
            ],
          ),
          const SizedBox(height: 34),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final helper in widget.helpers)
                _matched.contains(helper.hil)
                    ? const SizedBox(width: 126, height: 126)
                    : _HelperDraggable(
                        helper: helper,
                        size: 126,
                        onMissed: () {
                          setState(() {
                            _message =
                                'Koka: Guyoda ang ${helper.hil} pakadto sa iya ginatrabahuan.';
                          });
                        },
                      ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HelperDraggable extends StatelessWidget {
  final _HelperWord helper;
  final double size;
  final VoidCallback onMissed;

  const _HelperDraggable({
    required this.helper,
    required this.size,
    required this.onMissed,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<_HelperWord>(
      data: helper,
      feedback: Material(
        color: Colors.transparent,
        child: _HelperArt(helper: helper, size: size * 1.08),
      ),
      childWhenDragging: Opacity(
        opacity: .24,
        child: _HelperArt(helper: helper, size: size),
      ),
      onDragEnd: (details) {
        if (!details.wasAccepted) onMissed();
      },
      child: _HelperArt(helper: helper, size: size),
    );
  }
}

class _ToolDraggable extends StatelessWidget {
  final _HelperTool tool;
  final double size;
  final VoidCallback onMissed;

  const _ToolDraggable({
    required this.tool,
    required this.size,
    required this.onMissed,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<_HelperTool>(
      data: tool,
      feedback: Material(
        color: Colors.transparent,
        child: _ToolArt(tool: tool, size: size * 1.08),
      ),
      childWhenDragging: Opacity(
        opacity: .24,
        child: _ToolArt(tool: tool, size: size),
      ),
      onDragEnd: (details) {
        if (!details.wasAccepted) onMissed();
      },
      child: _ToolArt(tool: tool, size: size),
    );
  }
}

class _HelperWorkplaceTarget extends StatelessWidget {
  final _HelperWord helper;
  final double size;
  final bool placed;
  final VoidCallback onAccept;
  final VoidCallback onWrongDrop;

  const _HelperWorkplaceTarget({
    required this.helper,
    required this.size,
    required this.placed,
    required this.onAccept,
    required this.onWrongDrop,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<_HelperWord>(
      onWillAcceptWithDetails: (_) => !placed,
      onAcceptWithDetails: (details) {
        if (details.data.hil == helper.hil) {
          onAccept();
        } else {
          onWrongDrop();
        }
      },
      builder: (context, candidates, rejected) {
        return _HelperWorkplaceArt(
          helper: helper,
          size: size,
          active: candidates.isNotEmpty,
          matched: placed,
        );
      },
    );
  }
}

class _HelperReviewWorkplace extends StatelessWidget {
  final _HelperWord helper;
  final bool matched;
  final ValueChanged<_HelperWord> onDrop;

  const _HelperReviewWorkplace({
    required this.helper,
    required this.matched,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<_HelperWord>(
      onWillAcceptWithDetails: (_) => !matched,
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidates, rejected) {
        return _HelperWorkplaceArt(
          helper: helper,
          size: 126,
          active: candidates.isNotEmpty,
          matched: matched,
        );
      },
    );
  }
}

class _HelperArt extends StatelessWidget {
  final _HelperWord helper;
  final double size;

  const _HelperArt({required this.helper, required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      helper.imageAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => _HelperIconArt(helper: helper, size: size),
    );
  }
}

class _HelperIconArt extends StatelessWidget {
  final _HelperWord helper;
  final double size;

  const _HelperIconArt({required this.helper, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: helper.color.withValues(alpha: .16),
      ),
      child: Icon(helper.icon, color: helper.color, size: size * .58),
    );
  }
}

class _HelperWorkplaceArt extends StatelessWidget {
  final _HelperWord helper;
  final double size;
  final bool active;
  final bool matched;

  const _HelperWorkplaceArt({
    required this.helper,
    required this.size,
    required this.active,
    required this.matched,
  });

  @override
  Widget build(BuildContext context) {
    final workplace = helper.workplaceAsset == null
        ? _HelperWorkplaceIcon(helper: helper, size: size)
        : Image.asset(
            helper.workplaceAsset!,
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) =>
                _HelperWorkplaceIcon(helper: helper, size: size),
          );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.transparent,
        boxShadow: active || matched
            ? [
                BoxShadow(
                  color: TudloColors.green.withValues(alpha: .24),
                  blurRadius: 22,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: Center(child: workplace),
    );
  }
}

class _HelperWorkplaceIcon extends StatelessWidget {
  final _HelperWord helper;
  final double size;

  const _HelperWorkplaceIcon({required this.helper, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * .88,
      height: size * .88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: TudloColors.softGreen.withValues(alpha: .82),
      ),
      child: Icon(
        helper.workplaceIcon,
        color: TudloColors.forest,
        size: size * .48,
      ),
    );
  }
}

class _ToolArt extends StatelessWidget {
  final _HelperTool tool;
  final double size;

  const _ToolArt({required this.tool, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tool.color.withValues(alpha: .18),
        boxShadow: [
          BoxShadow(
            color: tool.color.withValues(alpha: .18),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Icon(tool.icon, color: tool.color, size: size * .54),
    );
  }
}

List<_HelperTool> _toolChoicesFor(
  _HelperWord target,
  List<_HelperWord> helpers,
) {
  final tools = <_HelperTool>[target.tool];
  for (final helper in helpers) {
    if (helper.tool.hil != target.tool.hil) tools.add(helper.tool);
    if (tools.length == 3) break;
  }
  if (tools.length < 3) {
    for (final helper in _helpersForLesson(4)) {
      if (tools.any((tool) => tool.hil == helper.tool.hil)) continue;
      tools.add(helper.tool);
      if (tools.length == 3) break;
    }
  }
  return tools;
}

List<_HelperWord> _helpersForLesson(int lessonNumber) {
  const teacherTool = _HelperTool(
    hil: 'libro',
    icon: Icons.menu_book_rounded,
    color: TudloColors.blue,
  );
  const doctorTool = _HelperTool(
    hil: 'stethoscope',
    icon: Icons.health_and_safety_rounded,
    color: TudloColors.coral,
  );
  const nurseTool = _HelperTool(
    hil: 'thermometer',
    icon: Icons.thermostat_rounded,
    color: TudloColors.orange,
  );
  const policeTool = _HelperTool(
    hil: 'whistle',
    icon: Icons.campaign_rounded,
    color: TudloColors.blue,
  );
  const firefighterTool = _HelperTool(
    hil: 'hos',
    icon: Icons.water_drop_rounded,
    color: TudloColors.coral,
  );
  const vendorTool = _HelperTool(
    hil: 'basket sang prutas',
    icon: Icons.shopping_basket_rounded,
    color: TudloColors.gold,
  );
  const farmerTool = _HelperTool(
    hil: 'gamit pang-uma',
    icon: Icons.agriculture_rounded,
    color: TudloColors.forest,
  );
  const fisherTool = _HelperTool(
    hil: 'pukot',
    icon: Icons.phishing_rounded,
    color: TudloColors.blue,
  );

  const teacher = _HelperWord(
    hil: 'manunudlo',
    eng: 'manunudlo',
    tapSpeech: 'Manunudlo. Ang manunudlo nagatudlo sa mga bata.',
    workplaceLabel: 'eskwelahan',
    workplaceSpeech: 'Husto! Ang manunudlo nagatrabaho sa eskwelahan.',
    imageAsset: 'assets/images/level_game/Grade1/unit1/manunudlo.png',
    workplaceAsset: 'assets/images/level_game/Grade1/unit1/eskwelahan.png',
    tool: teacherTool,
    icon: Icons.school_rounded,
    workplaceIcon: Icons.school_rounded,
    color: TudloColors.blue,
  );
  const doctor = _HelperWord(
    hil: 'doktor',
    eng: 'doktor',
    tapSpeech: 'Doktor. Ang doktor nagabulig sa mga masakiton.',
    workplaceLabel: 'ospital',
    workplaceSpeech: 'Husto! Ang doktor nagatrabaho sa ospital.',
    imageAsset: 'assets/images/level_game/Grade1/unit1/doktor.png',
    workplaceAsset: 'assets/images/level_game/Grade1/unit1/ospital.png',
    tool: doctorTool,
    icon: Icons.medical_services_rounded,
    workplaceIcon: Icons.local_hospital_rounded,
    color: TudloColors.coral,
  );
  const nurse = _HelperWord(
    hil: 'nars',
    eng: 'nars',
    tapSpeech: 'Nars. Ang nars nagaatipan sa mga masakiton.',
    workplaceLabel: 'ospital',
    workplaceSpeech: 'Husto! Ang nars nagatrabaho sa ospital.',
    imageAsset: 'assets/images/level_game/Grade1/unit1/nars.png',
    workplaceAsset: 'assets/images/level_game/Grade1/unit1/ospital.png',
    tool: nurseTool,
    icon: Icons.medical_information_rounded,
    workplaceIcon: Icons.local_hospital_rounded,
    color: TudloColors.orange,
  );
  const police = _HelperWord(
    hil: 'pulis',
    eng: 'pulis',
    tapSpeech: 'Pulis. Ang pulis nagabantay sang katawhayan.',
    workplaceLabel: 'estasyon sang pulis',
    workplaceSpeech: 'Husto! Ang pulis nagatrabaho sa estasyon sang pulis.',
    imageAsset: 'assets/images/level_game/Grade1/unit1/pulis.png',
    workplaceAsset:
        'assets/images/level_game/Grade1/unit1/estasyon-sang-pulis.png',
    tool: policeTool,
    icon: Icons.local_police_rounded,
    workplaceIcon: Icons.local_police_rounded,
    color: TudloColors.blue,
  );
  const firefighter = _HelperWord(
    hil: 'bumbero',
    eng: 'bumbero',
    tapSpeech: 'Bumbero. Ang bumbero nagapatay sang kalayo.',
    workplaceLabel: 'estasyon sang bumbero',
    workplaceSpeech: 'Husto! Ang bumbero nagatrabaho sa estasyon sang bumbero.',
    imageAsset: 'assets/images/level_game/Grade1/unit1/bumbero.png',
    workplaceAsset:
        'assets/images/level_game/Grade1/unit1/estasyon-sang-bumbero.png',
    tool: firefighterTool,
    icon: Icons.local_fire_department_rounded,
    workplaceIcon: Icons.local_fire_department_rounded,
    color: TudloColors.coral,
  );
  const vendor = _HelperWord(
    hil: 'tindera',
    eng: 'tindera',
    tapSpeech: 'Tindera. Ang tindera nagabaligya sang mga balaklon.',
    workplaceLabel: 'tinda',
    workplaceSpeech: 'Husto! Ang tindera nagatrabaho sa tinda.',
    imageAsset: 'assets/images/level_game/Grade1/unit1/tindera.png',
    workplaceAsset: 'assets/images/level_game/Grade1/unit1/tinda.png',
    tool: vendorTool,
    icon: Icons.storefront_rounded,
    workplaceIcon: Icons.storefront_rounded,
    color: TudloColors.gold,
  );
  const farmer = _HelperWord(
    hil: 'mangunguma',
    eng: 'mangunguma',
    tapSpeech: 'Mangunguma. Ang mangunguma nagatanom sang humay kag utan.',
    workplaceLabel: 'uma',
    workplaceSpeech: 'Husto! Ang mangunguma nagatrabaho sa uma.',
    imageAsset: 'assets/images/level_game/Grade1/unit1/mangunguma.png',
    workplaceAsset: 'assets/images/level_game/Grade1/unit1/uma.png',
    tool: farmerTool,
    icon: Icons.agriculture_rounded,
    workplaceIcon: Icons.agriculture_rounded,
    color: TudloColors.forest,
  );
  const fisher = _HelperWord(
    hil: 'mangingisda',
    eng: 'mangingisda',
    tapSpeech: 'Mangingisda. Ang mangingisda nagadakop sang isda.',
    workplaceLabel: 'baybay',
    workplaceSpeech: 'Husto! Ang mangingisda nagatrabaho sa baybay.',
    imageAsset: 'assets/images/level_game/Grade1/unit1/mangingisda.png',
    workplaceAsset: 'assets/images/level_game/Grade1/unit1/dagat.png',
    tool: fisherTool,
    icon: Icons.sailing_rounded,
    workplaceIcon: Icons.beach_access_rounded,
    color: TudloColors.blue,
  );

  return switch (lessonNumber) {
    1 => const [teacher, doctor, nurse],
    2 => const [police, firefighter, vendor],
    3 => const [farmer, fisher],
    _ => const [
      teacher,
      doctor,
      nurse,
      police,
      firefighter,
      vendor,
      farmer,
      fisher,
    ],
  };
}

class _GradeOnePlaceLesson extends StatefulWidget {
  final LevelContent content;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOnePlaceLesson({
    required this.content,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeOnePlaceLesson> createState() => _GradeOnePlaceLessonState();
}

class _GradeOnePlaceLessonState extends State<_GradeOnePlaceLesson> {
  int _stepIndex = 0;
  bool _reportedComplete = false;

  void _goToStep(int index, int maxIndex) {
    final next = index.clamp(0, maxIndex);
    if (next == _stepIndex) return;
    setState(() => _stepIndex = next);
  }

  void _advanceAfterCorrect(int maxIndex) {
    final completedStep = _stepIndex;
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || _stepIndex != completedStep) return;
      _goToStep(completedStep + 1, maxIndex);
    });
  }

  void _markComplete() {
    if (_reportedComplete) return;
    _reportedComplete = true;
    for (var index = 0; index < widget.content.quizItems.length; index++) {
      widget.onQuizCorrect(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final places = _placesForLesson(widget.content.lessonNumber);
    var maxIndex = 0;
    final reviewPlaces = _placeReviewTargetsFor(widget.content.lessonNumber);
    final steps = [
      _AlphabetFadeStep(
        child: _PlaceOpeningCard(onDone: () => _advanceAfterCorrect(maxIndex)),
      ),
      for (final place in places) ...[
        _AlphabetFadeStep(
          child: _PlaceTapCard(
            key: ValueKey('place-tap-${widget.content.id}-${place.hil}'),
            place: place,
            onDone: () => _advanceAfterCorrect(maxIndex),
          ),
        ),
        _AlphabetFadeStep(
          child: _KokaTravelCard(
            key: ValueKey('place-travel-${widget.content.id}-${place.hil}'),
            place: place,
            onDone: () => _advanceAfterCorrect(maxIndex),
          ),
        ),
      ],
      _AlphabetFadeStep(
        child: _QuizTimeSplash(
          onDone: () => _goToStep(_stepIndex + 1, maxIndex),
        ),
      ),
      _AlphabetFadeStep(
        child: _PlaceMapGuideCard(
          key: ValueKey('place-guide-${widget.content.id}'),
          places: reviewPlaces,
          onDone: () => _advanceAfterCorrect(maxIndex),
        ),
      ),
      _AlphabetFadeStep(
        child: _PlaceSituationGameCard(
          key: ValueKey('place-situations-${widget.content.id}'),
          onDone: _markComplete,
        ),
      ),
    ];
    maxIndex = steps.length - 1;
    final activeStep = steps[_stepIndex.clamp(0, maxIndex)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(390.0, constraints.maxWidth);
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 850),
                reverseDuration: const Duration(milliseconds: 650),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: .97, end: 1).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child: Align(
                  key: ValueKey('place-step-$_stepIndex'),
                  alignment: Alignment.topCenter,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(width: width, child: activeStep.child),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PlaceWord {
  final String hil;
  final String eng;
  final String asset;
  final IconData icon;
  final Color color;
  final String introSpeech;
  final String tapSpeech;
  final List<IconData> effects;

  const _PlaceWord({
    required this.hil,
    required this.eng,
    required this.asset,
    required this.icon,
    required this.color,
    required this.introSpeech,
    required this.tapSpeech,
    required this.effects,
  });

  String get upperName => hil.toUpperCase();
  String get tapInstruction => 'Ipindot ang $hil.';
  String get travelInstruction => 'Guyoda si Koka pakadto sa $hil.';
  String get arrivedSpeech => 'Husto! Ari na si Koka sa $hil.';
}

class _PlaceOpeningCard extends StatefulWidget {
  final VoidCallback onDone;

  const _PlaceOpeningCard({required this.onDone});

  @override
  State<_PlaceOpeningCard> createState() => _PlaceOpeningCardState();
}

class _PlaceOpeningCardState extends State<_PlaceOpeningCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          'Maglibot kita sa aton banwa!',
          hiligaynon: true,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: 'Koka: Maglibot kita sa aton banwa!',
      child: SizedBox(
        height: 510,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 38,
              child: Image.asset(
                'assets/images/level_game/Grade1/unit1/road.png',
                width: 350,
                height: 270,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            const Positioned(top: 118, child: TudloMascot(size: 190)),
            Positioned(
              bottom: 46,
              child: SizedBox(
                width: 260,
                height: 70,
                child: ElevatedButton(
                  onPressed: widget.onDone,
                  child: const Text('Lakbay!'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceTapCard extends StatefulWidget {
  final _PlaceWord place;
  final VoidCallback onDone;

  const _PlaceTapCard({super.key, required this.place, required this.onDone});

  @override
  State<_PlaceTapCard> createState() => _PlaceTapCardState();
}

class _PlaceTapCardState extends State<_PlaceTapCard> {
  bool _tapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          widget.place.introSpeech,
          hiligaynon: true,
        ),
      );
    });
  }

  Future<void> _tapPlace() async {
    if (_tapped) return;
    setState(() => _tapped = true);
    await TudloVoiceButton.speak(
      context,
      widget.place.tapSpeech,
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _tapped
          ? 'Koka: ${widget.place.tapSpeech}'
          : 'Koka: ${widget.place.tapInstruction}',
      child: Column(
        children: [
          Text(
            widget.place.upperName,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: widget.place.upperName.length > 9 ? 36 : 44,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: _tapPlace,
            child: _AnimalBounce(
              active: _tapped,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  _PlaceArt(place: widget.place, size: 330),
                  if (_tapped) ...[
                    const _AnimalSparkles(size: 360),
                    for (
                      var index = 0;
                      index < widget.place.effects.length;
                      index++
                    )
                      Positioned(
                        right: 16.0 + index * 34,
                        top: index.isEven ? 18 : 72,
                        child: Icon(
                          widget.place.effects[index],
                          color: widget.place.color,
                          size: 42,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KokaTravelCard extends StatefulWidget {
  final _PlaceWord place;
  final VoidCallback onDone;

  const _KokaTravelCard({super.key, required this.place, required this.onDone});

  @override
  State<_KokaTravelCard> createState() => _KokaTravelCardState();
}

class _KokaTravelCardState extends State<_KokaTravelCard> {
  bool _arrived = false;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          widget.place.travelInstruction,
          hiligaynon: true,
        ),
      );
    });
  }

  void _retry() {
    if (_arrived) return;
    setState(() => _retrying = true);
    unawaited(
      TudloVoiceButton.speak(
        context,
        'Liwata. ${widget.place.travelInstruction}',
        hiligaynon: true,
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _retrying = false);
    });
  }

  Future<void> _arrive() async {
    if (_arrived) return;
    setState(() => _arrived = true);
    await TudloVoiceButton.speak(
      context,
      '${widget.place.arrivedSpeech} Welcome!',
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _arrived
          ? 'Koka: ${widget.place.arrivedSpeech}'
          : _retrying
          ? 'Koka: Liwata. ${widget.place.travelInstruction}'
          : 'Koka: ${widget.place.travelInstruction}',
      child: SizedBox(
        height: 530,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 6,
              right: 6,
              bottom: 88,
              child: Image.asset(
                'assets/images/level_game/Grade1/unit1/road.png',
                height: 170,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
            ),
            Positioned(
              right: 12,
              top: 18,
              child: DragTarget<String>(
                onWillAcceptWithDetails: (_) => !_arrived,
                onAcceptWithDetails: (_) => _arrive(),
                builder: (context, candidates, rejected) {
                  return _PlaceArt(
                    place: widget.place,
                    size: candidates.isNotEmpty || _arrived ? 246 : 232,
                    glow: candidates.isNotEmpty || _arrived,
                  );
                },
              ),
            ),
            Positioned(
              left: 22,
              bottom: 116,
              child: _arrived
                  ? const SizedBox(width: 132, height: 132)
                  : Draggable<String>(
                      data: widget.place.hil,
                      feedback: const Material(
                        color: Colors.transparent,
                        child: TudloMascot(size: 142),
                      ),
                      childWhenDragging: const Opacity(
                        opacity: .24,
                        child: TudloMascot(size: 132),
                      ),
                      onDragEnd: (details) {
                        if (!details.wasAccepted) _retry();
                      },
                      child: const TudloMascot(size: 132),
                    ),
            ),
            if (_arrived)
              Positioned(
                right: 62,
                top: 110,
                child: Column(
                  children: [
                    const TudloMascot(size: 104),
                    Text(
                      'Welcome!',
                      style: GoogleFonts.nunito(
                        color: TudloColors.green,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaceMapGuideCard extends StatefulWidget {
  final List<_PlaceWord> places;
  final VoidCallback onDone;

  const _PlaceMapGuideCard({
    super.key,
    required this.places,
    required this.onDone,
  });

  @override
  State<_PlaceMapGuideCard> createState() => _PlaceMapGuideCardState();
}

class _PlaceMapGuideCardState extends State<_PlaceMapGuideCard> {
  int _targetIndex = 0;
  String? _arrivedHil;
  bool _reported = false;

  _PlaceWord get _target => widget.places[_targetIndex];

  Future<void> _tapPlace(_PlaceWord place) async {
    if (_reported) return;
    if (place.hil != _target.hil) {
      await TudloVoiceButton.speak(
        context,
        'Liwata. Buligi ako magkadto sa ${_target.hil}.',
        hiligaynon: true,
      );
      return;
    }
    setState(() => _arrivedHil = place.hil);
    await TudloVoiceButton.speak(
      context,
      'Husto! Ari na kita sa ${place.hil}.',
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (_targetIndex >= widget.places.length - 1) {
        _reported = true;
        widget.onDone();
      } else {
        setState(() {
          _targetIndex++;
          _arrivedHil = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: 'Koka: Buligi ako magkadto sa ${_target.hil}.',
      child: Column(
        children: [
          Text(
            'Mapa sang Banwa',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 430,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/level_game/Grade1/unit1/road.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                for (var index = 0; index < widget.places.length; index++)
                  Positioned(
                    left: _mapOffset(index, widget.places.length).dx,
                    top: _mapOffset(index, widget.places.length).dy,
                    child: GestureDetector(
                      onTap: () => _tapPlace(widget.places[index]),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _PlaceArt(
                            place: widget.places[index],
                            size: 112,
                            glow:
                                _arrivedHil == widget.places[index].hil ||
                                _target.hil == widget.places[index].hil,
                          ),
                          if (_arrivedHil == widget.places[index].hil)
                            const Positioned(
                              right: -18,
                              bottom: -10,
                              child: TudloMascot(size: 58),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Offset _mapOffset(int index, int count) {
    final offsets = const [
      Offset(18, 40),
      Offset(220, 38),
      Offset(108, 172),
      Offset(28, 284),
      Offset(224, 284),
    ];
    return offsets[index % offsets.length];
  }
}

class _PlaceSituationGameCard extends StatefulWidget {
  final VoidCallback onDone;

  const _PlaceSituationGameCard({super.key, required this.onDone});

  @override
  State<_PlaceSituationGameCard> createState() =>
      _PlaceSituationGameCardState();
}

class _PlaceSituationGameCardState extends State<_PlaceSituationGameCard> {
  int _index = 0;
  String? _arrivedHil;
  bool _reported = false;

  final List<_PlaceSituation> _situations = [
    _PlaceSituation(
      prompt: 'May bata nga masakit.',
      answerHil: 'ospital',
      choices: ['ospital', 'eskwelahan', 'uma'],
      icon: Icons.sick_rounded,
    ),
    _PlaceSituation(
      prompt: 'Gutom ang karbaw.',
      answerHil: 'uma',
      choices: ['uma', 'baybay', 'ospital'],
      icon: Icons.agriculture_rounded,
    ),
    _PlaceSituation(
      prompt: 'Oras na magtuon.',
      answerHil: 'eskwelahan',
      choices: ['eskwelahan', 'baybay', 'tinda'],
      icon: Icons.menu_book_rounded,
    ),
  ];

  _PlaceSituation get _current => _situations[_index];

  Future<void> _tapChoice(_PlaceWord place) async {
    if (_reported) return;
    if (place.hil != _current.answerHil) {
      await TudloVoiceButton.speak(
        context,
        'Liwata. Diin kita makadto?',
        hiligaynon: true,
      );
      return;
    }
    setState(() => _arrivedHil = place.hil);
    await TudloVoiceButton.speak(
      context,
      'Husto! Makadto kita sa ${place.hil}.',
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (_index >= _situations.length - 1) {
        _reported = true;
        widget.onDone();
      } else {
        setState(() {
          _index++;
          _arrivedHil = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final choices = _current.choices
        .map(_placeByHil)
        .whereType<_PlaceWord>()
        .toList();
    return _AnimalStage(
      mascotMessage: 'Koka: Diin kita makadto?',
      child: Column(
        children: [
          Icon(_current.icon, color: TudloColors.green, size: 78),
          const SizedBox(height: 8),
          Text(
            _current.prompt,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: 26,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final place in choices)
                GestureDetector(
                  onTap: () => _tapChoice(place),
                  child: _PlaceArt(
                    place: place,
                    size: 112,
                    glow: _arrivedHil == place.hil,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 26),
          if (_arrivedHil != null) const TudloMascot(size: 118),
        ],
      ),
    );
  }
}

class _PlaceSituation {
  final String prompt;
  final String answerHil;
  final List<String> choices;
  final IconData icon;

  const _PlaceSituation({
    required this.prompt,
    required this.answerHil,
    required this.choices,
    required this.icon,
  });
}

class _PlaceArt extends StatelessWidget {
  final _PlaceWord place;
  final double size;
  final bool glow;

  const _PlaceArt({required this.place, required this.size, this.glow = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: place.color.withValues(alpha: .34),
                  blurRadius: 26,
                  spreadRadius: 6,
                ),
              ]
            : null,
      ),
      child: Image.asset(
        place.asset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) =>
            Icon(place.icon, color: place.color, size: size * .58),
      ),
    );
  }
}

List<_PlaceWord> _placesForLesson(int lessonNumber) {
  final all = _allPlaces();
  return switch (lessonNumber) {
    1 => [all['balay']!, all['eskwelahan']!, all['simbahan']!],
    2 => [all['tinda']!, all['plasa']!, all['ospital']!],
    3 => [all['uma']!, all['baybay']!],
    _ => [
      all['balay']!,
      all['eskwelahan']!,
      all['tinda']!,
      all['ospital']!,
      all['uma']!,
      all['baybay']!,
      all['plasa']!,
    ],
  };
}

List<_PlaceWord> _placeReviewTargetsFor(int lessonNumber) {
  final all = _allPlaces();
  return switch (lessonNumber) {
    1 => [all['balay']!, all['eskwelahan']!, all['simbahan']!],
    2 => [all['ospital']!, all['tinda']!, all['plasa']!],
    3 => [all['uma']!, all['baybay']!, all['eskwelahan']!],
    _ => [all['ospital']!, all['eskwelahan']!, all['uma']!, all['baybay']!],
  };
}

_PlaceWord? _placeByHil(String hil) => _allPlaces()[hil];

Map<String, _PlaceWord> _allPlaces() {
  const house = _PlaceWord(
    hil: 'balay',
    eng: 'balay',
    asset: 'assets/images/level_game/Grade1/unit1/house.png',
    icon: Icons.home_rounded,
    color: TudloColors.green,
    introSpeech: 'Ini ang balay.',
    tapSpeech: 'Balay. Diri nagapuyo ang pamilya.',
    effects: [Icons.door_front_door_rounded, Icons.pets_rounded],
  );
  const school = _PlaceWord(
    hil: 'eskwelahan',
    eng: 'eskwelahan',
    asset: 'assets/images/level_game/Grade1/unit1/eskwelahan.png',
    icon: Icons.school_rounded,
    color: TudloColors.blue,
    introSpeech: 'Ini ang eskwelahan.',
    tapSpeech: 'Eskwelahan. Diri kita nagatuon.',
    effects: [Icons.notifications_active_rounded, Icons.waving_hand_rounded],
  );
  const church = _PlaceWord(
    hil: 'simbahan',
    eng: 'simbahan',
    asset: 'assets/images/level_game/Grade1/unit1/simbahan.png',
    icon: Icons.church_rounded,
    color: TudloColors.forest,
    introSpeech: 'Ini ang simbahan.',
    tapSpeech: 'Simbahan. Diri nagasimba ang mga tawo.',
    effects: [Icons.notifications_rounded, Icons.door_front_door_rounded],
  );
  const market = _PlaceWord(
    hil: 'tinda',
    eng: 'tinda',
    asset: 'assets/images/level_game/Grade1/unit1/tinda.png',
    icon: Icons.storefront_rounded,
    color: TudloColors.gold,
    introSpeech: 'Ini ang tinda.',
    tapSpeech: 'Tinda. Diri kita nagabakal sang pagkaon.',
    effects: [Icons.shopping_basket_rounded, Icons.local_grocery_store_rounded],
  );
  const plaza = _PlaceWord(
    hil: 'plasa',
    eng: 'plasa',
    asset: 'assets/images/level_game/Grade1/unit1/plaza.png',
    icon: Icons.park_rounded,
    color: TudloColors.green,
    introSpeech: 'Ini ang plasa.',
    tapSpeech: 'Plasa. Diri nagadula kag nagapahuway ang mga tawo.',
    effects: [Icons.celebration_rounded, Icons.air_rounded],
  );
  const hospital = _PlaceWord(
    hil: 'ospital',
    eng: 'ospital',
    asset: 'assets/images/level_game/Grade1/unit1/ospital.png',
    icon: Icons.local_hospital_rounded,
    color: TudloColors.coral,
    introSpeech: 'Ini ang ospital.',
    tapSpeech: 'Ospital. Diri ginabuligan ang mga masakiton.',
    effects: [Icons.medical_services_rounded, Icons.local_hospital_rounded],
  );
  const farm = _PlaceWord(
    hil: 'uma',
    eng: 'uma',
    asset: 'assets/images/level_game/Grade1/unit1/uma.png',
    icon: Icons.agriculture_rounded,
    color: TudloColors.forest,
    introSpeech: 'Ini ang uma.',
    tapSpeech: 'Uma. Diri nagatanom ang mangunguma.',
    effects: [Icons.agriculture_rounded, Icons.grass_rounded],
  );
  const beach = _PlaceWord(
    hil: 'baybay',
    eng: 'baybay',
    asset: 'assets/images/level_game/Grade1/unit1/baybay.png',
    icon: Icons.beach_access_rounded,
    color: TudloColors.blue,
    introSpeech: 'Ini ang baybay.',
    tapSpeech: 'Baybay. Diri nagapangisda ang mangingisda.',
    effects: [Icons.waves_rounded, Icons.water_rounded],
  );
  return const {
    'balay': house,
    'eskwelahan': school,
    'simbahan': church,
    'tinda': market,
    'plasa': plaza,
    'ospital': hospital,
    'uma': farm,
    'baybay': beach,
  };
}

class _FamilyWordLessonCard extends StatelessWidget {
  final _FamilyWord word;
  final bool canGoBack;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _FamilyWordLessonCard({
    super.key,
    required this.word,
    required this.canGoBack,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _FamilyStage(
      mascotMessage: 'Koka: ${_titleCase(word.hil)}.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 390,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 8,
                  child: _FamilyImage(
                    word: word,
                    size: 350,
                    voiceMessage: word.hil,
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 148,
                  child: _PictureArrow(
                    icon: Icons.chevron_left_rounded,
                    enabled: canGoBack,
                    onPressed: onBack,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 148,
                  child: _PictureArrow(
                    icon: Icons.chevron_right_rounded,
                    enabled: true,
                    onPressed: onNext,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _titleCase(word.hil),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: TudloColors.ink,
              fontSize: 40,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PictureArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _PictureArrow({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .36,
      child: Material(
        color: enabled
            ? TudloColors.green.withValues(alpha: .14)
            : TudloColors.line.withValues(alpha: .26),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            width: 66,
            height: 66,
            child: Icon(
              icon,
              color: enabled ? TudloColors.blue : TudloColors.muted,
              size: 56,
            ),
          ),
        ),
      ),
    );
  }
}

class _FamilyQuizCard extends StatefulWidget {
  final _FamilyWord target;
  final List<_FamilyWord> choices;
  final VoidCallback onCorrect;

  const _FamilyQuizCard({
    super.key,
    required this.target,
    required this.choices,
    required this.onCorrect,
  });

  @override
  State<_FamilyQuizCard> createState() => _FamilyQuizCardState();
}

class _FamilyQuizCardState extends State<_FamilyQuizCard> {
  String? _selected;
  bool _checked = false;
  bool _correct = false;
  int _feedbackKey = 0;

  Future<void> _choose(_FamilyWord choice) async {
    if (_checked && _correct) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!spent) {
      if (mounted) await showLowEnergyDialog(context);
      return;
    }
    if (!mounted) return;
    await TudloVoiceButton.speak(context, choice.hil, hiligaynon: true);
    final isCorrect = choice.hil == widget.target.hil;
    setState(() {
      _selected = choice.hil;
      _checked = true;
      _correct = isCorrect;
      _feedbackKey++;
    });
    if (isCorrect) {
      widget.onCorrect();
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (!mounted || _correct) return;
      setState(() {
        _checked = false;
        _selected = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _FamilyStage(
      mascotMessage: _checked
          ? (_correct ? 'Husto! Maayo gid.' : 'Sulayi liwat.')
          : _cleanFamilyPrompt('Koka: Pili-a ang sakto nga sabat.'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 0),
          _FamilyImage(
            word: widget.target,
            size: 292,
            voiceMessage: widget.target.hil,
          ),
          const SizedBox(height: 14),
          _FamilyChoiceGrid(
            choices: widget.choices,
            selected: _selected,
            checked: _checked,
            answer: widget.target.hil,
            feedbackKey: _feedbackKey,
            onChoose: _choose,
          ),
        ],
      ),
    );
  }
}

class _FamilyMatchingCard extends StatefulWidget {
  final List<_FamilyWord> words;
  final VoidCallback onCorrect;

  const _FamilyMatchingCard({
    super.key,
    required this.words,
    required this.onCorrect,
  });

  @override
  State<_FamilyMatchingCard> createState() => _FamilyMatchingCardState();
}

class _FamilyMatchingCardState extends State<_FamilyMatchingCard> {
  String? _selectedHil;
  String? _wrongHil;
  String? _wrongImageHil;
  final Set<String> _matched = {};
  bool _reported = false;
  int _feedbackKey = 0;

  Future<void> _selectWord(_FamilyWord word) async {
    if (_matched.contains(word.hil) || _reported) return;
    await TudloVoiceButton.speak(context, word.hil, hiligaynon: true);
    if (!mounted) return;
    setState(() {
      _selectedHil = _selectedHil == word.hil ? null : word.hil;
      _wrongHil = null;
      _wrongImageHil = null;
    });
  }

  Future<void> _selectImage(_FamilyWord word) async {
    if (_selectedHil == null || _matched.contains(word.hil) || _reported) {
      return;
    }
    final spent = await AppData.spendQuestionEnergy();
    if (!spent) {
      if (mounted) await showLowEnergyDialog(context);
      return;
    }
    if (!mounted) return;
    final selected = _selectedHil!;
    final correct = selected == word.hil;
    setState(() {
      _feedbackKey++;
      if (correct) {
        _matched.add(word.hil);
        _selectedHil = null;
        _wrongHil = null;
        _wrongImageHil = null;
      } else {
        _wrongHil = selected;
        _wrongImageHil = word.hil;
        _selectedHil = null;
      }
    });
    if (correct && _matched.length == widget.words.length && !_reported) {
      _reported = true;
      widget.onCorrect();
      return;
    }
    if (!correct) {
      Future<void>.delayed(const Duration(milliseconds: 850), () {
        if (!mounted || _reported) return;
        setState(() {
          _wrongHil = null;
          _wrongImageHil = null;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FamilyStage(
      mascotMessage: _matched.length == widget.words.length
          ? 'Husto! Maayo gid.'
          : 'Koka: Ipares ang pareho.',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final word in widget.words) ...[
                    _matchWordButton(word),
                    if (word != widget.words.last) const SizedBox(height: 18),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final word in widget.words) ...[
                    _matchImageButton(word),
                    if (word != widget.words.last) const SizedBox(height: 18),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _matchWordButton(_FamilyWord word) {
    final selected = _selectedHil == word.hil;
    final matched = _matched.contains(word.hil);
    final wrong = _wrongHil == word.hil;
    return _FeedbackMotion(
      key: ValueKey('word-${word.hil}-$_feedbackKey-$selected-$matched'),
      correct: matched,
      wrong: wrong,
      child: SizedBox(
        height: 122,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _selectWord(word),
          style: ElevatedButton.styleFrom(
            backgroundColor: matched
                ? TudloColors.green
                : selected
                ? TudloColors.blue
                : const Color(0xFF49CC55),
            foregroundColor: Colors.white,
            elevation: selected || matched ? 7 : 4,
            shadowColor: TudloColors.forest.withValues(alpha: .20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            textStyle: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          child: FittedBox(child: Text(_titleCase(word.hil))),
        ),
      ),
    );
  }

  Widget _matchImageButton(_FamilyWord word) {
    final matched = _matched.contains(word.hil);
    final wrong = _wrongImageHil == word.hil;
    return _FeedbackMotion(
      key: ValueKey('image-${word.hil}-$_feedbackKey-$matched'),
      correct: matched,
      wrong: wrong,
      child: GestureDetector(
        onTap: () => _selectImage(word),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 122,
          width: double.infinity,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: matched
                ? const Color(0xFFE8FFD8)
                : wrong
                ? const Color(0xFFFFEEEE)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: matched
                ? [
                    BoxShadow(
                      color: TudloColors.green.withValues(alpha: .20),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: ClipRect(
            child: Transform.scale(
              scale: 1.18,
              child: Image.asset(
                word.imageAsset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) =>
                    Icon(word.icon, color: TudloColors.forest, size: 72),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FamilyStage extends StatelessWidget {
  final Widget child;
  final String mascotMessage;

  const _FamilyStage({required this.child, required this.mascotMessage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: SizedBox(
          height: 760,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                height: 555,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: Align(alignment: Alignment.topCenter, child: child),
                ),
              ),
              Positioned(
                right: -18,
                top: 510,
                child: IgnorePointer(
                  child: _AlphabetMascotBubble(message: mascotMessage),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FamilyImage extends StatelessWidget {
  final _FamilyWord word;
  final double size;
  final String voiceMessage;

  const _FamilyImage({
    required this.word,
    required this.size,
    required this.voiceMessage,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Image.asset(
              word.imageAsset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) =>
                  Icon(word.icon, color: TudloColors.forest, size: size * .56),
            ),
          ),
          Positioned(
            bottom: 0,
            child: TudloVoiceButton(
              message: voiceMessage,
              tooltip: 'Pamatii',
              size: 58,
              hiligaynon: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyChoiceGrid extends StatelessWidget {
  final List<_FamilyWord> choices;
  final String? selected;
  final bool checked;
  final String answer;
  final int feedbackKey;
  final ValueChanged<_FamilyWord> onChoose;

  const _FamilyChoiceGrid({
    required this.choices,
    required this.selected,
    required this.checked,
    required this.answer,
    required this.feedbackKey,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final visibleChoices = choices.take(3).toList();
    final topChoices = visibleChoices.take(2).toList();
    final bottomChoice = visibleChoices.length > 2 ? visibleChoices[2] : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (var index = 0; index < topChoices.length; index++) ...[
              Expanded(child: _button(topChoices[index])),
              if (index == 0) const SizedBox(width: 14),
            ],
          ],
        ),
        if (bottomChoice != null) ...[
          const SizedBox(height: 10),
          SizedBox(width: 190, child: _button(bottomChoice)),
        ],
      ],
    );
  }

  Widget _button(_FamilyWord choice) {
    final active = selected == choice.hil;
    final correct = checked && active && choice.hil == answer;
    final wrong = checked && active && choice.hil != answer;
    return _FeedbackMotion(
      key: ValueKey('${choice.hil}-$feedbackKey-$active'),
      correct: correct,
      wrong: wrong,
      child: SizedBox(
        height: 74,
        child: ElevatedButton(
          onPressed: () => onChoose(choice),
          style: ElevatedButton.styleFrom(
            backgroundColor: wrong
                ? const Color(0xFFE53935)
                : correct
                ? TudloColors.green
                : const Color(0xFF49CC55),
            foregroundColor: Colors.white,
            elevation: active ? 8 : 3,
            shadowColor: TudloColors.forest.withValues(alpha: .24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            textStyle: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          child: FittedBox(child: Text(_titleCase(choice.hil))),
        ),
      ),
    );
  }
}

List<_FamilyWord> _familyWordsFor(int lessonNumber) {
  const nanay = _FamilyWord(
    hil: 'nanay',
    eng: 'nanay',
    imageAsset: 'assets/images/level_game/Grade1/unit1/nanay.png',
    icon: Icons.woman_rounded,
  );
  const tatay = _FamilyWord(
    hil: 'tatay',
    eng: 'tatay',
    imageAsset: 'assets/images/level_game/Grade1/unit1/tatay.png',
    icon: Icons.man_rounded,
  );
  const bata = _FamilyWord(
    hil: 'bata',
    eng: 'bata',
    imageAsset: 'assets/images/level_game/Grade1/unit1/bata-nga-babayi.png',
    icon: Icons.child_care_rounded,
  );
  const lola = _FamilyWord(
    hil: 'lola',
    eng: 'lola',
    imageAsset: 'assets/images/level_game/Grade1/unit1/lola.png',
    icon: Icons.elderly_woman_rounded,
  );
  const lolo = _FamilyWord(
    hil: 'lolo',
    eng: 'lolo',
    imageAsset: 'assets/images/level_game/Grade1/unit1/lolo.png',
    icon: Icons.elderly_rounded,
  );
  const magulang = _FamilyWord(
    hil: 'magulang',
    eng: 'magulang',
    imageAsset: 'assets/images/level_game/Grade1/unit1/bata-nga-lalaki.png',
    icon: Icons.escalator_warning_rounded,
  );
  const manghod = _FamilyWord(
    hil: 'manghod',
    eng: 'manghod',
    imageAsset: 'assets/images/level_game/Grade1/unit1/bata-nga-babayi.png',
    icon: Icons.child_friendly_rounded,
  );

  return switch (lessonNumber) {
    1 => const [nanay, tatay, bata],
    2 => const [lola, lolo, nanay],
    3 => const [magulang, manghod, lola, tatay],
    _ => const [nanay, tatay, bata, lola, lolo, magulang, manghod],
  };
}

List<_FamilyWord> _familyChoicesFor(
  _FamilyWord target,
  List<_FamilyWord> words,
  int count,
) {
  final pool = words.isEmpty ? [target] : words;
  final selected = <_FamilyWord>[];
  if (count == 2) {
    final distractor = pool.firstWhere(
      (word) => word.hil != target.hil,
      orElse: () => target,
    );
    selected.addAll([distractor, target]);
  } else {
    selected.addAll(pool.take(count));
    if (!selected.any((word) => word.hil == target.hil)) {
      selected[selected.length - 1] = target;
    }
  }
  return selected;
}

String _cleanFamilyPrompt(String prompt) {
  return prompt
      .replaceAll('â€¦', '...')
      .replaceAll('…', '...')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class _GradeOneAnimalLesson extends StatefulWidget {
  final LevelContent content;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOneAnimalLesson({
    required this.content,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeOneAnimalLesson> createState() => _GradeOneAnimalLessonState();
}

class _GradeOneAnimalLessonState extends State<_GradeOneAnimalLesson> {
  int _stepIndex = 0;
  bool _reportedComplete = false;

  void _goToStep(int index, int maxIndex) {
    final next = index.clamp(0, maxIndex);
    if (next == _stepIndex) return;
    setState(() => _stepIndex = next);
  }

  void _advanceAfterCorrect(int maxIndex) {
    final completedStep = _stepIndex;
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || _stepIndex != completedStep) return;
      _goToStep(completedStep + 1, maxIndex);
    });
  }

  void _markComplete() {
    if (_reportedComplete) return;
    _reportedComplete = true;
    for (var index = 0; index < widget.content.quizItems.length; index++) {
      widget.onQuizCorrect(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final animals = _animalsForLesson(widget.content.lessonNumber);
    var maxIndex = 0;
    final steps = [
      for (final animal in animals) ...[
        _AlphabetFadeStep(
          child: _AnimalTapCard(
            key: ValueKey('animal-tap-${widget.content.id}-${animal.hil}'),
            animal: animal,
            onDone: () => _advanceAfterCorrect(maxIndex),
          ),
        ),
        _AlphabetFadeStep(
          child: _AnimalHomeDragCard(
            key: ValueKey('animal-drag-${widget.content.id}-${animal.hil}'),
            animal: animal,
            onDone: () => _advanceAfterCorrect(maxIndex),
          ),
        ),
      ],
      _AlphabetFadeStep(
        child: _QuizTimeSplash(
          onDone: () => _goToStep(_stepIndex + 1, maxIndex),
        ),
      ),
      _AlphabetFadeStep(
        child: _AnimalReviewCard(
          key: ValueKey('animal-review-${widget.content.id}'),
          animals: animals.take(3).toList(),
          onDone: _markComplete,
        ),
      ),
    ];
    maxIndex = steps.length - 1;
    final activeStep = steps[_stepIndex.clamp(0, maxIndex)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(390.0, constraints.maxWidth);
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 850),
                reverseDuration: const Duration(milliseconds: 650),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: .97, end: 1).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child: Align(
                  key: ValueKey('animal-step-$_stepIndex'),
                  alignment: Alignment.topCenter,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(width: width, child: activeStep.child),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AnimalWord {
  final String hil;
  final String eng;
  final String soundText;
  final String tapSpeech;
  final String dragHomeLabel;
  final String? imageAsset;
  final String? homeAsset;
  final IconData icon;
  final IconData homeIcon;
  final Color color;

  const _AnimalWord({
    required this.hil,
    required this.eng,
    required this.soundText,
    required this.tapSpeech,
    required this.dragHomeLabel,
    required this.icon,
    required this.homeIcon,
    required this.color,
    this.imageAsset,
    this.homeAsset,
  });

  String get upperName => hil.toUpperCase();
  String get tapInstruction => 'Ipindot ang $hil.';
  String get dragInstruction => 'Guyoda ang $hil pakadto sa $dragHomeLabel.';
  String get retryInstruction =>
      'Liwata. Guyoda ang $hil pakadto sa $dragHomeLabel.';
  String get successSpeech => 'Husto! Ara na ang $hil sa $dragHomeLabel.';
}

class _AnimalTapCard extends StatefulWidget {
  final _AnimalWord animal;
  final VoidCallback onDone;

  const _AnimalTapCard({super.key, required this.animal, required this.onDone});

  @override
  State<_AnimalTapCard> createState() => _AnimalTapCardState();
}

class _AnimalTapCardState extends State<_AnimalTapCard> {
  bool _tapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          widget.animal.tapInstruction,
          hiligaynon: true,
        ),
      );
    });
  }

  Future<void> _tapAnimal() async {
    if (_tapped) return;
    setState(() => _tapped = true);
    await TudloVoiceButton.speak(
      context,
      '${widget.animal.soundText}! ${widget.animal.tapSpeech}',
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 550), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _tapped
          ? widget.animal.tapSpeech
          : 'Koka: ${widget.animal.tapInstruction}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.animal.upperName,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 48,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 42),
          GestureDetector(
            onTap: _tapAnimal,
            child: _AnimalBounce(
              active: _tapped,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 374,
                    height: 374,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _tapped
                          ? widget.animal.color.withValues(alpha: .18)
                          : Colors.transparent,
                      boxShadow: _tapped
                          ? [
                              BoxShadow(
                                color: widget.animal.color.withValues(
                                  alpha: .34,
                                ),
                                blurRadius: 34,
                                spreadRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  _AnimalArt(animal: widget.animal, size: 352),
                  if (_tapped) const _AnimalSparkles(size: 390),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimalHomeDragCard extends StatefulWidget {
  final _AnimalWord animal;
  final VoidCallback onDone;

  const _AnimalHomeDragCard({
    super.key,
    required this.animal,
    required this.onDone,
  });

  @override
  State<_AnimalHomeDragCard> createState() => _AnimalHomeDragCardState();
}

class _AnimalHomeDragCardState extends State<_AnimalHomeDragCard> {
  bool _placed = false;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          widget.animal.dragInstruction,
          hiligaynon: true,
        ),
      );
    });
  }

  void _retry() {
    if (_placed) return;
    setState(() => _retrying = true);
    unawaited(
      TudloVoiceButton.speak(
        context,
        widget.animal.retryInstruction,
        hiligaynon: true,
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _retrying = false);
    });
  }

  Future<void> _accept() async {
    if (_placed) return;
    setState(() => _placed = true);
    await TudloVoiceButton.speak(
      context,
      '${widget.animal.soundText}! ${widget.animal.successSpeech}',
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _placed
          ? 'Koka: ${widget.animal.successSpeech}'
          : _retrying
          ? 'Koka: ${widget.animal.retryInstruction}'
          : 'Koka: ${widget.animal.dragInstruction}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.animal.upperName,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 42,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 445,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -8,
                  top: 18,
                  child: _AnimalHomeTarget(
                    animal: widget.animal,
                    size: 260,
                    placed: _placed,
                    onAccept: _accept,
                    onWrongDrop: _retry,
                  ),
                ),
                Positioned(
                  left: -2,
                  bottom: 18,
                  child: _placed
                      ? const SizedBox(width: 248, height: 248)
                      : _AnimalDraggable(
                          animal: widget.animal,
                          size: 248,
                          onMissed: _retry,
                        ),
                ),
                if (_placed)
                  Positioned(
                    right: 50,
                    top: 104,
                    child: _AnimalBounce(
                      active: true,
                      child: _AnimalArt(animal: widget.animal, size: 156),
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

class _AnimalReviewCard extends StatefulWidget {
  final List<_AnimalWord> animals;
  final VoidCallback onDone;

  const _AnimalReviewCard({
    super.key,
    required this.animals,
    required this.onDone,
  });

  @override
  State<_AnimalReviewCard> createState() => _AnimalReviewCardState();
}

class _AnimalReviewCardState extends State<_AnimalReviewCard> {
  final Set<String> _matched = {};
  String _message = 'Koka: Guyoda ang kada sapat pakadto sa iya puluy-an.';
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          'Guyoda ang kada sapat pakadto sa iya puluy-an.',
          hiligaynon: true,
        ),
      );
    });
  }

  Future<void> _handleDrop(_AnimalWord target, _AnimalWord dragged) async {
    if (_reported || _matched.contains(dragged.hil)) return;
    if (target.hil != dragged.hil) {
      setState(() {
        _message = 'Koka: Liwata. Pangitaa ang puluy-an sang ${dragged.hil}.';
      });
      await TudloVoiceButton.speak(
        context,
        'Liwata. Pangitaa ang puluy-an sang ${dragged.hil}.',
        hiligaynon: true,
      );
      return;
    }

    setState(() {
      _matched.add(dragged.hil);
      _message = 'Koka: Husto! ${_titleCase(dragged.hil)}.';
    });
    await TudloVoiceButton.speak(
      context,
      '${dragged.soundText}! Husto! Ara na ang ${dragged.hil} sa ${dragged.dragHomeLabel}.',
      hiligaynon: true,
    );
    if (!mounted) return;
    if (_matched.length == widget.animals.length && !_reported) {
      _reported = true;
      setState(() {
        _message = 'Koka: Maayo gid! Kabalo ka na sang mga sapat sa palibot!';
      });
      await TudloVoiceButton.speak(
        context,
        'Maayo gid! Kabalo ka na sang mga sapat sa palibot!',
        hiligaynon: true,
      );
      if (mounted) widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _message,
      child: Column(
        children: [
          Text(
            'Ipares ang Puluy-an',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final animal in widget.animals)
                _ReviewHomeTarget(
                  animal: animal,
                  matched: _matched.contains(animal.hil),
                  size: 126,
                  onDrop: (dragged) => _handleDrop(animal, dragged),
                ),
            ],
          ),
          const SizedBox(height: 34),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final animal in widget.animals)
                _matched.contains(animal.hil)
                    ? const SizedBox(width: 136, height: 136)
                    : _AnimalDraggable(
                        animal: animal,
                        size: 136,
                        onMissed: () {
                          setState(() {
                            _message =
                                'Koka: Guyoda ang ${animal.hil} pakadto sa iya puluy-an.';
                          });
                        },
                      ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimalStage extends StatelessWidget {
  final Widget child;
  final String mascotMessage;

  const _AnimalStage({required this.child, required this.mascotMessage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: SizedBox(
          height: 760,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                height: 550,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: Align(alignment: Alignment.topCenter, child: child),
                ),
              ),
              Positioned(
                right: -18,
                top: 500,
                child: IgnorePointer(
                  child: _AlphabetMascotBubble(message: mascotMessage),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimalDraggable extends StatelessWidget {
  final _AnimalWord animal;
  final double size;
  final VoidCallback onMissed;

  const _AnimalDraggable({
    required this.animal,
    required this.size,
    required this.onMissed,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<_AnimalWord>(
      data: animal,
      feedback: Material(
        color: Colors.transparent,
        child: _AnimalArt(animal: animal, size: size * 1.08),
      ),
      childWhenDragging: Opacity(
        opacity: .24,
        child: _AnimalArt(animal: animal, size: size),
      ),
      onDragEnd: (details) {
        if (!details.wasAccepted) onMissed();
      },
      child: _AnimalArt(animal: animal, size: size),
    );
  }
}

class _AnimalHomeTarget extends StatelessWidget {
  final _AnimalWord animal;
  final double size;
  final bool placed;
  final VoidCallback onAccept;
  final VoidCallback onWrongDrop;

  const _AnimalHomeTarget({
    required this.animal,
    required this.size,
    required this.placed,
    required this.onAccept,
    required this.onWrongDrop,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<_AnimalWord>(
      onWillAcceptWithDetails: (_) => !placed,
      onAcceptWithDetails: (details) {
        if (details.data.hil == animal.hil) {
          onAccept();
        } else {
          onWrongDrop();
        }
      },
      builder: (context, candidateData, rejectedData) {
        return _AnimalHomeArt(
          animal: animal,
          size: size,
          active: candidateData.isNotEmpty,
          matched: placed,
          showLabel: false,
        );
      },
    );
  }
}

class _ReviewHomeTarget extends StatelessWidget {
  final _AnimalWord animal;
  final bool matched;
  final double size;
  final ValueChanged<_AnimalWord> onDrop;

  const _ReviewHomeTarget({
    required this.animal,
    required this.matched,
    required this.size,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<_AnimalWord>(
      onWillAcceptWithDetails: (_) => !matched,
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidateData, rejectedData) {
        return _AnimalHomeArt(
          animal: animal,
          size: size,
          active: candidateData.isNotEmpty,
          matched: matched,
          showLabel: false,
        );
      },
    );
  }
}

class _AnimalArt extends StatelessWidget {
  final _AnimalWord animal;
  final double size;

  const _AnimalArt({required this.animal, required this.size});

  @override
  Widget build(BuildContext context) {
    if (animal.imageAsset != null) {
      return Image.asset(
        animal.imageAsset!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) =>
            _AnimalIconArt(animal: animal, size: size),
      );
    }
    return _AnimalIconArt(animal: animal, size: size);
  }
}

class _AnimalIconArt extends StatelessWidget {
  final _AnimalWord animal;
  final double size;

  const _AnimalIconArt({required this.animal, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: animal.color.withValues(alpha: .18),
        boxShadow: [
          BoxShadow(
            color: animal.color.withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(animal.icon, color: animal.color, size: size * .58),
    );
  }
}

class _AnimalHomeArt extends StatelessWidget {
  final _AnimalWord animal;
  final double size;
  final bool active;
  final bool matched;
  final bool showLabel;

  const _AnimalHomeArt({
    required this.animal,
    required this.size,
    required this.active,
    required this.matched,
    required this.showLabel,
  });

  @override
  Widget build(BuildContext context) {
    final home = animal.homeAsset == null
        ? _AnimalHomeIcon(animal: animal, size: size)
        : Image.asset(
            animal.homeAsset!,
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) =>
                _AnimalHomeIcon(animal: animal, size: size),
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: showLabel ? size + 42 : size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.transparent,
        boxShadow: active || matched
            ? [
                BoxShadow(
                  color: TudloColors.green.withValues(alpha: .24),
                  blurRadius: 22,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Center(child: home),
          ),
          if (showLabel) ...[
            const SizedBox(height: 4),
            Text(
              _titleCase(animal.dragHomeLabel),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                color: TudloColors.ink,
                fontSize: 22,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnimalHomeIcon extends StatelessWidget {
  final _AnimalWord animal;
  final double size;

  const _AnimalHomeIcon({required this.animal, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * .88,
      height: size * .88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: TudloColors.softGreen.withValues(alpha: .82),
      ),
      child: Icon(animal.homeIcon, color: TudloColors.forest, size: size * .48),
    );
  }
}

class _AnimalBounce extends StatelessWidget {
  final bool active;
  final Widget child;

  const _AnimalBounce({required this.active, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: active ? 1 : 0),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final jump = -math.sin(value * math.pi) * 34;
        return Transform.translate(
          offset: Offset(0, jump),
          child: Transform.scale(scale: 1 + value * .04, child: child),
        );
      },
      child: child,
    );
  }
}

class _AnimalSparkles extends StatelessWidget {
  final double size;

  const _AnimalSparkles({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: const [
          Positioned(
            top: 18,
            right: 42,
            child: _Sparkle(color: TudloColors.gold, size: 18),
          ),
          Positioned(
            top: 70,
            left: 20,
            child: _Sparkle(color: TudloColors.green, size: 13),
          ),
          Positioned(
            bottom: 48,
            right: 24,
            child: _Sparkle(color: TudloColors.gold, size: 15),
          ),
          Positioned(
            bottom: 30,
            left: 56,
            child: _Sparkle(color: TudloColors.green, size: 11),
          ),
        ],
      ),
    );
  }
}

List<_AnimalWord> _animalsForLesson(int lessonNumber) {
  const dog = _AnimalWord(
    hil: 'ido',
    eng: 'ido',
    soundText: 'aw aw',
    tapSpeech: 'Ido. Ang ido nagatahol.',
    dragHomeLabel: 'iya balay',
    imageAsset: 'assets/images/level_game/Grade1/unit1/dog.png',
    homeAsset: 'assets/images/level_game/Grade1/unit1/house.png',
    icon: Icons.pets_rounded,
    homeIcon: Icons.home_rounded,
    color: TudloColors.orange,
  );
  const cat = _AnimalWord(
    hil: 'kuring',
    eng: 'kuring',
    soundText: 'ngiyaw',
    tapSpeech: 'Kuring. Ang kuring nagingiyaw.',
    dragHomeLabel: 'iya balay',
    imageAsset: 'assets/images/level_game/Grade1/unit1/cat.png',
    homeAsset: 'assets/images/level_game/Grade1/unit1/house.png',
    icon: Icons.pets_rounded,
    homeIcon: Icons.home_rounded,
    color: TudloColors.coral,
  );
  const chicken = _AnimalWord(
    hil: 'manok',
    eng: 'manok',
    soundText: 'tok tok',
    tapSpeech: 'Manok. Ang manok nagapotok.',
    dragHomeLabel: 'tangkal',
    icon: Icons.egg_alt_rounded,
    homeIcon: Icons.home_work_rounded,
    color: TudloColors.gold,
  );
  const pig = _AnimalWord(
    hil: 'baboy',
    eng: 'baboy',
    soundText: 'oynk oynk',
    tapSpeech: 'Baboy. Ang baboy naga-ukoy.',
    dragHomeLabel: 'iya kulungan',
    icon: Icons.pets_rounded,
    homeIcon: Icons.home_work_rounded,
    color: TudloColors.coral,
  );
  const cow = _AnimalWord(
    hil: 'baka',
    eng: 'baka',
    soundText: 'moo',
    tapSpeech: 'Baka. Ang baka nagangaaw.',
    dragHomeLabel: 'hilamunan',
    imageAsset: 'assets/images/level_game/Grade1/unit1/lesson1/cow.png',
    icon: Icons.agriculture_rounded,
    homeIcon: Icons.park_rounded,
    color: TudloColors.blue,
  );
  const carabao = _AnimalWord(
    hil: 'karbaw',
    eng: 'karbaw',
    soundText: 'ngaa',
    tapSpeech: 'Karbaw. Ang karbaw nagahuni.',
    dragHomeLabel: 'palayan',
    icon: Icons.agriculture_rounded,
    homeIcon: Icons.agriculture_rounded,
    color: TudloColors.forest,
  );
  const fish = _AnimalWord(
    hil: 'isda',
    eng: 'isda',
    soundText: 'bulubula',
    tapSpeech: 'Isda. Ang isda nagalangoy.',
    dragHomeLabel: 'tubig',
    icon: Icons.water_rounded,
    homeIcon: Icons.water_rounded,
    color: TudloColors.blue,
  );
  const bird = _AnimalWord(
    hil: 'pispis',
    eng: 'pispis',
    soundText: 'tsirit tsirit',
    tapSpeech: 'Pispis. Ang pispis nagahuni.',
    dragHomeLabel: 'iya pugad',
    icon: Icons.flutter_dash_rounded,
    homeIcon: Icons.park_rounded,
    color: TudloColors.green,
  );
  const goat = _AnimalWord(
    hil: 'kanding',
    eng: 'kanding',
    soundText: 'mee mee',
    tapSpeech: 'Kanding. Ang kanding nagame.',
    dragHomeLabel: 'hilamunan',
    icon: Icons.pets_rounded,
    homeIcon: Icons.park_rounded,
    color: TudloColors.meadow,
  );

  return switch (lessonNumber) {
    1 => const [dog, cat, chicken],
    2 => const [pig, cow, carabao],
    3 => const [fish, bird, goat],
    _ => const [dog, cat, chicken, pig, cow, carabao, fish, bird, goat],
  };
}

String _titleCase(String value) {
  if (value.trim().isEmpty) return value;
  return value
      .trim()
      .split(RegExp(r'\s+'))
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}

class _LevelQuizCard extends StatefulWidget {
  final int number;
  final LessonQuestion question;
  final ValueChanged<bool> onChecked;

  const _LevelQuizCard({
    super.key,
    required this.number,
    required this.question,
    required this.onChecked,
  });

  @override
  State<_LevelQuizCard> createState() => _LevelQuizCardState();
}

class _LevelQuizCardState extends State<_LevelQuizCard> {
  String? selectedAnswer;
  String? selectedMatchLeft;
  String? wrongMatchLeft;
  String? wrongMatchRight;
  Timer? _wrongMatchClearTimer;
  Timer? _matchedPulseTimer;
  int wrongMatchAttempt = 0;
  String? newMatchLeft;
  String? newMatchRight;
  int matchPulseAttempt = 0;
  int answerFeedbackAttempt = 0;
  bool checked = false;
  bool lastCorrect = false;
  final Map<String, String> matches = {};
  final List<String> builtWords = [];

  @override
  void dispose() {
    _wrongMatchClearTimer?.cancel();
    _matchedPulseTimer?.cancel();
    super.dispose();
  }

  LessonQuestion get question => widget.question;

  bool get canCheck {
    return switch (question.type) {
      QuestionType.matching => matches.length == question.leftItems.length,
      QuestionType.fillBlank =>
        builtWords.length >= question.answer.split(' ').length,
      QuestionType.arrangeWords =>
        builtWords.length >= question.answer.split(' ').length,
      QuestionType.buildSentence =>
        builtWords.length >= question.answer.split(' ').length,
      _ => selectedAnswer != null,
    };
  }

  bool get isCorrect {
    return switch (question.type) {
      QuestionType.matching => _matchingCorrect(question),
      QuestionType.fillBlank =>
        _normalizeAnswer(builtWords.join(' ')) ==
            _normalizeAnswer(question.answer),
      QuestionType.arrangeWords =>
        _normalizeAnswer(builtWords.join(' ')) ==
            _normalizeAnswer(question.answer),
      QuestionType.buildSentence =>
        _normalizeAnswer(builtWords.join(' ')) ==
            _normalizeAnswer(question.answer),
      _ => selectedAnswer == question.answer,
    };
  }

  Future<void> _checkAnswer() async {
    if (checked || !canCheck) return;

    final spent = await AppData.spendQuestionEnergy();
    if (!spent) {
      if (mounted) await showLowEnergyDialog(context);
      return;
    }

    final correct = isCorrect;
    setState(() {
      checked = true;
      lastCorrect = correct;
      answerFeedbackAttempt++;
    });
    if (correct) {
      widget.onChecked(true);
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || lastCorrect) return;
      setState(() {
        checked = false;
      });
    });
  }

  String _titleFor(QuestionType type) {
    return switch (type) {
      QuestionType.translationChoice => 'Pili-a ang Husto nga Sabat',
      QuestionType.arrangeWords => 'Ano ini sa Hiligaynon',
      QuestionType.fillBlank => 'Kompletoha',
      QuestionType.choice => 'Pili-a ang Husto nga Sabat',
      QuestionType.matching => 'Ipares ang Tinaga',
      QuestionType.completeSentence => 'Pili-a ang Husto nga Sabat',
      QuestionType.buildSentence => 'Ano ini sa Hiligaynon',
      QuestionType.imageChoice => 'Pili-a ang Laragway',
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
          if (checked && lastCorrect) return;
          TudloVoiceButton.speak(context, value);
          setState(() {
            selectedAnswer = value;
            if (!lastCorrect) checked = false;
          });
        },
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
          final expected = _expectedMatch(q, left);
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
    if (_usesChoiceActivityCard(question.type)) {
      return _ChoiceActivityCard(
        title: _titleFor(question.type),
        question: question,
        choices: question.choices,
        selected: selectedAnswer,
        checked: checked,
        answer: question.answer,
        feedbackAttempt: answerFeedbackAttempt,
        choiceMeanings: {
          for (final choice in question.choices)
            choice: translatedMeaningFor(choice),
        },
        onSelected: (value) {
          if (checked && lastCorrect) return;
          TudloVoiceButton.speak(context, value);
          setState(() {
            selectedAnswer = value;
            if (!lastCorrect) checked = false;
          });
        },
      );
    }

    if (question.type == QuestionType.matching ||
        question.type == QuestionType.imageChoice ||
        question.type == QuestionType.fillBlank) {
      return _buildQuestionBody(question);
    }

    if (question.type == QuestionType.buildSentence ||
        question.type == QuestionType.arrangeWords) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PromptCard(question: question),
          const SizedBox(height: 18),
          _buildQuestionBody(question),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PromptCard(question: question),
        const SizedBox(height: 18),
        _buildQuestionBody(question),
      ],
    );
  }

  bool _usesChoiceActivityCard(QuestionType type) {
    return type == QuestionType.choice ||
        type == QuestionType.translationChoice ||
        type == QuestionType.completeSentence;
  }

  String _expectedMatch(LessonQuestion question, String left) {
    final pair = question.matchingPairs[left];
    if (pair != null) return pair;

    const hiligaynonMatches = {
      'Pangalan': 'ngalan',
      'Katawhan': 'mga karakter',
      'Halamtangan': 'lugar kag tion',
      'Hinabo': 'natabo',
      'Rina': 'Child',
      'Nanay Rowena': 'Mother',
      'Iloilo River': 'River',
      'Plaza Libertad': 'Park',
    };
    final hiligaynonMatch = hiligaynonMatches[left];
    if (hiligaynonMatch != null) return hiligaynonMatch;

    final index = question.leftItems.indexOf(left);
    return index >= 0 && index < question.rightItems.length
        ? question.rightItems[index]
        : left;
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

  String _normalizeAnswer(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[.!?"]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _matchingCorrect(LessonQuestion q) {
    for (final left in q.leftItems) {
      if (matches[left] != _expectedMatch(q, left)) return false;
    }
    return true;
  }

  String _feedbackPhraseFor(LessonQuestion question) {
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
    if (question.sentenceMeaning.trim().isNotEmpty) {
      return question.sentenceMeaning.trim();
    }
    final phrase = _feedbackPhraseFor(question);
    const meanings = {
      'Kumusta ka?': 'Pangamusta',
      'Salamat gid.': 'Pagpasalamat',
      'Palihog, gusto ko sang tubig.': 'Pagpangayo sang tubig',
      'Nagkaon ako sang kan-on': 'Nagakaon sang kan-on',
      'Palihog hatag sang tubig': 'Pagpangayo sang tubig',
      'Nagabasa ako sang libro': 'Nagabasa sang libro',
      'Nagakadto ako sa eskwelahan': 'Nagakadto sa eskwelahan',
    };
    return meanings[_meaningKey(phrase)] ?? question.targetMeaning.trim();
  }

  String _meaningKey(String value) {
    return value.trim().replaceAll(RegExp(r'[.!?]+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final feedbackPhrase = _feedbackPhraseFor(question);
    final feedbackMeaning = _feedbackMeaningFor(question);
    final showMeaning = question.type != QuestionType.matching;
    final usesChoiceActivityCard = _usesChoiceActivityCard(question.type);

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          child: Column(
            crossAxisAlignment: question.type == QuestionType.fillBlank
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.stretch,
            children: [
              if (!usesChoiceActivityCard) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuestionNumberBadge(number: widget.number),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question.type == QuestionType.imageChoice
                            ? question.prompt
                            : _titleFor(question.type),
                        textAlign: question.type == QuestionType.fillBlank
                            ? TextAlign.left
                            : TextAlign.center,
                        style: const TextStyle(
                          color: TudloColors.ink,
                          fontSize: 29,
                          fontWeight: FontWeight.w900,
                          height: 1.08,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
              ],
              _questionContentArea(question),
              if (checked && !lastCorrect) ...[
                const SizedBox(height: 18),
                _AnswerFeedbackPanel(
                  correct: lastCorrect,
                  phrase: feedbackPhrase,
                  meaning: feedbackMeaning,
                  showDetails: showMeaning,
                ),
              ],
              const SizedBox(height: 18),
              _FeedbackMotion(
                key: ValueKey('check-$answerFeedbackAttempt'),
                correct: checked && lastCorrect,
                wrong: checked && !lastCorrect,
                child: SizedBox(
                  width: double.infinity,
                  height: 68,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: checked
                          ? lastCorrect
                                ? TudloColors.green
                                : TudloColors.coral
                          : TudloColors.blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: TudloColors.line,
                      disabledForegroundColor: TudloColors.muted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    onPressed: checked || !canCheck ? null : _checkAnswer,
                    child: Text(
                      checked ? 'NAPASA' : 'IPASA',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (checked && lastCorrect)
          Positioned.fill(
            child: IgnorePointer(
              child: _ConfettiBurst(
                key: ValueKey('confetti-$answerFeedbackAttempt'),
                fill: true,
              ),
            ),
          ),
      ],
    );
  }
}

class _LevelIntroHeader extends StatelessWidget {
  final int level;
  final String title;

  const _LevelIntroHeader({required this.level, required this.title});

  @override
  Widget build(BuildContext context) {
    final localLevel = AppData.lessonNumberForLevel(level);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Leksiyon $localLevel',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: TudloColors.blue,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (title.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: TudloColors.ink,
              fontSize: 30,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
    );
  }
}

class _LearningSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Color accentColor;

  const _LearningSection({
    required this.title,
    required this.child,
    this.accentColor = TudloColors.coral,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: TudloColors.forest,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StoryLessonSection extends StatelessWidget {
  final LessonLevelContent content;

  const _StoryLessonSection({required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              const Text(
                'Istorya',
                style: TextStyle(
                  color: Color(0xFF259C13),
                  fontSize: 29,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TudloVoiceButton(
                  message: '${content.storyTitle}. ${content.story}',
                  tooltip: 'Pamatii ang istorya',
                  size: 54,
                  hiligaynon: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _StoryIllustration(imagePath: _storyImagePathForActiveGrade()),
          const SizedBox(height: 18),
          Text(
            content.storyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF259C13),
              fontSize: 29,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _SpeechBubble(text: content.story),
        ],
      ),
    );
  }
}

class _StoryIllustration extends StatelessWidget {
  final String imagePath;

  const _StoryIllustration({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 214,
      decoration: BoxDecoration(
        color: const Color(0xFFF3FFE5),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => const _StoryImageFallback(),
            ),
          ),
        ],
      ),
    );
  }
}

String _storyImagePathForActiveGrade() {
  return switch (AppData.selectedGradeLevel) {
    GradeLevel.grade1 =>
      'assets/images/level_game/Grade1/unit1/lesson1/story.png',
    GradeLevel.grade2 => 'assets/images/level_game/Grade2/classroom.png',
    GradeLevel.grade3 =>
      'assets/images/level_game/Grade3/unit1/lesson1/story.png',
  };
}

class _StoryImageFallback extends StatelessWidget {
  const _StoryImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3FFE5),
      child: const Center(
        child: Icon(Icons.image_rounded, color: TudloColors.forest, size: 58),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  final String text;

  const _SpeechBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FFE8),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: TudloColors.ink,
          fontSize: 20,
          height: 1.35,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ExampleCardGrid extends StatelessWidget {
  final List<LessonExample> examples;

  const _ExampleCardGrid({required this.examples});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: examples.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ExampleCard(
            example: entry.value,
            color: _lessonPalette(entry.key),
          ),
        );
      }).toList(),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final LessonExample example;
  final Color color;

  const _ExampleCard({required this.example, required this.color});

  @override
  Widget build(BuildContext context) {
    final category = example.category.isEmpty ? 'Example' : example.category;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {},
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 58,
                height: 58,
                child: Icon(_iconForCategory(category), color: color, size: 34),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      example.hiligaynon,
                      style: const TextStyle(
                        color: TudloColors.ink,
                        fontSize: 23,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (example.note.trim().isNotEmpty)
                      Text(
                        example.note,
                        style: const TextStyle(
                          color: TudloColors.muted,
                          fontSize: 16,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
              TudloVoiceButton(
                message: example.hiligaynon,
                tooltip: 'Pamatii ang halimbawa',
                size: 46,
                hiligaynon: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _lessonPalette(int index) {
  const colors = [
    TudloColors.orange,
    TudloColors.blue,
    Color(0xFF8B5CF6),
    TudloColors.green,
    TudloColors.coral,
  ];
  return colors[index % colors.length];
}

IconData _iconForCategory(String category) {
  final text = category.toLowerCase();
  if (text.contains('tawo') || text.contains('person')) {
    return Icons.face_rounded;
  }
  if (text.contains('lugar') || text.contains('place')) {
    return Icons.park_rounded;
  }
  if (text.contains('sapat') || text.contains('animal')) {
    return Icons.cruelty_free_rounded;
  }
  if (text.contains('count')) return Icons.format_list_numbered_rounded;
  if (text.contains('mass')) return Icons.water_drop_rounded;
  if (text.contains('pangalan')) return Icons.star_rounded;
  return Icons.category_rounded;
}

class _QuizSectionHeader extends StatelessWidget {
  const _QuizSectionHeader();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Short Quiz',
      style: TextStyle(
        color: TudloColors.ink,
        fontSize: 34,
        height: 1,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _QuestionNumberBadge extends StatelessWidget {
  final int number;

  const _QuestionNumberBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: TudloColors.softGreen,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            color: TudloColors.green,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
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
                          'TAPOS NA',
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
                          'Maayo gid!',
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
                              ? 'Himpit ang imo leksiyon!'
                              : 'Natapos mo ang leksiyon!',
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
                          label: 'ORAS',
                          value: durationLabel,
                          icon: Icons.timer_rounded,
                        ),
                        const SizedBox(height: 10),
                        _RewardStatRow(
                          label: 'ISKOR',
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
                            child: const Text('BALIK SA MAPA'),
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
              'LEKSIYON ${AppData.lessonNumberForLevel(level)}',
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

class _ChoiceActivityCard extends StatelessWidget {
  final String title;
  final LessonQuestion question;
  final List<String> choices;
  final String? selected;
  final bool checked;
  final String answer;
  final int feedbackAttempt;
  final Map<String, String> choiceMeanings;
  final ValueChanged<String> onSelected;

  const _ChoiceActivityCard({
    required this.title,
    required this.question,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final mascotSize = constraints.maxWidth < 380 ? 112.0 : 132.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: mascotSize + 18,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 8,
                    bottom: 0,
                    child: TudloMascot(size: mascotSize),
                  ),
                  Positioned(
                    left: mascotSize * .70,
                    right: 6,
                    top: 8,
                    child: _ChoiceTitleBubble(title: title),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -2),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF78EA86),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _choicePromptText(question.prompt),
                      textAlign: TextAlign.left,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 23,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                        shadows: const [
                          Shadow(
                            color: TudloColors.forest,
                            offset: Offset(1, 1.4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                    ),
                    if (question.imagePath.trim().isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Center(
                        child: Container(
                          width: 138,
                          height: 138,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFFFF5),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Image.asset(
                            question.imagePath,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (_, __, ___) =>
                                const _ImageChoiceFallback(),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    _ChoiceGrid(
                      choices: choices,
                      selected: selected,
                      checked: checked,
                      answer: answer,
                      feedbackAttempt: feedbackAttempt,
                      choiceMeanings: choiceMeanings,
                      onSelected: onSelected,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _choicePromptText(String prompt) {
    final match = RegExp(r'"([^"]+)"').firstMatch(prompt);
    final text = (match?.group(1) ?? prompt).trim();
    if (text.startsWith('"') && text.endsWith('"')) return text;
    return '"$text"';
  }
}

class _ChoiceTitleBubble extends StatelessWidget {
  final String title;

  const _ChoiceTitleBubble({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        title,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.nunito(
          color: TudloColors.ink,
          fontSize: 22,
          height: 1.05,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ChoiceGrid extends StatelessWidget {
  final List<String> choices;
  final String? selected;
  final bool checked;
  final String answer;
  final int feedbackAttempt;
  final Map<String, String> choiceMeanings;
  final ValueChanged<String> onSelected;

  const _ChoiceGrid({
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - 14) / 2;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: choices.map((choice) {
            final active = selected == choice;
            final correct = checked && active && choice == answer;
            final wrong = checked && active && choice != answer;
            return SizedBox(
              width: tileWidth,
              child: _ChoicePill(
                label: choice,
                active: active,
                correct: correct,
                wrong: wrong,
                feedbackKey: active ? feedbackAttempt : 0,
                longPressMeaning: choiceMeanings[choice] ?? choice,
                onTap: checked ? null : () => onSelected(choice),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ChoicePill extends StatelessWidget {
  final String label;
  final bool active;
  final bool correct;
  final bool wrong;
  final int feedbackKey;
  final String longPressMeaning;
  final VoidCallback? onTap;

  const _ChoicePill({
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
    final background = correct
        ? TudloColors.green
        : wrong
        ? TudloColors.coral
        : active
        ? const Color(0xFF2BA83A)
        : const Color(0xFFFFF15A);
    final foreground = (active || correct || wrong)
        ? Colors.white
        : TudloColors.forest;

    return WordMeaningTooltipTarget(
      meaning: longPressMeaning,
      child: _FeedbackMotion(
        key: ValueKey('choice-pill-$label-$feedbackKey'),
        correct: correct,
        wrong: wrong,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              height: 76,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: foreground,
                  fontSize: 21,
                  height: 1.08,
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

class _PromptCard extends StatelessWidget {
  final LessonQuestion question;

  const _PromptCard({required this.question});

  @override
  Widget build(BuildContext context) {
    // Shared prompt layout for all Level Game question types.
    // The mascot makes the prompt feel like a spoken message, while the rounded
    // bubble keeps the question readable and consistent across exercises.
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 430;
        final bubble = Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2, right: 12),
                child: Icon(
                  Icons.volume_up_rounded,
                  color: TudloColors.green,
                  size: 32,
                ),
              ),
              Expanded(child: _PromptText(question: question)),
            ],
          ),
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: TudloMascot(size: 148),
              ),
              Transform.translate(offset: const Offset(0, -14), child: bubble),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(
              width: 142,
              height: 160,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: TudloMascot(size: 150),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 8, bottom: 10),
                child: bubble,
              ),
            ),
          ],
        );
      },
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
      fontSize: 24,
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
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final imageHeight = hasImage
            ? (availableHeight * .32).clamp(180.0, 300.0).toDouble()
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
                  fontSize: 28,
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
            fontSize: 28,
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
        constraints: const BoxConstraints(minWidth: 96, minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: hasWord ? color.withValues(alpha: .12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          hasWord ? label : '',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: checked && !correct ? TudloColors.coral : TudloColors.ink,
            fontSize: 25,
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
              horizontal: 18,
              vertical: 11,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: TudloColors.line, width: 2.5),
            ),
            labelStyle: const TextStyle(
              color: TudloColors.ink,
              fontSize: 20,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final rowWidth = (constraints.maxWidth * .84)
            .clamp(280.0, 560.0)
            .toDouble();
        return Column(
          children: List.generate(maxRows, (index) {
            final left = index < question.leftItems.length
                ? question.leftItems[index]
                : null;
            final right = index < question.rightItems.length
                ? question.rightItems[index]
                : null;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Center(
                child: SizedBox(
                  width: rowWidth,
                  child: Row(
                    children: [
                      Expanded(
                        child: left == null
                            ? const SizedBox(height: 82)
                            : _MatchTile(
                                label: left,
                                selected: selectedLeft == left,
                                matched: matches.containsKey(left),
                                wrong: wrongLeft == left,
                                justMatched: newMatchLeft == left,
                                shakeKey: wrongLeft == left ? wrongAttempt : 0,
                                jumpKey: newMatchLeft == left
                                    ? matchPulseAttempt
                                    : 0,
                                onTap: () => onSelectLeft(left),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: right == null
                            ? const SizedBox(height: 82)
                            : _MatchTile(
                                label: right,
                                selected: false,
                                matched: usedRight.contains(right),
                                wrong: wrongRight == right,
                                justMatched: newMatchRight == right,
                                shakeKey: wrongRight == right
                                    ? wrongAttempt
                                    : 0,
                                jumpKey: newMatchRight == right
                                    ? matchPulseAttempt
                                    : 0,
                                onTap: () => onSelectRight(right),
                                compact: true,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
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
            height: 82,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
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
                maxLines: 2,
                softWrap: true,
                style: TextStyle(
                  color: textColor,
                  fontSize: compact ? 19 : 21,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .1,
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
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final imageHeight = hasImage
            ? (availableHeight * .28).clamp(150.0, 260.0).toDouble()
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
                              horizontal: 16,
                              vertical: 10,
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
                                width: 3,
                              ),
                            ),
                            labelStyle: const TextStyle(
                              color: TudloColors.ink,
                              fontSize: 19,
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
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: remaining.map((word) {
                    return WordMeaningTooltipTarget(
                      meaning: translatedMeaningFor(word),
                      child: ActionChip(
                        label: Text(word),
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(
                            color: TudloColors.line,
                            width: 3,
                          ),
                        ),
                        labelStyle: const TextStyle(
                          color: TudloColors.ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                        onPressed: () => onAdd(word),
                      ),
                    );
                  }).toList(),
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
        onTap: checked
            ? null
            : () {
                TudloVoiceButton.speak(context, term.hil);
                onSelected(term.hil);
              },
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
              Text(
                term.hil,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 20,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
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
    final title = correct ? 'Maayo gid!' : 'Sulayi liwat!';
    final subtitle = correct
        ? 'Husto ang imo sabat.'
        : 'Tan-awa liwat ang sabat.';

    // Feedback panel shown after checking an answer. Correct answers use a
    // soft green sheet with the mascot and answer details.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: correct
            ? TudloColors.softGreen.withValues(alpha: .92)
            : TudloColors.coral.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const TudloMascot(size: 102),
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
                    fontSize: 34,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: accent,
                    fontSize: 20,
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
                          fontSize: 26,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Icon(Icons.volume_up_rounded, color: accent, size: 32),
                    ],
                  ),
                  const SizedBox(height: 4),
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
            margin: const EdgeInsets.only(bottom: 16),
            constraints: const BoxConstraints(minHeight: 112),
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: wrong ? TudloColors.coral : TudloColors.ink,
                      fontSize: 30,
                      height: 1.08,
                      fontWeight: active ? FontWeight.w900 : FontWeight.w800,
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

class _ConfettiBurst extends StatelessWidget {
  final bool fill;

  const _ConfettiBurst({super.key, this.fill = false});

  @override
  Widget build(BuildContext context) {
    final confetti = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return CustomPaint(
          painter: _ConfettiPainter(progress: value),
          child: const SizedBox.expand(),
        );
      },
    );

    if (fill) return confetti;

    return SizedBox(height: 86, child: confetti);
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;

  const _ConfettiPainter({required this.progress});

  static const _colors = [
    TudloColors.green,
    TudloColors.blue,
    TudloColors.gold,
    TudloColors.coral,
    Color(0xFF8B5CF6),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .58);
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 42; i++) {
      final angle = (-math.pi) + (math.pi * 2) * (i / 41);
      final distance = (24 + (i % 7) * 11) * progress;
      final fall = 34 * progress * progress;
      final position =
          center +
          Offset(math.cos(angle) * distance, math.sin(angle) * distance + fall);
      final opacity = (1 - progress).clamp(0.0, 1.0);
      paint.color = _colors[i % _colors.length].withValues(alpha: opacity);
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(angle + progress * math.pi);
      final width = 7.0 + (i % 3) * 2;
      final height = 12.0 + (i % 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: width, height: height),
          const Radius.circular(3),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
