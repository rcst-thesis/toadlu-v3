part of '../../level_game_page.dart';

enum _G2ParkGreetingStep {
  intro,
  map,
  morningTeach,
  morningPractice,
  afternoonTeach,
  afternoonPractice,
  eveningTeach,
  eveningPractice,
  review,
  match,
  reward,
}

class _GradeTwoUnitTwoLessonOneParkGreetingFlow extends StatefulWidget {
  final VoidCallback onExit;
  final void Function(int index, bool correct) onQuizAttempt;
  final ValueChanged<int> onQuizCorrect;

  const _GradeTwoUnitTwoLessonOneParkGreetingFlow({
    required this.onExit,
    required this.onQuizAttempt,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeTwoUnitTwoLessonOneParkGreetingFlow> createState() =>
      _GradeTwoUnitTwoLessonOneParkGreetingFlowState();
}

class _GradeTwoUnitTwoLessonOneParkGreetingFlowState
    extends State<_GradeTwoUnitTwoLessonOneParkGreetingFlow> {
  static const _voiceBase = 'audio/VO-final/grade2';
  static const _backgroundAsset =
      'assets/images/level_game/grade2/backgrounds/Tudlo_Park_Intro_Background.svg';
  static const _friendGirlOne =
      'assets/images/level_game/grade2/people/Tudlo_Park_Friend_Girl_1.svg';
  static const _friendBoy =
      'assets/images/level_game/grade2/people/Tudlo_Park_Friend_Boy.svg';
  static const _friendGirlTwo =
      'assets/images/level_game/grade2/people/Tudlo_Park_Friend_Girl_2.svg';
  static const _answerByTime = {
    'morning': 'good_morning',
    'afternoon': 'good_afternoon',
    'evening': 'good_evening',
  };

  _G2ParkGreetingStep _step = _G2ParkGreetingStep.intro;
  bool _voicePlaying = false;
  bool _parkSelected = false;
  bool _characterTapped = false;
  String? _selectedGreetingId;
  String? _wrongGreetingId;
  String? _activeMatchTimeId;
  String? _wrongMatchGreetingId;
  bool _completed = false;
  final Set<String> _completedTimes = {};
  final Set<String> _reviewedTimes = {};
  final Map<String, String> _matchedGreetings = {};

  double get _progress =>
      (_G2ParkGreetingStep.values.indexOf(_step) + 1) /
      _G2ParkGreetingStep.values.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _speakForStep();
    });
  }

  @override
  void dispose() {
    unawaited(TudloVoiceButton.stop());
    super.dispose();
  }

  void _goToStep(_G2ParkGreetingStep step) {
    if (_step == step) return;
    unawaited(TudloVoiceButton.stop());
    setState(() {
      _step = step;
      _characterTapped = false;
      _selectedGreetingId = null;
      _wrongGreetingId = null;
      _wrongMatchGreetingId = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _speakForStep();
    });
  }

  Future<void> _playVoice(List<int> clips) async {
    await TudloVoiceButton.stop();
    await AppAudioService.instance.lowerBackgroundVolume();
    await AppAudioService.instance.playVoiceAssets([
      for (final clip in clips) '$_voiceBase/Gr_2_Les_2_1_$clip.wav',
    ]);
    await AppAudioService.instance.restoreBackgroundVolume();
  }

  Future<void> _speakForStep() async {
    final clips = switch (_step) {
      _G2ParkGreetingStep.intro => const [2],
      _G2ParkGreetingStep.map => const [3],
      _G2ParkGreetingStep.morningTeach => const [4],
      _G2ParkGreetingStep.morningPractice => const [5, 6],
      _G2ParkGreetingStep.afternoonTeach => const [9],
      _G2ParkGreetingStep.afternoonPractice => const [10, 11],
      _G2ParkGreetingStep.eveningTeach => const [14],
      _G2ParkGreetingStep.eveningPractice => const [15, 16],
      _G2ParkGreetingStep.review => const [19],
      _G2ParkGreetingStep.match => const [19],
      _G2ParkGreetingStep.reward => const [22],
    };
    setState(() => _voicePlaying = true);
    try {
      await _playVoice(clips);
    } catch (_) {
      if (!mounted) return;
      await TudloVoiceButton.speak(
        context,
        switch (_step) {
          _G2ParkGreetingStep.intro =>
            'Maglibot kita sa Park halin aga tubtob gab-i!',
          _G2ParkGreetingStep.map => 'I-tap ang Park sa mapa.',
          _G2ParkGreetingStep.morningTeach => 'Good morning sa aga.',
          _G2ParkGreetingStep.morningPractice => 'Pilia ang Good morning.',
          _G2ParkGreetingStep.afternoonTeach => 'Good afternoon sa hapon.',
          _G2ParkGreetingStep.afternoonPractice => 'Pilia ang Good afternoon.',
          _G2ParkGreetingStep.eveningTeach => 'Good evening sa gab-i.',
          _G2ParkGreetingStep.eveningPractice => 'Pilia ang Good evening.',
          _G2ParkGreetingStep.review =>
            'Ipares ang greeting sa aga, hapon, kag gab-i.',
          _G2ParkGreetingStep.match =>
            'Ipares ang greeting sa aga, hapon, kag gab-i.',
          _G2ParkGreetingStep.reward =>
            'Kabalo ka na mag-greet sa nagkalain-lain nga tion!',
        },
        hiligaynon: true,
        waitForCompletion: true,
      );
    } finally {
      await AppAudioService.instance.restoreBackgroundVolume();
      if (mounted) setState(() => _voicePlaying = false);
    }
  }

  Future<void> _tapPark() async {
    if (_voicePlaying || _parkSelected) return;
    setState(() => _parkSelected = true);
    await AppAudioService.instance.playCorrect();
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (mounted) _goToStep(_G2ParkGreetingStep.morningTeach);
  }

  void _tapCharacter() {
    if (_voicePlaying || _characterTapped) return;
    unawaited(AppAudioService.instance.playTap());
    setState(() => _characterTapped = true);
  }

  Future<void> _chooseGreeting(String timeId, _G2FriendChoice choice) async {
    if (_voicePlaying || !_characterTapped || _selectedGreetingId != null) {
      return;
    }
    final quizIndex = switch (timeId) {
      'morning' => 0,
      'afternoon' => 1,
      _ => 2,
    };
    final correct = _answerByTime[timeId] == choice.id;
    widget.onQuizAttempt(quizIndex, correct);
    setState(() {
      _selectedGreetingId = choice.id;
      _wrongGreetingId = correct ? null : choice.id;
    });
    if (!correct) {
      await AppAudioService.instance.playWrong();
      await _playVoice(switch (timeId) {
        'morning' => const [8],
        'afternoon' => const [13],
        _ => const [18],
      });
      await Future<void>.delayed(const Duration(milliseconds: 460));
      if (!mounted) return;
      setState(() {
        _selectedGreetingId = null;
        _wrongGreetingId = null;
      });
      return;
    }
    widget.onQuizCorrect(quizIndex);
    setState(() => _completedTimes.add(timeId));
    await AppAudioService.instance.playCorrect();
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    _goToStep(switch (timeId) {
      'morning' => _G2ParkGreetingStep.afternoonTeach,
      'afternoon' => _G2ParkGreetingStep.eveningTeach,
      _ => _G2ParkGreetingStep.match,
    });
  }

  Future<void> _reviewTime(String timeId) async {
    if (_voicePlaying) return;
    setState(() => _reviewedTimes.add(timeId));
    await _playVoice(switch (timeId) {
      'morning' => const [6],
      'afternoon' => const [8],
      _ => const [10],
    });
  }

  Future<void> _matchGreeting(String greetingId, String timeId) async {
    if (_voicePlaying || _matchedGreetings.containsKey(timeId)) return;
    final correct = _answerByTime[timeId] == greetingId;
    widget.onQuizAttempt(3, correct);
    if (!correct) {
      setState(() => _wrongMatchGreetingId = greetingId);
      await AppAudioService.instance.playWrong();
      await _playVoice(const [21]);
      await Future<void>.delayed(const Duration(milliseconds: 430));
      if (mounted) setState(() => _wrongMatchGreetingId = null);
      return;
    }
    setState(() {
      _matchedGreetings[timeId] = greetingId;
      _activeMatchTimeId = null;
    });
    await AppAudioService.instance.playCorrect();
    if (_matchedGreetings.length == 3) {
      widget.onQuizCorrect(3);
      await _playVoice(const [20]);
      await Future<void>.delayed(_lessonCompletionHold);
      if (mounted) _goToStep(_G2ParkGreetingStep.reward);
    }
  }

  Future<void> _tapGreetingForMatch(String greetingId) async {
    final timeId = _activeMatchTimeId;
    if (timeId == null) return;
    await _matchGreeting(greetingId, timeId);
  }

  void _finish() {
    if (_completed) return;
    _completed = true;
    for (var index = 0; index < _lessonQuizCount; index++) {
      widget.onQuizCorrect(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey('g2-u2-l1-$_step'),
        child: switch (_step) {
          _G2ParkGreetingStep.intro => _G2ParkGreetingIntroStep(
            progress: _progress,
            backgroundAsset: _backgroundAsset,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(_G2ParkGreetingStep.map),
          ),
          _G2ParkGreetingStep.map => _G2ParkGreetingMapStep(
            progress: _progress,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: _tapPark,
          ),
          _G2ParkGreetingStep.morningTeach => _G2ParkGreetingTeachStep(
            progress: _progress,
            backgroundAsset: _parkGreetingTimes[0].backgroundAsset,
            time: _parkGreetingTimes[0],
            characterAsset: _friendGirlOne,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(_G2ParkGreetingStep.morningPractice),
          ),
          _G2ParkGreetingStep.morningPractice => _G2ParkGreetingPracticeStep(
            progress: _progress,
            backgroundAsset: _parkGreetingTimes[0].backgroundAsset,
            time: _parkGreetingTimes[0],
            characterAsset: _friendGirlOne,
            completedTimes: _completedTimes,
            characterTapped: _characterTapped,
            selectedId: _selectedGreetingId,
            wrongId: _wrongGreetingId,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onTapCharacter: _tapCharacter,
            onChoose: (choice) => _chooseGreeting('morning', choice),
          ),
          _G2ParkGreetingStep.afternoonTeach => _G2ParkGreetingTeachStep(
            progress: _progress,
            backgroundAsset: _parkGreetingTimes[1].backgroundAsset,
            time: _parkGreetingTimes[1],
            characterAsset: _friendBoy,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(_G2ParkGreetingStep.afternoonPractice),
          ),
          _G2ParkGreetingStep.afternoonPractice => _G2ParkGreetingPracticeStep(
            progress: _progress,
            backgroundAsset: _parkGreetingTimes[1].backgroundAsset,
            time: _parkGreetingTimes[1],
            characterAsset: _friendBoy,
            completedTimes: _completedTimes,
            characterTapped: _characterTapped,
            selectedId: _selectedGreetingId,
            wrongId: _wrongGreetingId,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onTapCharacter: _tapCharacter,
            onChoose: (choice) => _chooseGreeting('afternoon', choice),
          ),
          _G2ParkGreetingStep.eveningTeach => _G2ParkGreetingTeachStep(
            progress: _progress,
            backgroundAsset: _parkGreetingTimes[2].backgroundAsset,
            time: _parkGreetingTimes[2],
            characterAsset: _friendGirlTwo,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(_G2ParkGreetingStep.eveningPractice),
          ),
          _G2ParkGreetingStep.eveningPractice => _G2ParkGreetingPracticeStep(
            progress: _progress,
            backgroundAsset: _parkGreetingTimes[2].backgroundAsset,
            time: _parkGreetingTimes[2],
            characterAsset: _friendGirlTwo,
            completedTimes: _completedTimes,
            characterTapped: _characterTapped,
            selectedId: _selectedGreetingId,
            wrongId: _wrongGreetingId,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onTapCharacter: _tapCharacter,
            onChoose: (choice) => _chooseGreeting('evening', choice),
          ),
          _G2ParkGreetingStep.review => _G2ParkGreetingReviewStep(
            progress: _progress,
            backgroundAsset: _backgroundAsset,
            reviewedTimes: _reviewedTimes,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onReviewTime: _reviewTime,
            onNext: () => _goToStep(_G2ParkGreetingStep.match),
          ),
          _G2ParkGreetingStep.match => _G2ParkGreetingMatchStep(
            progress: _progress,
            backgroundAsset: _parkGreetingTimes[0].backgroundAsset,
            activeTimeId: _activeMatchTimeId,
            matchedGreetings: _matchedGreetings,
            wrongGreetingId: _wrongMatchGreetingId,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onSelectTime: (timeId) =>
                setState(() => _activeMatchTimeId = timeId),
            onMatch: _matchGreeting,
            onTapGreeting: _tapGreetingForMatch,
          ),
          _G2ParkGreetingStep.reward => _G2ParkGreetingRewardStep(
            progress: _progress,
            backgroundAsset: _backgroundAsset,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onDone: _finish,
          ),
        },
      ),
    );
  }
}

class _ParkGreetingTime {
  final String id;
  final String timeLabel;
  final String localLabel;
  final String greeting;
  final String backgroundAsset;
  final IconData icon;
  final Color color;
  final Color tint;

  const _ParkGreetingTime({
    required this.id,
    required this.timeLabel,
    required this.localLabel,
    required this.greeting,
    required this.backgroundAsset,
    required this.icon,
    required this.color,
    required this.tint,
  });
}

const _parkGreetingTimes = [
  _ParkGreetingTime(
    id: 'morning',
    timeLabel: 'Morning',
    localLabel: 'aga',
    greeting: 'Good morning',
    backgroundAsset:
        'assets/images/level_game/grade2/backgrounds/Tudlo_Park_Morning_Background.svg',
    icon: Icons.wb_sunny_rounded,
    color: Color(0xFFFFC928),
    tint: Color(0x22FFD35C),
  ),
  _ParkGreetingTime(
    id: 'afternoon',
    timeLabel: 'Afternoon',
    localLabel: 'hapon',
    greeting: 'Good afternoon',
    backgroundAsset:
        'assets/images/level_game/grade2/backgrounds/Tudlo_Park_Afternoon_Background.svg',
    icon: Icons.light_mode_rounded,
    color: Color(0xFFFF8A28),
    tint: Color(0x33FF9F43),
  ),
  _ParkGreetingTime(
    id: 'evening',
    timeLabel: 'Evening',
    localLabel: 'gab-i',
    greeting: 'Good evening',
    backgroundAsset:
        'assets/images/level_game/grade2/backgrounds/Tudlo_Park_Night_Background.svg',
    icon: Icons.dark_mode_rounded,
    color: Color(0xFF536DFE),
    tint: Color(0x44304B9B),
  ),
];

const _parkGreetingChoices = [
  _G2FriendChoice('good_morning', 'Good morning'),
  _G2FriendChoice('good_afternoon', 'Good afternoon'),
  _G2FriendChoice('good_evening', 'Good evening'),
];

String _parkGreetingLabel(String id) {
  return _parkGreetingChoices.firstWhere((choice) => choice.id == id).label;
}

class _G2ParkScene extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final _ParkGreetingTime? time;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Widget child;

  const _G2ParkScene({
    required this.progress,
    required this.backgroundAsset,
    required this.time,
    required this.onExit,
    required this.onReplay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: backgroundAsset,
      child: Stack(children: [child]),
    );
  }
}

class _G2ParkGreetingIntroStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _G2ParkGreetingIntroStep({
    required this.progress,
    required this.backgroundAsset,
    required this.inputReady,
    required this.onExit,
    required this.onReplay,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _G2ParkScene(
      progress: progress,
      backgroundAsset: backgroundAsset,
      time: null,
      onExit: onExit,
      onReplay: onReplay,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .06,
          view.height * .15,
          view.width * .06,
          view.height * .04,
        ),
        child: Column(
          children: [
            Row(
              children: [
                for (final time in _parkGreetingTimes)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _ParkTimeCard(time: time, selected: false),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            _LessonKokaMascot(
              size: (view.width * .43).clamp(150.0, 230.0),
              mood: KokaMood.idle,
            ),
            const Spacer(),
            const _LessonOneMessageCard(
              message: 'Maglibot kita sa Park halin aga tubtob gab-i!',
            ),
            SizedBox(height: view.height * .018),
            _LessonOneBlueButton(
              label: 'Libot ta',
              onTap: inputReady ? onNext : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _G2ParkGreetingMapStep extends StatelessWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _G2ParkGreetingMapStep({
    required this.progress,
    required this.onExit,
    required this.onReplay,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final mapSize = Size(view.width * 1.34, view.height * 1.06);
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: 'assets/images/level_game/backgrounds/tudlomap.svg',
      child: Stack(
        children: [
          SizedBox(
            width: mapSize.width,
            height: mapSize.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _LessonBackgroundAsset(
                  asset: 'assets/images/level_game/backgrounds/tudlomap.svg',
                ),
                Positioned(
                  left: mapSize.width * .40,
                  top: mapSize.height * .42,
                  width: mapSize.width * .22,
                  height: mapSize.width * .22,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onNext,
                    child: const _LessonOneMapDestinationCue(),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: view.width * .12,
            right: view.width * .12,
            bottom: view.height * .06,
            child: const _LessonOneMessageCard(
              message: 'I-tap ang Park.',
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _G2ParkGreetingTeachStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final _ParkGreetingTime time;
  final String characterAsset;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _G2ParkGreetingTeachStep({
    required this.progress,
    required this.backgroundAsset,
    required this.time,
    required this.characterAsset,
    required this.inputReady,
    required this.onExit,
    required this.onReplay,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _G2ParkScene(
      progress: progress,
      backgroundAsset: backgroundAsset,
      time: time,
      onExit: onExit,
      onReplay: onReplay,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .06,
          view.height * .15,
          view.width * .06,
          view.height * .045,
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: (view.width * .25).clamp(86.0, 116.0),
                child: _ParkTimeCard(time: time, selected: true),
              ),
            ),
            Expanded(
              child: _ParkCharacterGreetingStage(
                time: time,
                characterAsset: characterAsset,
                greeting: time.greeting,
              ),
            ),
            _LessonOneMessageCard(
              message: '${time.greeting} sa ${time.localLabel}.',
              compact: true,
            ),
            SizedBox(height: view.height * .018),
            _LessonOneBlueButton(
              label: 'Padayon',
              onTap: inputReady ? onNext : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _G2ParkGreetingPracticeStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final _ParkGreetingTime time;
  final String characterAsset;
  final Set<String> completedTimes;
  final bool characterTapped;
  final String? selectedId;
  final String? wrongId;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onTapCharacter;
  final Future<void> Function(_G2FriendChoice choice) onChoose;

  const _G2ParkGreetingPracticeStep({
    required this.progress,
    required this.backgroundAsset,
    required this.time,
    required this.characterAsset,
    required this.completedTimes,
    required this.characterTapped,
    required this.selectedId,
    required this.wrongId,
    required this.inputReady,
    required this.onExit,
    required this.onReplay,
    required this.onTapCharacter,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final correctId =
        _GradeTwoUnitTwoLessonOneParkGreetingFlowState._answerByTime[time.id]!;
    return _G2ParkScene(
      progress: progress,
      backgroundAsset: backgroundAsset,
      time: time,
      onExit: onExit,
      onReplay: onReplay,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .055,
          view.height * .13,
          view.width * .055,
          view.height * .035,
        ),
        child: Column(
          children: [
            _LessonOneMessageCard(
              message: characterTapped
                  ? 'Pilia ang ${time.greeting}.'
                  : 'I-tap ang karakter.',
              compact: true,
            ),
            Expanded(
              child: GestureDetector(
                onTap: inputReady ? onTapCharacter : null,
                child: _ParkCharacterGreetingStage(
                  time: time,
                  characterAsset: characterAsset,
                  greeting: time.greeting,
                  showTapCue: !characterTapped,
                  active: characterTapped,
                ),
              ),
            ),
            Column(
              children: [
                for (final choice in _parkGreetingChoices)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: SizedBox(
                      width: double.infinity,
                      child: _ParkGreetingCard(
                        label: choice.label,
                        correct:
                            selectedId == choice.id && choice.id == correctId,
                        wrong: wrongId == choice.id,
                        enabled:
                            inputReady && characterTapped && selectedId == null,
                        onTap: () => onChoose(choice),
                      ),
                    ),
                  ),
              ],
            ),
            if (time.id != 'morning') ...[
              SizedBox(height: view.height * .01),
              _ParkTimeReviewStrip(completedTimes: completedTimes),
            ],
          ],
        ),
      ),
    );
  }
}

class _ParkCharacterGreetingStage extends StatelessWidget {
  final _ParkGreetingTime time;
  final String characterAsset;
  final String greeting;
  final bool showTapCue;
  final bool active;

  const _ParkCharacterGreetingStage({
    required this.time,
    required this.characterAsset,
    required this.greeting,
    this.showTapCue = false,
    this.active = true,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: view.width * .01,
          bottom: view.height * .03,
          child: _LessonKokaMascot(
            size: (view.width * .34).clamp(124.0, 176.0),
            mood: KokaMood.idle,
          ),
        ),
        Positioned(
          right: view.width * .02,
          bottom: view.height * .02,
          width: view.width * .42,
          height: view.height * .40,
          child: _FeedbackMotion(
            correct: active,
            wrong: false,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                _LessonPictureAsset(
                  asset: characterAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_) => Icon(
                    Icons.person_rounded,
                    color: TudloColors.blue,
                    size: view.width * .28,
                  ),
                ),
                if (showTapCue)
                  Positioned(
                    right: -view.width * .01,
                    bottom: view.height * .045,
                    child: const _FamilyTapCue(),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          left: view.width * .25,
          right: view.width * .25,
          bottom: view.height * .19,
          child: _ParkGreetingCard(
            label: greeting,
            correct: active,
            wrong: false,
            enabled: false,
            onTap: () {},
          ),
        ),
      ],
    );
  }
}

class _G2ParkGreetingReviewStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final Set<String> reviewedTimes;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function(String timeId) onReviewTime;
  final VoidCallback onNext;

  const _G2ParkGreetingReviewStep({
    required this.progress,
    required this.backgroundAsset,
    required this.reviewedTimes,
    required this.inputReady,
    required this.onExit,
    required this.onReplay,
    required this.onReviewTime,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final canContinue = reviewedTimes.length == 3;
    return _G2ParkScene(
      progress: progress,
      backgroundAsset: backgroundAsset,
      time: null,
      onExit: onExit,
      onReplay: onReplay,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .06,
          view.height * .15,
          view.width * .06,
          view.height * .04,
        ),
        child: Column(
          children: [
            const _LessonOneMessageCard(
              message: 'Pamatian liwat ang mga greeting.',
              compact: true,
            ),
            SizedBox(height: view.height * .035),
            for (final time in _parkGreetingTimes) ...[
              GestureDetector(
                onTap: inputReady ? () => onReviewTime(time.id) : null,
                child: _ParkTimeGreetingRow(
                  time: time,
                  reviewed: reviewedTimes.contains(time.id),
                ),
              ),
              SizedBox(height: view.height * .02),
            ],
            const Spacer(),
            _LessonOneBlueButton(
              label: 'Padayon',
              onTap: inputReady && canContinue ? onNext : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _G2ParkGreetingMatchStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final String? activeTimeId;
  final Map<String, String> matchedGreetings;
  final String? wrongGreetingId;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final ValueChanged<String> onSelectTime;
  final Future<void> Function(String greetingId, String timeId) onMatch;
  final Future<void> Function(String greetingId) onTapGreeting;

  const _G2ParkGreetingMatchStep({
    required this.progress,
    required this.backgroundAsset,
    required this.activeTimeId,
    required this.matchedGreetings,
    required this.wrongGreetingId,
    required this.inputReady,
    required this.onExit,
    required this.onReplay,
    required this.onSelectTime,
    required this.onMatch,
    required this.onTapGreeting,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final usedGreetingIds = matchedGreetings.values.toSet();
    return _G2ParkScene(
      progress: progress,
      backgroundAsset: backgroundAsset,
      time: null,
      onExit: onExit,
      onReplay: onReplay,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .045,
          view.height * .13,
          view.width * .045,
          view.height * .035,
        ),
        child: Column(
          children: [
            const _LessonOneMessageCard(
              message: 'Ipares ang greeting sa aga, hapon, kag gab-i.',
              compact: true,
            ),
            SizedBox(height: view.height * .018),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final time in _parkGreetingTimes) ...[
                          _ParkTimeDropTarget(
                            time: time,
                            active: activeTimeId == time.id,
                            greetingId: matchedGreetings[time.id],
                            inputReady: inputReady,
                            onSelect: () => onSelectTime(time.id),
                            onAccept: (greetingId) =>
                                onMatch(greetingId, time.id),
                          ),
                          SizedBox(height: view.height * .018),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: view.width * .035),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final choice in _parkGreetingChoices) ...[
                          _DraggableGreetingCard(
                            choice: choice,
                            hidden: usedGreetingIds.contains(choice.id),
                            wrong: wrongGreetingId == choice.id,
                            enabled: inputReady,
                            onAcceptTime: (timeId) =>
                                onMatch(choice.id, timeId),
                            onTap: () => onTapGreeting(choice.id),
                          ),
                          SizedBox(height: view.height * .018),
                        ],
                      ],
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

class _G2ParkGreetingRewardStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onDone;

  const _G2ParkGreetingRewardStep({
    required this.progress,
    required this.backgroundAsset,
    required this.onExit,
    required this.onReplay,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return _G2ParkScene(
      progress: progress,
      backgroundAsset: backgroundAsset,
      time: null,
      onExit: onExit,
      onReplay: onReplay,
      child: _StickerUnlockRewardContent(
        fallback: const _FamilyReferenceBadge(label: 'PANAMYAW\n1'),
        message: 'Kabalo ka na mag-greet sa nagkalain-lain nga tion!',
        onDone: onDone,
      ),
    );
  }
}

class _ParkTimeCard extends StatelessWidget {
  final _ParkGreetingTime time;
  final bool selected;
  final bool checked;

  const _ParkTimeCard({
    required this.time,
    required this.selected,
    this.checked = false,
  });

  @override
  Widget build(BuildContext context) {
    return _FeedbackMotion(
      correct: checked || selected,
      wrong: false,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 82,
            height: 82,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: time.color.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: time.color, width: 3),
            ),
            child: Icon(time.icon, color: time.color, size: 50),
          ),
          if (checked)
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: TudloColors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ParkTimeReviewStrip extends StatelessWidget {
  final Set<String> completedTimes;

  const _ParkTimeReviewStrip({required this.completedTimes});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final time in _parkGreetingTimes)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                height: 64,
                child: _ParkTimeCard(
                  time: time,
                  selected: false,
                  checked: completedTimes.contains(time.id),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ParkGreetingCard extends StatelessWidget {
  final String label;
  final bool correct;
  final bool wrong;
  final bool enabled;
  final VoidCallback onTap;

  const _ParkGreetingCard({
    required this.label,
    required this.correct,
    required this.wrong,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FeedbackMotion(
      correct: correct,
      wrong: wrong,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 82,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: correct ? const Color(0xFFE8FFD8) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: correct
                  ? TudloColors.green
                  : wrong
                  ? TudloColors.coral
                  : TudloColors.blue,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .14),
                blurRadius: 8,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.nunito(
                color: TudloColors.blue,
                fontSize: 20,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ParkTimeGreetingRow extends StatelessWidget {
  final _ParkGreetingTime time;
  final bool reviewed;

  const _ParkTimeGreetingRow({required this.time, required this.reviewed});

  @override
  Widget build(BuildContext context) {
    return _FeedbackMotion(
      correct: reviewed,
      wrong: false,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: reviewed ? TudloColors.green : const Color(0xFFD8E8F6),
            width: 3,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: _ParkTimeCard(time: time, selected: reviewed),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                time.greeting,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: TudloColors.blue,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            Icon(
              reviewed ? Icons.check_circle_rounded : Icons.volume_up_rounded,
              color: reviewed ? TudloColors.green : TudloColors.blue,
              size: 34,
            ),
          ],
        ),
      ),
    );
  }
}

class _ParkTimeDropTarget extends StatelessWidget {
  final _ParkGreetingTime time;
  final bool active;
  final String? greetingId;
  final bool inputReady;
  final VoidCallback onSelect;
  final Future<void> Function(String greetingId) onAccept;

  const _ParkTimeDropTarget({
    required this.time,
    required this.active,
    required this.greetingId,
    required this.inputReady,
    required this.onSelect,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final locked = greetingId != null;
    final card = DragTarget<String>(
      onWillAcceptWithDetails: (_) => inputReady && !locked,
      onAcceptWithDetails: (details) {
        unawaited(onAccept(details.data));
      },
      builder: (context, _, __) {
        return GestureDetector(
          onTap: inputReady && !locked ? onSelect : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 98),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: locked
                  ? const Color(0xFFE8FFD8)
                  : active
                  ? const Color(0xFFFFF5C4)
                  : Colors.white.withValues(alpha: .92),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: locked
                    ? TudloColors.green
                    : active
                    ? TudloColors.gold
                    : const Color(0xFFD8E8F6),
                width: 3,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(time.icon, color: time.color, size: 30),
                Text(
                  time.localLabel,
                  style: GoogleFonts.nunito(
                    color: TudloColors.blue,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  greetingId == null ? '...' : _parkGreetingLabel(greetingId!),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: locked ? TudloColors.green : TudloColors.blue,
                    fontSize: 16,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (locked || !inputReady) return card;
    return Draggable<String>(
      data: time.id,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 120, child: card),
      ),
      childWhenDragging: Opacity(opacity: .36, child: card),
      child: card,
    );
  }
}

class _DraggableGreetingCard extends StatelessWidget {
  final _G2FriendChoice choice;
  final bool hidden;
  final bool wrong;
  final bool enabled;
  final Future<void> Function(String timeId) onAcceptTime;
  final VoidCallback onTap;

  const _DraggableGreetingCard({
    required this.choice,
    required this.hidden,
    required this.wrong,
    required this.enabled,
    required this.onAcceptTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = DragTarget<String>(
      onWillAcceptWithDetails: (_) => enabled && !hidden,
      onAcceptWithDetails: (details) {
        unawaited(onAcceptTime(details.data));
      },
      builder: (context, _, __) => AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: hidden ? .22 : 1,
        child: _ParkGreetingCard(
          label: choice.label,
          correct: hidden,
          wrong: wrong,
          enabled: enabled && !hidden,
          onTap: onTap,
        ),
      ),
    );
    if (hidden || !enabled) return child;
    return Draggable<String>(
      data: choice.id,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 165, child: child),
      ),
      childWhenDragging: Opacity(opacity: .35, child: child),
      child: child,
    );
  }
}
