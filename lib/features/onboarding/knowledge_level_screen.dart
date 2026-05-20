import 'package:flutter/material.dart';
import 'package:tudloapp/core/models/proficiency.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/features/navigation/scaffold_card.dart';
import 'package:tudloapp/features/onboarding/evaluation_intro_screen.dart';

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
      subtitle: '',
      bottomAction: SizedBox(
        //continue button
        width: MediaQuery.sizeOf(context).width * .74,
        height: 58,
        child: ElevatedButton(
          onPressed: selected == null
              ? null
              : () {
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
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: active
                          ? OnboardingColors.green
                          : OnboardingColors.panel2,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: active
                            ? OnboardingColors.green
                            : OnboardingColors.green.withValues(alpha: .82),
                        width: 2.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option.label,
                            style: TextStyle(
                              color: active
                                  ? Colors.white
                                  : OnboardingColors.text,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 38,
                          height: 34,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ...List.generate(4, (barIndex) {
                                final filled = barIndex < option.level;
                                return Container(
                                  width: 5,
                                  height: 9.0 + barIndex * 5,
                                  margin: const EdgeInsets.only(left: 3),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? Colors.white.withValues(
                                            alpha: filled ? 1 : .42,
                                          )
                                        : filled
                                        ? OnboardingColors.green
                                        : OnboardingColors.muted,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
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
