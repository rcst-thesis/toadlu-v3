import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudloapp/core/services/app_audio_service.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/dialogue_assets.dart';
import 'package:tudloapp/core/widgets/language_toggle.dart';
import 'package:tudloapp/core/widgets/mascot_widget.dart';
import 'package:tudloapp/features/translation/services/child_safety_filter.dart';
import 'package:tudloapp/features/translation/services/nmt_translation_service.dart';

class _TranslateStyle {
  static const softBg = TudloColors.paper;
}

/// Offline English-to-Hiligaynon model translation.
class TranslationPage extends StatefulWidget {
  final Future<String> Function(String)? translateEnglish;

  const TranslationPage({super.key, this.translateEnglish});

  @override
  State<TranslationPage> createState() => _TranslationPageState();
}

class _TranslationPageState extends State<TranslationPage> {
  final TextEditingController topController = TextEditingController();
  final TextEditingController bottomController = TextEditingController();

  bool showHelpOverlay = !AppData.translateHelpDone;
  bool _isTranslating = false;
  bool _nmtRunning = false;
  bool _disposed = false;
  bool _safetyReady = false;
  bool _inputBlocked = false;
  int _requestId = 0;
  Timer? _translationDebounce;
  String? _translationError;
  ({String text, int requestId})? _pendingRequest;
  NmtTranslationService? _nmtService;
  late final Future<String> Function(String) _translateEnglish;

  @override
  void initState() {
    super.initState();
    _nmtService = widget.translateEnglish == null
        ? NmtTranslationService()
        : null;
    _translateEnglish = widget.translateEnglish ?? _nmtService!.translate;
    topController.addListener(_onInputChanged);
    _safetyReady = ChildSafetyFilter.isReady;
    if (!_safetyReady) {
      ChildSafetyFilter.initialize().then(
        (_) {
          if (mounted) setState(() => _safetyReady = true);
        },
        onError: (_) {
          if (mounted) {
            setState(() {
              _translationError =
                  'Child-safe translation is unavailable. Try again.';
            });
          }
        },
      );
    }
  }

  void _onInputChanged() {
    if (!_safetyReady) return;

    final input = topController.text;
    final requestId = ++_requestId;
    _translationDebounce?.cancel();
    _pendingRequest = null;
    final inputBlocked = ChildSafetyFilter.isUnsafe(input);
    bottomController.text = inputBlocked
        ? ChildSafetyFilter.blockedMessage
        : '';

    setState(() {
      _inputBlocked = inputBlocked;
      _isTranslating = false;
      _translationError = null;
      if (input.trim().isNotEmpty && !AppData.translateHelpDone) {
        showHelpOverlay = false;
        AppData.translateHelpDone = true;
      }
    });

    if (!inputBlocked && input.trim().isNotEmpty) {
      _translationDebounce = Timer(const Duration(milliseconds: 450), () {
        if (!_isCurrent(input, requestId)) return;
        _pendingRequest = (text: input, requestId: requestId);
        unawaited(_drainNmtRequests());
      });
    }
  }

  Future<void> _drainNmtRequests() async {
    if (_nmtRunning) return;
    _nmtRunning = true;
    try {
      while (_pendingRequest != null) {
        final request = _pendingRequest!;
        _pendingRequest = null;
        if (!_isCurrent(request.text, request.requestId)) continue;
        setState(() => _isTranslating = true);
        try {
          final translation = (await _translateEnglish(request.text)).trim();
          if (!_isCurrent(request.text, request.requestId)) continue;
          if (translation.isEmpty) {
            throw StateError('The model returned an empty translation.');
          }
          setState(() {
            bottomController.text = ChildSafetyFilter.isUnsafe(translation)
                ? ChildSafetyFilter.blockedMessage
                : translation;
            _translationError = null;
          });
        } catch (_) {
          if (!_isCurrent(request.text, request.requestId)) continue;
          setState(() {
            bottomController.clear();
            _translationError = 'Offline translation unavailable. Try again.';
          });
        } finally {
          if (_isCurrent(request.text, request.requestId)) {
            setState(() => _isTranslating = false);
          }
        }
      }
    } finally {
      _nmtRunning = false;
    }
  }

  bool _isCurrent(String text, int requestId) {
    return !_disposed &&
        mounted &&
        requestId == _requestId &&
        topController.text == text;
  }

  @override
  void dispose() {
    _disposed = true;
    _requestId++;
    _translationDebounce?.cancel();
    _pendingRequest = null;
    topController.removeListener(_onInputChanged);
    final service = _nmtService;
    if (service != null) unawaited(service.close());
    topController.dispose();
    bottomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _TranslateStyle.softBg,
      body: Stack(
        children: [
          const Positioned.fill(child: _TranslateBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final horizontalPadding = availableWidth >= 700 ? 44.0 : 24.0;
                final contentWidth = (availableWidth - horizontalPadding * 2)
                    .clamp(0.0, availableWidth);
                final maxContentWidth = availableWidth >= 700 ? 720.0 : 520.0;
                final titleSize = availableWidth >= 700 ? 56.0 : 44.0;
                final topPadding = availableWidth >= 700 ? 50.0 : 38.0;

                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      topPadding,
                      horizontalPadding,
                      154,
                    ),
                    child: SizedBox(
                      width: contentWidth.clamp(0.0, maxContentWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Hubad',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  style: GoogleFonts.archivoBlack(
                                    color: const Color(0xFF078C3A),
                                    fontSize: titleSize,
                                    letterSpacing: 0,
                                    shadows: [
                                      Shadow(
                                        color: Colors.white.withValues(
                                          alpha: .78,
                                        ),
                                        offset: const Offset(0, 5),
                                        blurRadius: 0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: availableWidth >= 700 ? 36 : 30),
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Column(
                                children: [
                                  _TranslationLanguageCard(
                                    language: 'Ingles',
                                    controller: topController,
                                    hint: 'Isulat ang Ingles',
                                    readOnly: false,
                                    inputEnabled: _safetyReady,
                                    safeActions: !_inputBlocked,
                                    onClear: topController.clear,
                                  ),
                                  SizedBox(
                                    height: availableWidth >= 700 ? 46 : 42,
                                  ),
                                  _TranslationLanguageCard(
                                    language: 'Hiligaynon',
                                    controller: bottomController,
                                    hint: 'Ang hubad makita diri',
                                    readOnly: true,
                                    inputEnabled: true,
                                    safeActions: true,
                                    onClear: () {
                                      setState(() => bottomController.clear());
                                    },
                                  ),
                                ],
                              ),
                              const _TranslateCenterButton(),
                            ],
                          ),
                          if (!_safetyReady || _isTranslating)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: const LinearProgressIndicator(
                                  minHeight: 7,
                                ),
                              ),
                            ),
                          if (_translationError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                _translationError!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(
                                  color: TudloColors.coral,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (showHelpOverlay)
            Positioned.fill(
              child: _TranslateHelpOverlay(
                onTap: () => setState(() => showHelpOverlay = false),
              ),
            ),
        ],
      ),
    );
  }
}

class _TranslateHelpOverlay extends StatelessWidget {
  final VoidCallback onTap;

  const _TranslateHelpOverlay({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final mascotWidth = (size.width * .55).clamp(190.0, 270.0);
    final bubbleWidth = (size.width * .58).clamp(200.0, 280.0);
    final mascotBottom = (size.height * .14).clamp(104.0, 150.0);
    final mascotLeft = (size.width * .07).clamp(16.0, 34.0);
    final mascotTop = size.height - mascotBottom - mascotWidth;
    final mascotVisibleTop = mascotTop + mascotWidth * .158;
    final bubbleVisibleBottom = bubbleWidth * 1.234;
    final bubbleTop = (mascotVisibleTop - bubbleVisibleBottom - 12).clamp(
      MediaQuery.paddingOf(context).top + 86,
      size.height * .46,
    );
    final bubbleLeft = (mascotLeft + mascotWidth * .5 - bubbleWidth * .5).clamp(
      12.0,
      size.width - bubbleWidth - 12,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        color: Colors.black.withValues(alpha: .34),
        child: Stack(
          children: [
            Positioned(
              left: mascotLeft,
              bottom: mascotBottom,
              child: TudloMascot(size: mascotWidth),
            ),
            Positioned(
              left: bubbleLeft,
              top: bubbleTop,
              child: _TranslateDialogueBubble(
                width: bubbleWidth,
                message: 'Testingan ta mag type',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TranslateDialogueBubble extends StatelessWidget {
  final double width;
  final String message;

  const _TranslateDialogueBubble({required this.width, required this.message});

  @override
  Widget build(BuildContext context) {
    final bubbleHeight = width * 1920 / 1080;
    return SizedBox(
      width: width,
      height: bubbleHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              TudloDialogueAssets.dialogueBox,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          Positioned(
            left: width * .20,
            right: width * .20,
            top: width * .59,
            height: width * .46,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width * .58),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: TudloColors.ink,
                    fontSize: 22,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TranslateBackground extends StatelessWidget {
  const _TranslateBackground();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/game_map/backgroundv3.svg',
      fit: BoxFit.cover,
      alignment: Alignment.center,
      placeholderBuilder: (_) =>
          const CustomPaint(painter: _TranslateBackgroundPainter()),
    );
  }
}

class _TranslateBackgroundPainter extends CustomPainter {
  const _TranslateBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = Colors.white.withValues(alpha: .80);
    canvas.drawCircle(Offset(size.width * .29, size.height * .08), 46, paint);
    canvas.drawCircle(Offset(size.width * .39, size.height * .07), 62, paint);
    canvas.drawCircle(Offset(size.width * .51, size.height * .09), 38, paint);

    paint.color = Colors.white.withValues(alpha: .68);
    canvas.drawCircle(Offset(size.width * .74, size.height * .14), 40, paint);
    canvas.drawCircle(Offset(size.width * .83, size.height * .13), 54, paint);
    canvas.drawCircle(Offset(size.width * .93, size.height * .15), 33, paint);

    paint.color = const Color(0xFF7CCF78).withValues(alpha: .34);
    canvas.drawOval(
      Rect.fromLTWH(-70, size.height * .21, size.width * .58, 190),
      paint,
    );
    paint.color = const Color(0xFF56B965).withValues(alpha: .28);
    canvas.drawOval(
      Rect.fromLTWH(size.width * .56, size.height * .22, size.width * .62, 210),
      paint,
    );

    paint.color = const Color(0xFF128F55).withValues(alpha: .28);
    canvas.drawCircle(Offset(-22, size.height * .63), 106, paint);
    canvas.drawCircle(Offset(size.width + 18, size.height * .61), 94, paint);
    canvas.drawCircle(Offset(size.width * .15, size.height + 8), 110, paint);
    canvas.drawCircle(Offset(size.width * .86, size.height + 6), 112, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TranslateCenterButton extends StatelessWidget {
  const _TranslateCenterButton();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: TudloColors.blue.withValues(alpha: .32),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        width: 78,
        height: 78,
        margin: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF39B7FF), Color(0xFF097CFF)],
          ),
        ),
        child: const Icon(
          Icons.sync_alt_rounded,
          color: Colors.white,
          size: 43,
        ),
      ),
    );
  }
}

class _TranslationLanguageCard extends StatelessWidget {
  final String language;
  final TextEditingController controller;
  final String hint;
  final bool readOnly;
  final bool inputEnabled;
  final bool safeActions;
  final VoidCallback onClear;

  const _TranslationLanguageCard({
    required this.language,
    required this.controller,
    required this.hint,
    required this.readOnly,
    required this.inputEnabled,
    required this.safeActions,
    required this.onClear,
  });

  Future<void> _copyText(BuildContext context, String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    await AppAudioService.instance.playTap();
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Copied text'),
          duration: Duration(milliseconds: 900),
        ),
      );
  }

  Future<void> _clearText() async {
    if (controller.text.trim().isEmpty) return;
    await AppAudioService.instance.playTap();
    onClear();
  }

  @override
  Widget build(BuildContext context) {
    final text = controller.text.trim();
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 520).clamp(1.0, 1.18);
        final labelSize = 31.0 * scale;
        final bodySize = (constraints.maxWidth * .058).clamp(23.0, 31.0);

        return Container(
          constraints: BoxConstraints(minHeight: 204 * scale),
          padding: EdgeInsets.fromLTRB(
            18 * scale,
            16 * scale,
            18 * scale,
            18 * scale,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26 * scale),
            boxShadow: [
              BoxShadow(
                color: TudloColors.ink.withValues(alpha: .11),
                blurRadius: 24 * scale,
                offset: Offset(0, 12 * scale),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _LanguageMark(language: language, scale: scale),
                  SizedBox(width: 12 * scale),
                  Expanded(
                    child: Text(
                      language,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF255D8F),
                        fontSize: labelSize,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Listen',
                    iconSize: 30 * scale,
                    onPressed: text.isEmpty || !safeActions
                        ? null
                        : () => TudloVoiceButton.speak(context, text),
                    icon: Opacity(
                      opacity: text.isEmpty || !safeActions ? .35 : 1,
                      child: TudloSpeakerIcon(size: 24 * scale),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18 * scale),
              Container(
                constraints: BoxConstraints(minHeight: 94 * scale),
                padding: EdgeInsets.fromLTRB(
                  18 * scale,
                  10 * scale,
                  14 * scale,
                  10 * scale,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FC),
                  borderRadius: BorderRadius.circular(18 * scale),
                  boxShadow: [
                    BoxShadow(
                      color: TudloColors.muted.withValues(alpha: .07),
                      blurRadius: 14 * scale,
                      offset: Offset(0, 7 * scale),
                    ),
                  ],
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: readOnly
                      ? Text(
                          text.isEmpty ? hint : controller.text,
                          softWrap: true,
                          style: GoogleFonts.nunito(
                            color: text.isEmpty
                                ? TudloColors.muted.withValues(alpha: .56)
                                : Colors.black,
                            fontSize: bodySize,
                            height: 1.14,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : TextField(
                          controller: controller,
                          enabled: inputEnabled,
                          maxLines: null,
                          minLines: 1,
                          style: GoogleFonts.nunito(
                            color: Colors.black,
                            fontSize: bodySize,
                            height: 1.14,
                            fontWeight: FontWeight.w900,
                          ),
                          decoration: InputDecoration(
                            hintText: hint,
                            hintStyle: GoogleFonts.nunito(
                              color: TudloColors.muted.withValues(alpha: .56),
                              fontWeight: FontWeight.w900,
                            ),
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            isCollapsed: true,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 12 * scale),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TranslationActionButton(
                      tooltip: 'Copy text',
                      icon: Icons.copy_rounded,
                      color: TudloColors.forest,
                      enabled: text.isNotEmpty && safeActions,
                      scale: scale,
                      onTap: () => _copyText(context, controller.text),
                    ),
                    SizedBox(width: 8 * scale),
                    _TranslationActionButton(
                      tooltip: 'Clear text',
                      icon: Icons.delete_rounded,
                      color: TudloColors.coral,
                      enabled: text.isNotEmpty,
                      scale: scale,
                      onTap: _clearText,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LanguageMark extends StatelessWidget {
  final String language;
  final double scale;

  const _LanguageMark({required this.language, required this.scale});

  @override
  Widget build(BuildContext context) {
    final isEnglish = language == 'Ingles' || language == 'English';
    return Container(
      width: 54 * scale,
      height: 40 * scale,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11 * scale),
        border: Border.all(color: Colors.white, width: 2 * scale),
        boxShadow: [
          BoxShadow(
            color: TudloColors.ink.withValues(alpha: .14),
            blurRadius: 8 * scale,
            offset: Offset(0, 4 * scale),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: isEnglish ? _UsFlag(scale: scale) : _PhilippinesFlag(scale: scale),
    );
  }
}

class _UsFlag extends StatelessWidget {
  final double scale;

  const _UsFlag({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          children: [
            for (var index = 0; index < 7; index++)
              Expanded(
                child: ColoredBox(
                  color: index.isEven ? const Color(0xFFE84A5F) : Colors.white,
                ),
              ),
          ],
        ),
        Align(
          alignment: Alignment.topLeft,
          child: FractionallySizedBox(
            widthFactor: .48,
            heightFactor: .56,
            child: Container(
              color: const Color(0xFF2457A6),
              padding: EdgeInsets.all(3 * scale),
              child: Wrap(
                spacing: 3 * scale,
                runSpacing: 3 * scale,
                children: [
                  for (var index = 0; index < 12; index++)
                    Container(
                      width: 2.3 * scale,
                      height: 2.3 * scale,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhilippinesFlag extends StatelessWidget {
  final double scale;

  const _PhilippinesFlag({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          children: const [
            Expanded(child: ColoredBox(color: Color(0xFF2457A6))),
            Expanded(child: ColoredBox(color: Color(0xFFE6353E))),
          ],
        ),
        ClipPath(
          clipper: const _FlagTriangleClipper(),
          child: Container(color: Colors.white),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 8 * scale),
            child: Container(
              width: 8 * scale,
              height: 8 * scale,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD54D),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FlagTriangleClipper extends CustomClipper<Path> {
  const _FlagTriangleClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * .58, size.height / 2)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _TranslationActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final bool enabled;
  final double scale;
  final VoidCallback onTap;

  const _TranslationActionButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = 38 * scale;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled
            ? color.withValues(alpha: .11)
            : TudloColors.line.withValues(alpha: .70),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              icon,
              color: enabled ? color : TudloColors.muted.withValues(alpha: .45),
              size: 21 * scale,
            ),
          ),
        ),
      ),
    );
  }
}
