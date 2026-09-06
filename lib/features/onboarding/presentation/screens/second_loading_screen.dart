import 'dart:async';

import 'package:flutter/material.dart';

import 'package:tudlo/core/navigation/fade_page_route.dart';
import 'package:tudlo/core/theme/app_colors.dart';
import 'package:tudlo/features/onboarding/presentation/screens/learner_card_screen.dart';

class SecondLoadingScreen extends StatefulWidget {
  const SecondLoadingScreen({
    required this.learnerName,
    required this.grade,
    required this.energy,
    this.minimumDisplayDuration = const Duration(seconds: 5),
    this.prepareNextStage,
    super.key,
  });

  final String learnerName;
  final int grade;
  final int energy;
  final Duration minimumDisplayDuration;
  final Future<void> Function()? prepareNextStage;

  @override
  State<SecondLoadingScreen> createState() => _SecondLoadingScreenState();
}

class _SecondLoadingScreenState extends State<SecondLoadingScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_prepareAndContinue());
  }

  Future<void> _prepareAndContinue() async {
    await Future.wait<void>([
      Future<void>.delayed(widget.minimumDisplayDuration),
      widget.prepareNextStage?.call() ?? _warmNextStageAssets(),
    ]);
    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      FadePageRoute<void>(
        page: LearnerCardScreen(
          learnerName: widget.learnerName,
          grade: widget.grade,
          energy: widget.energy,
        ),
      ),
    );
  }

  Future<void> _warmNextStageAssets() async {
    final kokaAsset = switch (widget.grade) {
      2 => 'assets/images/koka_blue.png',
      3 => 'assets/images/koka_red.png',
      _ => 'assets/images/koka_green.png',
    };
    final assets = <String>[
      'assets/images/learner_card_earned.png',
      kokaAsset,
      for (var badge = 1; badge <= 8; badge++) 'assets/images/badge_$badge.png',
    ];
    await Future.wait<void>(
      assets.map((asset) => precacheImage(AssetImage(asset), context)),
    );
    await WidgetsBinding.instance.endOfFrame;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColoredBox(
        color: AppColors.mint,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // The source PNG has transparent padding. A 125 px frame gives
              // its visible artwork the same scale as the 116 px first logo.
              final artworkWidth =
                  (constraints.maxWidth * 125 / 412).clamp(99.0, 172.0);
              return Center(
                child: Semantics(
                  label: 'Koka second loading screen',
                  image: true,
                  child: SizedBox(
                    key: const Key('second-loading-artwork-frame'),
                    width: artworkWidth,
                    child: const Image(
                      image: AssetImage(
                        'assets/images/second_loading_koka.png',
                      ),
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
