import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/theme/app_theme.dart';

/// Koka companion page.
///
/// Koka is now an energy-based companion only. The full-screen pond is Koka's
/// calm home environment.
class PetPage extends StatefulWidget {
  const PetPage({super.key});

  @override
  State<PetPage> createState() => _PetPageState();
}

class _PetPageState extends State<PetPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    AppData.refreshEnergy(save: true);
    // Recalculate recharge while the page is visible so Koka's mood and the
    // compact energy number stay in sync with real elapsed time.
    _timer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await AppData.refreshEnergy(save: true);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<int>(
        valueListenable: AppData.energyRevision,
        builder: (context, _, __) {
          final size = MediaQuery.sizeOf(context);
          final petSize = (size.width * .46).clamp(168.0, 250.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Full-screen pond setup: the image fills the entire tab
              // edge-to-edge so the page feels like Koka's environment rather
              // than a card inside a normal settings page.
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
                      TudloColors.forest.withValues(alpha: .18),
                      Colors.transparent,
                      TudloColors.forest.withValues(alpha: .22),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Stack(
                  children: [
                    // Energy widget placement: compact and tucked into the
                    // upper-right so it is readable but does not block Koka or
                    // the pond scenery.
                    const Positioned(
                      top: 14,
                      right: 16,
                      child: _CompactEnergyPill(),
                    ),
                    // Name label positioning: centered above Koka with a soft
                    // translucent chip to keep the text readable on the pond.
                    Positioned(
                      left: 0,
                      right: 0,
                      top: size.height * .33,
                      child: const Center(child: _KokaNameChip()),
                    ),
                    // Koka positioning: these offsets place the pet-state art
                    // over the central rock area in pond.jpeg so Koka feels
                    // grounded in the scene instead of floating over water.
                    Positioned(
                      left: 0,
                      right: 0,
                      top: size.height * .39,
                      child: Center(
                        child: Image.asset(
                          AppData.kokaPetAsset,
                          width: petSize,
                          height: petSize,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _KokaNameChip extends StatelessWidget {
  const _KokaNameChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .84),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: TudloColors.forest.withValues(alpha: .16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Text(
        'Koka',
        style: TextStyle(
          color: TudloColors.forest,
          fontSize: 24,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CompactEnergyPill extends StatelessWidget {
  const _CompactEnergyPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: .58),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: TudloColors.forest.withValues(alpha: .16),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.battery_charging_full_rounded,
            color: TudloColors.green,
            size: 24,
          ),
          const SizedBox(width: 6),
          Text(
            '${AppData.currentEnergy}/${AppData.maxEnergy}',
            style: const TextStyle(
              color: TudloColors.forest,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
