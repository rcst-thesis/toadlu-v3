import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tudlo/core/navigation/app_bottom_tab_navigation.dart';
import 'package:tudlo/features/map/presentation/widgets/map_exit_landscape_button.dart';
import 'package:tudlo/features/map/presentation/widgets/map_expand_button.dart';
import 'package:tudlo/features/map/presentation/widgets/rive_map_scene.dart';

/// Pannable/zoomable barangay map, framed on Koka's house by default. The
/// map art and all per-location interactivity (availability, active state,
/// tap events) live inside the Rive scene itself; this screen just frames
/// and pans/zooms it.
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
  const MapScreen({super.key});

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

  static const _portraitOrientations = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ];
  static const _landscapeOrientations = [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  final _transformationController = TransformationController();
  Size? _viewportSize;
  var _isFullscreen = false;

  @override
  void dispose() {
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

  // Tapping Koka's house while it's available goes straight to Home, same
  // as tapping the Home tab. Later, other events may replace this with
  // something else (e.g. opening the house itself) once that exists.
  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
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
          final minScale =
              viewport.width / _mapWidth < viewport.height / _mapHeight
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
                    child: RiveMapScene(onHouseActivated: _goHome),
                  ),
                ),
              ),
              Positioned(
                top: topInset + 24,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 233,
                    height: 60,
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
