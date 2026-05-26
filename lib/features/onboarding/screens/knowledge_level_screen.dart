import 'package:flutter/material.dart';
import 'package:tudloapp/core/models/proficiency.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/features/onboarding/widgets/scaffold_card.dart';
import 'package:tudloapp/features/evaluation/screens/evaluation_intro_screen.dart';

/// Third onboarding screen.
///
/// The visible text is friendly, while the app stores the hidden numeric
/// knowledge level from `KnowledgeOption`.
class KnowledgeLevelScreen extends StatefulWidget {
  const KnowledgeLevelScreen({super.key});

  @override
  State<KnowledgeLevelScreen> createState() => _KnowledgeLevelScreenState();
}

class _KnowledgeLevelScreenState extends State<KnowledgeLevelScreen> {
  KnowledgeOption? selected;

  @override
  Widget build(BuildContext context) {
    return ScaffoldCard(
      title: 'How much Hiligaynon do you know?',
      subtitle: "We'll use this to guide your learning experience.",
      bottomAction: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: selected == null
              ? null
              : () {
                  // Continue button:
                  // Save the selected knowledge option, then direct the user
                  // to the Evaluation Intro screen before entering the app.
                  AppStateScope.of(context).setKnowledgeOption(selected!);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EvaluationIntroScreen(),
                    ),
                  );
                },
          child: const Text('Continue'),
        ),
      ),
      child: Column(
        children: [
          ...List.generate(knowledgeOptions.length, (index) {
            final option = knowledgeOptions[index];
            final active = selected == option;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  // Selecting a new option updates the active green outline.
                  setState(() {
                    selected = option;
                  });
                },
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
                  scale: active ? 1.02 : 1,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    constraints: const BoxConstraints(minHeight: 72),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? OnboardingColors.selected
                          : OnboardingColors.panel,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: active
                            ? OnboardingColors.green
                            : OnboardingColors.border,
                        width: 2.5,
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: OnboardingColors.green.withValues(
                                  alpha: .18,
                                ),
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
                            color: active
                                ? OnboardingColors.green
                                : Colors.transparent,
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
                            option.label,
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
              ),
            );
          }),
        ],
      ),
    );
  }
}
