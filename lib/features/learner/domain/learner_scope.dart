import 'package:flutter/widgets.dart';

import 'package:tudlo/features/learner/domain/learner_profile.dart';
import 'package:tudlo/features/learner/domain/learner_repository.dart';

/// The app's one current [LearnerProfile], if any, and the single place
/// that creates/updates/persists it. `profile` is `null` until either
/// [loadSaved] finds one on disk or [createAndSave] makes a new one (e.g.
/// at the end of onboarding) -- screens should treat `null` as "nothing
/// loaded yet" and fall back to their own sensible defaults, not as an
/// error.
class LearnerController extends ChangeNotifier {
  LearnerController({LearnerRepository repository = const LearnerRepository()})
      : _repository = repository;

  final LearnerRepository _repository;
  LearnerProfile? _profile;

  LearnerProfile? get profile => _profile;

  /// Loads whatever learner was last saved as current, if any. Safe to call
  /// even if nothing has ever been saved, or if storage isn't available at
  /// all (e.g. a widget test with no `shared_preferences` mock set up) --
  /// either way [profile] is just left `null`, same as "nothing saved yet".
  Future<void> loadSaved() async {
    try {
      final loaded = await _repository.loadCurrent();
      if (loaded == null) return;
      _profile = loaded;
      notifyListeners();
    } catch (_) {
      // Storage unavailable/corrupt: proceed with no restored profile
      // rather than crashing startup over it.
    }
  }

  /// Creates a new learner from onboarding's collected data and makes it
  /// current immediately (so the rest of the app sees it right away), then
  /// best-effort persists it -- a failed save shouldn't block finishing
  /// onboarding, it just means the profile won't survive a restart.
  Future<void> createAndSave({
    required String name,
    required int grade,
    required int energy,
  }) async {
    final created = LearnerProfile(
      id: LearnerRepository.generateId(),
      name: name,
      grade: grade,
      energy: energy,
      createdAt: DateTime.now(),
    );
    _profile = created;
    notifyListeners();
    try {
      await _repository.setCurrent(created);
    } catch (_) {
      // Best-effort: the app keeps using the in-memory profile either way.
    }
  }

  /// Records [locationId] (a `MapLocation.riveId`) as permanently unlocked
  /// on the current learner and best-effort persists it. A no-op if there's
  /// no current learner yet, or it's already unlocked.
  Future<void> unlockMapLocation(String locationId) async {
    final current = _profile;
    if (current == null) return;
    if (current.unlockedMapLocations.contains(locationId)) return;
    final updated = current.copyWith(
      unlockedMapLocations: {...current.unlockedMapLocations, locationId},
    );
    _profile = updated;
    notifyListeners();
    try {
      await _repository.save(updated);
    } catch (_) {
      // Best-effort, same as createAndSave.
    }
  }

  /// Toggles [wordId] (a `DictionaryEntry.id`) in the current learner's
  /// favorited words and best-effort persists it. A no-op if there's no
  /// current learner yet.
  Future<void> toggleFavoriteWord(String wordId) async {
    final current = _profile;
    if (current == null) return;
    final isFavorited = current.favoritedWords.contains(wordId);
    final updated = current.copyWith(
      favoritedWords: isFavorited
          ? ({...current.favoritedWords}..remove(wordId))
          : {...current.favoritedWords, wordId},
    );
    _profile = updated;
    notifyListeners();
    try {
      await _repository.save(updated);
    } catch (_) {
      // Best-effort, same as createAndSave.
    }
  }
}

/// Makes the app's one [LearnerController] available to every screen,
/// without threading it through navigation call sites. Same pattern as
/// `AppAnimationScope` (`lib/core/motion/app_animation_controller.dart`).
class LearnerScope extends InheritedNotifier<LearnerController> {
  const LearnerScope({
    required LearnerController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  /// Returns the shared controller if one is above [context], otherwise a
  /// fresh standalone one with no loaded profile -- e.g. a widget test that
  /// pumps a screen inside a bare `MaterialApp` rather than the full
  /// `TudloApp` shell.
  static LearnerController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LearnerScope>();
    return scope?.notifier ?? LearnerController();
  }
}
