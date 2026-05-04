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
  String? selectedAnswer;
  String? selectedMatchLeft;
  String? wrongMatchLeft;
  String? wrongMatchRight;
  bool checked = false;
  bool lastCorrect = false;
  final Map<String, String> matches = {};
  final List<String> builtWords = [];

  @override
  void initState() {
    super.initState();
    questions = LessonBank.questionsForLevel(widget.level);
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
        if (lastCorrect) score++;
      });
      return;
    }

    if (questionIndex < questions.length - 1) {
      setState(() {
        questionIndex++;
        selectedAnswer = null;
        selectedMatchLeft = null;
        wrongMatchLeft = null;
        wrongMatchRight = null;
        checked = false;
        lastCorrect = false;
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Seriously???',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFFFC928),
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
                    color: Color(0xFFFFC928),
                    icon: Icons.bolt_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ResultStat(
                    label: 'AMAZING',
                    value: '$accuracy%',
                    color: Color(0xFF98E526),
                    icon: Icons.track_changes_rounded,
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
                  const SizedBox(width: 16),
                  const Icon(Icons.bolt_rounded, color: TudloColors.coral),
                  const SizedBox(width: 4),
                  Text(
                    '${25 - questionIndex}',
                    style: const TextStyle(
                      color: TudloColors.coral,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
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
                        lastCorrect ? 'Amazing!' : 'Try the next one',
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
        onSelected: (value) => setState(() => selectedAnswer = value),
      ),
      QuestionType.matching => _MatchingExercise(
        question: q,
        matches: matches,
        selectedLeft: selectedMatchLeft,
        wrongLeft: wrongMatchLeft,
        wrongRight: wrongMatchRight,
        onSelectLeft: (left) {
          if (matches.containsKey(left)) return;
          setState(() {
            selectedMatchLeft = selectedMatchLeft == left ? null : left;
            wrongMatchLeft = null;
            wrongMatchRight = null;
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
              wrongMatchLeft = null;
              wrongMatchRight = null;
            } else {
              wrongMatchLeft = left;
              wrongMatchRight = right;
            }
            selectedMatchLeft = null;
          });
        },
      ),
      QuestionType.buildSentence => _BuildSentenceExercise(
        question: q,
        builtWords: builtWords,
        onAdd: (word) => setState(() => builtWords.add(word)),
        onRemove: (index) => setState(() => builtWords.removeAt(index)),
      ),
    };
  }

  String _expectedMatch(String left) {
    return LessonBank.terms.firstWhere((term) => term.hil == left).eng;
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
  final ValueChanged<String> onSelected;

  const _ChoiceList({
    required this.choices,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: choices.map((choice) {
        final active = selected == choice;
        return _AnswerTile(
          label: choice,
          active: active,
          icon: active ? Icons.check_circle_rounded : Icons.circle_outlined,
          onTap: () => onSelected(choice),
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
  final ValueChanged<String> onSelectLeft;
  final ValueChanged<String> onSelectRight;

  const _MatchingExercise({
    required this.question,
    required this.matches,
    required this.selectedLeft,
    required this.wrongLeft,
    required this.wrongRight,
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
  final bool dimWhenIdle;
  final bool compact;
  final VoidCallback onTap;

  const _MatchTile({
    required this.label,
    required this.selected,
    required this.matched,
    required this.wrong,
    required this.onTap,
    this.dimWhenIdle = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final active = selected || matched || wrong;
    final borderColor = wrong
        ? TudloColors.coral
        : active
        ? TudloColors.green
        : TudloColors.line;
    final textColor = matched
        ? TudloColors.green
        : wrong
        ? TudloColors.coral
        : dimWhenIdle
        ? TudloColors.muted
        : TudloColors.ink;
    final backgroundColor = wrong
        ? TudloColors.coral.withValues(alpha: .08)
        : active
        ? TudloColors.green.withValues(alpha: .08)
        : Colors.white;
    final shadowColor = wrong ? TudloColors.coral : TudloColors.green;

    return InkWell(
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
    );
  }
}

class _BuildSentenceExercise extends StatelessWidget {
  final LessonQuestion question;
  final List<String> builtWords;
  final ValueChanged<String> onAdd;
  final ValueChanged<int> onRemove;

  const _BuildSentenceExercise({
    required this.question,
    required this.builtWords,
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
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: TudloColors.line, width: 4),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: builtWords.asMap().entries.map((entry) {
              return InputChip(
                label: Text(entry.value),
                backgroundColor: TudloColors.sky.withValues(alpha: .12),
                labelStyle: const TextStyle(color: TudloColors.ink),
                onDeleted: () => onRemove(entry.key),
              );
            }).toList(),
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
              onPressed: () => onAdd(word),
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
  final IconData icon;
  final VoidCallback onTap;

  const _AnswerTile({
    required this.label,
    required this.active,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: active ? TudloColors.sky.withValues(alpha: .12) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? TudloColors.sky : TudloColors.line,
            width: 4,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: active ? TudloColors.sky : TudloColors.muted),
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
    );
  }
}
