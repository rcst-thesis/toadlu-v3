import 'package:flutter/material.dart';
import '../app_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _green = Color(0xFF08C66B);

  final PageController _controller = PageController();
  int currentPage = 0;

  final data = const [
    {
      'title': 'Learn\nHiligaynon\nand English\nin a fun\nway',
      'align': Alignment.centerLeft,
    },
    {
      'title': 'Type\nwords and\nswitch\nbetween\nlanguages\neasily',
      'align': Alignment.centerRight,
    },
    {
      'title': 'Play lessons,\nanswer\nquizzes, and\ntrack\nprogress',
      'align': Alignment.centerLeft,
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (currentPage < data.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AppShell(initialIndex: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _green,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: data.length,
                onPageChanged: (value) {
                  setState(() {
                    currentPage = value;
                  });
                },
                itemBuilder: (context, index) {
                  final align = data[index]['align']! as Alignment;
                  final isRight = align == Alignment.centerRight;

                  return Align(
                    alignment: align,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: isRight ? 76 : 30,
                        right: isRight ? 28 : 54,
                        top: 24,
                        bottom: 118,
                      ),
                      child: Text(
                        data[index]['title']! as String,
                        textAlign: isRight ? TextAlign.right : TextAlign.left,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          height: .90,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(data.length, (index) {
                final active = currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : const Color(0xFF087D49),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 0, 30, 22),
              child: SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _green,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
