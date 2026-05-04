import 'package:flutter/material.dart';
import '../app_data.dart';
import '../app_state.dart';
import '../app_theme.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return Scaffold(
      backgroundColor: TudloColors.cloud,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 112),
          child: Column(
            children: [
              Container(
                width: 98,
                height: 98,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: TudloColors.ink.withValues(alpha: 0.12),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: TudloColors.sky,
                  size: 54,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                appState.username.isEmpty ? 'User' : appState.username,
                style: const TextStyle(
                  color: TudloColors.ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Learner Profile',
                style: TextStyle(
                  color: TudloColors.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              TudloCard(
                child: Column(
                  children: [
                    _row(
                      Icons.cake_rounded,
                      'Age Range',
                      appState.ageRange.isEmpty ? 'Not set' : appState.ageRange,
                    ),
                    const Divider(),
                    _row(
                      Icons.stacked_bar_chart_rounded,
                      'Knowledge Level',
                      '${appState.knowledgeLevel}',
                    ),
                    const Divider(),
                    _row(
                      Icons.bolt_rounded,
                      'Energy',
                      '${AppData.energyPoints}',
                    ),
                    const Divider(),
                    _row(
                      Icons.local_fire_department_rounded,
                      'Streak',
                      '${AppData.streakDays} days',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: TudloColors.sky, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: TudloColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: TudloColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
