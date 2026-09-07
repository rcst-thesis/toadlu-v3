import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tudlo/core/navigation/fade_page_route.dart';
import 'package:tudlo/core/theme/app_colors.dart';
import 'package:tudlo/features/placeholder/presentation/placeholder_screen.dart';

class HomeLoadingScreen extends StatefulWidget {
  const HomeLoadingScreen({
    required this.learnerName,
    required this.grade,
    required this.energy,
    this.minimumDisplayDuration = const Duration(seconds: 5),
    this.preparationTimeout = const Duration(seconds: 30),
    this.prepareHome,
    this.homeBuilder,
    super.key,
  });

  final String learnerName;
  final int grade;
  final int energy;
  final Duration minimumDisplayDuration;
  final Duration preparationTimeout;
  final Future<void> Function()? prepareHome;
  final WidgetBuilder? homeBuilder;

  @override
  State<HomeLoadingScreen> createState() => _HomeLoadingScreenState();
}

class _HomeLoadingScreenState extends State<HomeLoadingScreen> {
  static const _loadingLabels = <String>[
    'Hopping in...',
    'Packing lessons...',
    'Almost ready...',
  ];

  static const _onboardingAssets = <String>[
    'assets/images/maral_loading_logo.png',
    'assets/images/loading_logo.png',
    'assets/images/main_menu_reference.png',
    'assets/images/onboarding_footer.png',
    'assets/images/onboarding_logo.png',
    'assets/images/load_logo.png',
    'assets/images/toadlu_icon.png',
    'assets/images/koka_green.png',
    'assets/images/koka_blue.png',
    'assets/images/koka_red.png',
    'assets/images/name_character.png',
    'assets/images/grade_1_header.png',
    'assets/images/grade_2_header.png',
    'assets/images/grade_3_header.png',
    'assets/images/energy_instructions.png',
    'assets/images/energy_heading.png',
    'assets/images/energy_bubble_label.png',
    'assets/images/second_loading_koka.png',
    'assets/images/learner_card_earned.png',
    'assets/images/badge_1.png',
    'assets/images/badge_2.png',
    'assets/images/badge_3.png',
    'assets/images/badge_4.png',
    'assets/images/badge_5.png',
    'assets/images/badge_6.png',
    'assets/images/badge_7.png',
    'assets/images/badge_8.png',
  ];

  bool _started = false;
  bool _preparing = false;
  Object? _preparationError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_prepareAndContinue());
  }

  Future<void> _prepareAndContinue() async {
    if (_preparing) return;
    setState(() {
      _preparing = true;
      _preparationError = null;
    });
    try {
      await Future.wait<void>([
        Future<void>.delayed(widget.minimumDisplayDuration),
        _prepareHomeResources().timeout(widget.preparationTimeout),
      ]);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        FadePageRoute<void>(page: _buildHome(context)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _preparing = false;
        _preparationError = error;
      });
    }
  }

  Future<void> _prepareHomeResources() async {
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await _releaseOnboardingAssets();
    await (widget.prepareHome?.call() ?? _waitForNextFrame());
  }

  Future<void> _releaseOnboardingAssets() async {
    for (final asset in _onboardingAssets) {
      await AssetImage(asset).evict();
    }
  }

  Future<void> _waitForNextFrame() async {
    await WidgetsBinding.instance.endOfFrame;
  }

  Widget _buildHome(BuildContext context) {
    if (widget.homeBuilder case final builder?) return builder(context);
    return const PlaceholderScreen(
      title: 'home screen',
      description: 'The Tudlo home experience will appear here.',
      icon: Icons.home_rounded,
      showBackButton: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColoredBox(
        color: AppColors.mint,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Match the complete visible composition (including the baked
              // label) to the roughly 85-90 px width of Loading 1 and 2.
              final artworkWidth =
                  (constraints.maxWidth * 104 / 412).clamp(52.0, 104.0);
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      key: const Key('home-loading-artwork-frame'),
                      width: artworkWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Semantics(
                            label: 'Koka third loading screen',
                            image: true,
                            child: FractionallySizedBox(
                              widthFactor: 0.73,
                              child: Image.asset(
                                'assets/images/koka_blue_2_loading.png',
                                key: const Key('home-loading-koka'),
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                excludeFromSemantics: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          const _WaveLoadingLabel(labels: _loadingLabels),
                        ],
                      ),
                    ),
                    if (_preparationError != null) ...[
                      const SizedBox(height: 18),
                      const Text(
                        'wala natapos ang paghanda',
                        key: Key('home-loading-error'),
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        key: const Key('home-loading-retry-button'),
                        onPressed: _prepareAndContinue,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('try liwat'),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WaveLoadingLabel extends StatefulWidget {
  const _WaveLoadingLabel({required this.labels});

  final List<String> labels;

  @override
  State<_WaveLoadingLabel> createState() => _WaveLoadingLabelState();
}

class _WaveLoadingLabelState extends State<_WaveLoadingLabel>
    with TickerProviderStateMixin {
  late final AnimationController _waveController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();
  late final AnimationController _labelController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2150),
  )
    ..addStatusListener(_handleAnimationStatus)
    ..forward();

  int _labelIndex = 0;

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() => _labelIndex = (_labelIndex + 1) % widget.labels.length);
    _labelController.forward(from: 0);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final label = widget.labels[_labelIndex];
    final metrics = TextPainter(
      text: TextSpan(text: label, style: _WaveLabelPainter.textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    return Semantics(
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: SizedBox(
            key: const Key('home-loading-label'),
            height: 22,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: CustomPaint(
                size: Size(metrics.width, 22),
                painter: _WaveLabelPainter(
                  label: label,
                  waveAnimation: _waveController,
                  labelAnimation: _labelController,
                  animate: !reduceMotion,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WaveLabelPainter extends CustomPainter {
  _WaveLabelPainter({
    required this.label,
    required this.waveAnimation,
    required this.labelAnimation,
    required this.animate,
  }) : super(
          repaint: animate
              ? Listenable.merge([waveAnimation, labelAnimation])
              : null,
        ) {
    _textPainter = TextPainter(
      text: TextSpan(text: label, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    _characterEdges = [
      for (var index = 0; index <= label.length; index++)
        _textPainter
            .getOffsetForCaret(
              TextPosition(offset: index),
              Rect.zero,
            )
            .dx,
    ];
  }

  static const textStyle = TextStyle(
    color: Colors.black,
    fontSize: 15,
    height: 1,
    fontWeight: FontWeight.w700,
  );

  final String label;
  final Animation<double> waveAnimation;
  final Animation<double> labelAnimation;
  final bool animate;
  late final TextPainter _textPainter;
  late final List<double> _characterEdges;

  @override
  void paint(Canvas canvas, Size size) {
    final waveProgress = animate ? waveAnimation.value : 0.5;
    final labelProgress = animate ? labelAnimation.value : 0.5;
    final opacity = switch (labelProgress) {
      < 0.16 => Curves.easeInOutSine.transform(labelProgress / 0.16),
      > 0.84 =>
        1 - Curves.easeInOutSine.transform((labelProgress - 0.84) / 0.16),
      _ => 1.0,
    };
    canvas.saveLayer(
      Offset.zero & size,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    final textTop = (size.height - _textPainter.height) / 2;
    for (var index = 0; index < label.length; index++) {
      final left = _characterEdges[index];
      final right = _characterEdges[index + 1];
      if (right <= left) continue;
      final y = animate
          ? math.sin((waveProgress * math.pi * 2) - (index * 0.42)) * 1.65
          : 0.0;
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(left - 0.5, 0, right + 0.5, size.height));
      _textPainter.paint(canvas, Offset.zero.translate(0, textTop + y));
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WaveLabelPainter oldDelegate) {
    return oldDelegate.label != label || oldDelegate.animate != animate;
  }
}
