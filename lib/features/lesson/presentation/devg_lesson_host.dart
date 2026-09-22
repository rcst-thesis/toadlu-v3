import 'dart:async';

import 'package:flutter/material.dart';

import 'package:tudlo/features/learner/domain/learner_scope.dart';
import 'package:tudlo/features/lesson/domain/lesson_definition.dart';
import 'package:tudlo/features/lesson/domain/lesson_progress_controller.dart';
import 'package:tudlo/features/lesson/presentation/devg_canonical/core/data/app_data.dart';
import 'package:tudlo/features/lesson/presentation/devg_canonical/core/models/lesson_score.dart';
import 'package:tudlo/features/lesson/presentation/devg_canonical/core/services/app_audio_service.dart';
import 'package:tudlo/features/lesson/presentation/devg_canonical/core/state/app_state.dart';
import 'package:tudlo/features/lesson/presentation/devg_canonical/features/home_map/screens/lessons_screen.dart'
    hide MapLocation;
import 'package:tudlo/features/lesson/presentation/devg_canonical/features/lesson_game/screens/lesson_intro_page.dart';
import 'package:tudlo/features/lesson/presentation/devg_canonical/features/lesson_game/screens/level_game_page.dart'
    as devg;
import 'package:tudlo/features/lesson/presentation/devg_lesson_host_scope.dart';
import 'package:tudlo/features/lesson/presentation/devg_lesson_mapping.dart';
import 'package:tudlo/features/map/domain/map_location.dart';
import 'package:tudlo/shared/audio/tudlo_audio_scope.dart';

/// Hosts the preserved DevG lesson-card page inside Tudlo.
///
/// Its artwork, carousel, card narration, and interaction mechanics remain
/// source-authentic. Navigation, persistence, energy, and audio are projected
/// from Tudlo at this boundary rather than imported from DevG.
class DevGLessonCatalogHost extends StatefulWidget {
  const DevGLessonCatalogHost({this.location, super.key});

  final MapLocation? location;

  @override
  State<DevGLessonCatalogHost> createState() => _DevGLessonCatalogHostState();
}

class _DevGLessonCatalogHostState extends State<DevGLessonCatalogHost> {
  LessonDefinition? _running;
  Future<void>? _completion;

  void _startSourceLevel(int sourceLevel) {
    final grade = LearnerScope.of(context).profile?.grade ?? 1;
    final lesson = DevGLessonMapping.definitionFor(
      grade: grade,
      sourceLevel: sourceLevel,
    );
    if (lesson != null) setState(() => _running = lesson);
  }

  Future<void> _claim(LessonScoreStats score) {
    final running = _running;
    if (running == null) return Future.value();
    return _completion ??= _completeLesson(context, running, score);
  }

  Future<void> _returnToCards({bool waitForCompletion = false}) async {
    if (waitForCompletion) await (_completion ?? Future<void>.value());
    if (!mounted) return;
    setState(() {
      _running = null;
      _completion = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final running = _running;
    return _DevGLessonEnvironment(
      running: running,
      catalogLocation: widget.location,
      onStartSourceLevel: _startSourceLevel,
      onClaim: _claim,
      onExitIncomplete: _returnToCards,
      onExitAfterCompletion: () => _returnToCards(waitForCompletion: true),
      child: Builder(builder: (context) {
        if (running == null) return const LessonsScreen();
        final level = DevGLessonMapping.sourceLevelFor(running);
        return devg.LevelGamePage(level: level);
      }),
    );
  }
}

/// Opens one preserved flow from Home or the real Rive map. Closing it always
/// returns to the route that launched it; there is no DevG navigation shell.
class DevGLessonRunnerScreen extends StatefulWidget {
  const DevGLessonRunnerScreen({required this.lessonId, super.key});

  final String lessonId;

  @override
  State<DevGLessonRunnerScreen> createState() => _DevGLessonRunnerScreenState();
}

class _DevGLessonRunnerScreenState extends State<DevGLessonRunnerScreen> {
  Future<void>? _completion;
  var _activityStarted = false;

  LessonDefinition? get _lesson => LessonCatalog.byId(widget.lessonId);

  Future<void> _claim(LessonScoreStats score) {
    final lesson = _lesson;
    if (lesson == null) return Future.value();
    return _completion ??= _completeLesson(context, lesson, score);
  }

  Future<void> _exit({required bool waitForCompletion}) async {
    if (waitForCompletion) await (_completion ?? Future<void>.value());
    if (mounted) Navigator.of(context).pop();
  }

  void _startSourceLevel(int sourceLevel) {
    final lesson = _lesson;
    if (lesson == null ||
        sourceLevel != DevGLessonMapping.sourceLevelFor(lesson)) {
      return;
    }
    setState(() => _activityStarted = true);
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson;
    if (lesson == null) {
      return const Scaffold(
          body: Center(child: Text('Wala nakita ang leksiyon.')));
    }
    return _DevGLessonEnvironment(
      running: lesson,
      catalogLocation: null,
      onStartSourceLevel: _startSourceLevel,
      onClaim: _claim,
      onExitIncomplete: () => _exit(waitForCompletion: false),
      onExitAfterCompletion: () => _exit(waitForCompletion: true),
      child: _activityStarted
          ? devg.LevelGamePage(level: DevGLessonMapping.sourceLevelFor(lesson))
          : LessonIntroPage(level: DevGLessonMapping.sourceLevelFor(lesson)),
    );
  }
}

class _DevGLessonEnvironment extends StatefulWidget {
  const _DevGLessonEnvironment({
    required this.running,
    required this.catalogLocation,
    required this.onStartSourceLevel,
    required this.onClaim,
    required this.onExitIncomplete,
    required this.onExitAfterCompletion,
    required this.child,
  });

  final LessonDefinition? running;
  final MapLocation? catalogLocation;
  final void Function(int) onStartSourceLevel;
  final Future<void> Function(LessonScoreStats) onClaim;
  final Future<void> Function() onExitIncomplete;
  final Future<void> Function() onExitAfterCompletion;
  final Widget child;

  @override
  State<_DevGLessonEnvironment> createState() => _DevGLessonEnvironmentState();
}

class _DevGLessonEnvironmentState extends State<_DevGLessonEnvironment> {
  AppState? _appState;
  String? _activeProfileId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final learner = LearnerScope.of(context).profile;
    if (_appState != null && _activeProfileId == learner?.id) return;
    _appState?.dispose();
    _activeProfileId = learner?.id;
    _appState = AppState(
      username: learner?.name ?? 'Abyan',
      activeProfileId: learner?.id,
    );
  }

  @override
  void dispose() {
    _appState?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final learner = LearnerScope.of(context).profile;
    final progress = LessonProgressScope.of(context);
    final grade = learner?.grade ?? 1;
    final unlocked = <int>[];
    final completed = <int>[];
    final stickers = <int, String>{};
    final catalogLessons = _catalogLessonsFor(
      grade: grade,
      running: widget.running,
      location: widget.catalogLocation,
    );

    for (final lesson in LessonCatalog.forGrade(grade)) {
      final sourceLevel = DevGLessonMapping.sourceLevelFor(lesson);
      if (progress.isUnlocked(lesson)) unlocked.add(sourceLevel);
      final completion = progress.progress.completions[lesson.id];
      if (completion != null) {
        completed.add(sourceLevel);
        stickers[sourceLevel] = completion.rewardAsset;
      }
    }
    AppData.configure(
      grade: grade,
      energy: learner?.energy ?? AppData.maxEnergy,
      unlockedLevels: unlocked,
      completed: completed,
      stickers: stickers,
      catalogLevels: catalogLessons.map(DevGLessonMapping.sourceLevelFor),
    );
    AppAudioService.instance.attach(TudloAudioScope.maybeOf(context));

    return AppStateScope(
      notifier: _appState!,
      child: DevGLessonHostScope(
        startSourceLevel: widget.onStartSourceLevel,
        exitIncomplete: widget.onExitIncomplete,
        exitAfterCompletion: widget.onExitAfterCompletion,
        claimCompletion: widget.onClaim,
        child: widget.child,
      ),
    );
  }
}

List<LessonDefinition> _catalogLessonsFor({
  required int grade,
  required LessonDefinition? running,
  required MapLocation? location,
}) {
  if (running != null) return <LessonDefinition>[running];

  // Grade 3 map lessons already handle their own location sequence after a
  // card is started. Keeping the catalog whole prevents a map entry from
  // hiding the other approved Grade 3 lessons.
  if (location == null || grade == 3) return LessonCatalog.forGrade(grade);

  return LessonCatalog.forLocation(
    grade: grade,
    location: location,
  );
}

Future<void> _completeLesson(
  BuildContext context,
  LessonDefinition lesson,
  LessonScoreStats score,
) {
  return LessonProgressScope.of(context).completeAndClaim(
    lesson: lesson,
    score: score.accuracy,
    accuracy: (score.accuracy / 100).clamp(0, 1).toDouble(),
    mistakes: score.mistakes,
    duration: Duration(milliseconds: score.timeTakenMs),
  );
}
