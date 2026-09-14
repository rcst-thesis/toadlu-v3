import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tudlo/core/navigation/app_bottom_tab_navigation.dart';
import 'package:tudlo/core/navigation/fade_page_route.dart';
import 'package:tudlo/features/me/presentation/widgets/me_badge_collection.dart';
import 'package:tudlo/features/me/presentation/widgets/me_collections_header.dart';
import 'package:tudlo/features/me/presentation/widgets/me_content_footer.dart';
import 'package:tudlo/features/me/presentation/widgets/me_daily_streak_card.dart';
import 'package:tudlo/features/me/presentation/widgets/me_edit_button.dart';
import 'package:tudlo/features/me/presentation/widgets/me_learner_card.dart';
import 'package:tudlo/features/me/presentation/widgets/me_settings_button.dart';
import 'package:tudlo/features/placeholder/presentation/placeholder_screen.dart';
import 'package:tudlo/features/settings/presentation/settings_screen.dart';
import 'package:tudlo/shared/widgets/rive_settings_button.dart';

/// Incremental Me screen. Currently hosts the top Settings/Edit buttons,
/// the learner card with its about/details/progress tabs, and the daily
/// streak card; badge collection follows later.
///
/// [learnerName], [grade], [userCode], [createdAt], [lessonsFinished],
/// [stickersEarned], [badgesEarned], and [currentStreak] are constructor-
/// carried placeholders, same as Home's `energy` default, until an approved
/// persistent/application-state architecture supplies real learner data.
/// [createdAt] defaults to now, so the "details" tab's age reads "today";
/// the progress counts and streak default honestly (0, 1) rather than
/// fabricated numbers.
class MeScreen extends StatefulWidget {
  MeScreen({
    this.learnerName = 'Koka',
    this.grade = 1,
    this.userCode = '0000001',
    this.lessonsFinished = 0,
    this.stickersEarned = 0,
    this.badgesEarned = 0,
    this.currentStreak = 1,
    DateTime? createdAt,
    super.key,
  }) : createdAt = createdAt ?? DateTime.now();

  final String learnerName;
  final int grade;
  final String userCode;
  final DateTime createdAt;
  final int lessonsFinished;
  final int stickersEarned;
  final int badgesEarned;
  final int currentStreak;

  static const _topBackgroundColor = Color(0xFFE5D5A9);
  static const _bottomBackgroundColor = Color(0xFFDCCB8C);
  static const _designWidth = 412.0;

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  var _selectedTab = MeCardTab.about;

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      FadePageRoute<void>(page: const SettingsScreen()),
    );
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context).push(
      FadePageRoute<void>(
        page: const PlaceholderScreen(
          title: 'Edit',
          description: 'Temporary Edit profile shell',
          icon: Icons.edit_rounded,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('me-screen'),
      backgroundColor: MeScreen._topBackgroundColor,
      bottomNavigationBar: const AppBottomTabNavigation(currentIndex: 5),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final canvasWidth = math.min(viewport.maxWidth, 720.0);
            final canvasSideInset = (viewport.maxWidth - canvasWidth) / 2;
            final topControlScale = (canvasWidth / 460).clamp(.82, 1.12);
            final sceneScale = canvasWidth / MeScreen._designWidth;
            return Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    key: const Key('me-content-scroll-view'),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: canvasWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ColoredBox(
                              color: MeScreen._topBackgroundColor,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  19 * sceneScale,
                                  140 * sceneScale,
                                  19 * sceneScale,
                                  24 * sceneScale,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    MeLearnerCard(
                                      learnerName: widget.learnerName,
                                      grade: widget.grade,
                                      userCode: widget.userCode,
                                      selectedTab: _selectedTab,
                                      onTabSelected: (tab) =>
                                          setState(() => _selectedTab = tab),
                                      createdAt: widget.createdAt,
                                      lessonsFinished: widget.lessonsFinished,
                                      stickersEarned: widget.stickersEarned,
                                      badgesEarned: widget.badgesEarned,
                                    ),
                                    SizedBox(height: 16 * sceneScale),
                                    MeDailyStreakCard(
                                      currentStreak: widget.currentStreak,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            ColoredBox(
                              color: MeScreen._bottomBackgroundColor,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      19 * sceneScale,
                                      10 * sceneScale,
                                      19 * sceneScale,
                                      0,
                                    ),
                                    child: const MeCollectionsHeader(),
                                  ),
                                  SizedBox(height: 12 * sceneScale),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 19 * sceneScale,
                                    ),
                                    child: const MeBadgeCollection(),
                                  ),
                                  SizedBox(height: 24 * sceneScale),
                                  SizedBox(
                                    height: 48 * sceneScale,
                                    child: const MeContentFooter(),
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
                Positioned(
                  top: 51 * topControlScale,
                  left: canvasSideInset + (30 * topControlScale),
                  width: RiveSettingsButton.width * topControlScale,
                  height: RiveSettingsButton.height * topControlScale,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: MeSettingsButton(
                      onTap: () => _openSettings(context),
                    ),
                  ),
                ),
                Positioned(
                  top: 51 * topControlScale,
                  right: canvasSideInset + (30 * topControlScale),
                  width: MeEditButton.width * topControlScale,
                  height: MeEditButton.height * topControlScale,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: MeEditButton(
                      onPressed: () => _openEdit(context),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
