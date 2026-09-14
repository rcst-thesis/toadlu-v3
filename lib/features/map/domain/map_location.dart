/// A tappable location on Koka's barangay map. Names match the Rive view
/// model's per-location namespace exactly (e.g. `house/isAvailable`,
/// `house/eventTriggered`), so [riveId] is just the enum name.
enum MapLocation {
  house,
  school,
  plaza,
  market,
  farm,
  beach,
  church,
  hospital;

  String get riveId => name;

  /// The [MapLocation] whose [riveId] matches [id], or `null` if none does
  /// -- e.g. a stale id from a saved learner profile if a location is ever
  /// renamed or removed.
  static MapLocation? fromRiveId(String id) {
    for (final location in values) {
      if (location.riveId == id) return location;
    }
    return null;
  }
}
