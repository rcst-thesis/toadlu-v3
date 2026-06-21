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

  static Future<void> speak(
    BuildContext context,
    String message, {
    bool hiligaynon = true,
  }) async {
    final text = message.trim();
    if (text.isEmpty) return;
    try {
      await _tts.stop();
      await _tts.setLanguage(hiligaynon ? 'fil-PH' : 'en-US');
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

  final String message;
  final String tooltip;
  final double size;

  const TudloVoiceButton({
    super.key,
    required this.message,
    this.tooltip = 'Play voice message',
    this.size = 54,
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
          await speak(context, message, hiligaynon: appState.isHiligaynon);
        },
        icon: const Icon(Icons.volume_up_rounded),
      ),
    );
  }
}
