import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/style/app_theme.dart';
import 'package:tudloapp/core/style/forest_art.dart';

class StreakPage extends StatefulWidget {
  const StreakPage({super.key});

  @override
  State<StreakPage> createState() => _StreakPageState();
}

class _StreakPageState extends State<StreakPage> {
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    AppData.updateKokaStatus();
    _statusTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      AppData.updateKokaStatus();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _useCareAction({
    required String name,
    required bool Function() spendAndCare,
  }) {
    final caredFor = spendAndCare();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(caredFor ? '$name used for Koka.' : 'Not enough XP.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: caredFor ? TudloColors.forest : TudloColors.coral,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    AppData.updateKokaStatus();

    return Scaffold(
      backgroundColor: TudloColors.cloud,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 116),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Koka',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TudloColors.brightGreen,
                  fontSize: 38,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              _HabitatScene(
                points: AppData.energyPoints,
                health: AppData.kokaHealth,
                hungry: AppData.kokaHungry,
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 17),
                decoration: BoxDecoration(
                  color: TudloColors.green,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Menu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _NeedCard(
                            asset: 'assets/images/food.png',
                            title: 'Insect',
                            cost: 50,
                            gain: '+40',
                            status: 'Hungry',
                            enabled: AppData.energyPoints >= 50,
                            onTap: () => _useCareAction(
                              name: 'Insect',
                              spendAndCare: AppData.feedKoka,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _NeedCard(
                            asset: 'assets/images/clean.png',
                            title: 'Clean',
                            cost: 70,
                            gain: '+30',
                            status: 'Health',
                            enabled: AppData.energyPoints >= 70,
                            onTap: () => _useCareAction(
                              name: 'Clean',
                              spendAndCare: AppData.cleanKokaPond,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _NeedCard(
                            asset: 'assets/images/sleep.png',
                            title: 'Sleep',
                            cost: 60,
                            gain: '+40',
                            status: 'Health',
                            enabled: AppData.energyPoints >= 60,
                            onTap: () => _useCareAction(
                              name: 'Sleep',
                              spendAndCare: AppData.restKoka,
                            ),
                          ),
                        ),
                      ],
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

class _HabitatScene extends StatelessWidget {
  final int points;
  final int health;
  final int hungry;

  const _HabitatScene({
    required this.points,
    required this.health,
    required this.hungry,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sceneHeight = (constraints.maxWidth * .62).clamp(250.0, 360.0);
        final statusWidth = (constraints.maxWidth * .38).clamp(160.0, 250.0);

        return SizedBox(
          height: sceneHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/pond.jpeg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: .14),
                        Colors.transparent,
                        TudloColors.forest.withValues(alpha: .18),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 9,
                  top: 18,
                  child: SizedBox(
                    width: statusWidth,
                    child: Column(
                      children: [
                        _SceneStatusBar(
                          label: 'Health Bar',
                          value: health,
                          color: TudloColors.green,
                        ),
                        const SizedBox(height: 8),
                        _SceneStatusBar(
                          label: 'Hungry Bar',
                          value: hungry,
                          color: TudloColors.green,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(top: 10, right: 9, child: _XpPill(points: points)),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        width: 198,
                        height: 58,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5DA74E).withValues(alpha: .34),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const TudloMascot(size: 176),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SceneStatusBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SceneStatusBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1,
            shadows: [Shadow(color: TudloColors.forest, blurRadius: 4)],
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            children: [
              Container(height: 22, color: Colors.white.withValues(alpha: .86)),
              FractionallySizedBox(
                widthFactor: value / 100,
                child: Container(height: 22, color: color),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '$value',
                      style: const TextStyle(
                        color: TudloColors.forest,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _XpPill extends StatelessWidget {
  final int points;

  const _XpPill({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: TudloColors.cloud,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .72)),
        boxShadow: [
          BoxShadow(
            color: TudloColors.forest.withValues(alpha: .12),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: TudloColors.green, size: 22),
          const SizedBox(width: 4),
          Text(
            '$points XP',
            style: const TextStyle(
              color: TudloColors.forest,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedCard extends StatelessWidget {
  final String asset;
  final String title;
  final int cost;
  final String gain;
  final String status;
  final bool enabled;
  final VoidCallback onTap;

  const _NeedCard({
    required this.asset,
    required this.title,
    required this.cost,
    required this.gain,
    required this.status,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          height: 180,
          padding: const EdgeInsets.fromLTRB(6, 12, 6, 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: enabled ? Colors.white : TudloColors.line,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: TudloColors.forest.withValues(alpha: .06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$title: $cost XP',
                  maxLines: 1,
                  style: TextStyle(
                    color: enabled ? TudloColors.green : TudloColors.muted,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Opacity(
                    opacity: enabled ? 1 : .55,
                    child: Image.asset(
                      asset,
                      width: 104,
                      height: 104,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$gain $status',
                  maxLines: 1,
                  style: TextStyle(
                    color: enabled ? TudloColors.green : TudloColors.muted,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
