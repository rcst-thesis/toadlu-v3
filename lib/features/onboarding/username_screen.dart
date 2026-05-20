import 'package:flutter/material.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/features/navigation/scaffold_card.dart';
import 'package:tudloapp/features/onboarding/age_range_screen.dart';

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldCard(
      title: 'How would you like us to call you?',
      subtitle: '',
      bottomAction: SizedBox(
        //continue button
        width: MediaQuery.sizeOf(context).width * .74,
        height: 58,
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
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: OnboardingColors.shadow,
                  blurRadius: focusNode.hasFocus ? 18 : 0,
                  offset: focusNode.hasFocus
                      ? const Offset(0, 9)
                      : const Offset(8, 8),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              cursorColor: OnboardingColors.blue,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: OnboardingColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
              decoration: InputDecoration(
                hintText: 'Type your name here...',
                hintStyle: const TextStyle(
                  color: OnboardingColors.muted,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
                filled: true,
                fillColor: OnboardingColors.panel2,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: OnboardingColors.border,
                    width: 3,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: OnboardingColors.border,
                    width: 3,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: OnboardingColors.border,
                    width: 4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
