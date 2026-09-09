import 'package:flutter/material.dart';

import 'package:tudlo/core/motion/app_animation_controller.dart';
import 'package:tudlo/core/theme/app_colors.dart';
import 'package:tudlo/shared/widgets/design_navigation_button.dart';

/// Temporary Settings shell with the app-wide animation switch.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final animationController = AppAnimationScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.mint,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'animations',
                                  style: TextStyle(
                                    color: AppColors.darkGreen,
                                    fontFamily: 'ComicRelief',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'turn animations on or off',
                                  style: TextStyle(
                                    color: Color(0xFF4F5355),
                                    fontFamily: 'ComicRelief',
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            key: const Key('settings-animation-switch'),
                            value: animationController.isEnabled,
                            onChanged: animationController.setEnabled,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AdaptiveBackButtonPlacement(
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
