import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/language_toggle.dart';
import 'package:tudloapp/core/widgets/mascot_widget.dart';
import 'package:tudloapp/features/navigation/app_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _controller;
  int _pageIndex = 0;
  String? _lastNarrationKey;

  static const _pages = [
    _TudloOnboardingPageData(
      hiligaynonTitle: 'Tuon sang Hiligaynon',
      englishTitle: 'Learn Hiligaynon',
      hiligaynonDescription:
          'Magtuon sang Hiligaynon paagi sa leksiyon, estorya, ehemplo, kag lingaw nga buluhaton.',
      englishDescription:
          'Learn Hiligaynon through fun lessons, stories, examples, and interactive activities.',
      hiligaynonVoice:
          'Maayong pag-abot, abyan! Diri makatuon kita sang Hiligaynon paagi sa sari-sari nga leksiyon, istorya, mga ehemplo, kag kaliliagaw nga mga buluhaton!',
      englishVoice:
          'Welcome to Tudlo! Here, you can learn Hiligaynon through lessons, stories, examples, and fun activities. Let us start learning!',
      color: TudloColors.green,
      accent: TudloColors.gold,
    ),
    _TudloOnboardingPageData(
      hiligaynonTitle: 'Tinaga',
      englishTitle: 'Dictionary',
      hiligaynonDescription:
          'Mangita sang Hiligaynon kag English nga tinaga kag pamatii ang ila paglitok.',
      englishDescription:
          'Search Hiligaynon and English words anytime. Listen to pronunciation and discover new words.',
      hiligaynonVoice:
          'Diri, puwede ka man makapangita sang mga tinaga nga gusto mo mahibaluan kag kon ano ang ila kahulugan.',
      englishVoice:
          'You can search for words in Hiligaynon and English. Listen to their correct pronunciation and discover new words every day.',
      color: TudloColors.blue,
      accent: TudloColors.softGreen,
    ),
    _TudloOnboardingPageData(
      hiligaynonTitle: 'Hubad',
      englishTitle: 'Translate',
      hiligaynonDescription:
          'Ihubad ang tinaga kag simple nga pangungusap sa Hiligaynon kag English.',
      englishDescription:
          'Translate words and simple sentences between Hiligaynon and English.',
      hiligaynonVoice:
          'Puwede mo man diri mahubad ang imo mga tinaga halin sa Hiligaynon pakadto sa English, ukon halin sa English pakadto sa Hiligaynon.',
      englishVoice:
          'You can translate words and simple sentences from Hiligaynon to English, and from English to Hiligaynon anytime.',
      color: TudloColors.coral,
      accent: TudloColors.sky,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    unawaited(TudloVoiceButton.stop());
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleNarrationIfNeeded();
  }

  Future<void> _finish() async {
    final appState = AppStateScope.of(context);
    await TudloVoiceButton.stop();
    await appState.markOnboardingSeen();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AppShell(initialIndex: 0)),
      (_) => false,
    );
  }

  void _next() {
    if (_pageIndex >= _pages.length - 1) {
      _finish();
      return;
    }
    final nextIndex = _pageIndex + 1;
    unawaited(_playNarrationForPage(nextIndex, force: true));
    _controller.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  void _scheduleNarrationIfNeeded() {
    final appState = AppStateScope.of(context);
    final key = '$_pageIndex-${appState.appLanguage}';
    if (_lastNarrationKey == key) return;
    final pageIndex = _pageIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pageIndex != pageIndex) return;
      unawaited(_playNarrationForPage(pageIndex));
    });
  }

  Future<void> _playNarrationForPage(int index, {bool force = false}) {
    if (index < 0 || index >= _pages.length) return Future.value();
    final appState = AppStateScope.of(context);
    final key = '$index-${appState.appLanguage}';
    if (!force && _lastNarrationKey == key) return Future.value();
    _lastNarrationKey = key;
    final activePage = _pages[index];
    return TudloVoiceButton.speak(
      context,
      activePage.hiligaynonVoice,
      hiligaynon: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isHiligaynon = appState.isHiligaynon;
    final activePage = _pages[_pageIndex];
    return Scaffold(
      backgroundColor: TudloColors.paper,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 700;
            return Padding(
              padding: EdgeInsets.fromLTRB(22, compact ? 12 : 18, 22, 22),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Row(
                      children: [
                        const TudloLanguageToggle(),
                        const Spacer(),
                        TextButton(
                          onPressed: _finish,
                          child: Text(
                            isHiligaynon ? 'Laktawan' : 'Skip',
                            style: GoogleFonts.nunito(
                              color: TudloColors.muted,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _pages.length,
                      onPageChanged: (value) {
                        setState(() => _pageIndex = value);
                        _scheduleNarrationIfNeeded();
                      },
                      itemBuilder: (context, index) {
                        return _TudloOnboardingPage(
                          data: _pages[index],
                          compact: compact,
                          hiligaynon: isHiligaynon,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  _OnboardingDots(
                    count: _pages.length,
                    activeIndex: _pageIndex,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: compact ? 56 : 64,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activePage.color,
                        foregroundColor: Colors.white,
                        shadowColor: activePage.color.withValues(alpha: .35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        textStyle: GoogleFonts.nunito(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      child: Text(
                        _pageIndex == _pages.length - 1
                            ? isHiligaynon
                                  ? 'Umpisahan ta na'
                                  : 'Start Learning'
                            : isHiligaynon
                            ? 'Padayon'
                            : 'Continue',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TudloOnboardingPage extends StatelessWidget {
  final _TudloOnboardingPageData data;
  final bool compact;
  final bool hiligaynon;

  const _TudloOnboardingPage({
    required this.data,
    required this.compact,
    required this.hiligaynon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: EdgeInsets.fromLTRB(24, compact ? 22 : 30, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: TudloColors.green.withValues(alpha: .10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: TudloMascot(
                size: compact ? 210 : 270,
                mood: KokaMood.idle,
              ),
            ),
          ),
          Text(
            data.titleText(hiligaynon),
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: compact ? 36 : 42,
              height: 1.02,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            data.descriptionText(hiligaynon),
            textAlign: TextAlign.center,
            maxLines: compact ? 5 : 6,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              color: TudloColors.muted,
              fontSize: compact ? 20 : 23,
              height: 1.20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingDots extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _OnboardingDots({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: index == activeIndex ? 30 : 11,
            height: 11,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: index == activeIndex
                  ? TudloColors.green
                  : TudloColors.line,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

class _TudloOnboardingPageData {
  final String hiligaynonTitle;
  final String englishTitle;
  final String hiligaynonDescription;
  final String englishDescription;
  final String hiligaynonVoice;
  final String englishVoice;
  final Color color;
  final Color accent;

  const _TudloOnboardingPageData({
    required this.hiligaynonTitle,
    required this.englishTitle,
    required this.hiligaynonDescription,
    required this.englishDescription,
    required this.hiligaynonVoice,
    required this.englishVoice,
    required this.color,
    required this.accent,
  });

  String titleText(bool hiligaynon) =>
      hiligaynon ? hiligaynonTitle : englishTitle;

  String descriptionText(bool hiligaynon) =>
      hiligaynon ? hiligaynonDescription : englishDescription;

  String voiceText(bool hiligaynon) =>
      hiligaynon ? hiligaynonVoice : englishVoice;
}
