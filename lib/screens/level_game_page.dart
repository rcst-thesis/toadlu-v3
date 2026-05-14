import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../app_data.dart';
import '../app_shell.dart';
import '../app_theme.dart';
import '../lesson_bank.dart';

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
      QuestionType.buildSentence => builtWords.isNotEmpty,
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
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Seriously???',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: TudloColors.meadow,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You made ${questions.length - score} mistakes.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: TudloColors.ink, fontSize: 18),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _ResultStat(
                    label: 'TOTAL XP',
                    value: '${score * 10}',
                    color: TudloColors.meadow,
                    icon: Icons.bolt_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ResultStat(
                    label: 'AMAZING',
                    value: '$accuracy%',
                    color: TudloColors.forest,
                    icon: Icons.track_changes_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ResultStat(
                    label: 'TIME',
                    value: _formatDuration(duration),
                    color: TudloColors.sky,
                    icon: Icons.timer_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: TudloColors.sky,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AppShell(initialIndex: 0),
                  ),
                  (route) => false,
                );
              },
              child: const Text('CLAIM XP'),
            ),
          ),
        ],
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
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _titleFor(currentQuestion.type),
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
                child: SingleChildScrollView(
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
                        : TudloColors.ink,
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
      QuestionType.matching => 'Tap the matching pairs',
      QuestionType.completeSentence => 'Complete the sentence',
      QuestionType.buildSentence => 'Translate this sentence',
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

class _ResultStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _ResultStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 4),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
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

class _PromptCard extends StatelessWidget {
  final LessonQuestion question;

  const _PromptCard({required this.question});

  @override
  Widget build(BuildContext context) {
    final icon = switch (question.type) {
      QuestionType.choice => Icons.auto_awesome_rounded,
      QuestionType.matching => Icons.link_rounded,
      QuestionType.completeSentence => Icons.edit_note_rounded,
      QuestionType.buildSentence => Icons.volume_up_rounded,
    };

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
              color: TudloColors.sky,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              question.prompt,
              style: const TextStyle(
                color: TudloColors.ink,
                fontSize: 24,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
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
                        dimWhenIdle: selectedLeft == null,
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
  final bool dimWhenIdle;
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
    this.dimWhenIdle = false,
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
        : dimWhenIdle
        ? TudloColors.muted
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
                  labelStyle: const TextStyle(color: TudloColors.ink),
                  onDeleted: checked ? null : () => onRemove(entry.key),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: remaining.map((word) {
            return ActionChip(
              label: Text(word),
              backgroundColor: Colors.white,
              side: const BorderSide(color: TudloColors.line, width: 3),
              labelStyle: const TextStyle(
                color: TudloColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              onPressed: checked ? null : () => onAdd(word),
            );
          }).toList(),
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
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
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
