import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppAudioService {
  AppAudioService._();

  static final AppAudioService instance = AppAudioService._();

  static const tap = 'audio/effects/tap.mp3';
  static const correct = 'audio/effects/correct.mp3';
  static const wrong = 'audio/effects/wrong.mp3';
  static const syllableTap = 'audio/effects/syllable_tap.mp3';
  static const lessonUnlock = 'audio/effects/lesson_unlock.mp3';
  static const lessonComplete = 'audio/effects/lesson_complete.mp3';
  static const star = 'audio/effects/star.mp3';
  static const _initialAssets = [
    tap,
    correct,
    wrong,
    syllableTap,
    lessonUnlock,
    lessonComplete,
    star,
  ];

  static const _soundEffectsKey = 'audio.soundEffectsEnabled';
  static const _musicKey = 'audio.musicEnabled';
  static const _voiceOverKey = 'audio.voiceOverEnabled';

  final AudioPlayer _effectPlayer = AudioPlayer();
  final AudioPlayer _backgroundPlayer = AudioPlayer();
  final AudioPlayer _voicePlayer = AudioPlayer();
  final ValueNotifier<bool> soundEffectsEnabledNotifier = ValueNotifier<bool>(
    true,
  );
  final ValueNotifier<bool> musicEnabledNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> voiceOverEnabledNotifier = ValueNotifier<bool>(
    true,
  );

  DateTime _lastEffectAt = DateTime.fromMillisecondsSinceEpoch(0);
  String? _currentBackgroundTrack;
  double _backgroundVolume = .18;
  bool _initialized = false;
  int _voiceToken = 0;

  bool get soundEffectsEnabled => soundEffectsEnabledNotifier.value;
  bool get musicEnabled => musicEnabledNotifier.value;
  bool get voiceOverEnabled => voiceOverEnabledNotifier.value;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    soundEffectsEnabledNotifier.value = prefs.getBool(_soundEffectsKey) ?? true;
    musicEnabledNotifier.value = prefs.getBool(_musicKey) ?? true;
    voiceOverEnabledNotifier.value = prefs.getBool(_voiceOverKey) ?? true;
    try {
      await AudioCache.instance.loadAll(_initialAssets);
    } catch (_) {
      // Missing optional audio must not block app startup.
    }
  }

  Future<void> preloadLessonAudio(Iterable<String> assetPaths) async {
    final paths = assetPaths
        .map((path) => path.startsWith('assets/') ? path.substring(7) : path)
        .where((path) => path.isNotEmpty)
        .toSet()
        .take(5)
        .toList();
    try {
      await AudioCache.instance.loadAll(paths);
    } catch (_) {
      // Lessons can fall back to text-to-speech when recordings are absent.
    }
  }

  Future<void> playSoundEffect(
    String assetPath, {
    double volume = .45,
    bool allowRapidRepeat = false,
  }) async {
    if (!soundEffectsEnabled) return;
    final now = DateTime.now();
    if (!allowRapidRepeat &&
        now.difference(_lastEffectAt) < const Duration(milliseconds: 70)) {
      return;
    }
    _lastEffectAt = now;

    try {
      await _effectPlayer.stop();
      await _effectPlayer.setVolume(volume.clamp(0, 1).toDouble());
      await _effectPlayer.play(AssetSource(assetPath));
    } catch (_) {
      // Placeholder or missing audio must never interrupt learning.
    }
  }

  Future<void> playTap() => playSoundEffect(tap, volume: .30);
  Future<void> playCorrect() => playSoundEffect(correct, volume: .42);
  Future<void> playWrong() => playSoundEffect(wrong, volume: .34);
  Future<void> playSyllableTap() => playSoundEffect(syllableTap, volume: .36);
  Future<void> playLessonUnlock() => playSoundEffect(lessonUnlock, volume: .40);
  Future<void> playLessonComplete() =>
      playSoundEffect(lessonComplete, volume: .48);
  Future<void> playStar() => playSoundEffect(star, volume: .38);

  Future<void> playVoiceAssets(
    List<String> assetPaths, {
    double volume = .95,
  }) async {
    if (!voiceOverEnabled || assetPaths.isEmpty) return;
    final token = ++_voiceToken;
    try {
      await _voicePlayer.stop();
      await _voicePlayer.setReleaseMode(ReleaseMode.stop);
      await _voicePlayer.setVolume(volume.clamp(0, 1).toDouble());
      for (final assetPath in assetPaths) {
        if (token != _voiceToken) return;
        final completed = Completer<void>();
        late final StreamSubscription<void> sub;
        sub = _voicePlayer.onPlayerComplete.listen((_) {
          if (!completed.isCompleted) completed.complete();
        });
        await _voicePlayer.play(AssetSource(assetPath));
        await completed.future.timeout(
          const Duration(seconds: 30),
          onTimeout: () {},
        );
        await sub.cancel();
      }
    } catch (_) {
      rethrow;
    }
  }

  Future<void> stopVoice() async {
    _voiceToken++;
    try {
      await _voicePlayer.stop();
    } catch (_) {}
  }

  Future<void> playBackgroundMusic(
    String assetPath, {
    double volume = .18,
  }) async {
    if (!musicEnabled || _currentBackgroundTrack == assetPath) return;
    _currentBackgroundTrack = assetPath;
    _backgroundVolume = volume.clamp(0, 1).toDouble();
    try {
      await _backgroundPlayer.stop();
      await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundPlayer.setVolume(_backgroundVolume);
      await _backgroundPlayer.play(AssetSource(assetPath));
    } catch (_) {
      _currentBackgroundTrack = null;
    }
  }

  Future<void> lowerBackgroundVolume() async {
    try {
      await _backgroundPlayer.setVolume(.05);
    } catch (_) {}
  }

  Future<void> restoreBackgroundVolume() async {
    if (!musicEnabled) return;
    try {
      await _backgroundPlayer.setVolume(_backgroundVolume);
    } catch (_) {}
  }

  Future<void> setSoundEffectsEnabled(bool enabled) async {
    soundEffectsEnabledNotifier.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEffectsKey, enabled);
    if (!enabled) await _effectPlayer.stop();
  }

  Future<void> setMusicEnabled(bool enabled) async {
    musicEnabledNotifier.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicKey, enabled);
    try {
      if (!enabled) {
        await _backgroundPlayer.pause();
      } else if (_currentBackgroundTrack != null) {
        await _backgroundPlayer.resume();
      }
    } catch (_) {}
  }

  Future<void> setVoiceOverEnabled(bool enabled) async {
    voiceOverEnabledNotifier.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_voiceOverKey, enabled);
  }

  Future<void> dispose() async {
    await _effectPlayer.dispose();
    await _backgroundPlayer.dispose();
    await _voicePlayer.dispose();
  }
}
