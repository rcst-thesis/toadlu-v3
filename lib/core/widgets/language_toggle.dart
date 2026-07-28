import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tudloapp/core/services/app_audio_service.dart';
import 'package:tudloapp/core/services/tudlo_tts_platform.dart';
import 'package:tudloapp/core/services/tudlo_tts_platform_interface.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/dialogue_assets.dart';

class TudloLanguageToggle extends StatelessWidget {
  const TudloLanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isHil = appState.isHiligaynon;

    return Semantics(
      button: true,
      label: 'Switch language',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: appState.toggleAppLanguage,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 46,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: TudloColors.forest, width: 3),
            boxShadow: [
              BoxShadow(
                color: TudloColors.forest.withValues(alpha: .18),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LanguagePill(label: 'HIL', active: isHil),
              const SizedBox(width: 4),
              _LanguagePill(label: 'EN', active: !isHil),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguagePill extends StatelessWidget {
  final String label;
  final bool active;

  const _LanguagePill({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 48,
      height: 34,
      decoration: BoxDecoration(
        color: active ? TudloColors.green : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : TudloColors.muted,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class TudloVoiceButton extends StatelessWidget {
  static final TudloTtsPlatform _tts = createTudloTtsPlatform();
  static final ValueNotifier<bool> isSpeaking = ValueNotifier<bool>(false);
  static int _speechToken = 0;

  static Future<void> speak(
    BuildContext context,
    String message, {
    bool hiligaynon = true,
    bool waitForCompletion = false,
  }) async {
    final text = message.trim();
    if (text.isEmpty) return;
    final audio = AppAudioService.instance;
    if (!audio.voiceOverEnabled) return;
    try {
      await _tts.stop();
      isSpeaking.value = false;
      final token = ++_speechToken;
      await audio.lowerBackgroundVolume();
      isSpeaking.value = true;
      await _tts.speak(
        text,
        hiligaynon: hiligaynon,
        waitForCompletion: waitForCompletion,
      );
      if (waitForCompletion) {
        if (_speechToken == token) isSpeaking.value = false;
        await audio.restoreBackgroundVolume();
      } else {
        _resetSpeakingAfterEstimate(text, token);
      }
    } catch (_) {
      isSpeaking.value = false;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));
    }
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
      _speechToken++;
      isSpeaking.value = false;
      await AppAudioService.instance.restoreBackgroundVolume();
    } catch (_) {
      // Stopping narration should never block navigation.
    }
  }

  static void _resetSpeakingAfterEstimate(String text, int token) {
    final milliseconds = (text.length * 85).clamp(900, 9000);
    Future<void>.delayed(Duration(milliseconds: milliseconds), () async {
      if (_speechToken == token) isSpeaking.value = false;
      if (_speechToken == token) {
        await AppAudioService.instance.restoreBackgroundVolume();
      }
    });
  }

  final String message;
  final String tooltip;
  final double size;
  final bool? hiligaynon;
  final Color backgroundColor;
  final Color foregroundColor;

  const TudloVoiceButton({
    super.key,
    required this.message,
    this.tooltip = 'Play voice message',
    this.size = 54,
    this.hiligaynon,
    this.backgroundColor = TudloColors.forest,
    this.foregroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final glowColor = backgroundColor == Colors.white
        ? TudloColors.green
        : backgroundColor;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: .40),
            blurRadius: 22,
            spreadRadius: 3,
          ),
          BoxShadow(
            color: TudloColors.forest.withValues(alpha: .18),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: IconButton.filled(
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          minimumSize: Size(size, size),
          iconSize: size * .56,
        ),
        onPressed: () async {
          final appState = AppStateScope.of(context);
          final useHiligaynon = hiligaynon ?? appState.isHiligaynon;
          unawaited(AppAudioService.instance.playTap());
          await speak(context, message, hiligaynon: useHiligaynon);
        },
        icon: TudloSpeakerIcon(size: size * .54),
      ),
    );
  }
}
