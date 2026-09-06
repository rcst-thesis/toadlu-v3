import 'package:flutter/material.dart';

import 'package:tudlo/core/navigation/fade_page_route.dart';
import 'package:tudlo/core/theme/app_colors.dart';
import 'package:tudlo/features/load/presentation/load_screen.dart';
import 'package:tudlo/features/onboarding/presentation/screens/name_screen.dart';
import 'package:tudlo/features/placeholder/presentation/placeholder_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(FadePageRoute<void>(page: screen));
  }

  Widget _hitTarget({
    required String label,
    required VoidCallback onTap,
    Key? key,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        key: key,
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Center(child: Opacity(opacity: 0, child: Text(label))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColoredBox(
        color: AppColors.mint,
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 412,
              height: 917,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/main_menu_reference.png',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  const Positioned(
                    left: 70,
                    top: 270,
                    width: 272,
                    height: 300,
                    child: ColoredBox(color: AppColors.mint),
                  ),
                  Positioned(
                    key: const Key('main-menu-logo'),
                    left: 82,
                    top: 280,
                    width: 248,
                    height: 279,
                    child: Image.asset(
                      'assets/images/onboarding_logo.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      semanticLabel: 'Tudlo logo and description',
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    top: 815,
                    width: 412,
                    height: 48,
                    child: ColoredBox(color: AppColors.mint),
                  ),
                  Positioned(
                    key: const Key('main-menu-footer'),
                    left: 30,
                    top: 820,
                    width: 352,
                    height: 42,
                    child: Image.asset(
                      'assets/images/onboarding_footer.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      semanticLabel: 'Tudlo project footer',
                    ),
                  ),
                  Positioned(
                    left: 335,
                    top: 51,
                    width: 47,
                    height: 49,
                    child: _hitTarget(
                      key: const Key('main-settings-button'),
                      label: 'Settings',
                      onTap: () => _open(
                        context,
                        const PlaceholderScreen(
                          title: 'Settings',
                          description: 'Settings screen placeholder',
                          icon: Icons.settings_rounded,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 30,
                    top: 633,
                    width: 352.295,
                    height: 44,
                    child: _hitTarget(
                      label: 'start new koka',
                      onTap: () => _open(context, const NameScreen()),
                    ),
                  ),
                  Positioned(
                    left: 30,
                    top: 703,
                    width: 352,
                    height: 44,
                    child: _hitTarget(
                      label: 'continue',
                      onTap: () => _open(
                        context,
                        const PlaceholderScreen(
                          title: 'Continue',
                          description:
                              'Continue flow placeholder. Connect saved progress here.',
                          icon: Icons.play_circle_outline_rounded,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 30,
                    top: 767,
                    width: 352,
                    height: 44,
                    child: _hitTarget(
                      label: 'load',
                      onTap: () => _open(context, const LoadScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MenuButton extends StatelessWidget {
  const MenuButton({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 5,
          shadowColor: AppColors.darkGreen,
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        child: Text(label),
      ),
    );
  }
}
