import 'package:flutter/material.dart';

import 'package:tudlo/features/map/domain/map_location.dart';
import 'package:tudlo/features/placeholder/presentation/placeholder_screen.dart';

/// What happens when a map location's tap resolves. Most locations push a
/// screen; House's default action instead returns to Home (mirroring the
/// bottom tab's Home behavior), so it's modeled separately from a push.
sealed class MapRouteAction {
  const MapRouteAction();
}

/// Pops back to the app's root route, same as tapping the Home tab.
class GoHomeRouteAction extends MapRouteAction {
  const GoHomeRouteAction();
}

/// Pushes the screen built by [builder].
class PushScreenRouteAction extends MapRouteAction {
  const PushScreenRouteAction(this.builder);

  final WidgetBuilder builder;
}

/// Flutter-owned default destination for each map location. These are the
/// project's real screens where they exist (only Home, via
/// [GoHomeRouteAction] for House); every other location has no built screen
/// yet, so it opens a temporary shell consistent with the other
/// not-yet-built bottom-tab destinations (Translate/Lessons/Dictionary) --
/// see `AppBottomTabNavigation.destinationFor`.
class MapDefaultRoutes {
  const MapDefaultRoutes._();

  static const Map<MapLocation, MapRouteAction> _actions = {
    MapLocation.house: GoHomeRouteAction(),
    MapLocation.school: PushScreenRouteAction(_school),
    MapLocation.plaza: PushScreenRouteAction(_plaza),
    MapLocation.market: PushScreenRouteAction(_market),
    MapLocation.farm: PushScreenRouteAction(_farm),
    MapLocation.beach: PushScreenRouteAction(_beach),
    MapLocation.church: PushScreenRouteAction(_church),
    MapLocation.hospital: PushScreenRouteAction(_hospital),
  };

  static MapRouteAction actionFor(MapLocation location) =>
      _actions[location] ?? const GoHomeRouteAction();

  static Widget _school(BuildContext context) => const PlaceholderScreen(
        title: 'School',
        description: 'Temporary School shell',
        icon: Icons.school_rounded,
      );

  static Widget _plaza(BuildContext context) => const PlaceholderScreen(
        title: 'Plaza',
        description: 'Temporary Plaza shell',
        icon: Icons.park_rounded,
      );

  static Widget _market(BuildContext context) => const PlaceholderScreen(
        title: 'Market',
        description: 'Temporary Market shell',
        icon: Icons.storefront_rounded,
      );

  static Widget _farm(BuildContext context) => const PlaceholderScreen(
        title: 'Farm',
        description: 'Temporary Farm shell',
        icon: Icons.agriculture_rounded,
      );

  static Widget _beach(BuildContext context) => const PlaceholderScreen(
        title: 'Beach',
        description: 'Temporary Beach shell',
        icon: Icons.beach_access_rounded,
      );

  static Widget _church(BuildContext context) => const PlaceholderScreen(
        title: 'Church',
        description: 'Temporary Church shell',
        icon: Icons.church_rounded,
      );

  static Widget _hospital(BuildContext context) => const PlaceholderScreen(
        title: 'Hospital',
        description: 'Temporary Hospital shell',
        icon: Icons.local_hospital_rounded,
      );
}

/// Flutter-owned truth for any lesson/event that currently overrides a map
/// location's default destination. Empty by default (no active event), in
/// which case every location resolves to [MapDefaultRoutes]. A caller (the
/// future lesson/event system) sets an override while its lesson/event is
/// active and clears it when that lesson/event ends, restoring the default.
class MapEventOverrides extends ChangeNotifier {
  final Map<MapLocation, MapRouteAction> _overrides = {};

  MapRouteAction? overrideFor(MapLocation location) => _overrides[location];

  /// Resolves [location]'s current destination: its active-event override
  /// if one is set, otherwise its default route.
  MapRouteAction resolve(MapLocation location) =>
      _overrides[location] ?? MapDefaultRoutes.actionFor(location);

  void setOverride(MapLocation location, MapRouteAction action) {
    _overrides[location] = action;
    notifyListeners();
  }

  void clearOverride(MapLocation location) {
    if (_overrides.remove(location) != null) notifyListeners();
  }

  /// Clears every override, e.g. when the active event ends. All locations
  /// return to their default routes.
  void clearAll() {
    if (_overrides.isEmpty) return;
    _overrides.clear();
    notifyListeners();
  }
}
