import 'dart:async';

import 'package:flutter/material.dart';

import 'package:tudlo/core/theme/app_colors.dart';
import 'package:tudlo/features/main_menu/presentation/main_menu_screen.dart';

class StartupFlow extends StatefulWidget {
  const StartupFlow({
    this.splashDuration = const Duration(seconds: 5),
    this.splashWarmup,
    this.assetWarmup,
    super.key,
  });

  final Duration splashDuration;
  final Future<void> Function()? splashWarmup;
  final Future<void> Function()? assetWarmup;

  @override
  State<StartupFlow> createState() => _StartupFlowState();
}

class _StartupFlowState extends State<StartupFlow> {
  int _stage = 0;
  bool _running = false;
  Object? _startupError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_runStartup());
    });
  }

  Future<void> _runStartup() async {
    if (_running) return;
    _running = true;
    try {
      // Maral remains visible for the full minimum duration while the next
      // splash is decoded into Flutter's image cache.
      await Future.wait<void>([
        Future<void>.delayed(widget.splashDuration),
        widget.splashWarmup?.call() ??
            precacheImage(
              const AssetImage('assets/images/loading_logo.png'),
              context,
            ),
      ]);
      if (!mounted) return;
      setState(() => _stage = 1);

      // Tudlo remains visible for at least five seconds. It stays on screen
      // longer when the Main Menu's immediate artwork is not ready yet.
      final minimumDisplay = Future<void>.delayed(widget.splashDuration);
      final assetWarmup = widget.assetWarmup?.call() ?? _precacheMenuAssets();
      await Future.wait<void>([minimumDisplay, assetWarmup]);
      if (!mounted) return;
      setState(() => _stage = 2);
    } catch (error) {
      if (!mounted) return;
      setState(() => _startupError = error);
    } finally {
      _running = false;
    }
  }

  Future<void> _precacheMenuAssets() async {
    // Later screens own their load boundaries; do not retain onboarding art
    // at app launch when the Main Menu is the only immediate destination.
    const assets = <String>[
      'assets/images/main_menu_reference.png',
      'assets/images/onboarding_footer.png',
      'assets/images/onboarding_logo.png',
    ];
    await Future.wait<void>(
      assets.map((asset) => precacheImage(AssetImage(asset), context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_startupError != null) {
      return ColoredBox(
        color: AppColors.mint,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('wala natapos ang paghanda'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _stage = 0;
                    _startupError = null;
                  });
                  unawaited(_runStartup());
                },
                child: const Text('try liwat'),
              ),
            ],
          ),
        ),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 550),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: switch (_stage) {
        0 => const SplashImage(
            key: ValueKey('maral'),
            asset: 'assets/images/maral_loading_logo.png',
            backgroundColor: AppColors.charcoal,
            semanticLabel: 'Maral MT splash screen',
            designWidth: 224,
            maximumWidth: 280,
          ),
        1 => const SplashImage(
            key: ValueKey('tudlo'),
            asset: 'assets/images/loading_logo.png',
            backgroundColor: AppColors.mint,
            semanticLabel: 'Tudlo splash screen',
            designWidth: 116,
          ),
        _ => const MainMenuScreen(key: ValueKey('menu')),
      },
    );
  }
}

class SplashImage extends StatelessWidget {
  const SplashImage({
    required this.asset,
    required this.backgroundColor,
    required this.semanticLabel,
    this.designWidth,
    this.maximumWidth = 160,
    super.key,
  });

  final String asset;
  final Color backgroundColor;
  final String semanticLabel;
  final double? designWidth;
  final double maximumWidth;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final targetWidth = designWidth == null
              ? constraints.maxWidth
              : (constraints.maxWidth * designWidth! / 412)
                  .clamp(92.0, maximumWidth);
          return Center(
            child: SizedBox(
              width: targetWidth,
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                semanticLabel: semanticLabel,
              ),
            ),
          );
        },
      ),
    );
  }
}
