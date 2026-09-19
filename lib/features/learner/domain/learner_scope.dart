import 'package:flutter/widgets.dart';

import 'package:tudlo/features/learner/domain/learner_profile.dart';
import 'package:tudlo/features/learner/domain/learner_repository.dart';
import 'package:tudlo/features/settings/domain/app_settings.dart';

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
  ///
  /// [initialSettings] seeds the new learner's own `LearnerProfile.settings`
  /// -- pass the current device-wide `AppSettingsController.settings` at
  /// the call site so a brand new learner starts from whatever was already
  /// configured at the main menu. This is a one-time copy, not a live
  /// link: once created, the learner's settings are fully independent from
  /// the device-wide ones and from every other learner's own copy. Omit it
  /// to fall back to [AppSettings.defaults].
  Future<void> createAndSave({
    required String name,
    required int grade,
    required int energy,
    AppSettings? initialSettings,
  }) async {
    final created = LearnerProfile(
      id: LearnerRepository.generateId(),
      name: name,
      grade: grade,
      energy: energy,
      createdAt: DateTime.now(),
      settings: initialSettings ?? AppSettings.defaults,
    );
    _profile = created;
    notifyListeners();
    try {
      await _repository.setCurrent(created);
    } catch (_) {
      // Best-effort: the app keeps using the in-memory profile either way.
    }
  }

  /// Logs out the current learner: clears it from memory immediately (so
  /// every screen watching [profile] sees `null` right away) and
  /// best-effort forgets it as "current" on disk too, so a fresh app
  /// launch doesn't silently resume this learner. A no-op if there's no
  /// current learner.
  Future<void> logOut() async {
    if (_profile == null) return;
    _profile = null;
    notifyListeners();
    try {
      await _repository.clearCurrent();
    } catch (_) {
      // Best-effort, same as createAndSave.
    }
  }

  /// The most recently active learner, even after [logOut] -- unlike
  /// [profile], logging out does not clear this. Lets the main menu's
  /// "continue" keep naming whoever you'd resume, independent of whether
  /// anyone is actively signed in right now. `null` if nothing has ever
  /// been used on this device, or storage is unavailable.
  Future<LearnerProfile?> loadLastUsedProfile() async {
    try {
      return await _repository.loadLastUsed();
    } catch (_) {
      return null;
    }
  }

  /// Every learner profile currently saved on this device -- the Load
  /// screen's real save list.
  Future<List<LearnerProfile>> listSavedProfiles() async {
    try {
      return await _repository.listSavedProfiles();
    } catch (_) {
      return const [];
    }
  }

  /// Makes [profile] the current learner (e.g. picking a real save to load)
  /// -- same effect [createAndSave] has, just for an already-existing
  /// profile instead of a brand new one.
  Future<void> switchTo(LearnerProfile profile) async {
    _profile = profile;
    notifyListeners();
    try {
      await _repository.setCurrent(profile);
    } catch (_) {
      // Best-effort, same as createAndSave.
    }
  }

  /// Deletes [id] outright. If it's the profile currently in memory, clears
  /// it (same in-memory effect as [logOut]) so nothing keeps reading a
  /// profile that no longer exists on disk.
  Future<void> deleteProfile(String id) async {
    if (_profile?.id == id) {
      _profile = null;
      notifyListeners();
    }
    try {
      await _repository.deleteProfile(id);
    } catch (_) {
      // Best-effort, same as createAndSave.
    }
  }

  /// Updates the current learner's energy level (10-100, in 10% steps --
  /// same range/step as onboarding's energy setter) and best-effort
  /// persists it. This is the "parent controlled" value the Learning &
  /// Energy settings panel edits, and what Home's lesson panel reads to
  /// cap how many lessons are available today
  /// (`home_lesson_panel.dart`'s `_availableLessons`). A no-op if there's
  /// no current learner yet.
  Future<void> setEnergy(int energy) async {
    final current = _profile;
    if (current == null) return;
    final updated = current.copyWith(energy: energy);
    _profile = updated;
    notifyListeners();
    try {
      await _repository.save(updated);
    } catch (_) {
      // Best-effort, same as createAndSave.
    }
  }

  /// Replaces the current learner's own [AppSettings] (language, volumes,
  /// animation/quality preferences, lesson reminders) and best-effort
  /// persists it. This is what General/Sound & Voice/Display &
  /// Performance/Learning & Energy's "Lesson Reminders" write to while
  /// `insideLearnerProfile` is true, instead of the device-wide
  /// `AppSettingsController`. A no-op if there's no current learner yet.
  Future<void> updateSettings(AppSettings settings) async {
    final current = _profile;
    if (current == null) return;
    final updated = current.copyWith(settings: settings);
    _profile = updated;
    notifyListeners();
    try {
      await _repository.save(updated);
    } catch (_) {
      // Best-effort, same as createAndSave.
    }
  }

  /// Records [locationId] (a `MapLocation.persistedId`) as permanently unlocked
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

  /// Records [id] (a `DictionaryEntry.id`) as the current learner's word of
  /// the day for [date], plus the updated rotation [history], and
  /// best-effort persists it. A no-op if there's no current learner yet.
  Future<void> recordWordOfTheDay({
    required String id,
    required DateTime date,
    required Set<String> history,
  }) async {
    final current = _profile;
    if (current == null) return;
    final updated = current.copyWith(
      wordOfTheDayId: id,
      wordOfTheDayDate: date,
      wordOfTheDayHistory: history,
    );
    _profile = updated;
    notifyListeners();
    try {
      await _repository.save(updated);
    } catch (_) {
      // Best-effort, same as createAndSave.
    }
  }

  /// Bumps [category]'s per-learner interest counter (used by
  /// `resolveFeatured` to rank which categories the featured tray should
  /// draw from) and best-effort persists it. A no-op if there's no current
  /// learner yet.
  Future<void> incrementCategorySearchCount(String category) async {
    final current = _profile;
    if (current == null) return;
    final count = (current.categorySearchCounts[category] ?? 0) + 1;
    final updated = current.copyWith(
      categorySearchCounts: {
        ...current.categorySearchCounts,
        category: count,
      },
    );
    _profile = updated;
    notifyListeners();
    try {
      await _repository.save(updated);
    } catch (_) {
      // Best-effort, same as createAndSave.
    }
  }

  /// Records [ids] (`DictionaryEntry.id`s) as the current learner's
  /// featured-tray picks for [date], plus the updated rotation [history],
  /// and best-effort persists it. A no-op if there's no current learner
  /// yet.
  ///
  /// [decayedCategoryCounts], when passed, replaces the stored
  /// `categorySearchCounts` in the same save -- `DictionaryBrowseScreen`
  /// passes `decayCategorySearchCounts(profile.categorySearchCounts)` here
  /// once a day (whenever this is a fresh pick, not a same-day cache hit)
  /// so old interest fades instead of accumulating forever. Omit it to
  /// leave the counts untouched.
  Future<void> recordFeatured({
    required List<String> ids,
    required DateTime date,
    required Set<String> history,
    Map<String, int>? decayedCategoryCounts,
  }) async {
    final current = _profile;
    if (current == null) return;
    final updated = current.copyWith(
      featuredIds: ids,
      featuredDate: date,
      featuredHistory: history,
      categorySearchCounts: decayedCategoryCounts,
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
