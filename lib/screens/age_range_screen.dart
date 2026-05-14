import 'package:flutter/material.dart';
import '../app_state.dart';
import 'knowledge_level_screen.dart';
import 'scaffold_card.dart';

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
      child: Column(
        children: [
          _option('6 - 9 years old'),
          const SizedBox(height: 12),
          _option('10 - 13 years old'),
          const SizedBox(height: 12),
          _option('14+ years old'),
          const SizedBox(height: 26),
          SizedBox(
            width: 138,
            height: 36,
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
              width: active ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: active
                    ? OnboardingColors.shadow
                    : OnboardingColors.green.withValues(alpha: .14),
                blurRadius: active ? 20 : 0,
                offset: active ? const Offset(0, 10) : const Offset(8, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: active ? Colors.white : OnboardingColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: active ? 1 : 0,
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
