import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

import 'package:tudlo/features/map/domain/map_location.dart';

/// Lets a caller fire a location's press feedback without reaching into
/// [RiveMapScene]'s internals. Bound automatically once the scene's Rive
/// file finishes loading; calls made before that (or after the scene is
/// disposed) are silently no-ops, same as every other Rive input in this
/// app that can be asked for before its file is ready.
class RiveMapSceneController {
  _RiveMapSceneState? _state;

  void _attach(_RiveMapSceneState state) => _state = state;

  void _detach(_RiveMapSceneState state) {
    if (identical(_state, state)) _state = null;
  }

  /// Fires `<location>/eventTriggered` so Rive plays that location's 200ms
  /// squash press animation. Purely a visual cue; Flutter still owns
  /// whether/where to navigate.
  void fireTrigger(MapLocation location) => _state?._fireTrigger(location);

  /// Sets `<location>/isActive`, which Rive uses to render that location's
  /// golden/bouncy "active event" visual. Flutter is the source of truth for
  /// this -- it should be `true` exactly while an active lesson/event has an
  /// override set for that location (see `MapEventOverrides` and
  /// `MapScreen._syncEventVisuals`).
  void setActive(MapLocation location, bool value) =>
      _state?._setActive(location, value);

  /// Sets `<location>/isAvailable`. Normally Rive-owned (unlocked by
  /// whatever the app's real progression system is) and Flutter only reads
  /// it -- the one exception is an active lesson/event, which needs a
  /// location to be tappable even if it isn't normally unlocked yet.
  /// `MapScreen._syncEventVisuals` is the only caller: it forces this `true`
  /// the moment a location gets an event override, and leaves it `true`
  /// afterwards -- an event permanently unlocks a location, it never
  /// re-locks one.
  void setAvailable(MapLocation location, bool value) =>
      _state?._setAvailable(location, value);
}

/// Interactive Koka's barangay map (`mapvtwo.riv`, artboard "Brgy. Koka").
/// The Rive file owns the map art and each location's availability/active
/// press-feedback *visuals* via `MapAvailabilityStateMachine` and the
/// `MapLocationStates` view model; it has no click listeners of its own.
/// `isAvailable` is normally Rive-owned data (Flutter only reads it to gate
/// taps) and `isActive` is Flutter-owned (Rive only renders it) -- but see
/// [RiveMapSceneController.setAvailable] for the one case where Flutter
/// temporarily writes `isAvailable` too: an active lesson/event.
///
/// Flutter owns tap detection: this widget lays one transparent tap zone
/// per [MapLocation] over the map, positioned in the artboard's native
/// 2400x1400 coordinate space so they scale/pan together with the Rive
/// scene's own transform (see [RiveMapScene.artboardWidth]/[artboardHeight])
/// instead of fixed phone pixels. A tap calls [onLocationTapped]; firing the
/// squash-feedback trigger, debouncing, delaying, resolving the route, and
/// navigating are the caller's job (see `MapScreen`).
class RiveMapScene extends StatefulWidget {
  const RiveMapScene({
    required this.onLocationTapped,
    this.controller,
    this.onReady,
    super.key,
  });

  static const artboardWidth = 2400.0;
  static const artboardHeight = 1400.0;

  static const _assetPath = 'assets/images/mapvtwo.riv';
  static const _artboardName = 'Brgy. Koka';
  static const _stateMachineName = 'MapAvailabilityStateMachine';

  /// Each location's tap zone in artboard coordinates, calibrated against
  /// the exported map art. Update these if the art's location layout
  /// changes.
  static const Map<MapLocation, Rect> _tapZones = {
    MapLocation.church: Rect.fromLTWH(589, 230, 340, 300),
    MapLocation.farm: Rect.fromLTWH(1719, 70, 420, 300),
    MapLocation.school: Rect.fromLTWH(77, 430, 380, 260),
    MapLocation.plaza: Rect.fromLTWH(959, 330, 380, 260),
    MapLocation.market: Rect.fromLTWH(1382, 470, 380, 260),
    MapLocation.beach: Rect.fromLTWH(179, 930, 380, 300),
    MapLocation.hospital: Rect.fromLTWH(946, 770, 340, 260),
    MapLocation.house: Rect.fromLTWH(1887, 820, 420, 260),
  };

  final Future<void> Function(MapLocation location) onLocationTapped;
  final RiveMapSceneController? controller;

  /// Called once the Rive file has finished loading and [controller]'s
  /// imperative methods (`fireTrigger`, `setActive`) start actually doing
  /// something. Callers that need to sync state in from before the scene
  /// was ready (e.g. active-event overrides set while Map wasn't on screen)
  /// should do that sync here.
  final VoidCallback? onReady;

  @override
  State<RiveMapScene> createState() => _RiveMapSceneState();
}

class _RiveMapSceneState extends State<RiveMapScene> {
  rive.File? _file;
  rive.RiveWidgetController? _controller;
  rive.ViewModelInstance? _viewModel;
  final _triggers = <MapLocation, rive.ViewModelInstanceTrigger>{};
  final _availability = <MapLocation, rive.ViewModelInstanceBoolean>{};
  final _activeStates = <MapLocation, rive.ViewModelInstanceBoolean>{};

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    unawaited(_load());
  }

  @override
  void didUpdateWidget(RiveMapScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  Future<void> _load() async {
    final file = await rive.File.asset(
      RiveMapScene._assetPath,
      riveFactory: rive.Factory.flutter,
    );
    if (!mounted || file == null) {
      file?.dispose();
      return;
    }

    final controller = rive.RiveWidgetController(
      file,
      artboardSelector:
          rive.ArtboardSelector.byName(RiveMapScene._artboardName),
      stateMachineSelector:
          rive.StateMachineSelector.byName(RiveMapScene._stateMachineName),
    );
    final viewModel = controller.dataBind(rive.DataBind.auto());
    if (!mounted) {
      viewModel.dispose();
      controller.dispose();
      file.dispose();
      return;
    }

    final triggers = <MapLocation, rive.ViewModelInstanceTrigger>{};
    final availability = <MapLocation, rive.ViewModelInstanceBoolean>{};
    final activeStates = <MapLocation, rive.ViewModelInstanceBoolean>{};
    for (final location in MapLocation.values) {
      final trigger = viewModel.trigger('${location.riveId}/eventTriggered');
      if (trigger != null) triggers[location] = trigger;
      final isAvailable = viewModel.boolean('${location.riveId}/isAvailable');
      if (isAvailable != null) availability[location] = isAvailable;
      final isActive = viewModel.boolean('${location.riveId}/isActive');
      if (isActive != null) activeStates[location] = isActive;
    }

    setState(() {
      _file = file;
      _controller = controller;
      _viewModel = viewModel;
      _triggers
        ..clear()
        ..addAll(triggers);
      _availability
        ..clear()
        ..addAll(availability);
      _activeStates
        ..clear()
        ..addAll(activeStates);
    });
    widget.onReady?.call();
  }

  void _fireTrigger(MapLocation location) {
    _triggers[location]?.trigger();
  }

  void _setActive(MapLocation location, bool value) {
    _activeStates[location]?.value = value;
  }

  // A location with no `isAvailable` property (shouldn't happen for this
  // asset's contract) fails closed: not tappable rather than silently
  // always-on.
  bool _isAvailable(MapLocation location) =>
      _availability[location]?.value ?? false;

  void _setAvailable(MapLocation location, bool value) {
    _availability[location]?.value = value;
  }

  void _handleTap(MapLocation location) {
    if (!_isAvailable(location)) return;
    widget.onLocationTapped(location);
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _controller?.dispose();
    _viewModel?.dispose();
    _file?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return SizedBox(
      width: RiveMapScene.artboardWidth,
      height: RiveMapScene.artboardHeight,
      child: controller == null
          ? const SizedBox.shrink()
          : Stack(
              children: [
                Positioned.fill(
                  child: rive.RiveWidget(
                    controller: controller,
                    fit: rive.Fit.contain,
                    alignment: Alignment.center,
                  ),
                ),
                for (final entry in RiveMapScene._tapZones.entries)
                  Positioned.fromRect(
                    rect: entry.value,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _handleTap(entry.key),
                    ),
                  ),
              ],
            ),
    );
  }
}
