import 'package:flutter/material.dart';

import 'package:tudlo/core/navigation/fade_page_route.dart';
import 'package:tudlo/core/theme/app_colors.dart';
import 'package:tudlo/features/home/presentation/screens/fourth_loading_screen.dart';
import 'package:tudlo/features/load/presentation/load_screen.dart';
import 'package:tudlo/features/onboarding/presentation/screens/name_screen.dart';
import 'package:tudlo/features/settings/presentation/settings_screen.dart';
import 'package:tudlo/shared/widgets/rive_long_button.dart';
import 'package:tudlo/shared/widgets/rive_settings_button.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(FadePageRoute<void>(page: screen));
  }

  void _replaceWith(BuildContext context, Widget screen) {
    Navigator.of(context).pushReplacement(FadePageRoute<void>(page: screen));
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
                    child: RiveSettingsButton(
                      key: const Key('main-settings-button'),
                      onPressed: () => _open(
                        context,
                        const SettingsScreen(),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 30,
                    top: 629,
                    width: 352.295,
                    height: RiveLongButton.height,
                    child: RiveLongButton(
                      label: 'start new koka',
                      onPressed: () => _open(context, const NameScreen()),
                    ),
                  ),
                  Positioned(
                    left: 30,
                    top: 699,
                    width: 352,
                    height: RiveLongButton.height,
                    child: RiveLongButton(
                      label: 'continue',
                      onPressed: () =>
                          _replaceWith(context, const FourthLoadingScreen()),
                    ),
                  ),
                  Positioned(
                    left: 30,
                    top: 763,
                    width: 352,
                    height: RiveLongButton.height,
                    child: RiveLongButton(
                      label: 'load',
                      onPressed: () => _open(context, const LoadScreen()),
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
