import 'dart:async';

import 'package:flutter/material.dart';

import 'package:tudlo/core/motion/app_animation_controller.dart';
import 'package:tudlo/core/theme/app_colors.dart';
import 'package:tudlo/features/learner/domain/learner_scope.dart';
import 'package:tudlo/features/map/domain/map_progress.dart';
import 'package:tudlo/features/settings/domain/app_settings_scope.dart';
import 'package:tudlo/features/startup/presentation/startup_flow.dart';
import 'package:tudlo/shared/audio/tudlo_audio_controller.dart';
import 'package:tudlo/shared/audio/tudlo_audio_scope.dart';

class TudloApp extends StatefulWidget {
  const TudloApp({super.key});

  @override
  State<TudloApp> createState() => _TudloAppState();
}

class _TudloAppState extends State<TudloApp> {
  late final AppAnimationController _animationController =
      AppAnimationController();
  final _mapProgress = MapProgressController();
  final _learnerController = LearnerController();
  final _appSettingsController = AppSettingsController();
  final _audioController = TudloAudioController();

  @override
  void initState() {
    super.initState();
    _learnerController.addListener(_syncEffectiveAudioSettings);
    _appSettingsController.addListener(_syncEffectiveAudioSettings);
    unawaited(_learnerController.loadSaved());
    unawaited(_appSettingsController.loadSaved());
  }

  void _syncEffectiveAudioSettings() {
    // Both stores load asynchronously. The audio controller is the one place
    // that reconciles a late-arriving effective setting with active playback.
    final settings =
        _learnerController.profile?.settings ?? _appSettingsController.settings;
    unawaited(_audioController.applySettings(settings));
  }

  @override
  void dispose() {
    _learnerController.removeListener(_syncEffectiveAudioSettings);
    _appSettingsController.removeListener(_syncEffectiveAudioSettings);
    _animationController.dispose();
    _learnerController.dispose();
    _appSettingsController.dispose();
    _audioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppAnimationScope(
      controller: _animationController,
      child: LearnerScope(
        controller: _learnerController,
        child: AppSettingsScope(
          controller: _appSettingsController,
          child: TudloAudioScope(
            controller: _audioController,
            child: MapProgressScope(
            controller: _mapProgress,
            child: MaterialApp(
                title: 'Tudlo',
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  fontFamily: 'ComicRelief',
                  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.green),
                  scaffoldBackgroundColor: AppColors.mint,
                  useMaterial3: true,
                ),
                builder: (context, child) {
                  final animationsEnabled =
                      AppAnimationScope.of(context).isEnabled;
                  final mediaQuery = MediaQuery.of(context);
                  return MediaQuery(
                    data: mediaQuery.copyWith(
                      disableAnimations:
                          mediaQuery.disableAnimations || !animationsEnabled,
                    ),
                    child: child ?? const SizedBox.shrink(),
                  );
                },
                home: const StartupFlow(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
