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
  int selected = 1;

  final labels = const ['Beginner', 'Basic', 'Intermediate', 'Advanced'];

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
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: active
                        ? OnboardingColors.panel2
                        : OnboardingColors.bg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: active
                          ? OnboardingColors.green
                          : OnboardingColors.border,
                      width: 4,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: List.generate(4, (barIndex) {
                            final filled = barIndex < level;
                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                height: 12,
                                decoration: BoxDecoration(
                                  color: filled
                                      ? (active
                                            ? OnboardingColors.green
                                            : OnboardingColors.green)
                                      : OnboardingColors.border,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        labels[index],
                        style: TextStyle(
                          color: active
                              ? OnboardingColors.green
                              : OnboardingColors.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                AppStateScope.of(context).setKnowledgeLevel(selected);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
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
