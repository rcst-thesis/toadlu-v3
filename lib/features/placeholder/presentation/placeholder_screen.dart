import 'package:flutter/material.dart';

import 'package:tudlo/core/theme/app_colors.dart';
import 'package:tudlo/shared/widgets/design_navigation_button.dart';
import 'package:tudlo/shared/widgets/rive_placeholder.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.title,
    required this.description,
    required this.icon,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColoredBox(
        color: AppColors.mint,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 100, 28, 28),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RivePlaceholder(label: '$title\nRive placeholder'),
                          const SizedBox(height: 28),
                          Icon(icon, size: 42, color: AppColors.darkGreen),
                          const SizedBox(height: 12),
                          Text(
                            description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 17, height: 1.4),
                          ),
                        ],
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
      ),
    );
  }
}
