import 'package:flutter/material.dart';

import 'package:tudlo/core/theme/app_colors.dart';
import 'package:tudlo/features/load/domain/save_preview.dart';
import 'package:tudlo/features/load/presentation/widgets/load_confirmation_dialog.dart';
import 'package:tudlo/features/load/presentation/widgets/save_card.dart';
import 'package:tudlo/shared/widgets/design_navigation_button.dart';

class LoadScreen extends StatefulWidget {
  const LoadScreen({super.key});

  @override
  State<LoadScreen> createState() => _LoadScreenState();
}

class _LoadScreenState extends State<LoadScreen> {
  static const _pageSize = 4;

  final saves = const <SavePreview>[
    SavePreview(
      name: 'Koka',
      grade: GradeLevel.grade1,
    ),
    SavePreview(
      name: 'Koka pero kulay blue',
      grade: GradeLevel.grade2,
    ),
    SavePreview(
      name: 'Koka 3',
      grade: GradeLevel.grade1,
    ),
    SavePreview(
      name: 'Koka pero kulay red',
      grade: GradeLevel.grade3,
    ),
    SavePreview(
      name: 'Koka 5',
      grade: GradeLevel.grade1,
    ),
    SavePreview(
      name: 'Koka 6',
      grade: GradeLevel.grade2,
    ),
    SavePreview(
      name: 'Koka 7',
      grade: GradeLevel.grade3,
    ),
  ];

  int _currentPage = 0;

  int get _pageCount => (saves.length / _pageSize).ceil();

  void _goToPage(int page) {
    if (page < 0 || page >= _pageCount || page == _currentPage) return;
    setState(() => _currentPage = page);
  }

  Future<void> _confirm(int index, bool deleting) async {
    final save = saves[index];
    final accepted = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: deleting ? 'Delete confirmation' : 'Load confirmation',
      barrierColor: Colors.black.withValues(alpha: 0.51),
      transitionDuration: const Duration(milliseconds: 160),
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
      pageBuilder: (context, animation, secondaryAnimation) =>
          LoadConfirmationDialog(
        name: save.name,
        previewColor: save.previewColor,
        previewAsset: save.assetPath,
        deleting: deleting,
      ),
    );
    if (!mounted || accepted != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text(deleting ? '${save.name} deleted' : '${save.name} loaded')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageStart = _currentPage * _pageSize;
    final visibleSaves = saves.skip(pageStart).take(_pageSize).toList();

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.zero,
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    key: const Key('load-page-canvas'),
                    width: 412,
                    height: 917,
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: FittedBox(
                        fit: BoxFit.fill,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: 412,
                          height: 917,
                          child: MediaQuery.withNoTextScaling(
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 47,
                                  top: 108,
                                  child: SizedBox(
                                    key: const Key('load-header-image'),
                                    width: 318,
                                    height: 186.5,
                                    child: Image.asset(
                                      'assets/images/load_logo.png',
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.high,
                                      semanticLabel:
                                          'maayong pag balik! Load saved progress',
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 26,
                                  top: 323,
                                  width: 360,
                                  child: Wrap(
                                    alignment: WrapAlignment.start,
                                    runAlignment: WrapAlignment.start,
                                    spacing: 24,
                                    runSpacing: 18,
                                    children: [
                                      for (var index = 0;
                                          index < visibleSaves.length;
                                          index++)
                                        SizedBox(
                                          width: 168,
                                          height: 193,
                                          child: SaveCard(
                                            name: visibleSaves[index].name,
                                            previewColor: visibleSaves[index]
                                                .previewColor,
                                            previewShadowColor:
                                                visibleSaves[index]
                                                    .previewShadowColor,
                                            previewAsset:
                                                visibleSaves[index].assetPath,
                                            onLoad: () => _confirm(
                                                pageStart + index, false),
                                            onDelete: () => _confirm(
                                                pageStart + index, true),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: AdaptiveBackButtonPlacement(
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale = _largeScreenScale(constraints);
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    26 * scale,
                    0,
                    26 * scale,
                    16 * scale,
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: 255 * scale,
                      child: Row(
                        key: const Key('load-pagination'),
                        children: [
                          _ScaledDesignControl(
                            scale: scale,
                            child: DesignNavigationButton(
                              key: const Key('load-previous-button'),
                              label: 'previous',
                              enabled: _currentPage > 0,
                              onPressed: () => _goToPage(_currentPage - 1),
                            ),
                          ),
                          SizedBox(width: 20 * scale),
                          SizedBox(
                            width: 29 * scale,
                            height: 19 * scale,
                            child: FittedBox(
                              fit: BoxFit.fill,
                              child: Container(
                                key: const Key('load-page-number'),
                                width: 29,
                                height: 19,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.green,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_currentPage + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    height: 1,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 20 * scale),
                          _ScaledDesignControl(
                            scale: scale,
                            child: DesignNavigationButton(
                              key: const Key('load-next-button'),
                              label: 'next',
                              enabled: _currentPage < _pageCount - 1,
                              onPressed: () => _goToPage(_currentPage + 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

double _largeScreenScale(BoxConstraints constraints) {
  final widthScale = constraints.maxWidth / 412;
  final heightScale = constraints.maxHeight / 917;
  return widthScale < heightScale ? widthScale : heightScale;
}

class _ScaledDesignControl extends StatelessWidget {
  const _ScaledDesignControl({required this.scale, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 93 * scale,
      height: 44 * scale,
      child: FittedBox(fit: BoxFit.fill, child: child),
    );
  }
}
