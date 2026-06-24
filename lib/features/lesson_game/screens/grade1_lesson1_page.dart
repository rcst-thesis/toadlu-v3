import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/language_toggle.dart';
import 'package:tudloapp/core/widgets/mascot_widget.dart';
import 'package:tudloapp/features/energy/widgets/energy_indicator.dart';

class SoundItem {
  final String id;
  final String image;
  final String answer;

  const SoundItem({
    required this.id,
    required this.image,
    required this.answer,
  });
}

class Grade1Lesson1Result {
  final int correct;
  final int total;

  const Grade1Lesson1Result({required this.correct, required this.total});
}

final List<SoundItem> activityAItems = [
  SoundItem(
    id: 'alarm',
    image: 'assets/images/alarm.png',
    answer: 'Kring kring!',
  ),
  SoundItem(id: 'cow', image: 'assets/images/cow.png', answer: 'Moo moo!'),
  SoundItem(
    id: 'whistle',
    image: 'assets/images/whistle.png',
    answer: 'Prit prit!',
  ),
  SoundItem(id: 'baby', image: 'assets/images/baby.png', answer: 'Waa waa!'),
  SoundItem(id: 'car', image: 'assets/images/car.png', answer: 'Brum brum!'),
  SoundItem(
    id: 'camera',
    image: 'assets/images/camera.png',
    answer: 'Klik klik!',
  ),
];

final List<String> activityAChoices = [
  'Brum brum!',
  'Moo moo!',
  'Waa waa!',
  'Prit prit!',
  'Klik klik!',
  'Kring kring!',
];

final List<SoundItem> matchingItems = [
  SoundItem(
    id: 'telephone',
    image: 'assets/images/telephone.png',
    answer: 'krriiing! krriiing!',
  ),
  SoundItem(
    id: 'whistle',
    image: 'assets/images/whistle.png',
    answer: 'prrt! prrt! prrt!',
  ),
  SoundItem(
    id: 'bell',
    image: 'assets/images/bell.png',
    answer: 'ting! ting! ting!',
  ),
  SoundItem(
    id: 'hammer',
    image: 'assets/images/hammer.png',
    answer: 'pok! pok! pok!',
  ),
];

final List<String> matchingChoices = [
  'krriiing! krriiing!',
  'prrt! prrt! prrt!',
  'ting! ting! ting!',
  'pok! pok! pok!',
];

final List<Map<String, dynamic>> animalQuiz = [
  {
    'image': 'assets/images/cow.png',
    'answer': 'Moo moo!',
    'choices': ['Brum brum!', 'Moo moo!', 'Waa waa!'],
  },
  {
    'image': 'assets/images/cat.png',
    'answer': 'Meow meow!',
    'choices': ['Prit prit!', 'Klik klik!', 'Meow meow!'],
  },
  {
    'image': 'assets/images/dog.png',
    'answer': 'Arf arf!',
    'choices': ['Moo moo!', 'Arf arf!', 'Meow meow!'],
  },
];

const _storyText = '''
Kriiing! Kriiing! Kriing!

"Abaw! Ken, bugtaw ka na dira. Umpisa na sang klase subong," hambal ni Tiyay Maria sa iya anak.

"Oo Nanay, mabangon na ako. Diin bala si Tatay?" pamangkot ni Ken.

"Ato sa ugsaran, nagapatuka sang mga manok," sabat ni Tiyay Maria.

Gilayon naligo kag nagkaon si Ken. Nagpalapit gilayon ang iya ginasagud nga kuring.

Ngiyaw... ngiyaw... ngiyaw... paangga sang iya kuring kay Ken.

Gintagaan gilayon ni Ken sang pagkaon ang iya kuring.

Pagkatapos manipilyo dali-dali sia nga nagkuha sang iya mga gamit para sa eskwelahan.

Brum! Brum! Brum! Pinaandar na sang iya amay ang tricycle agud idul-ong si Ken sa eskwelahan.

Wala naulihi sa iya una nga adlaw sang pag-eskwela si Ken.
''';

class Grade1Lesson1LevelPage extends StatefulWidget {
  final Future<void> Function() onBack;
  final ValueChanged<Grade1Lesson1Result> onFinish;

  const Grade1Lesson1LevelPage({
    super.key,
    required this.onBack,
    required this.onFinish,
  });

  @override
  State<Grade1Lesson1LevelPage> createState() => _Grade1Lesson1LevelPageState();
}

class _Grade1Lesson1LevelPageState extends State<Grade1Lesson1LevelPage> {
  static const _quizTotal = 6;
  static const _activityATotal = 6;
  static const _matchingTotal = 4;
  static const _animalTotal = 3;
  static const _totalItems =
      _quizTotal + _activityATotal + _matchingTotal + _animalTotal;

  final Map<String, bool> _quizCorrect = {};
  final Map<int, bool> _animalCorrect = {};
  int _activityACorrect = 0;
  int _matchingCorrect = 0;

  int get _correctCount {
    return _quizCorrect.values.where((correct) => correct).length +
        _activityACorrect +
        _matchingCorrect +
        _animalCorrect.values.where((correct) => correct).length;
  }

  void _finishLevel() {
    widget.onFinish(
      Grade1Lesson1Result(correct: _correctCount, total: _totalItems),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3FFE5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LessonHeader(onBack: widget.onBack),
              const SizedBox(height: 18),
              const _LessonCard(
                title: 'Katuyuan',
                color: Color(0xFFFFC857),
                child: _BulletList(
                  items: [
                    'Makilala ang huni gikan sa ginhatag nga laragway.',
                    'Mahambal ang nagakaigo nga huni sang mga sapat, salakyan kag iban pa nga mga butang.',
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _LessonCard(
                title: 'Pasanyuga Ini!',
                color: Color(0xFFFF8FAB),
                child: Column(
                  children: [
                    _VocabularyCard(
                      word: 'ginpaandar',
                      meaning: 'ginpadalagan',
                      example:
                          'Ginpaandar ni tatay ang iya pangpasahero nga dyip.',
                    ),
                    SizedBox(height: 12),
                    _VocabularyCard(
                      word: 'nagapatuka',
                      meaning: 'nagapakaon sang manok ukon pispis',
                      example:
                          'Nagapatuka anay sang manok ang akon magulang nga lalaki antes magsulod sa trabaho.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _LessonCard(
                title: 'Pamati-i / Tuluka / Basaha',
                color: Color(0xFF70D6FF),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuestionLine(
                      text:
                          'Ano ang mga butang sa palibot nga makatuga sing huni ukon tunog?',
                    ),
                    _QuestionLine(text: 'Ano ang nagpabugtaw kay Ken?'),
                    _QuestionLine(
                      text:
                          'Pamati-i ang manunudlo samtang ginabasa ang istorya.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _StoryCard(),
              const SizedBox(height: 16),
              _IstoryahanNatonSection(
                onChecked: (id, correct) {
                  setState(() => _quizCorrect[id] = correct);
                },
              ),
              const SizedBox(height: 16),
              const _LessonCard(
                title: 'Paminsara Ini',
                color: Color(0xFFA0E8AF),
                child: Text(
                  'May nanarisari nga huni ang mga butang sa aton palibot. May ara nga matunog kag may ara man nga mahinay. Mahimo maghalin sa tawo ukon sapat ang huni ukon tunog. Mahimo man ini nga maghalin sa mga butang kasubong sang salakyan, hampanganan kag iban pa.',
                  style: _lessonTextStyle,
                ),
              ),
              const SizedBox(height: 16),
              _ActivityADragDrop(
                onCorrectCountChanged: (count) {
                  setState(() => _activityACorrect = count);
                },
              ),
              const SizedBox(height: 16),
              _MatchingActivity(
                onCorrectCountChanged: (count) {
                  setState(() => _matchingCorrect = count);
                },
              ),
              const SizedBox(height: 16),
              _AnimalMultipleChoiceActivity(
                onChecked: (index, correct) {
                  setState(() => _animalCorrect[index] = correct);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 68,
                child: ElevatedButton(
                  onPressed: _finishLevel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF12B76A),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: const Color(0xFF12B76A).withValues(alpha: .32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: const Text('Finish Level'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonHeader extends StatelessWidget {
  final Future<void> Function() onBack;

  const _LessonHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: TudloColors.blue,
              iconSize: 38,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 54, height: 54),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: const LinearProgressIndicator(
                  value: .42,
                  minHeight: 18,
                  backgroundColor: Color(0xFFDDF5DD),
                  color: Color(0xFFAEEBFF),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const EnergyIndicator(),
          ],
        ),
        const SizedBox(height: 28),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TudloMascot(size: 86),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Leksyon 1',
                    style: TextStyle(
                      color: TudloColors.blue,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Leksyon 1:\nMga Huni sa Akon Palibot',
                    style: TextStyle(
                      color: TudloColors.ink,
                      fontSize: 30,
                      height: 1.02,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LessonCard extends StatelessWidget {
  final String title;
  final Color color;
  final Widget child;

  const _LessonCard({
    required this.title,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color, width: 4),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .16),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF259C13),
              fontSize: 27,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFAEEBFF), width: 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Column(
            children: [
              _StoryPlayButton(),
              SizedBox(height: 8),
              Text(
                'Istorya',
                style: TextStyle(
                  color: Color(0xFF259C13),
                  fontSize: 29,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 214,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFF3FFE5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: TudloColors.forest, width: 2),
            ),
            child: const _LessonImage(
              image: 'assets/images/story.png',
              semanticLabel: 'May Klase na Naman',
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'May Klase na Naman',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF259C13),
              fontSize: 29,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF6FFE8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFFD21E), width: 3),
            ),
            child: const Text(_storyText, style: _lessonTextStyle),
          ),
        ],
      ),
    );
  }
}

class _StoryPlayButton extends StatelessWidget {
  const _StoryPlayButton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Pamatii ang istorya',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () =>
            TudloVoiceButton.speak(context, _storyText, hiligaynon: true),
        child: Ink(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2AAA00),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2AAA00).withValues(alpha: .35),
                blurRadius: 24,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 42,
          ),
        ),
      ),
    );
  }
}

class _MascotPrompt extends StatelessWidget {
  const _MascotPrompt();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TudloMascot(size: 96),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            margin: const EdgeInsets.only(top: 22),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TudloColors.ink, width: 2),
            ),
            child: const Text(
              'Pili-a ang Sakto',
              style: TextStyle(
                color: TudloColors.ink,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuizCard extends StatefulWidget {
  final String question;
  final List<String> choices;
  final String answer;
  final ValueChanged<bool> onChecked;

  const _QuizCard({
    required this.question,
    required this.choices,
    required this.answer,
    required this.onChecked,
  });

  @override
  State<_QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<_QuizCard> {
  String? _selected;
  bool? _correct;

  void _check() {
    if (_selected == null) {
      setState(() => _correct = false);
      return;
    }
    final correct = _selected == widget.answer;
    setState(() => _correct = correct);
    widget.onChecked(correct);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: const Color(0xFF75EA82),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF168A35), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.question, style: _greenCardQuestionStyle),
              const SizedBox(height: 18),
              _ChoiceGrid(
                choices: widget.choices,
                selected: _selected,
                checkedCorrect: _correct,
                answer: widget.answer,
                onTap: (choice) {
                  if (_correct == true) return;
                  setState(() {
                    _selected = choice;
                    _correct = null;
                  });
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _correct == true ? null : _check,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF118AB2),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFA0E8AF),
                    disabledForegroundColor: TudloColors.forest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: Text(_correct == true ? 'Napasa' : 'Ipasa'),
                ),
              ),
              if (_correct == false) ...[
                const SizedBox(height: 12),
                const Text(
                  'Sulayi liwat!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFEF476F),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_correct == true)
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: _ConfettiBurst(
                  key: ValueKey('quiz-confetti-${widget.question}'),
                  fill: true,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ChoiceGrid extends StatelessWidget {
  final List<String> choices;
  final String? selected;
  final bool? checkedCorrect;
  final String answer;
  final ValueChanged<String> onTap;

  const _ChoiceGrid({
    required this.choices,
    required this.selected,
    required this.checkedCorrect,
    required this.answer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 12.0;
        final columns = choices.length == 4
            ? 2
            : constraints.maxWidth >= 430
            ? 3
            : 1;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: choices.map((choice) {
            final active = selected == choice;
            final correct = checkedCorrect == true && choice == answer;
            final wrong = checkedCorrect == false && active;
            return SizedBox(
              width: width,
              child: _ChoiceButton(
                label: choice,
                selected: active,
                correct: correct,
                wrong: wrong,
                onTap: () => onTap(choice),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _DraggableAnswerChip extends StatelessWidget {
  final String label;

  const _DraggableAnswerChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: label,
      feedback: Material(
        color: Colors.transparent,
        child: _AnswerChip(label: label, lifted: true),
      ),
      childWhenDragging: Opacity(
        opacity: .35,
        child: _AnswerChip(label: label),
      ),
      child: _AnswerChip(label: label),
    );
  }
}

class _ActivityADragDrop extends StatefulWidget {
  final ValueChanged<int> onCorrectCountChanged;

  const _ActivityADragDrop({required this.onCorrectCountChanged});

  @override
  State<_ActivityADragDrop> createState() => _ActivityADragDropState();
}

class _ActivityADragDropState extends State<_ActivityADragDrop> {
  final Map<String, String> _answers = {};
  String _feedback = 'I-drag ang huni pakadto sa insakto nga laragway.';
  bool _lastDropCorrect = false;

  @override
  Widget build(BuildContext context) {
    final remainingChoices = activityAChoices.where((choice) {
      return !_answers.values.contains(choice);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _MascotPrompt(),
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE2FFC2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Masarangan Ko Ini! Activity A',
                    style: TextStyle(
                      color: Color(0xFF259C13),
                      fontSize: 27,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Ihatag ang huni sang mga butang sa palibot. Ipabati sa klase.',
                    style: _activityInstructionStyle,
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: .72,
                    children: activityAItems.map((item) {
                      return _SoundDropCard(
                        item: item,
                        answer: _answers[item.id],
                        onDropped: (data) {
                          if (data == item.answer) {
                            setState(() {
                              _answers[item.id] = data;
                              _feedback = '';
                              _lastDropCorrect = true;
                            });
                            widget.onCorrectCountChanged(_answers.length);
                          } else {
                            setState(() {
                              _feedback =
                                  'Sulayi liwat! Pili-a ang husto nga huni.';
                              _lastDropCorrect = false;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  if (!_lastDropCorrect)
                    Text(
                      _feedback,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: TudloColors.forest,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC3F79B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: remainingChoices.map((choice) {
                        return _DraggableAnswerChip(label: choice);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            if (_lastDropCorrect)
              Positioned.fill(
                child: IgnorePointer(
                  child: _ConfettiBurst(
                    key: ValueKey('activity-a-${_answers.length}'),
                    fill: true,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SoundDropCard extends StatelessWidget {
  final SoundItem item;
  final String? answer;
  final ValueChanged<String> onDropped;

  const _SoundDropCard({
    required this.item,
    required this.answer,
    required this.onDropped,
  });

  @override
  Widget build(BuildContext context) {
    final completed = answer != null;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _LessonImage(image: item.image, semanticLabel: item.id),
          ),
        ),
        const SizedBox(height: 8),
        DragTarget<String>(
          onAcceptWithDetails: (details) => onDropped(details.data),
          builder: (context, candidateData, rejectedData) {
            final hovering = candidateData.isNotEmpty;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: double.infinity,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: completed
                    ? const Color(0xFFE7F8EE)
                    : hovering
                    ? const Color(0xFFE0F7FA)
                    : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: completed ? const Color(0xFF12B76A) : TudloColors.ink,
                  width: completed ? 3 : 2,
                ),
              ),
              child: Center(
                child: Text(
                  answer ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: completed
                        ? const Color(0xFF087443)
                        : TudloColors.muted,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MatchingActivity extends StatefulWidget {
  final ValueChanged<int> onCorrectCountChanged;

  const _MatchingActivity({required this.onCorrectCountChanged});

  @override
  State<_MatchingActivity> createState() => _MatchingActivityState();
}

class _MatchingActivityState extends State<_MatchingActivity> {
  String? _selectedId;
  final Set<String> _matchedIds = {};
  final Set<String> _matchedSounds = {};
  String _feedback = 'Tap ang laragway, dayon pili-a ang huni.';
  bool _lastMatchCorrect = false;

  void _selectItem(SoundItem item) {
    if (_matchedIds.contains(item.id)) return;
    setState(() {
      _selectedId = item.id;
      _feedback = 'Pili-a ang huni para sa ${item.id}.';
      _lastMatchCorrect = false;
    });
  }

  void _selectSound(String sound) {
    final selected = _selectedId;
    if (selected == null) {
      setState(() {
        _feedback = 'Pili anay sang laragway.';
        _lastMatchCorrect = false;
      });
      return;
    }
    final item = matchingItems.firstWhere((item) => item.id == selected);
    if (item.answer == sound) {
      setState(() {
        _matchedIds.add(item.id);
        _matchedSounds.add(sound);
        _selectedId = null;
        _feedback = '';
        _lastMatchCorrect = true;
      });
      widget.onCorrectCountChanged(_matchedIds.length);
    } else {
      setState(() {
        _feedback = 'Sulayi liwat! Indi pa amo sina.';
        _lastMatchCorrect = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _MascotPrompt(),
        Stack(
          children: [
            _LessonCard(
              title: 'Masarangan Ko Ini! Activity B',
              color: const Color(0xFF00BBF9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Langot sang linya ang tagsa ka laragway kag ang huni sini.',
                    style: _activitySmallInstructionStyle,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4FFC8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFBDE0FE),
                        width: 3,
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final stacked = constraints.maxWidth < 560;
                        final left = _MatchingImageColumn(
                          selectedId: _selectedId,
                          matchedIds: _matchedIds,
                          onSelect: _selectItem,
                        );
                        final right = _MatchingSoundColumn(
                          matchedSounds: _matchedSounds,
                          onSelect: _selectSound,
                        );
                        if (stacked) {
                          return Column(
                            children: [left, const SizedBox(height: 12), right],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: left),
                            const SizedBox(width: 12),
                            Expanded(child: right),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!_lastMatchCorrect)
                    Text(
                      _feedback,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF259C13),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
            ),
            if (_lastMatchCorrect)
              Positioned.fill(
                child: IgnorePointer(
                  child: _ConfettiBurst(
                    key: ValueKey('activity-b-${_matchedIds.length}'),
                    fill: true,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MatchingImageColumn extends StatelessWidget {
  final String? selectedId;
  final Set<String> matchedIds;
  final ValueChanged<SoundItem> onSelect;

  const _MatchingImageColumn({
    required this.selectedId,
    required this.matchedIds,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: matchingItems.map((item) {
        final selected = selectedId == item.id;
        final matched = matchedIds.contains(item.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: matched ? null : () => onSelect(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              height: 92,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: matched
                    ? const Color(0xFFE7F8EE)
                    : selected
                    ? const Color(0xFFD6FFF1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: matched
                      ? const Color(0xFF12B76A)
                      : selected
                      ? TudloColors.green
                      : const Color(0xFFBDE0FE),
                  width: 3,
                ),
                boxShadow: [
                  if (selected || matched)
                    BoxShadow(
                      color:
                          (matched
                                  ? const Color(0xFF12B76A)
                                  : TudloColors.green)
                              .withValues(alpha: .18),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                ],
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: selected || matched
                        ? const Color(0xFFCFFFD5)
                        : const Color(0xFFF2FFF5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _LessonImage(
                    image: item.image,
                    semanticLabel: item.id,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MatchingSoundColumn extends StatelessWidget {
  final Set<String> matchedSounds;
  final ValueChanged<String> onSelect;

  const _MatchingSoundColumn({
    required this.matchedSounds,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: matchingChoices.map((sound) {
        final matched = matchedSounds.contains(sound);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            width: double.infinity,
            height: 76,
            child: ElevatedButton(
              onPressed: matched ? null : () => onSelect(sound),
              style: ElevatedButton.styleFrom(
                elevation: matched ? 0 : 3,
                shadowColor: const Color(0xFFFFC857).withValues(alpha: .40),
                backgroundColor: matched
                    ? const Color(0xFFA0E8AF)
                    : const Color(0xFFFFF275),
                foregroundColor: TudloColors.ink,
                disabledBackgroundColor: const Color(0xFFA0E8AF),
                disabledForegroundColor: TudloColors.forest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: matched
                        ? const Color(0xFF12B76A)
                        : const Color(0xFFFFC857),
                    width: 3,
                  ),
                ),
                textStyle: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              child: Text(sound, textAlign: TextAlign.center),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AnimalMultipleChoiceActivity extends StatefulWidget {
  final void Function(int index, bool correct) onChecked;

  const _AnimalMultipleChoiceActivity({required this.onChecked});

  @override
  State<_AnimalMultipleChoiceActivity> createState() =>
      _AnimalMultipleChoiceActivityState();
}

class _AnimalMultipleChoiceActivityState
    extends State<_AnimalMultipleChoiceActivity> {
  final Map<int, String> _selectedByIndex = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _MascotPrompt(),
        _LessonCard(
          title: 'Masarangan Ko Ini! Activity C',
          color: const Color(0xFF06D6A0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bilugi ang huni sang sapat sa tagsa ka laragway.',
                style: _activitySmallInstructionStyle,
              ),
              const SizedBox(height: 14),
              ...animalQuiz.asMap().entries.map((entry) {
                return _AnimalChoiceCard(
                  index: entry.key,
                  item: entry.value,
                  selected: _selectedByIndex[entry.key],
                  onSelected: (choice) {
                    setState(() => _selectedByIndex[entry.key] = choice);
                    widget.onChecked(
                      entry.key,
                      choice == (entry.value['answer'] as String),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimalChoiceCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> item;
  final String? selected;
  final ValueChanged<String> onSelected;

  const _AnimalChoiceCard({
    required this.index,
    required this.item,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final answer = item['answer'] as String;
    final choices = item['choices'] as List<String>;
    final image = item['image'] as String;
    final correctSelected = selected == answer;

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE7F8EE),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF06D6A0), width: 3),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 130,
                child: _LessonImage(
                  image: image,
                  semanticLabel: 'animal $index',
                ),
              ),
              const SizedBox(height: 12),
              ...choices.map((choice) {
                final active = selected == choice;
                final correct = active && choice == answer;
                final wrong = active && choice != answer;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: double.infinity,
                    height: 62,
                    child: ElevatedButton(
                      onPressed: () => onSelected(choice),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: correct
                            ? const Color(0xFF12B76A)
                            : wrong
                            ? const Color(0xFFEF476F)
                            : const Color(0xFFFFF25A),
                        foregroundColor: correct || wrong
                            ? Colors.white
                            : TudloColors.ink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      child: Text(choice),
                    ),
                  ),
                );
              }),
              if (selected != null && selected != answer)
                const Text(
                  'Sulayi liwat!',
                  style: TextStyle(
                    color: Color(0xFFEF476F),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
        ),
        if (correctSelected)
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ConfettiBurst(
                  key: ValueKey('animal-$index-$selected'),
                  fill: true,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _IstoryahanNatonSection extends StatelessWidget {
  final void Function(String id, bool correct) onChecked;

  const _IstoryahanNatonSection({required this.onChecked});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _MascotPrompt(),
        const Text(
          'Istoryahan Naton',
          style: TextStyle(
            color: Color(0xFF259C13),
            fontSize: 30,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        _QuizCard(
          question: 'Sin-o ang ginpukaw ni Tiyay Maria?',
          answer: 'Ken',
          choices: const ['Ken', 'Tatay', 'Ang kuring'],
          onChecked: (correct) => onChecked('story-q1', correct),
        ),
        _QuizCard(
          question: 'Ngaa ginpukaw ni Tiyay Maria si Ken?',
          answer: 'Umpisa na sang klase subong.',
          choices: const [
            'Umpisa na sang klase subong.',
            'Maghampang sila sa guwa.',
            'Magbakal sila sang pagkaon.',
          ],
          onChecked: (correct) => onChecked('story-q2', correct),
        ),
        _QuizCard(
          question: 'Ano ang ginhatag ni Ken sa iya ginasagud nga kuring?',
          answer: 'Pagkaon',
          choices: const ['Pagkaon', 'Dyip', 'Libro', 'Sapatos'],
          onChecked: (correct) => onChecked('story-q3', correct),
        ),
        _QuizCard(
          question:
              'Ngaa nagdalidali si Ken sa pagkuha sang iya mga gamit sa eskwelahan?',
          answer: 'Para makakadto sia sa eskwelahan.',
          choices: const [
            'Para makakadto sia sa eskwelahan.',
            'Para magtulog liwat.',
            'Para magpatuka sang manok.',
          ],
          onChecked: (correct) => onChecked('story-q4', correct),
        ),
        _QuizCard(
          question: 'Ngaa ayhan wala naulihi sa klase si Ken?',
          answer: 'Gindul-ong sia sang iya amay sa tricycle.',
          choices: const [
            'Gindul-ong sia sang iya amay sa tricycle.',
            'Wala sia nag-eskwela.',
            'Nagpabilin sia sa balay.',
          ],
          onChecked: (correct) => onChecked('story-q5', correct),
        ),
        _QuizCard(
          question: 'Ano nga mga huni ang nahinambitan sa istorya?',
          answer: 'Kriiing, ngiyaw, kag brum.',
          choices: const [
            'Kriiing, ngiyaw, kag brum.',
            'Moo, prit, kag klik.',
            'Waa, arf, kag pok.',
          ],
          onChecked: (correct) => onChecked('story-q6', correct),
        ),
      ],
    );
  }
}

class _LessonImage extends StatelessWidget {
  final String image;
  final String semanticLabel;
  final BoxFit fit;

  const _LessonImage({
    required this.image,
    required this.semanticLabel,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      image,
      fit: fit,
      semanticLabel: semanticLabel,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) {
        final fallback = _fallbackImagePath(image);
        if (fallback != null && fallback != image) {
          return Image.asset(
            fallback,
            fit: fit,
            semanticLabel: semanticLabel,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => _ImageFallback(label: semanticLabel),
          );
        }
        return _ImageFallback(label: semanticLabel);
      },
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final String label;

  const _ImageFallback({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE9FBF7),
      child: Center(
        child: Icon(_fallbackIcon(label), color: TudloColors.forest, size: 54),
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;

  const _BulletList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(item, style: _lessonTextStyle),
        );
      }).toList(),
    );
  }
}

class _VocabularyCard extends StatelessWidget {
  final String word;
  final String meaning;
  final String example;

  const _VocabularyCard({
    required this.word,
    required this.meaning,
    required this.example,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFF8FAB), width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$word - $meaning',
            style: const TextStyle(
              color: TudloColors.forest,
              fontSize: 24,
              height: 1.12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text('Example: $example', style: _lessonTextStyle),
        ],
      ),
    );
  }
}

class _QuestionLine extends StatelessWidget {
  final String text;

  const _QuestionLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: _lessonTextStyle),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool correct;
  final bool wrong;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.correct,
    required this.wrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = correct
        ? const Color(0xFF2AAA35)
        : wrong
        ? const Color(0xFFEF476F)
        : selected
        ? const Color(0xFF2AAA35)
        : const Color(0xFFFFF25A);
    final border = correct
        ? const Color(0xFF168A35)
        : wrong
        ? const Color(0xFFC9184A)
        : selected
        ? const Color(0xFF168A35)
        : const Color(0xFFFFF25A);
    final textColor = correct || wrong || selected
        ? Colors.white
        : TudloColors.ink;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        constraints: const BoxConstraints(minHeight: 62),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              height: 1.12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnswerChip extends StatelessWidget {
  final String label;
  final bool lifted;

  const _AnswerChip({required this.label, this.lifted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF43D05A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF43D05A), width: 2),
        boxShadow: lifted
            ? [
                BoxShadow(
                  color: TudloColors.ink.withValues(alpha: .18),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

String? _fallbackImagePath(String image) {
  const base = 'assets/images/level_game/Grade1/unit1/lesson1';
  return switch (image) {
    'assets/images/alarm.png' => '$base/alarm-clock.png',
    'assets/images/baby.png' => '$base/crying-baby.png',
    'assets/images/cow.png' => '$base/cow.png',
    'assets/images/whistle.png' => '$base/whistle.png',
    'assets/images/car.png' => '$base/car.png',
    'assets/images/camera.png' => '$base/camera.png',
    'assets/images/cat.png' => '$base/cat.png',
    'assets/images/dog.png' => '$base/dog.png',
    _ => null,
  };
}

IconData _fallbackIcon(String label) {
  return switch (label) {
    'telephone' => Icons.phone_in_talk_rounded,
    'bell' => Icons.notifications_active_rounded,
    'hammer' => Icons.construction_rounded,
    _ => Icons.image_rounded,
  };
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

    return SizedBox(height: 72, child: confetti);
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;

  const _ConfettiPainter({required this.progress});

  static const _colors = [
    TudloColors.green,
    TudloColors.blue,
    Color(0xFFFFD21E),
    Color(0xFFEF476F),
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
      paint.color = _colors[i % _colors.length].withValues(alpha: 1 - progress);
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(angle + progress * math.pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: 7 + (i % 3) * 2,
            height: 11 + (i % 4),
          ),
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

const _lessonTextStyle = TextStyle(
  color: TudloColors.ink,
  fontSize: 20,
  height: 1.35,
  fontWeight: FontWeight.w800,
);

const _activityInstructionStyle = TextStyle(
  color: TudloColors.ink,
  fontSize: 21,
  height: 1.2,
  fontWeight: FontWeight.w900,
);

const _activitySmallInstructionStyle = TextStyle(
  color: TudloColors.ink,
  fontSize: 17,
  height: 1.2,
  fontWeight: FontWeight.w900,
);

const _greenCardQuestionStyle = TextStyle(
  color: Color(0xFF24658A),
  fontSize: 22,
  height: 1.15,
  fontWeight: FontWeight.w900,
);
