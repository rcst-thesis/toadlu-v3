import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudlo/features/lesson/presentation/devg_canonical/core/theme/app_theme.dart';

class GradeThreeStickerRewardOverlay extends StatelessWidget {
  final String stickerAsset;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const GradeThreeStickerRewardOverlay({
    super.key,
    required this.stickerAsset,
    required this.message,
    this.primaryLabel = 'OK',
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final hasSecondary = secondaryLabel != null && onSecondary != null;
    final titleTop = (view.height * .045).clamp(18.0, 34.0).toDouble();
    final titleHeight = (view.height * .16).clamp(54.0, 86.0).toDouble();
    final buttonHeight = (view.height * .105).clamp(44.0, 58.0).toDouble();
    final buttonBottom = (view.height * .055).clamp(18.0, 32.0).toDouble();
    final middleTop = titleTop + titleHeight + 4;
    final middleBottom = buttonBottom + buttonHeight + 10;
    final middleHeight =
        (view.height - middleTop - middleBottom).clamp(150.0, 380.0).toDouble();
    final stickerHeight = middleHeight;
    final stickerWidth = (view.width * .46)
        .clamp(300.0, 430.0)
        .toDouble()
        .clamp(0.0, view.width * .72)
        .toDouble();
    final starSize = (stickerHeight * .45).clamp(104.0, 158.0).toDouble();

    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: Colors.black.withValues(alpha: .50)),
        ),
        Positioned(
          left: view.width * .08,
          right: view.width * .08,
          top: titleTop,
          height: titleHeight,
          child: Center(
            child: Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: (view.width * .025).clamp(18.0, 25.0),
                height: 1.05,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
                shadows: const [
                  Shadow(
                    color: TudloColors.ink,
                    offset: Offset(0, 3),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: middleTop,
          bottom: middleBottom,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: onPrimary,
              child: SizedBox(
                width: stickerWidth,
                height: stickerHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: starSize * 1.38,
                      height: starSize * 1.38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFD33D).withValues(alpha: .12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFFD33D).withValues(alpha: .52),
                            blurRadius: 24,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.star_rounded,
                      size: starSize * 1.22,
                      color: const Color(0xFFFFD941),
                      shadows: [
                        Shadow(
                          color: const Color(0xFFFFA800).withValues(alpha: .9),
                          blurRadius: 8,
                        ),
                        Shadow(
                          color: Colors.white.withValues(alpha: .75),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    SizedBox(
                      width: stickerWidth,
                      height: stickerHeight,
                      child: _GradeThreeRewardSticker(
                        asset: stickerAsset,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: view.width * .08,
          right: view.width * .08,
          bottom: buttonBottom,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasSecondary) ...[
                Flexible(
                  child: _GradeThreeRewardButton(
                    label: secondaryLabel!,
                    onTap: onSecondary!,
                    filled: false,
                  ),
                ),
                SizedBox(width: view.width * .02),
              ],
              Flexible(
                child: _GradeThreeRewardButton(
                  label: primaryLabel,
                  onTap: onPrimary,
                  filled: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GradeThreeRewardSticker extends StatelessWidget {
  final String asset;

  const _GradeThreeRewardSticker({required this.asset});

  String? get _pngFallback {
    final name = asset.split('/').last;
    final match = RegExp(r'^(.+)-home-sticker\.svg$').firstMatch(name);
    if (match == null) return null;
    return 'assets/images/home_sticker_${match.group(1)}.png';
  }

  @override
  Widget build(BuildContext context) {
    final fallback = _pngFallback;
    if (fallback != null) {
      return Image.asset(
        fallback,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => SvgPicture.asset(
          asset,
          fit: BoxFit.contain,
        ),
      );
    }
    return SvgPicture.asset(asset, fit: BoxFit.contain);
  }
}

class _GradeThreeRewardButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _GradeThreeRewardButton({
    required this.label,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final green = TudloColors.green;
    return GestureDetector(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: (view.width * .22).clamp(170.0, 230.0),
          maxWidth: (view.width * .34).clamp(230.0, 320.0),
        ),
        child: Container(
          height: (view.height * .105).clamp(44.0, 58.0),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: filled ? green : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: green, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .16),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              color: filled ? Colors.white : green,
              fontSize: (view.width * .018).clamp(16.0, 23.0),
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}
