import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeEnergyIndicator extends StatelessWidget {
  const HomeEnergyIndicator({this.energy = 60, super.key});

  final int energy;

  @override
  Widget build(BuildContext context) {
    final displayedEnergy = energy.clamp(0, 100);
    return Semantics(
      key: const Key('home-energy-indicator'),
      label: 'Energy $displayedEnergy percent',
      child: SizedBox(
        width: 78,
        height: 52,
        child: Stack(
          children: [
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/images/home_energy_indicator.svg',
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ),
            Positioned(
              left: 16,
              top: 1,
              width: 34,
              height: 14,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFAD6E47),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '$displayedEnergy%',
                    key: const Key('home-energy-label'),
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'ComicRelief',
                      fontSize: 11,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
