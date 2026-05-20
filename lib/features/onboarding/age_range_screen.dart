import 'package:flutter/material.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/features/navigation/scaffold_card.dart';
import 'package:tudloapp/features/onboarding/knowledge_level_screen.dart';

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
      subtitle: '',
      bottomAction: SizedBox(
        //continue button
        width: MediaQuery.sizeOf(context).width * .74,
        height: 58,
        child: ElevatedButton(
          onPressed: selected.isEmpty
              ? null
              : () {
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            color: active ? OnboardingColors.green : OnboardingColors.panel2,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: active
                  ? OnboardingColors.green
                  : OnboardingColors.green.withValues(alpha: .82),
              width: 2.5,
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: active ? Colors.white : OnboardingColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
