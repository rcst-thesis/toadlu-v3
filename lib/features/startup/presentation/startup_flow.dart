import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'package:tudlo/core/theme/app_colors.dart';
import 'package:tudlo/features/learner/domain/learner_scope.dart';
import 'package:tudlo/features/main_menu/presentation/main_menu_screen.dart';
import 'package:tudlo/features/settings/domain/app_settings.dart';
import 'package:tudlo/features/settings/domain/app_settings_scope.dart';
import 'package:tudlo/shared/widgets/sticker_press_button.dart';

class StartupFlow extends StatefulWidget {
  const StartupFlow({
    this.splashDuration = const Duration(seconds: 5),
    this.splashWarmup,
    this.assetWarmup,
    this.logoAudioDelay = const Duration(seconds: 2),
    this.logoAudioPlayer,
    this.backgroundMusicPlayer,
    super.key,
  });

  final Duration splashDuration;
  final Future<void> Function()? splashWarmup;
  final Future<void> Function()? assetWarmup;

  /// How far into the Maral splash the logo sting plays -- a production
  /// splash cue (think a studio ident's audio hit), not a UI sound effect.
  final Duration logoAudioDelay;

  /// Overridable for tests, same convention as [splashWarmup]/
  /// [assetWarmup] -- defaults to actually playing `assets/audio/
  /// maral_splash.wav` via `flutter_soloud`, a real mixing engine (proper
  /// resampling, float-based gain) rather than a thin platform-player
  /// wrapper -- `audioplayers` made this one-shot logo sting sound ragged
  /// on Windows regardless of player mode/preloading.
  final Future<void> Function()? logoAudioPlayer;

  /// Overridable for tests, same convention as [logoAudioPlayer] -- defaults
  /// to actually looping `assets/audio/background_music.wav` via the same
  /// `flutter_soloud` engine, starting the moment the Maral splash ends
  /// (see [_StartupFlowState._runStartup]'s stage 0 -> 1 transition).
  final Future<void> Function()? backgroundMusicPlayer;

  @override
  State<StartupFlow> createState() => _StartupFlowState();
}

class _StartupFlowState extends State<StartupFlow> {
  int _stage = 0;
  bool _running = false;
  Object? _startupError;

  // 2x unity -- SoLoud mixes in floating point and only clips at the final
  // output stage, so this is genuine amplification, not the naive PCM
  // sample-scaling that risks clipping/distortion when done by hand.
  static const _logoAudioVolume = 15.0;

  AudioSource? _logoAudioSource;
  Timer? _logoAudioTimer;

  // Memoized so `_preloadDefaultLogoAudio` and `_preloadBackgroundMusic`
  // (fired concurrently, both unawaited, from `initState`) share exactly
  // one `init()` call instead of each racing to call it independently.
  // `SoLoud.init()` "deinits + re-inits" when already initialized (see
  // `_preloadDefaultLogoAudio`'s own comment, for the hot-restart case) --
  // two genuinely concurrent calls to it would mean the second silently
  // tears down the engine state the first one just set up mid-flight,
  // breaking whichever `loadAsset`/`play` call was in flight on it.
  Future<void>? _soloudInit;

  Future<void> _ensureSoloudReady() {
    return _soloudInit ??= SoLoud.instance.init();
  }

  AudioSource? _bgMusicSource;
  SoundHandle? _bgMusicHandle;
  bool _bgMusicStarted = false;

  // The 25MB `background_music.wav` (copied to a temp file for
  // `LoadMode.disk` streaming) isn't guaranteed to finish loading within
  // the 5s default splash window the way the ~100KB logo sting reliably
  // does -- `_playDefaultBackgroundMusic` awaits this directly instead of
  // just checking `_bgMusicSource` once and silently giving up forever if
  // the preload hasn't finished yet.
  Future<void>? _bgMusicPreload;

  // Cached from the first `didChangeDependencies` -- `AppSettingsScope.of`/
  // `LearnerScope.of` each hand back a throwaway standalone controller (not
  // the shared one) when no real scope sits above this widget (e.g. a
  // widget test mounting `StartupFlow` inside a bare `MaterialApp`), so
  // calling `.of(context)` again later to remove a listener could target a
  // different instance than the one it was added to.
  AppSettingsController? _appSettingsController;
  LearnerController? _learnerController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_runStartup());
    });
    // Only ever meant for the Maral splash (stage 0) -- guarded at fire
    // time in case `splashDuration` (e.g. in a test) is shorter than
    // `logoAudioDelay` and stage 0 is already gone by then.
    _logoAudioTimer = Timer(widget.logoAudioDelay, _playLogoAudio);
    // Loading the asset into the engine now (there's a full 2s before it's
    // actually needed) means play() at trigger time just starts
    // already-decoded audio instead of decoding on demand.
    unawaited(_preloadDefaultLogoAudio());
    // Same reasoning, but this one is also actually awaited at play time
    // (see `_bgMusicPreload`'s own comment) rather than just hoping the
    // splash-duration runway is enough -- this file is ~250x bigger than
    // the logo sting.
    _bgMusicPreload = _preloadBackgroundMusic();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_appSettingsController == null) {
      _appSettingsController = AppSettingsScope.of(context)
        ..addListener(_onSettingsChanged);
      _learnerController = LearnerScope.of(context)
        ..addListener(_onSettingsChanged);
    }
  }

  Future<void> _preloadDefaultLogoAudio() async {
    try {
      // `SoLoud.instance` itself throws synchronously if the native
      // library isn't available (e.g. any widget test, since that runs on
      // the pure Dart VM with no bundled native plugin) -- accessing it
      // has to happen inside this try, not as an eagerly-evaluated field,
      // or it would crash the whole widget tree during construction.
      final soloud = SoLoud.instance;
      // Always call init() -- do NOT guard this with `if
      // (!soloud.isInitialized)`. On a hot *restart* the native engine
      // survives (only the Dart isolate resets), so this fresh `SoLoud`
      // object's `isInitialized` reads true immediately, even though
      // *this* object never ran its own native callback wiring. Skipping
      // init() then means loadAsset() awaits a completer that a callback
      // never resolves and hangs forever -- silently, since it's
      // unawaited -- which is exactly why the audio never played after a
      // hot restart. SoLoud's own init() already detects "already
      // initialized" and deinits + re-inits properly; let it -- but only
      // ever from one call site (`_ensureSoloudReady`), never two
      // concurrent ones.
      await _ensureSoloudReady();
      _logoAudioSource = await soloud.loadAsset(
        'assets/audio/maral_splash.wav',
      );
    } catch (_) {
      // Best-effort -- _playLogoAudio's own try/catch covers a failed
      // preload too, since _playDefaultLogoAudio would then simply have
      // no source to play.
    }
  }

  Future<void> _playLogoAudio() async {
    if (!mounted || _stage != 0) return;
    try {
      await (widget.logoAudioPlayer ?? _playDefaultLogoAudio)();
    } catch (_) {
      // Best-effort: a missing/unsupported audio backend (e.g. no native
      // SoLoud library registered in a widget test) shouldn't block or
      // crash the splash sequence over a sound effect.
    }
  }

  Future<void> _playDefaultLogoAudio() async {
    final source = _logoAudioSource;
    if (source == null) return;
    await SoLoud.instance.play(source, volume: _logoAudioVolume);
  }

  Future<void> _preloadBackgroundMusic() async {
    try {
      final soloud = SoLoud.instance;
      await _ensureSoloudReady();
      // `LoadMode.disk` streams from disk instead of fully decoding into
      // memory -- flutter_soloud's own docs recommend it specifically for
      // background music (unlike the short `maral_splash.wav` sting above,
      // which stays on the `LoadMode.memory` default), since this track
      // plays continuously for the whole session and there's no reason to
      // hold the whole file resident in RAM.
      _bgMusicSource = await soloud.loadAsset(
        'assets/audio/background_music.wav',
        mode: LoadMode.disk,
      );
    } catch (_) {
      // Best-effort -- _startBackgroundMusic's own try/catch covers a
      // failed preload too, since _playDefaultBackgroundMusic would then
      // simply have no source to play.
    }
  }

  /// Fires once, right after the Maral splash ends (see [_runStartup]'s
  /// stage 0 -> 1 transition) -- "starts right after the Maral logo
  /// splash" per the feature request.
  Future<void> _startBackgroundMusic() async {
    if (!mounted || _bgMusicStarted) return;
    _bgMusicStarted = true;
    try {
      await (widget.backgroundMusicPlayer ?? _playDefaultBackgroundMusic)();
    } catch (_) {
      // Best-effort: a missing/unsupported audio backend shouldn't block
      // or crash startup over background music.
    }
  }

  Future<void> _playDefaultBackgroundMusic() async {
    await _bgMusicPreload;
    await _syncBackgroundMusicWithSettings();
  }

  // Same reasoning/magnitude as `_logoAudioVolume` above -- SoLoud mixes in
  // floating point and only clips at the final output stage, so this is
  // genuine amplification, not naive PCM scaling. Confirmed empirically on
  // a real device: unity (1.0) was inaudible for this track, but a flat
  // 10.0 played back clearly. At the default 80/80 master/music volumes
  // this lands at 15 * 0.64 = 9.6, matching that confirmed-audible level.
  static const _bgMusicBaseVolume = 15.0;

  double _effectiveVolume(AppSettings settings) =>
      _bgMusicBaseVolume *
      (settings.masterVolume / 100) *
      (settings.musicVolume / 100);

  /// Starts, pauses, resumes, or re-volumes the loop to match whatever
  /// settings are currently effective -- called both right after the Maral
  /// splash and every time settings change live (the Settings screen's
  /// mute switch or either volume slider, or signing in/out swapping which
  /// settings apply).
  ///
  /// Deliberately never eagerly opens a *paused* stream while music starts
  /// out disabled: on Android, `play(..., paused: true)` still opens the
  /// underlying AAudio device stream, and that stream gets torn down again
  /// after a short idle period since nothing audible is happening on it --
  /// a stale [SoundHandle] left over from that can't just be un-paused
  /// afterward. Instead, `play()` is only ever called once music is
  /// actually enabled, and a `setPause`/`setVolume` on a handle that turns
  /// out to be stale falls back to a fresh `play()` rather than silently
  /// doing nothing.
  void _onSettingsChanged() => unawaited(_syncBackgroundMusicWithSettings());

  Future<void> _syncBackgroundMusicWithSettings() async {
    if (!mounted) return;
    final source = _bgMusicSource;
    if (source == null) return;
    final settings = effectiveAppSettings(context);
    final soloud = SoLoud.instance;
    try {
      if (!settings.musicEnabled) {
        final handle = _bgMusicHandle;
        if (handle != null) soloud.setPause(handle, true);
        return;
      }
      final volume = _effectiveVolume(settings);
      final handle = _bgMusicHandle;
      if (handle != null) {
        try {
          soloud.setPause(handle, false);
          soloud.setVolume(handle, volume);
          return;
        } catch (_) {
          // Stale handle -- fall through and start a fresh one below.
          _bgMusicHandle = null;
        }
      }
      _bgMusicHandle = await soloud.play(source, volume: volume, looping: true);
    } catch (_) {
      // Best-effort -- same tolerance as every other SoLoud call here.
    }
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
      unawaited(_startBackgroundMusic());

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
      'assets/images/onboarding_footer.png',
      'assets/images/onboarding_logo.png',
    ];
    await Future.wait<void>(
      assets.map((asset) => precacheImage(AssetImage(asset), context)),
    );
  }

  @override
  void dispose() {
    _logoAudioTimer?.cancel();
    _appSettingsController?.removeListener(_onSettingsChanged);
    _learnerController?.removeListener(_onSettingsChanged);
    // StartupFlow realistically lives for the app's whole lifetime (its
    // AnimatedSwitcher just swaps children; this State is never actually
    // torn down after boot), so dispose() firing means either the app is
    // exiting or (in a widget test) the tree is being replaced -- either
    // way, deinit() is SoLoud's own documented cleanup call for exactly
    // this moment (it also tears down the looping background music, so no
    // separate stop call is needed for that). Only relevant if preloading
    // ever actually got a source loaded (i.e. SoLoud.instance didn't
    // throw) in the first place.
    if (_logoAudioSource != null || _bgMusicSource != null) {
      try {
        if (SoLoud.instance.isInitialized) {
          SoLoud.instance.deinit();
        }
      } catch (_) {
        // Best-effort cleanup.
      }
    }
    super.dispose();
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
              SizedBox(
                width: 160,
                height: 44,
                child: StickerPressButton(
                  label: 'try liwat',
                  onPressed: () {
                    setState(() {
                      _stage = 0;
                      _startupError = null;
                    });
                    unawaited(_runStartup());
                  },
                  frontColor: AppColors.green,
                  depthColor: AppColors.darkGreen,
                ),
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
