import 'package:flutter/material.dart';
import '../app_state.dart';
import 'age_range_screen.dart';
import 'scaffold_card.dart';

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldCard(
      title: 'How would you like us to call you?',
      subtitle: '',
      child: Column(
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            cursorColor: OnboardingColors.blue,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: OnboardingColors.text,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              hintText: '',
              filled: true,
              fillColor: OnboardingColors.panel2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: const BorderSide(
                  color: OnboardingColors.border,
                  width: 3,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: const BorderSide(
                  color: OnboardingColors.border,
                  width: 3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) return;
                AppStateScope.of(context).setUsername(controller.text.trim());
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AgeRangeScreen()),
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
