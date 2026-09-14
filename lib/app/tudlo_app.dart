import 'dart:async';

import 'package:flutter/material.dart';

import 'package:tudlo/core/motion/app_animation_controller.dart';
import 'package:tudlo/core/theme/app_colors.dart';
import 'package:tudlo/features/learner/domain/learner_scope.dart';
import 'package:tudlo/features/map/domain/map_progress.dart';
import 'package:tudlo/features/startup/presentation/startup_flow.dart';

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

  @override
  void initState() {
    super.initState();
    unawaited(_learnerController.loadSaved());
  }

  @override
  void dispose() {
    _animationController.dispose();
    _learnerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppAnimationScope(
      controller: _animationController,
      child: LearnerScope(
        controller: _learnerController,
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
              final animationsEnabled = AppAnimationScope.of(context).isEnabled;
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
    );
  }
}
