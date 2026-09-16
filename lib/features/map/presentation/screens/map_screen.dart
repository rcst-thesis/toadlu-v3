import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tudlo/core/navigation/app_bottom_tab_navigation.dart';
import 'package:tudlo/core/navigation/fade_page_route.dart';
import 'package:tudlo/features/learner/domain/learner_scope.dart';
import 'package:tudlo/features/map/domain/map_location.dart';
import 'package:tudlo/features/map/domain/map_progress.dart';
import 'package:tudlo/features/map/domain/map_route_resolver.dart';
import 'package:tudlo/features/map/presentation/widgets/map_exit_landscape_button.dart';
import 'package:tudlo/features/map/presentation/widgets/map_expand_button.dart';
import 'package:tudlo/features/map/presentation/widgets/rive_map_scene.dart';

/// Pannable/zoomable barangay map, framed on Koka's house by default. The
/// map art lives inside the Rive scene; this screen frames/pans/zooms it and
/// owns navigation -- reacting to `locationTapped` events the Rive scene
/// itself detects and fires (Rive owns hit-testing and press/locked-tap
/// feedback in this asset), debouncing taps, resolving default vs.
/// active-event routes, and navigating, or showing a locked explanation
/// instead. See [MapDefaultRoutes] and [MapEventOverrides].
///
/// The map itself renders full-bleed behind the status bar so it isn't cut
/// off at the top of the screen; only the overlay controls (label, expand/
/// exit buttons) are padded to stay clear of the safe area.
///
/// The expand button switches to a landscape fullscreen view zoomed out to
/// show nearly the whole map (bottom nav and system bars hidden); the exit
/// button on that view restores normal portrait mode framed back on the
/// house.
class MapScreen extends StatefulWidget {
  /// [eventOverrides] lets a caller supply its own [MapEventOverrides]
  /// instance -- mainly for tests. Real app code shouldn't need this:
  /// without one, MapScreen uses the app's single shared instance from
  /// [MapProgressScope] (wired once in `TudloApp`), which is what makes
  /// overrides survive leaving and returning to the Map tab, since
  /// MapScreen itself is rebuilt fresh every time it's navigated to (e.g.
  /// from [AppBottomTabNavigation]).
  const MapScreen({this.eventOverrides, super.key});

  final MapEventOverrides? eventOverrides;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _mapWidth = RiveMapScene.artboardWidth;
  static const _mapHeight = RiveMapScene.artboardHeight;

  // Koka's house sits roughly here in the map art; used to frame the
  // default portrait camera position.
  static const _houseCenterX = 2085.0;
  static const _houseCenterY = 1064.5;
  static const _portraitCropWidth = 420.0;
  static const _portraitVerticalAnchor = 0.42;

  // Fullscreen/landscape zooms out to show nearly the whole map instead.
  static const _fullscreenCropWidth = _mapWidth * 0.96;
  static const _fullscreenCenterX = _mapWidth / 2;
  static const _fullscreenCenterY = _mapHeight / 2;

  // "barangay koka" label size, native aspect ratio (233x60) preserved.
  // Smaller again in fullscreen, where the zoomed-out map leaves less
  // headroom for it.
  static const _labelWidth = 182.0;
  static const _labelHeight = 47.0;
  static const _fullscreenLabelWidth = 140.0;
  static const _fullscreenLabelHeight = 36.0;

  static const _portraitOrientations = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ];
  static const _landscapeOrientations = [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  final _transformationController = TransformationController();
  final _riveMapController = RiveMapSceneController();

  // Resolved once dependencies are available (see [didChangeDependencies]):
  // [widget.eventOverrides] if the caller supplied one (tests), otherwise
  // the app's shared instance from [MapProgressScope]. Neither is ever
  // owned/disposed by this screen -- a caller-supplied one is the caller's
  // responsibility, and the shared one outlives this screen by design.
  late final MapEventOverrides _eventOverrides;
  late final MapProgressController _mapProgress;
  late final LearnerController _learnerController;
  var _dependenciesResolved = false;

  Size? _viewportSize;
  var _isFullscreen = false;
  var _isHandlingTap = false;

  // Rate-limits the locked-location SnackBar -- without this, mashing a
  // locked location spams a new SnackBar on every single tap. `null` means
  // none has been shown yet this screen instance.
  static const _lockedMessageCooldown = Duration(seconds: 5);
  DateTime? _lastLockedMessageAt;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dependenciesResolved) return;
    _mapProgress = MapProgressScope.of(context);
    _eventOverrides = widget.eventOverrides ?? _mapProgress.eventOverrides;
    _learnerController = LearnerScope.of(context);
    // Bring in whatever this learner already had unlocked (from a previous
    // session, or an earlier tab visit this session) before the very first
    // sync pass, so it's included in the very first replay.
    for (final id in _learnerController.profile?.unlockedMapLocations ??
        const <String>{}) {
      final location = MapLocation.fromPersistedId(id);
      if (location != null) _mapProgress.unlock(location);
    }
    _eventOverrides.addListener(_syncEventVisuals);
    _dependenciesResolved = true;
  }

  // Keeps two Flutter-owned, Rive-visible booleans in sync: `hasEvent`
  // (golden/bouncy visual hint) follows whether each location currently has
  // an event override exactly, on while the override is set and off once
  // it's cleared. `isUnlocked` only ever moves one direction here for a
  // given location -- forced true the first time it gets an override (and
  // recorded in `_mapProgress.unlockedLocations`, then persisted onto the
  // current learner via `_learnerController.unlockMapLocation`), left true
  // afterwards even once that override clears. An event permanently unlocks
  // a location it touches; it never re-locks one. House is always unlocked,
  // permanently, from the start of a new game -- not conditional on
  // progression like every other location.
  //
  // Unlike the previous map asset, `isUnlocked` isn't partially Rive-owned
  // here -- Flutter is the sole source of truth for it now, so every
  // location's unlocked state (not just newly-overridden ones) is written
  // explicitly on every sync, from `_mapProgress.unlockedLocations`. That
  // list is what makes an unlock survive leaving and returning to the Map
  // tab within a session (the Rive scene itself resets to the asset's
  // packaged defaults every time it's reloaded, i.e. every time this screen
  // is rebuilt), and `_learnerController` is what makes it survive an app
  // restart too, once that learner is loaded again.
  //
  // Runs whenever MapEventOverrides changes, and once more when the Rive
  // scene finishes loading, to pick up overrides/unlocks that already
  // existed before this screen existed.
  void _syncEventVisuals() {
    _riveMapController.setUnlocked(MapLocation.house, true);
    for (final location in MapLocation.values) {
      if (location == MapLocation.house) continue;
      _riveMapController.setUnlocked(
        location,
        _mapProgress.unlockedLocations.contains(location),
      );
    }
    for (final location in MapLocation.values) {
      final hasOverride = _eventOverrides.overrideFor(location) != null;
      _riveMapController.setHasEvent(location, hasOverride);
      if (hasOverride) {
        _riveMapController.setUnlocked(location, true);
        _mapProgress.unlock(location);
        unawaited(_learnerController.unlockMapLocation(location.persistedId));
      }
    }
  }

  @override
  void dispose() {
    _eventOverrides.removeListener(_syncEventVisuals);
    _transformationController.dispose();
    if (_isFullscreen) _restorePortrait();
    super.dispose();
  }

  Matrix4 _framedOn({
    required Size viewport,
    required double cropWidth,
    required double centerX,
    required double centerY,
    double verticalAnchor = 0.5,
  }) {
    final scale = viewport.width / cropWidth;
    final cropHeight = viewport.height / scale;
    final cropLeft =
        (centerX - cropWidth / 2).clamp(0.0, _mapWidth - cropWidth);
    final cropTop = (centerY - cropHeight * verticalAnchor)
        .clamp(0.0, _mapHeight - cropHeight);
    return Matrix4.identity()
      ..scaleByDouble(scale, scale, scale, 1)
      ..translateByDouble(-cropLeft, -cropTop, 0, 1);
  }

  Matrix4 _defaultFramingFor(Size viewport) {
    return _isFullscreen
        ? _framedOn(
            viewport: viewport,
            cropWidth: _fullscreenCropWidth,
            centerX: _fullscreenCenterX,
            centerY: _fullscreenCenterY,
          )
        : _framedOn(
            viewport: viewport,
            cropWidth: _portraitCropWidth,
            centerX: _houseCenterX,
            centerY: _houseCenterY,
            verticalAnchor: _portraitVerticalAnchor,
          );
  }

  // Rive detects the tap itself and fires `locationTapped` -- for every tap
  // it registers, locked or not, playing its own press or locked-shake
  // feedback internally. Flutter just decides what a tap on an unlocked vs.
  // locked location means. `_isHandlingTap` blocks a second tap from
  // interrupting an in-flight navigation.
  Future<void> _handleLocationTapped(MapLocation location) async {
    if (_isHandlingTap) return;

    if (!_riveMapController.isUnlocked(location)) {
      final now = DateTime.now();
      final lastShown = _lastLockedMessageAt;
      if (lastShown == null ||
          now.difference(lastShown) >= _lockedMessageCooldown) {
        _lastLockedMessageAt = now;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_lockedMessageFor(location)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    _isHandlingTap = true;
    // A short beat so Rive's own press feedback is visible before the
    // screen navigates away.
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    switch (_eventOverrides.resolve(location)) {
      case GoHomeRouteAction():
        Navigator.of(context).popUntil((route) => route.isFirst);
      case PushScreenRouteAction(:final builder):
        Navigator.of(context)
            .push(FadePageRoute<void>(page: Builder(builder: builder)));
    }

    _isHandlingTap = false;
  }

  static const _locationNames = {
    MapLocation.house: 'house',
    MapLocation.school: 'school',
    MapLocation.plaza: 'plaza',
    MapLocation.market: 'market',
    MapLocation.farm: 'farm',
    MapLocation.beach: 'beach',
    MapLocation.church: 'church',
    MapLocation.hospital: 'hospital',
  };

  // Child-friendly, not a bare "locked" error -- explains a locked tap
  // without technical language, per the map's not-busy/not-distracting,
  // playful-but-inviting design.
  String _lockedMessageFor(MapLocation location) {
    final name = _locationNames[location] ?? 'this place';
    return 'The $name is still locked! Finish more lessons to open it.';
  }

  void _enterFullscreen() {
    SystemChrome.setPreferredOrientations(_landscapeOrientations);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    setState(() => _isFullscreen = true);
    _viewportSize = null;
  }

  void _restorePortrait() {
    SystemChrome.setPreferredOrientations(_portraitOrientations);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _exitFullscreen() {
    _restorePortrait();
    setState(() => _isFullscreen = false);
    _viewportSize = null;
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      key: const Key('map-screen'),
      backgroundColor: const Color(0xFFB9DDA0),
      bottomNavigationBar:
          _isFullscreen ? null : const AppBottomTabNavigation(currentIndex: 3),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = Size(constraints.maxWidth, constraints.maxHeight);
          if (_viewportSize != viewport) {
            _viewportSize = viewport;
            _transformationController.value = _defaultFramingFor(viewport);
          }
          final cropWidth =
              _isFullscreen ? _fullscreenCropWidth : _portraitCropWidth;
          // The larger of the two fit ratios, so the map always fully
          // covers the viewport at the minimum zoom (never leaves a gap
          // exposing the Scaffold's background behind it).
          final minScale =
              viewport.width / _mapWidth > viewport.height / _mapHeight
                  ? viewport.width / _mapWidth
                  : viewport.height / _mapHeight;
          final initialScale = viewport.width / cropWidth;

          return Stack(
            key: const Key('map-content-stack'),
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  key: const Key('map-interactive-viewer'),
                  transformationController: _transformationController,
                  constrained: false,
                  boundaryMargin: EdgeInsets.zero,
                  minScale: minScale,
                  maxScale: initialScale * 3,
                  child: RepaintBoundary(
                    child: RiveMapScene(
                      controller: _riveMapController,
                      onLocationTapped: _handleLocationTapped,
                      onReady: _syncEventVisuals,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: topInset + 24,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: _isFullscreen ? _fullscreenLabelWidth : _labelWidth,
                    height:
                        _isFullscreen ? _fullscreenLabelHeight : _labelHeight,
                    child: SvgPicture.asset(
                      'assets/images/map_barangay_koka_label.svg',
                    ),
                  ),
                ),
              ),
              if (_isFullscreen)
                Positioned(
                  key: const Key('map-exit-landscape-button'),
                  top: topInset + 16,
                  right: 16,
                  child: MapExitLandscapeButton(onPressed: _exitFullscreen),
                )
              else
                Positioned(
                  key: const Key('map-expand-button'),
                  right: 16,
                  bottom: 16,
                  child: MapExpandButton(onPressed: _enterFullscreen),
                ),
            ],
          );
        },
      ),
    );
  }
}
