import 'package:flutter/material.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/style/app_theme.dart';

class StreakPage extends StatelessWidget {
  const StreakPage({super.key});

  @override
  Widget build(BuildContext context) {
    final completedDays = AppData.streakDays.clamp(0, 7);

    return Scaffold(
      backgroundColor: TudloColors.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 112),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Streak',
                style: TextStyle(
                  color: TudloColors.ink,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Keep showing up and your progress grows.',
                style: TextStyle(
                  color: TudloColors.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [TudloColors.brightGreen, TudloColors.forest],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: TudloColors.forest.withValues(alpha: .18),
                      blurRadius: 26,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .22),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: TudloColors.gold.withValues(alpha: .42),
                            blurRadius: 28,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        size: 56,
                        color: TudloColors.gold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${AppData.streakDays} Day Streak',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${AppData.energyPoints} energy points collected',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: List.generate(7, (index) {
                        final active = index < completedDays;
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            height: 10,
                            decoration: BoxDecoration(
                              color: active
                                  ? TudloColors.gold
                                  : Colors.white.withValues(alpha: .25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TudloCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          color: TudloColors.forest,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'This week',
                          style: TextStyle(
                            color: TudloColors.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: List.generate(7, (index) {
                        final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Expanded(
                          child: _StreakDay(
                            label: labels[index],
                            completed: index < completedDays,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: TudloColors.softGreen,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: TudloColors.line),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.emoji_events_rounded, color: TudloColors.forest),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Keep going! You're doing great!",
                        style: TextStyle(
                          color: TudloColors.forest,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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
}

class _StreakDay extends StatelessWidget {
  final String label;
  final bool completed;

  const _StreakDay({required this.label, required this.completed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: completed ? TudloColors.brightGreen : TudloColors.paper,
            shape: BoxShape.circle,
            border: Border.all(
              color: completed ? TudloColors.brightGreen : TudloColors.line,
              width: 2,
            ),
            boxShadow: completed
                ? [
                    BoxShadow(
                      color: TudloColors.brightGreen.withValues(alpha: .18),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            completed ? Icons.check_rounded : Icons.circle_outlined,
            color: completed ? Colors.white : TudloColors.muted,
            size: completed ? 23 : 18,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: TextStyle(
            color: completed ? TudloColors.forest : TudloColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
