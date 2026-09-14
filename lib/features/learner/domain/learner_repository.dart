import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:tudlo/features/learner/domain/learner_profile.dart';

/// Persists [LearnerProfile]s to on-device storage via `shared_preferences`
/// -- the whole profile is one small JSON blob, read/written as a unit,
/// never queried by field, which is exactly what `shared_preferences` is
/// for. No backend, no sync: this is local-only, per-device storage.
///
/// Supports only one "current" learner today (this app has no
/// profile-switcher UI yet), but every profile is stored keyed by its own
/// [LearnerProfile.id], so adding multi-profile switching later doesn't
/// require changing how profiles are stored -- only which id is "current."
class LearnerRepository {
  const LearnerRepository();

  static const _currentIdKey = 'learner.currentId';
  static String _profileKey(String id) => 'learner.profile.$id';

  /// A reasonably unique id for a new learner -- fine for local,
  /// single-device uniqueness, which is all this needs today.
  static String generateId() {
    final random = Random();
    return '${DateTime.now().microsecondsSinceEpoch}-${random.nextInt(1 << 32)}';
  }

  Future<LearnerProfile?> loadCurrent() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_currentIdKey);
    if (id == null) return null;
    final raw = prefs.getString(_profileKey(id));
    if (raw == null) return null;
    return LearnerProfile.fromJson(
      jsonDecode(raw) as Map<String, Object?>,
    );
  }

  Future<void> save(LearnerProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _profileKey(profile.id), jsonEncode(profile.toJson()));
  }

  Future<void> setCurrent(LearnerProfile profile) async {
    await save(profile);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentIdKey, profile.id);
  }
}
