import 'package:flutter/material.dart';
import '../app_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentPage = 0;

  final data = const [
    {
      'title': 'Welcome to Tudlo',
      'subtitle': 'Learn Hiligaynon and English in a fun way.',
    },
    {
      'title': 'Translate with Ease',
      'subtitle': 'Type words and switch between languages easily.',
    },
    {
      'title': 'Practice and Improve',
      'subtitle': 'Play lessons, answer quizzes, and track progress.',
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5CC8F2), Color(0xFFA7E4FA)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppShell(initialIndex: 1),
                      ),
                    );
                  },
                  child: const Text(
                    'Skip',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
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
                    return Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Icon(
                              Icons.menu_book,
                              color: Colors.white,
                              size: 100,
                            ),
                          ),
                          const SizedBox(height: 36),
                          Text(
                            data[index]['title']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            data[index]['subtitle']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(data.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: currentPage == index ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: currentPage == index
                          ? Colors.white
                          : Colors.white54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _next,
                    child: Text(
                      currentPage == data.length - 1 ? 'Get Started' : 'Next',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
