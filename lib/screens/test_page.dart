import 'package:flutter/material.dart';
import '../app_data.dart';
import '../app_theme.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final TextEditingController controller = TextEditingController();
  late bool showTutorial = !AppData.testTutorialDone;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _dismissTutorial() {
    setState(() {
      showTutorial = false;
      AppData.testTutorialDone = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          TudloPageBackground(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 112),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Practice Test',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Answer a short prompt and check what you remember.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TudloCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: TudloColors.green.withValues(
                                  alpha: 0.13,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.fact_check_rounded,
                                color: TudloColors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Test 1',
                                style: TextStyle(
                                  color: TudloColors.ink,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'What is the English meaning of "Tubig"?',
                          style: TextStyle(
                            color: TudloColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: 'Type your answer here',
                            filled: true,
                            fillColor: TudloColors.paper,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onTap: () {
                            if (showTutorial) {
                              setState(() {
                                showTutorial = false;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showTutorial)
            Positioned.fill(
              child: GestureDetector(
                onTap: _dismissTutorial,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 30),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Text(
                        "Let's try to know how much you've learned",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
