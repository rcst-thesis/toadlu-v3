import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../app_data.dart';
import '../app_shell.dart';
import '../app_theme.dart';
import '../lesson_bank.dart';
import '../tap_word_meaning.dart';

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
  void initState() {
    super.initState();
    questions = LessonBank.questionsForLevel(widget.level);
    _levelStartedAt = DateTime.now();
  }

  @override
  void dispose() {
    _wrongMatchClearTimer?.cancel();
    _matchedPulseTimer?.cancel();
    super.dispose();
  }

  LessonQuestion get currentQuestion => questions[questionIndex];

  bool get canContinue {
    final q = currentQuestion;
    return switch (q.type) {
      QuestionType.matching => matches.length == q.leftItems.length,
      QuestionType.buildSentence =>
        builtWords.length >= q.answer.split(' ').length,
      _ => selectedAnswer != null,
    };
  }

  bool get isCorrect {
    final q = currentQuestion;
    return switch (q.type) {
      QuestionType.matching => _matchingCorrect(q),
      QuestionType.buildSentence =>
        builtWords.join(' ').toLowerCase() == q.answer.toLowerCase(),
      _ => selectedAnswer == q.answer,
    };
  }

  bool _matchingCorrect(LessonQuestion q) {
    for (final left in q.leftItems) {
      final term = LessonBank.terms.firstWhere((term) => term.hil == left);
      if (matches[left] != term.eng) return false;
    }
    return true;
  }

  void nextQuestion() {
    if (!checked) {
      setState(() {
        lastCorrect = isCorrect;
        checked = true;
        answerFeedbackAttempt++;
        if (lastCorrect) score++;
      });
      return;
    }

    if (questionIndex < questions.length - 1) {
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
      });
      return;
    }

    AppData.energyPoints += score * 10;
    AppData.saveLevelScore(widget.level, score, questions.length);
    if (AppData.unlockedLevel <= widget.level &&
        widget.level < AppData.maxLevel) {
      AppData.unlockedLevel = widget.level + 1;
    }
    _showCompleteDialog();
  }

  void _showCompleteDialog() {
    final accuracy = questions.isEmpty
        ? 0
        : ((score / questions.length) * 100).round();
    final duration = DateTime.now().difference(_levelStartedAt);
    showDialog(
      context: context,
      barrierColor: TudloColors.ink.withValues(alpha: .62),
      builder: (_) => _LessonCompleteDialog(
        xp: score * 10,
        accuracy: accuracy,
        mistakes: questions.length - score,
        durationLabel: _formatDuration(duration),
        onClaim: () {
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

  @override
  Widget build(BuildContext context) {
    final progress = (questionIndex + 1) / questions.length;

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
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.settings_rounded,
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
                ],
              ),
              const SizedBox(height: 26),
              Center(
                child: Text(
                  _titleFor(currentQuestion.type),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: TudloColors.ink,
                    fontSize: 31,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: currentQuestion.type == QuestionType.buildSentence
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PromptCard(question: currentQuestion),
                          const SizedBox(height: 26),
                          Expanded(child: _buildQuestionBody(currentQuestion)),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PromptCard(question: currentQuestion),
                            const SizedBox(height: 26),
                            _buildQuestionBody(currentQuestion),
                          ],
                        ),
                      ),
              ),
              if (checked) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: lastCorrect
                        ? TudloColors.green.withValues(alpha: .12)
                        : TudloColors.coral.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        lastCorrect
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: lastCorrect
                            ? TudloColors.green
                            : TudloColors.coral,
                        size: 30,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        lastCorrect ? 'Great job!' : 'Try again',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: lastCorrect
                              ? TudloColors.green
                              : TudloColors.coral,
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
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
                        : const Color.fromARGB(255, 46, 96, 0),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: TudloColors.line,
                    disabledForegroundColor: TudloColors.muted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: canContinue ? nextQuestion : null,
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
      QuestionType.choice => 'Select the missing word',
      QuestionType.matching => 'Matching pair',
      QuestionType.completeSentence => 'What is the word?',
      QuestionType.buildSentence => 'Translate the sentence',
    };
  }

  Widget _buildQuestionBody(LessonQuestion q) {
    return switch (q.type) {
      QuestionType.choice || QuestionType.completeSentence => _ChoiceList(
        choices: q.choices,
        selected: selectedAnswer,
        checked: checked,
        answer: q.answer,
        feedbackAttempt: answerFeedbackAttempt,
        onSelected: (value) {
          if (checked) return;
          setState(() => selectedAnswer = value);
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
          final expected = _expectedMatch(left);
          setState(() {
            if (expected == right) {
              matches[left] = right;
              _clearWrongMatch();
              newMatchLeft = left;
              newMatchRight = right;
              matchPulseAttempt++;
              _scheduleMatchedPulseClear(matchPulseAttempt);
              if (matches.length == q.leftItems.length && !checked) {
                lastCorrect = true;
                checked = true;
                score++;
              }
            } else {
              wrongMatchLeft = left;
              wrongMatchRight = right;
              wrongMatchAttempt++;
              _scheduleWrongMatchClear(wrongMatchAttempt);
            }
            selectedMatchLeft = null;
          });
        },
      ),
      QuestionType.buildSentence => _BuildSentenceExercise(
        question: q,
        builtWords: builtWords,
        checked: checked,
        correct: checked && lastCorrect,
        feedbackAttempt: answerFeedbackAttempt,
        onAdd: (word) => setState(() => builtWords.add(word)),
        onRemove: (index) => setState(() => builtWords.removeAt(index)),
      ),
    };
  }

  String _expectedMatch(String left) {
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _LessonCompleteDialog extends StatelessWidget {
  final int xp;
  final int accuracy;
  final int mistakes;
  final String durationLabel;
  final VoidCallback onClaim;

  const _LessonCompleteDialog({
    required this.xp,
    required this.accuracy,
    required this.mistakes,
    required this.durationLabel,
    required this.onClaim,
  });

  int get starCount {
    if (accuracy >= 90) return 3;
    if (accuracy >= 70) return 2;
    if (accuracy > 0) return 1;
    return 0;
  }

  String get message {
    if (mistakes == 0) return 'Perfect lesson! You made 0 mistakes.';
    if (accuracy >= 80) return 'Amazing work! You made $mistakes mistakes.';
    return 'Great effort! Keep practicing and try again.';
  }

  @override
  Widget build(BuildContext context) {
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
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 118),
              padding: const EdgeInsets.fromLTRB(24, 82, 24, 22),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCF2),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: TudloColors.green.withValues(alpha: .24),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .18),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    right: 6,
                    child: _Sparkle(color: TudloColors.green, size: 14),
                  ),
                  Positioned(
                    top: 104,
                    left: 4,
                    child: _Sparkle(color: TudloColors.meadow, size: 10),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: TudloColors.muted,
                          fontSize: 15,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .70),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: TudloColors.green.withValues(alpha: .12),
                          ),
                        ),
                        child: Column(
                          children: [
                            _RewardStatRow(
                              label: 'TOTAL XP',
                              value: '$xp',
                              icon: Icons.bolt_rounded,
                            ),
                            const _RewardDivider(),
                            _RewardStatRow(
                              label: 'ACCURACY',
                              value: '$accuracy%',
                              icon: Icons.track_changes_rounded,
                            ),
                            const _RewardDivider(),
                            _RewardStatRow(
                              label: 'TIME',
                              value: durationLabel,
                              icon: Icons.timer_rounded,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TudloColors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .3,
                            ),
                          ),
                          onPressed: onClaim,
                          child: const Text('CLAIM XP'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(top: 0, child: _RewardStars(count: starCount)),
            const Positioned(top: 74, child: _RewardBanner()),
          ],
        ),
      ),
    );
  }
}

class _RewardBanner extends StatelessWidget {
  const _RewardBanner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 98,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/banner.png',
              fit: BoxFit.contain,
              color: TudloColors.green,
              colorBlendMode: BlendMode.modulate,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'LESSON',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'LEVEL COMPLETE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .4,
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

class _RewardStars extends StatelessWidget {
  final int count;

  const _RewardStars({required this.count});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 178,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 6,
            top: 28,
            child: Transform.rotate(
              angle: -.18,
              child: _RewardStar(active: count >= 2, size: 56),
            ),
          ),
          Positioned(
            right: 6,
            top: 28,
            child: Transform.rotate(
              angle: .18,
              child: _RewardStar(active: count >= 3, size: 56),
            ),
          ),
          Positioned(
            top: 0,
            child: Transform.rotate(
              angle: .05,
              child: _RewardStar(active: count >= 1, size: 78),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: TudloColors.green.withValues(alpha: .14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: TudloColors.green, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: TudloColors.muted,
                fontSize: 13,
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
                  fontSize: 30,
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

class _RewardDivider extends StatelessWidget {
  const _RewardDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1.2,
      color: TudloColors.green.withValues(alpha: .16),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: TudloColors.green,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              switch (question.type) {
                QuestionType.choice => Icons.auto_awesome_rounded,
                QuestionType.matching => Icons.link_rounded,
                QuestionType.completeSentence => Icons.text_fields_rounded,
                QuestionType.buildSentence => Icons.translate_rounded,
              },
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: _PromptText(question: question)),
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
    const style = TextStyle(
      color: TudloColors.ink,
      fontSize: 24,
      height: 1.2,
      fontWeight: FontWeight.w800,
    );

    if (question.targetPhrase.trim().isEmpty ||
        question.targetMeaning.trim().isEmpty) {
      return Text(question.prompt, style: style);
    }

    return TapWordMeaningText(
      fullQuestionText: question.prompt,
      targetPhrase: question.targetPhrase,
      targetMeaning: question.targetMeaning,
      directionLabel: question.directionLabel,
      style: style,
    );
  }
}

class _ChoiceList extends StatelessWidget {
  final List<String> choices;
  final String? selected;
  final bool checked;
  final String answer;
  final int feedbackAttempt;
  final ValueChanged<String> onSelected;

  const _ChoiceList({
    required this.choices,
    required this.selected,
    required this.checked,
    required this.answer,
    required this.feedbackAttempt,
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
          icon: active ? Icons.check_circle_rounded : Icons.circle_outlined,
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

    return TweenAnimationBuilder<double>(
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
    final remaining = [...question.sentenceWords];
    for (final word in builtWords) {
      remaining.remove(word);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FeedbackMotion(
          key: ValueKey('build-$feedbackAttempt'),
          correct: checked && correct,
          wrong: checked && !correct,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: checked
                  ? correct
                        ? TudloColors.green.withValues(alpha: .10)
                        : TudloColors.coral.withValues(alpha: .08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: checked
                    ? correct
                          ? TudloColors.green
                          : TudloColors.coral
                    : TudloColors.line,
                width: 4,
              ),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: builtWords.asMap().entries.map((entry) {
                return InputChip(
                  label: Text(entry.value),
                  backgroundColor: TudloColors.sky.withValues(alpha: .12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: TudloColors.green.withValues(alpha: .22),
                      width: 2,
                    ),
                  ),
                  labelStyle: const TextStyle(
                    color: TudloColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                  onDeleted: checked ? null : () => onRemove(entry.key),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: remaining.map((word) {
                    return ActionChip(
                      label: Text(word),
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
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
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                      onPressed: checked ? null : () => onAdd(word),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnswerTile extends StatelessWidget {
  final String label;
  final bool active;
  final bool correct;
  final bool wrong;
  final int feedbackKey;
  final IconData icon;
  final VoidCallback? onTap;

  const _AnswerTile({
    required this.label,
    required this.active,
    required this.correct,
    required this.wrong,
    required this.feedbackKey,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = correct
        ? TudloColors.green
        : wrong
        ? TudloColors.coral
        : active
        ? TudloColors.sky
        : TudloColors.line;
    final backgroundColor = correct
        ? TudloColors.green.withValues(alpha: .10)
        : wrong
        ? TudloColors.coral.withValues(alpha: .08)
        : active
        ? TudloColors.sky.withValues(alpha: .12)
        : Colors.white;
    final iconColor = correct
        ? TudloColors.green
        : wrong
        ? TudloColors.coral
        : active
        ? TudloColors.sky
        : TudloColors.muted;

    return _FeedbackMotion(
      key: ValueKey('$label-$feedbackKey'),
      correct: correct,
      wrong: wrong,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: 4),
          ),
          child: Row(
            children: [
              Icon(wrong ? Icons.cancel_rounded : icon, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: active ? TudloColors.ink : TudloColors.muted,
                    fontSize: 22,
                    fontWeight: active ? FontWeight.w900 : FontWeight.w700,
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
