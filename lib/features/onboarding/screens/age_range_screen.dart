import 'package:flutter/material.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/features/onboarding/widgets/scaffold_card.dart';
import 'package:tudloapp/features/onboarding/screens/knowledge_level_screen.dart';

/// Second onboarding screen.
///
/// The selected age range is stored for profile display and future
/// personalization rules.
class AgeRangeScreen extends StatefulWidget {
  const AgeRangeScreen({super.key});

  @override
  State<AgeRangeScreen> createState() => _AgeRangeScreenState();
}

class _AgeRangeScreenState extends State<AgeRangeScreen> {
  String selected = '';

  @override
  Widget build(BuildContext context) {
    return ScaffoldCard(
      title: 'How old are you?',
      subtitle: 'This helps us personalize your experience.',
      bottomAction: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: selected.isEmpty
              ? null
              : () {
                  // Continue button:
                  // Save the selected age range, then direct the user to the
                  // Knowledge Level screen.
                  AppStateScope.of(context).setAgeRange(selected);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const KnowledgeLevelScreen(),
                    ),
                  );
                },
          child: const Text('Continue'),
        ),
      ),
      child: Column(
        children: [
          _option('6 - 9 years old'),
          const SizedBox(height: 12),
          _option('10 - 13 years old'),
          const SizedBox(height: 12),
          _option('14+ years old'),
        ],
      ),
    );
  }

  Widget _option(String text) {
    final active = selected == text;

    return GestureDetector(
      onTap: () {
        // Only one age option can be selected at a time.
        setState(() {
          selected = text;
        });
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        scale: active ? 1.02 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: active ? OnboardingColors.selected : OnboardingColors.panel,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: active ? OnboardingColors.green : OnboardingColors.border,
              width: 2.5,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: OnboardingColors.green.withValues(alpha: .18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: active ? OnboardingColors.green : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active
                        ? OnboardingColors.green
                        : OnboardingColors.border,
                    width: 2,
                  ),
                ),
                child: active
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: OnboardingColors.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 38),
            ],
          ),
        ),
      ),
    );
  }
}
