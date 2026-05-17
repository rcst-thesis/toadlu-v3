import 'package:flutter/material.dart';
import '../app_state.dart';
import 'onboarding_screen.dart';
import 'scaffold_card.dart';

class KnowledgeLevelScreen extends StatefulWidget {
  const KnowledgeLevelScreen({super.key});

  @override
  State<KnowledgeLevelScreen> createState() => _KnowledgeLevelScreenState();
}

class _KnowledgeLevelScreenState extends State<KnowledgeLevelScreen> {
  int? selected;

  final labels = const [
    "I'm still learning",
    'I know a bit',
    'I can understand most',
    "I'm fluent",
  ];

  @override
  Widget build(BuildContext context) {
    return ScaffoldCard(
      title: 'How much Hiligaynon do you know?',
      subtitle: '',
      child: Column(
        children: [
          ...List.generate(4, (index) {
            final level = index + 1;
            final active = selected == level;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selected = level;
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
                            labels[index],
                            style: TextStyle(
                              color: active
                                  ? Colors.white
                                  : OnboardingColors.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 24,
                          height: 22,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ...List.generate(4, (barIndex) {
                                final filled = barIndex < level;
                                return Container(
                                  width: 3,
                                  height: 5.0 + barIndex * 3,
                                  margin: const EdgeInsets.only(left: 2),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? Colors.white.withValues(
                                            alpha: filled ? 1 : .42,
                                          )
                                        : filled
                                        ? OnboardingColors.green
                                        : OnboardingColors.muted,
                                    borderRadius: BorderRadius.circular(3),
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
          const SizedBox(height: 20),
          SizedBox(
            width: MediaQuery.sizeOf(context).width * .74,
            height: 58,
            child: ElevatedButton(
              onPressed: selected == null
                  ? null
                  : () {
                      AppStateScope.of(context).setKnowledgeLevel(selected!);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OnboardingScreen(),
                        ),
                      );
                    },
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}
