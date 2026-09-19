part of '../../level_game_page.dart';

enum _G2BirthdayStep {
  invitation,
  map,
  balloons,
  askAge,
  seven,
  chooseSeven,
  buildAnswer,
  reward,
}

class _GradeTwoUnitOneLessonTwoBirthdayFlow extends StatefulWidget {
  final VoidCallback onExit;
  final void Function(int index, bool correct) onQuizAttempt;
  final ValueChanged<int> onQuizCorrect;

  const _GradeTwoUnitOneLessonTwoBirthdayFlow({
    required this.onExit,
    required this.onQuizAttempt,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeTwoUnitOneLessonTwoBirthdayFlow> createState() =>
      _GradeTwoUnitOneLessonTwoBirthdayFlowState();
}

class _GradeTwoUnitOneLessonTwoBirthdayFlowState
    extends State<_GradeTwoUnitOneLessonTwoBirthdayFlow> {
  static const _voiceBase = 'audio/VO-final/grade2';
  static const _anaAsset =
      'assets/images/level_game/grade2/people/Tudlo_Ana_Full_Body_Character.svg';
  static const _anaCelebrateAsset =
      'assets/images/level_game/grade2/people/Tudlo_Ana_Celebrating_Age_Seven.svg';
  static const _backgroundAsset =
      'assets/images/level_game/grade2/backgrounds/Tudlo_G2_U1_L1.2_Birthday_Living_Room_Background.svg';
  static const _activityBackgroundAsset = _g2BirthdayWithoutAnaBackground;
  static const _answerOrder = ['i_am', 'seven_years_old'];

  _G2BirthdayStep _step = _G2BirthdayStep.invitation;
  bool _voicePlaying = false;
  bool _invitationOpened = false;
  final Set<int> _revealedBalloons = {};
  String? _selectedAgeId;
  String? _wrongAgeId;
  String? _wrongTileId;
  bool _completed = false;
  final List<String?> _answerSlots = List<String?>.filled(2, null);

  double get _progress =>
      (_G2BirthdayStep.values.indexOf(_step) + 1) /
      _G2BirthdayStep.values.length;

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

  void _goToStep(_G2BirthdayStep step) {
    if (_step == step) return;
    unawaited(TudloVoiceButton.stop());
    setState(() {
      _step = step;
      _selectedAgeId = null;
      _wrongAgeId = null;
      _wrongTileId = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _speakForStep();
    });
  }

  Future<void> _playVoice(List<int> clips) async {
    await TudloVoiceButton.stop();
    await AppAudioService.instance.lowerBackgroundVolume();
    await AppAudioService.instance.playVoiceAssets([
      for (final clip in clips) '$_voiceBase/Gr_2_Les_1_2_$clip.wav',
    ]);
    await AppAudioService.instance.restoreBackgroundVolume();
  }

  Future<void> _speakForStep() async {
    final clips = switch (_step) {
      _G2BirthdayStep.invitation => const [2],
      _G2BirthdayStep.map => const [3],
      _G2BirthdayStep.balloons => const [4],
      _G2BirthdayStep.askAge => const [5, 6],
      _G2BirthdayStep.seven => const [7],
      _G2BirthdayStep.chooseSeven => const [8, 9],
      _G2BirthdayStep.buildAnswer => const [12, 13],
      _G2BirthdayStep.reward => const [16],
    };
    setState(() => _voicePlaying = true);
    try {
      await _playVoice(clips);
    } catch (_) {
      if (!mounted) return;
      await TudloVoiceButton.speak(
        context,
        switch (_step) {
          _G2BirthdayStep.invitation => 'May birthday invitation si Ana!',
          _G2BirthdayStep.map => 'I-tap ang Balay ni Koka.',
          _G2BirthdayStep.balloons => 'May mga balloon!',
          _G2BirthdayStep.askAge => 'How old are you?',
          _G2BirthdayStep.seven => 'Seven years old si Ana.',
          _G2BirthdayStep.chooseSeven => 'Pilia ang 7.',
          _G2BirthdayStep.buildAnswer => 'Ihan-ay: I am seven years old.',
          _G2BirthdayStep.reward => 'Makasiling ka na sang imo edad!',
        },
        hiligaynon: true,
        waitForCompletion: true,
      );
    } finally {
      await AppAudioService.instance.restoreBackgroundVolume();
      if (mounted) setState(() => _voicePlaying = false);
    }
  }

  Future<void> _openInvitation() async {
    if (_voicePlaying || _invitationOpened) return;
    setState(() => _invitationOpened = true);
    await AppAudioService.instance.playCorrect();
    await Future<void>.delayed(const Duration(milliseconds: 480));
    if (mounted) _goToStep(_G2BirthdayStep.map);
  }

  Future<void> _revealBalloon(int number) async {
    if (_voicePlaying || _revealedBalloons.contains(number)) return;
    setState(() => _revealedBalloons.add(number));
    await AppAudioService.instance.playTap();
    if (_revealedBalloons.length >= 4) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) _goToStep(_G2BirthdayStep.askAge);
    }
  }

  Future<void> _hearQuestion() async {
    if (_voicePlaying) return;
    await _playVoice(const [6]);
    if (mounted) _goToStep(_G2BirthdayStep.seven);
  }

  Future<void> _chooseAge(_G2FriendChoice choice) async {
    if (_voicePlaying || _selectedAgeId != null) return;
    final correct = choice.id == 'age_7';
    widget.onQuizAttempt(0, correct);
    setState(() {
      _selectedAgeId = choice.id;
      _wrongAgeId = correct ? null : choice.id;
    });
    if (!correct) {
      await AppAudioService.instance.playWrong();
      await _playVoice(const [11]);
      await Future<void>.delayed(const Duration(milliseconds: 430));
      if (!mounted) return;
      setState(() {
        _selectedAgeId = null;
        _wrongAgeId = null;
      });
      return;
    }
    widget.onQuizCorrect(0);
    await AppAudioService.instance.playCorrect();
    await _playVoice(const [10]);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (mounted) _goToStep(_G2BirthdayStep.buildAnswer);
  }

  Future<void> _placeAnswerTile(String tileId, int slotIndex) async {
    if (_voicePlaying || _answerSlots.contains(tileId)) return;
    setState(() => _answerSlots[slotIndex] = tileId);
    await AppAudioService.instance.playTap();
    if (_answerSlots.any((slot) => slot == null)) return;
    final correct = List.generate(
      _answerOrder.length,
      (index) => _answerSlots[index] == _answerOrder[index],
    ).every((match) => match);
    widget.onQuizAttempt(1, correct);
    if (!correct) {
      final wrongIds = <String>{
        for (var index = 0; index < _answerOrder.length; index++)
          if (_answerSlots[index] != _answerOrder[index]) _answerSlots[index]!,
      };
      setState(() => _wrongTileId = wrongIds.first);
      await AppAudioService.instance.playWrong();
      await _playVoice(const [19]);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      setState(() {
        for (var index = 0; index < _answerSlots.length; index++) {
          if (_answerSlots[index] != _answerOrder[index]) {
            _answerSlots[index] = null;
          }
        }
        _wrongTileId = null;
      });
      return;
    }
    widget.onQuizCorrect(1);
    await AppAudioService.instance.playCorrect();
    await _playVoice(const [15, 17]);
    await Future<void>.delayed(_lessonCompletionHold);
    if (mounted) _goToStep(_G2BirthdayStep.reward);
  }

  Future<void> _tapAnswerTile(String tileId) async {
    final slotIndex = _answerSlots.indexWhere((slot) => slot == null);
    if (slotIndex == -1) return;
    await _placeAnswerTile(tileId, slotIndex);
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
        key: ValueKey('g2-u1-l2-$_step'),
        child: switch (_step) {
          _G2BirthdayStep.invitation => _G2BirthdayInvitationStep(
            progress: _progress,
            backgroundAsset: _backgroundAsset,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onOpen: _openInvitation,
          ),
          _G2BirthdayStep.map => _G2BirthdayMapStep(
            progress: _progress,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(_G2BirthdayStep.balloons),
          ),
          _G2BirthdayStep.balloons => _G2BirthdayBalloonsStep(
            progress: _progress,
            backgroundAsset: _activityBackgroundAsset,
            revealed: _revealedBalloons,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onReveal: _revealBalloon,
          ),
          _G2BirthdayStep.askAge => _G2BirthdayAskAgeStep(
            progress: _progress,
            backgroundAsset: _activityBackgroundAsset,
            anaAsset: _anaAsset,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onQuestion: _hearQuestion,
          ),
          _G2BirthdayStep.seven => _G2BirthdaySevenStep(
            progress: _progress,
            backgroundAsset: _activityBackgroundAsset,
            anaAsset: _anaCelebrateAsset,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(_G2BirthdayStep.chooseSeven),
          ),
          _G2BirthdayStep.chooseSeven => _G2BirthdayChooseSevenStep(
            progress: _progress,
            backgroundAsset: _activityBackgroundAsset,
            selectedId: _selectedAgeId,
            wrongId: _wrongAgeId,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onChoose: _chooseAge,
          ),
          _G2BirthdayStep.buildAnswer => _G2BirthdayBuildAnswerStep(
            progress: _progress,
            backgroundAsset: _activityBackgroundAsset,
            anaAsset: _anaCelebrateAsset,
            slots: _answerSlots,
            wrongTileId: _wrongTileId,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onPlace: _placeAnswerTile,
            onTapTile: _tapAnswerTile,
          ),
          _G2BirthdayStep.reward => _G2BirthdayRewardStep(
            progress: _progress,
            backgroundAsset: _activityBackgroundAsset,
            anaAsset: _anaCelebrateAsset,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onDone: _finish,
          ),
        },
      ),
    );
  }
}

class _G2BirthdayInvitationStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function() onOpen;

  const _G2BirthdayInvitationStep({
    required this.progress,
    required this.backgroundAsset,
    required this.inputReady,
    required this.onExit,
    required this.onReplay,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: backgroundAsset,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .07,
          view.height * .15,
          view.width * .07,
          view.height * .045,
        ),
        child: Column(
          children: [
            const Spacer(),
            _LessonKokaMascot(
              size: (view.width * .48).clamp(170.0, 250.0),
              mood: KokaMood.idle,
            ),
            SizedBox(height: view.height * .02),
            GestureDetector(
              onTap: inputReady ? () => unawaited(onOpen()) : null,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: view.width * .58,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3B8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: TudloColors.gold, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: TudloColors.gold.withValues(alpha: .35),
                          blurRadius: 22,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Text(
                      'Happy Birthday\nAna!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: TudloColors.blue,
                        fontSize: (view.width * .075).clamp(26.0, 38.0),
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  if (inputReady)
                    Positioned(
                      right: -view.width * .08,
                      bottom: -view.height * .025,
                      child: const _FamilyTapCue(),
                    ),
                ],
              ),
            ),
            const Spacer(),
            const _LessonOneMessageCard(
              message: 'May birthday invitation si Ana!',
            ),
            SizedBox(height: view.height * .02),
            _LessonOneBlueButton(
              label: 'Sige',
              onTap: inputReady ? () => unawaited(onOpen()) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _G2BirthdayMapStep extends StatefulWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _G2BirthdayMapStep({
    required this.progress,
    required this.onExit,
    required this.onReplay,
    required this.onNext,
  });

  @override
  State<_G2BirthdayMapStep> createState() => _G2BirthdayMapStepState();
}

class _G2BirthdayMapStepState extends State<_G2BirthdayMapStep>
    with SingleTickerProviderStateMixin {
  late final TransformationController _controller;
  late final AnimationController _zoomController;
  Animation<Matrix4>? _zoomAnimation;
  Size? _lastView;
  bool _selected = false;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    _zoomController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 900),
        )..addListener(() {
          final animation = _zoomAnimation;
          if (animation != null) _controller.value = animation.value;
        });
  }

  @override
  void dispose() {
    _zoomController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _focusHouse(Size view) {
    if (_lastView == view) return;
    _lastView = view;
    final target = Matrix4.identity()
      ..setEntry(0, 0, 1.28)
      ..setEntry(1, 1, 1.28)
      ..setEntry(0, 3, -view.width * .16)
      ..setEntry(1, 3, -view.height * .08);
    _zoomAnimation = Matrix4Tween(begin: Matrix4.identity(), end: target)
        .animate(
          CurvedAnimation(parent: _zoomController, curve: Curves.easeOutCubic),
        );
    _zoomController.forward(from: 0);
  }

  Future<void> _tapHouse() async {
    if (_selected) return;
    setState(() => _selected = true);
    await AppAudioService.instance.playCorrect();
    await Future<void>.delayed(const Duration(milliseconds: 360));
    if (mounted) widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusHouse(view);
    });
    final mapSize = Size(view.width * 1.48, view.height * 1.16);
    return _LessonOneChrome(
      progress: widget.progress,
      onExit: widget.onExit,
      onReplay: widget.onReplay,
      backgroundAsset: 'assets/images/level_game/backgrounds/tudlomap.svg',
      child: Stack(
        children: [
          InteractiveViewer(
            transformationController: _controller,
            minScale: .95,
            maxScale: 2.2,
            boundaryMargin: EdgeInsets.all(view.longestSide),
            panEnabled: true,
            scaleEnabled: true,
            constrained: false,
            child: SizedBox(
              width: mapSize.width,
              height: mapSize.height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const _LessonBackgroundAsset(
                    asset: 'assets/images/level_game/backgrounds/tudlomap.svg',
                  ),
                  Positioned(
                    left: mapSize.width * .53,
                    top: mapSize.height * .31,
                    width: mapSize.width * .22,
                    height: mapSize.width * .22,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _tapHouse,
                      child: const _LessonOneMapDestinationCue(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: view.width * .10,
            right: view.width * .10,
            bottom: view.height * .08,
            child: const _LessonOneMessageCard(
              message: 'I-tap ang Balay ni Koka.',
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _G2BirthdayBalloonsStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final Set<int> revealed;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function(int number) onReveal;

  const _G2BirthdayBalloonsStep({
    required this.progress,
    required this.backgroundAsset,
    required this.revealed,
    required this.inputReady,
    required this.onExit,
    required this.onReplay,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final balloons = [5, 6, 7, 8];
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: backgroundAsset,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .06,
          view.height * .14,
          view.width * .06,
          view.height * .04,
        ),
        child: Column(
          children: [
            const _LessonOneMessageCard(
              message: 'May mga balloon!',
              compact: true,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _LessonKokaMascot(
                  size: (view.width * .34).clamp(125.0, 180.0),
                  mood: KokaMood.idle,
                ),
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: view.width * .025,
                    runSpacing: view.height * .012,
                    children: [
                      for (final number in balloons)
                        _BirthdayBalloonCard(
                          number: number,
                          revealed: revealed.contains(number),
                          enabled: inputReady,
                          onTap: () => onReveal(number),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _BirthdayBalloonCard extends StatelessWidget {
  final int number;
  final bool revealed;
  final bool enabled;
  final VoidCallback onTap;

  const _BirthdayBalloonCard({
    required this.number,
    required this.revealed,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return GestureDetector(
      onTap: enabled && !revealed ? onTap : null,
      child: SizedBox(
        width: view.width * .18,
        height: view.height * .19,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _LessonPictureAsset(
              asset:
                  'assets/images/level_game/lesson-game-assets/Tudlo_Birthday_Balloon_$number.svg',
              fit: BoxFit.contain,
              errorBuilder: (_) => Icon(
                Icons.circle_rounded,
                color: TudloColors.coral,
                size: view.width * .16,
              ),
            ),
            Container(
              width: view.width * .085,
              height: view.width * .085,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: revealed ? .94 : .78),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                revealed ? '$number' : '?',
                style: GoogleFonts.nunito(
                  color: TudloColors.blue,
                  fontSize: (view.width * .07).clamp(22.0, 34.0),
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _G2BirthdayAskAgeStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final String anaAsset;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function() onQuestion;

  const _G2BirthdayAskAgeStep({
    required this.progress,
    required this.backgroundAsset,
    required this.anaAsset,
    required this.inputReady,
    required this.onExit,
    required this.onReplay,
    required this.onQuestion,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: backgroundAsset,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .06,
          view.height * .14,
          view.width * .06,
          view.height * .05,
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: inputReady ? () => unawaited(onQuestion()) : null,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  const _LessonOneMessageCard(
                    message: 'How old are you?',
                    compact: true,
                  ),
                  if (inputReady)
                    Positioned(
                      right: -view.width * .10,
                      bottom: -view.height * .02,
                      child: const _FamilyTapCue(),
                    ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _LessonKokaMascot(
                  size: (view.width * .42).clamp(150.0, 220.0),
                  mood: KokaMood.idle,
                ),
                const Spacer(),
                SizedBox(
                  width: view.width * .36,
                  height: view.height * .44,
                  child: _LessonPictureAsset(
                    asset: anaAsset,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const _LessonOneMessageCard(
              message: 'I-tap ang question bubble kag pamatii.',
              compact: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _G2BirthdaySevenStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final String anaAsset;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _G2BirthdaySevenStep({
    required this.progress,
    required this.backgroundAsset,
    required this.anaAsset,
    required this.inputReady,
    required this.onExit,
    required this.onReplay,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: backgroundAsset,
      child: Stack(
        children: [
          Positioned(
            left: view.width * .04,
            top: view.height * .20,
            width: view.width * .72,
            height: view.height * .48,
            child: Image.asset(
              'assets/images/level_game/numbers/7.png',
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            right: -view.width * .12,
            top: view.height * .30,
            width: view.width * .72,
            height: view.height * .43,
            child: _LessonPictureAsset(asset: anaAsset, fit: BoxFit.contain),
          ),
          Positioned(
            left: view.width * .08,
            right: view.width * .08,
            bottom: view.height * .125,
            child: const _LessonOneMessageCard(
              message: 'Seven years old si Ana.',
            ),
          ),
          Positioned(
            left: view.width * .08,
            right: view.width * .08,
            bottom: view.height * .035,
            child: _LessonOneBlueButton(
              label: 'Padayon',
              onTap: inputReady ? onNext : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _G2BirthdayChooseSevenStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final String? selectedId;
  final String? wrongId;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function(_G2FriendChoice choice) onChoose;

  const _G2BirthdayChooseSevenStep({
    required this.progress,
    required this.backgroundAsset,
    required this.selectedId,
    required this.wrongId,
    required this.inputReady,
    required this.onExit,
    required this.onReplay,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final choices = const [
      _G2FriendChoice('age_5', '5'),
      _G2FriendChoice('age_6', '6'),
      _G2FriendChoice('age_7', '7'),
      _G2FriendChoice('age_8', '8'),
    ];
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: backgroundAsset,
      child: Stack(
        children: [
          Positioned(
            left: view.width * .22,
            right: view.width * .22,
            top: view.height * .15,
            child: const _LessonOneMessageCard(
              message: 'Pilia ang 7.',
              compact: true,
            ),
          ),
          Positioned(
            left: view.width * .03,
            bottom: view.height * .095,
            child: _LessonKokaMascot(
              size: (view.width * .34).clamp(112.0, 168.0),
              mood: KokaMood.idle,
            ),
          ),
          Positioned(
            left: view.width * .16,
            right: view.width * .08,
            bottom: view.height * .15,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final choice in choices)
                  _BirthdayAgeChoiceBalloon(
                    choice: choice,
                    selected: selectedId == choice.id,
                    wrong: wrongId == choice.id,
                    enabled: inputReady && selectedId == null,
                    onTap: () => onChoose(choice),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BirthdayAgeChoiceBalloon extends StatelessWidget {
  final _G2FriendChoice choice;
  final bool selected;
  final bool wrong;
  final bool enabled;
  final VoidCallback onTap;

  const _BirthdayAgeChoiceBalloon({
    required this.choice,
    required this.selected,
    required this.wrong,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final number = choice.label;
    final view = MediaQuery.sizeOf(context);
    return _FeedbackMotion(
      correct: selected && choice.id == 'age_7',
      wrong: wrong,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          scale: selected ? 1.12 : 1,
          child: SizedBox(
            width: view.width * .17,
            height: view.height * .18,
            child: _LessonPictureAsset(
              asset:
                  'assets/images/level_game/lesson-game-assets/Tudlo_Birthday_Balloon_$number.svg',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _G2BirthdayBuildAnswerStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final String anaAsset;
  final List<String?> slots;
  final String? wrongTileId;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function(String tileId, int slotIndex) onPlace;
  final Future<void> Function(String tileId) onTapTile;

  const _G2BirthdayBuildAnswerStep({
    required this.progress,
    required this.backgroundAsset,
    required this.anaAsset,
    required this.slots,
    required this.wrongTileId,
    required this.inputReady,
    required this.onExit,
    required this.onReplay,
    required this.onPlace,
    required this.onTapTile,
  });

  static const _tiles = [
    _G2FriendChoice('seven_years_old', 'seven years old.'),
    _G2FriendChoice('i_am', 'I am'),
  ];

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: backgroundAsset,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .055,
          view.height * .13,
          view.width * .055,
          view.height * .04,
        ),
        child: Column(
          children: [
            const _LessonOneMessageCard(
              message: 'I am seven years old.',
              compact: true,
            ),
            SizedBox(height: view.height * .015),
            SizedBox(
              height: view.height * .24,
              child: _LessonPictureAsset(asset: anaAsset, fit: BoxFit.contain),
            ),
            _G2AgeAnswerTray(slots: slots, onPlace: onPlace),
            const Spacer(),
            Row(
              children: [
                for (final tile in _tiles)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: _G2AgeResponseTile(
                        tile: tile,
                        hidden: slots.contains(tile.id),
                        wrong: wrongTileId == tile.id,
                        enabled: inputReady,
                        onTap: () => onTapTile(tile.id),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _G2AgeAnswerTray extends StatelessWidget {
  final List<String?> slots;
  final Future<void> Function(String tileId, int slotIndex) onPlace;

  const _G2AgeAnswerTray({required this.slots, required this.onPlace});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .84),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TudloColors.green, width: 3),
      ),
      child: Row(
        children: [
          for (var index = 0; index < slots.length; index++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: DragTarget<String>(
                  onWillAcceptWithDetails: (_) => slots[index] == null,
                  onAcceptWithDetails: (details) {
                    unawaited(onPlace(details.data, index));
                  },
                  builder: (context, _, __) {
                    final label = _g2AgeAnswerTileLabel(slots[index]);
                    return Container(
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: label == null
                            ? Colors.white.withValues(alpha: .55)
                            : const Color(0xFFE5FFD5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: label == null
                              ? const Color(0xFFB8B8B8)
                              : TudloColors.green,
                          width: 2.5,
                        ),
                      ),
                      child: Text(
                        label ?? '',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: TudloColors.blue,
                          fontSize: 17,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _G2AgeResponseTile extends StatelessWidget {
  final _G2FriendChoice tile;
  final bool hidden;
  final bool wrong;
  final bool enabled;
  final VoidCallback onTap;

  const _G2AgeResponseTile({
    required this.tile,
    required this.hidden,
    required this.wrong,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = _FeedbackMotion(
      correct: false,
      wrong: wrong,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: hidden ? .24 : 1,
        child: GestureDetector(
          onTap: enabled && !hidden ? onTap : null,
          child: Container(
            height: 70,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: wrong ? TudloColors.coral : TudloColors.blue,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: TudloColors.blue.withValues(alpha: .18),
                  blurRadius: 0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              tile.label,
              textAlign: TextAlign.center,
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
    if (hidden || !enabled) return child;
    return Draggable<String>(
      data: tile.id,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 170, child: child),
      ),
      childWhenDragging: Opacity(opacity: .35, child: child),
      child: child,
    );
  }
}

class _G2BirthdayRewardStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final String anaAsset;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onDone;

  const _G2BirthdayRewardStep({
    required this.progress,
    required this.backgroundAsset,
    required this.anaAsset,
    required this.onExit,
    required this.onReplay,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: backgroundAsset,
      child: _StickerUnlockRewardContent(
        fallback: const _FamilyReferenceBadge(label: 'ABYAN\n2'),
        message: 'Makasiling ka na sang imo edad!',
        onDone: onDone,
      ),
    );
  }
}

String? _g2AgeAnswerTileLabel(String? id) {
  return switch (id) {
    'i_am' => 'I am',
    'seven_years_old' => 'seven years old.',
    _ => null,
  };
}
