import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

/// Interactive Koka's barangay map, 1:1 replacement for the earlier static
/// SVG composite. The Rive file owns the whole scene's interactivity (each
/// location's availability/active/tap state via its own state machine and
/// nested `MapLocationStates` view model); Flutter only loads it, binds the
/// default view model instance, and displays it.
///
/// [onHouseActivated] fires when Koka's house is tapped while it reports
/// itself available (`house/isAvailable`); other locations aren't wired to
/// anything yet since they have no destination.
class RiveMapScene extends StatefulWidget {
  const RiveMapScene({this.onHouseActivated, super.key});

  static const artboardWidth = 2400.0;
  static const artboardHeight = 1400.0;
  static const _assetPath = 'assets/images/map_scene.riv';

  final VoidCallback? onHouseActivated;

  @override
  State<RiveMapScene> createState() => _RiveMapSceneState();
}

class _RiveMapSceneState extends State<RiveMapScene> {
  rive.File? _file;
  rive.RiveWidgetController? _controller;
  rive.ViewModelInstance? _viewModel;
  rive.ViewModelInstanceTrigger? _houseTrigger;
  void Function(bool)? _onHouseTriggered;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
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

    final controller = rive.RiveWidgetController(file);
    final viewModel = controller.dataBind(rive.DataBind.auto());
    if (!mounted) {
      viewModel.dispose();
      controller.dispose();
      file.dispose();
      return;
    }

    final houseTrigger = viewModel.trigger('house/eventTriggered');
    if (houseTrigger != null) {
      void onHouseTriggered(bool _) {
        if (viewModel.boolean('house/isAvailable')?.value ?? false) {
          widget.onHouseActivated?.call();
        }
      }

      houseTrigger.addListener(onHouseTriggered);
      _onHouseTriggered = onHouseTriggered;
    }

    setState(() {
      _file = file;
      _controller = controller;
      _viewModel = viewModel;
      _houseTrigger = houseTrigger;
    });
  }

  @override
  void dispose() {
    final onHouseTriggered = _onHouseTriggered;
    if (onHouseTriggered != null) {
      _houseTrigger?.removeListener(onHouseTriggered);
    }
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
          : rive.RiveWidget(
              controller: controller,
              fit: rive.Fit.fill,
              alignment: Alignment.center,
            ),
    );
  }
}
