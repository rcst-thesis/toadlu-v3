import 'package:flutter/material.dart';
import '../app_data.dart';
import '../app_theme.dart';

class StreakPage extends StatelessWidget {
  const StreakPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TudloPageBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 112),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Streak',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Keep showing up and your progress grows.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            TudloCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: TudloColors.coral.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      size: 56,
                      color: TudloColors.coral,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${AppData.streakDays} Day Streak',
                    style: const TextStyle(
                      color: TudloColors.ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppData.energyPoints} energy points collected',
                    style: const TextStyle(
                      color: TudloColors.muted,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: List.generate(7, (index) {
                      final active = index < AppData.streakDays.clamp(0, 7);
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 10,
                          decoration: BoxDecoration(
                            color: active ? TudloColors.gold : TudloColors.line,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
