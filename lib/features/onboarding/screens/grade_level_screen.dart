import 'package:flutter/material.dart';
import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/features/navigation/app_shell.dart';

class GradeLevelScreen extends StatefulWidget {
  final String? learnerName;

  const GradeLevelScreen({super.key, this.learnerName});

  @override
  State<GradeLevelScreen> createState() => _GradeLevelScreenState();
}

class _GradeLevelScreenState extends State<GradeLevelScreen> {
  GradeOption selected = gradeOptions.first;

  Future<void> _continue() async {
    final appState = AppStateScope.of(context);
    final name = widget.learnerName?.trim();
    if (name != null && name.isNotEmpty) {
      await appState.addProfile(name: name, grade: selected.label);
    } else {
      appState.setGradeLevel(selected.label);
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AppShell(initialIndex: 0)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2FAA1F),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 720;
            final eyesWidth = (constraints.maxWidth * (compact ? .62 : .78))
                .clamp(200.0, 360.0);
            final titleGap = compact ? 30.0 : 50.0;
            final buttonGap = compact ? 13.0 : 22.0;
            final arrowSize = compact ? 82.0 : 106.0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(vertical: compact ? 20 : 34),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - (compact ? 40 : 68))
                          .clamp(0, double.infinity),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/onbaording/eyes.png',
                          width: eyesWidth,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: titleGap),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Grade Level',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compact ? 42 : 48,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 20 : 26),
                        for (final option in gradeOptions) ...[
                          _GradeButton(
                            label: option.label,
                            selected: selected == option,
                            compact: compact,
                            onTap: () => setState(() => selected = option),
                          ),
                          SizedBox(height: buttonGap),
                        ],
                        SizedBox(height: compact ? 32 : 50),
                        _RoundNextButton(size: arrowSize, onTap: _continue),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GradeButton extends StatefulWidget {
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _GradeButton({
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_GradeButton> createState() => _GradeButtonState();
}

class _GradeButtonState extends State<_GradeButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final glowing = widget.selected || _pressed;
    final width =
        (MediaQuery.sizeOf(context).width * (widget.compact ? .76 : .70))
            .clamp(230.0, 380.0)
            .toDouble();
    final borderColor = _pressed
        ? const Color(0xFFFFE45C)
        : widget.selected
        ? const Color(0xFFFFD029)
        : Colors.white;

    return AnimatedScale(
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      scale: _pressed ? .96 : 1,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: width,
          padding: EdgeInsets.symmetric(
            horizontal: 26,
            vertical: widget.compact ? 10 : 15,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor, width: glowing ? 6 : 4),
            boxShadow: glowing
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFF06A).withValues(alpha: .95),
                      blurRadius: _pressed ? 34 : 24,
                      spreadRadius: _pressed ? 8 : 5,
                    ),
                    BoxShadow(
                      color: const Color(0xFF0B7F18).withValues(alpha: .32),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .10),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.label,
              style: TextStyle(
                color: _pressed
                    ? const Color(0xFF0B7F18)
                    : const Color(0xFF237915),
                fontSize: widget.compact ? 35 : 44,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundNextButton extends StatelessWidget {
  final double size;
  final VoidCallback onTap;

  const _RoundNextButton({required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black38,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.chevron_right_rounded,
            color: const Color(0xFF237915),
            size: size * .70,
          ),
        ),
      ),
    );
  }
}
