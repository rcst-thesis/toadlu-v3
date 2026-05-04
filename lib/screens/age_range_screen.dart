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
          _option('6 - 9'),
          const SizedBox(height: 12),
          _option('10 - 13'),
          const SizedBox(height: 12),
          _option('14+'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 19),
        decoration: BoxDecoration(
          color: active ? OnboardingColors.panel2 : OnboardingColors.bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: active ? OnboardingColors.green : OnboardingColors.border,
            width: 4,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? OnboardingColors.green : OnboardingColors.text,
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
