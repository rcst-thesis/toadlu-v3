import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';

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
  static final FlutterTts _tts = FlutterTts();
  static Map<String, String>? _preferredFilipinoVoice;
  static bool _lookedForFilipinoVoice = false;

  static Future<void> speak(
    BuildContext context,
    String message, {
    bool hiligaynon = true,
  }) async {
    final text = message.trim();
    if (text.isEmpty) return;
    try {
      await _tts.stop();
      await _setSpeechLanguage(hiligaynon: hiligaynon);
      await _tts.setSpeechRate(.42);
      await _tts.setPitch(1.08);
      await _tts.speak(text);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));
    }
  }

  static Future<void> _setSpeechLanguage({required bool hiligaynon}) async {
    if (!hiligaynon) {
      await _tts.setLanguage('en-US');
      return;
    }

    const preferredLocales = ['tl-PH', 'fil-PH'];
    for (final locale in preferredLocales) {
      try {
        await _tts.setLanguage(locale);
        break;
      } catch (_) {
        // Try the next Filipino/Tagalog locale supported by the platform.
      }
    }

    final voice = await _preferredVoiceForLocales(preferredLocales);
    if (voice != null) {
      try {
        await _tts.setVoice(voice);
      } catch (_) {
        // Some platforms accept the language but do not support setVoice.
      }
    }
  }

  static Future<Map<String, String>?> _preferredVoiceForLocales(
    List<String> locales,
  ) async {
    if (_lookedForFilipinoVoice) return _preferredFilipinoVoice;
    _lookedForFilipinoVoice = true;

    try {
      final voices = await _tts.getVoices;
      if (voices is! Iterable) return null;

      final normalizedLocales = locales.map((locale) => locale.toLowerCase());
      final candidates = <Map<String, String>>[];
      for (final voice in voices) {
        if (voice is! Map) continue;
        final name = voice['name']?.toString();
        final locale = voice['locale']?.toString();
        if (name == null || locale == null) continue;
        if (!normalizedLocales.contains(locale.toLowerCase())) continue;
        candidates.add({'name': name, 'locale': locale});
      }

      if (candidates.isEmpty) return null;
      candidates.sort((a, b) => _voiceRank(a).compareTo(_voiceRank(b)));
      _preferredFilipinoVoice = candidates.first;
      return _preferredFilipinoVoice;
    } catch (_) {
      return null;
    }
  }

  static int _voiceRank(Map<String, String> voice) {
    final name = voice['name']!.toLowerCase();
    final locale = voice['locale']!.toLowerCase();
    var rank = 0;
    if (locale == 'tl-ph') rank -= 20;
    if (name.contains('female') ||
        name.contains('woman') ||
        name.contains('zira')) {
      rank -= 8;
    }
    if (name.contains('male') ||
        name.contains('man') ||
        name.contains('david')) {
      rank += 8;
    }
    return rank;
  }

  final String message;
  final String tooltip;
  final double size;
  final bool? hiligaynon;

  const TudloVoiceButton({
    super.key,
    required this.message,
    this.tooltip = 'Play voice message',
    this.size = 54,
    this.hiligaynon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: TudloColors.forest.withValues(alpha: .40),
            blurRadius: 22,
            spreadRadius: 3,
          ),
          BoxShadow(
            color: TudloColors.forest.withValues(alpha: .24),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: IconButton.filled(
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: TudloColors.forest,
          foregroundColor: Colors.white,
          minimumSize: Size(size, size),
          iconSize: size * .56,
        ),
        onPressed: () async {
          final appState = AppStateScope.of(context);
          await speak(
            context,
            message,
            hiligaynon: hiligaynon ?? appState.isHiligaynon,
          );
        },
        icon: const Icon(Icons.volume_up_rounded),
      ),
    );
  }
}
