import 'package:flutter/material.dart';
import 'package:tudloapp/core/widgets/mascot_widget.dart';

/// Shared color tokens for the three onboarding question screens.
///
/// Keeping the onboarding palette here makes Username, Age, and Knowledge
/// Level screens feel like one consistent flow.
class OnboardingColors {
  static const bg = Colors.white;
  static const panel = Colors.white;
  static const panel2 = Color(0xFFF5FAF5);
  static const border = Color(0xFFDCEBDE);
  static const text = Color(0xFF25382A);
  static const muted = Color(0xFF728173);
  static const green = Color(0xFF08C66B);
  static const blue = Color(0xFF08C66B);
  static const selected = Color(0xFFE3F5EA);
  static const shadow = Color(0x3308C66B);
}

/// Reusable layout for the Username, Age, and Knowledge Level onboarding pages.
///
/// It provides the progress bar, back button, mascot area, question text, and
/// bottom Continue button space so each screen only supplies its own input.
class ScaffoldCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? bottomAction;

  const ScaffoldCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.bottomAction,
  });

  @override
  State<ScaffoldCard> createState() => _ScaffoldCardState();
}

class _ScaffoldCardState extends State<ScaffoldCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idleController;
  late final Animation<double> _floatAnimation;

  int get _step {
    // The current screen title determines which segment of the progress bar is
    // filled. This keeps the child screens simple.
    if (widget.title.contains('call you') || widget.title.contains('call')) {
      return 1;
    }
    if (widget.title.contains('old')) return 2;
    return 3;
  }

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _floatAnimation = CurvedAnimation(
      parent: _idleController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnboardingColors.bg,
      body: Theme(
        data: Theme.of(context).copyWith(
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: OnboardingColors.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: OnboardingColors.green.withValues(
                alpha: .18,
              ),
              disabledForegroundColor: OnboardingColors.muted.withValues(
                alpha: .45,
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
              minimumSize: const Size(240, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: OnboardingColors.bg),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Onboarding should not scroll. Spacing and mascot size shrink
                // on shorter screens so the options and Continue button stay
                // visible in one clean viewport.
                final compact = constraints.maxHeight < 820;
                final tiny = constraints.maxHeight < 720;
                final mascotSize = tiny
                    ? 76.0
                    : compact
                    ? 116.0
                    : 148.0;
                final topGap = tiny
                    ? 8.0
                    : compact
                    ? 18.0
                    : 30.0;
                final mascotGap = tiny
                    ? 12.0
                    : compact
                    ? 24.0
                    : 42.0;
                final titleGap = tiny
                    ? 12.0
                    : compact
                    ? 24.0
                    : 34.0;
                final childGap = tiny
                    ? 12.0
                    : compact
                    ? 26.0
                    : 42.0;
                final horizontalPadding = tiny ? 18.0 : 24.0;

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    18,
                    horizontalPadding,
                    12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _OnboardingTopBar(step: _step),
                      SizedBox(height: topGap),
                      const Text(
                        'ABOUT YOU',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: OnboardingColors.muted,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.6,
                        ),
                      ),
                      SizedBox(height: mascotGap),
                      AnimatedBuilder(
                        animation: _floatAnimation,
                        builder: (context, child) {
                          final lift = -5 * _floatAnimation.value;
                          final scale = 1 + (_floatAnimation.value * .015);
                          return Transform.translate(
                            offset: Offset(0, lift),
                            child: Transform.scale(scale: scale, child: child),
                          );
                        },
                        child: TudloMascot(size: mascotSize),
                      ),
                      SizedBox(height: titleGap),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: OnboardingColors.text,
                          fontSize: tiny ? 24 : 28,
                          height: 1.12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      if (widget.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: OnboardingColors.muted,
                            fontSize: tiny ? 15 : 18,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      SizedBox(height: childGap),
                      Flexible(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          child: widget.child,
                        ),
                      ),
                      if (widget.bottomAction != null) ...[
                        const SizedBox(height: 8),
                        widget.bottomAction!,
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingTopBar extends StatelessWidget {
  final int step;

  const _OnboardingTopBar({required this.step});

  @override
  Widget build(BuildContext context) {
    // Back returns to the previous onboarding step. The three green segments
    // show progress without using "Step 1 of 3" text.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            // Back button:
            // Goes to the previous onboarding screen when one exists.
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.chevron_left_rounded),
            color: OnboardingColors.muted,
            iconSize: 34,
            style: IconButton.styleFrom(
              backgroundColor: OnboardingColors.panel2,
              disabledBackgroundColor: OnboardingColors.panel2,
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Row(
            children: List.generate(3, (index) {
              final active = index < step;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  height: 12,
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 10),
                  decoration: BoxDecoration(
                    color: active
                        ? OnboardingColors.green
                        : OnboardingColors.selected,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}
