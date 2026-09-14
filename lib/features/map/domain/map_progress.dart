import 'package:flutter/widgets.dart';

import 'package:tudlo/features/map/domain/map_location.dart';
import 'package:tudlo/features/map/domain/map_route_resolver.dart';

/// The app's one long-lived source of Map progress: its shared
/// [MapEventOverrides] (so active-event routing survives leaving and
/// returning to the Map tab, since [MapScreen] itself is rebuilt fresh each
/// time), and every location an event has ever permanently unlocked this
/// session.
///
/// This is an in-memory stand-in for a real per-learner save system, which
/// this project does not have yet (see `docs/MAP_GUIDE.md`). When one
/// exists, [unlockedLocations] is exactly what it should back with
/// persistent, per-learner storage instead -- keep this class's shape, swap
/// its internals.
class MapProgressController {
  final eventOverrides = MapEventOverrides();
  final unlockedLocations = <MapLocation>{};

  /// Records [location] as permanently unlocked. Idempotent -- safe to call
  /// every time an event touches a location, not just the first time.
  void unlock(MapLocation location) => unlockedLocations.add(location);
}

/// Makes the app's one [MapProgressController] available to every screen,
/// without threading it through navigation call sites. Same pattern as
/// `AppAnimationScope` (`lib/core/motion/app_animation_controller.dart`).
class MapProgressScope extends InheritedWidget {
  const MapProgressScope({
    required this.controller,
    required super.child,
    super.key,
  });

  final MapProgressController controller;

  /// Returns the shared controller if one is above [context], otherwise a
  /// fresh standalone one -- e.g. a widget test that pumps `MapScreen` (or
  /// a screen that navigates to it) inside a bare `MaterialApp` rather than
  /// the full `TudloApp` shell. That fallback instance isn't shared with
  /// anything else, so overrides/unlocks made through it only last as long
  /// as whatever holds onto it.
  static MapProgressController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<MapProgressScope>();
    return scope?.controller ?? MapProgressController();
  }

  @override
  bool updateShouldNotify(MapProgressScope oldWidget) =>
      controller != oldWidget.controller;
}
