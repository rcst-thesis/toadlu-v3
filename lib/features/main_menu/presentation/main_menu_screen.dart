import 'dart:async';

import 'package:flutter/material.dart';

import 'package:tudlo/core/navigation/fade_page_route.dart';
import 'package:tudlo/core/theme/app_colors.dart';
import 'package:tudlo/features/home/presentation/screens/fourth_loading_screen.dart';
import 'package:tudlo/features/learner/domain/learner_profile.dart';
import 'package:tudlo/features/learner/domain/learner_scope.dart';
import 'package:tudlo/features/load/presentation/load_screen.dart';
import 'package:tudlo/features/onboarding/presentation/screens/name_screen.dart';
import 'package:tudlo/features/settings/presentation/settings_screen.dart';
import 'package:tudlo/shared/widgets/rive_long_button.dart';
import 'package:tudlo/shared/widgets/rive_settings_button.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  /// How many characters of the learner's name the "continue" button will
  /// show before cutting it off with "..." -- the button is a fixed-size
  /// Rive graphic, not a text field that can wrap or shrink to fit.
  static const _maxContinueNameLength = 10;

  LearnerProfile? _lastUsedProfile;
  var _resolvedLastUsed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only resolve once per mount -- didChangeDependencies can fire again
    // for unrelated inherited-widget changes. No need to fetch anything if
    // someone's already actively signed in.
    if (_resolvedLastUsed) return;
    _resolvedLastUsed = true;
    if (LearnerScope.of(context).profile != null) return;
    unawaited(_loadLastUsedProfile());
  }

  Future<void> _loadLastUsedProfile() async {
    final profile = await LearnerScope.of(context).loadLastUsedProfile();
    if (!mounted || profile == null) return;
    setState(() => _lastUsedProfile = profile);
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(FadePageRoute<void>(page: screen));
  }

  void _replaceWith(BuildContext context, Widget screen) {
    Navigator.of(context).pushReplacement(FadePageRoute<void>(page: screen));
  }

  /// "continue" alone if nobody's ever used this device, otherwise
  /// "continue as `name`" -- naming whoever's actively signed in, or
  /// failing that, whoever was last signed in (see [LearnerController.
  /// loadLastUsedProfile], which survives logging out). Cuts the name off
  /// with "..." once it'd make the label too long for the button.
  String _continueLabel(BuildContext context) {
    final name =
        (LearnerScope.of(context).profile?.name ?? _lastUsedProfile?.name)
            ?.trim();
    if (name == null || name.isEmpty) return 'continue';
    final shown = name.length > _maxContinueNameLength
        ? '${name.substring(0, _maxContinueNameLength - 3)}...'
        : name;
    return 'continue as $shown';
  }

  /// Resuming with nobody actively signed in (e.g. right after logging
  /// out) silently signs back into whoever "continue" named, so Home
  /// actually shows that learner instead of empty defaults.
  Future<void> _continue(BuildContext context) async {
    final scope = LearnerScope.of(context);
    if (scope.profile == null) {
      final resume = _lastUsedProfile ?? await scope.loadLastUsedProfile();
      if (resume != null) await scope.switchTo(resume);
    }
    if (!context.mounted) return;
    _replaceWith(context, const FourthLoadingScreen());
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
                      label: _continueLabel(context),
                      onPressed: () => unawaited(_continue(context)),
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
