import 'package:flutter/material.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/features/onboarding/widgets/scaffold_card.dart';
import 'package:tudloapp/features/onboarding/screens/age_range_screen.dart';

/// First onboarding screen.
///
/// This screen collects the name that appears later on the Home Map and
/// Profile page.
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
    controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Continue stays disabled until the user enters a non-empty name.
    final hasName = controller.text.trim().isNotEmpty;

    return ScaffoldCard(
      title: 'What should we call you?',
      subtitle: 'This helps personalize your experience.',
      bottomAction: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: hasName
              ? () {
                  // Continue button:
                  // Save the name in AppState, then direct the user to the
                  // Age Range screen, which is the next onboarding step.
                  AppStateScope.of(context).setUsername(controller.text.trim());
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AgeRangeScreen()),
                  );
                }
              : null,
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
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
              decoration: InputDecoration(
                hintText: 'Type your name here...',
                hintStyle: const TextStyle(
                  color: OnboardingColors.muted,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                filled: true,
                fillColor: OnboardingColors.panel,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 21,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(
                    color: OnboardingColors.border,
                    width: 2.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(
                    color: OnboardingColors.border,
                    width: 2.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(
                    color: OnboardingColors.green,
                    width: 3,
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
