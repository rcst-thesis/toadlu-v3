import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tudlo/core/navigation/app_bottom_tab_navigation.dart';
import 'package:tudlo/core/navigation/fade_page_route.dart';
import 'package:tudlo/features/learner/domain/learner_scope.dart';
import 'package:tudlo/features/me/presentation/widgets/me_badge_collection.dart';
import 'package:tudlo/features/me/presentation/widgets/me_collections_header.dart';
import 'package:tudlo/features/me/presentation/widgets/me_content_footer.dart';
import 'package:tudlo/features/me/presentation/widgets/me_daily_streak_card.dart';
import 'package:tudlo/features/me/presentation/widgets/me_edit_button.dart';
import 'package:tudlo/features/me/presentation/widgets/me_learner_card.dart';
import 'package:tudlo/features/me/presentation/widgets/me_section_wave_divider.dart';
import 'package:tudlo/features/me/presentation/widgets/me_settings_button.dart';
import 'package:tudlo/features/placeholder/presentation/placeholder_screen.dart';
import 'package:tudlo/features/settings/presentation/settings_screen.dart';
import 'package:tudlo/shared/widgets/rive_settings_button.dart';

/// Incremental Me screen. Currently hosts the top Settings/Edit buttons,
/// the learner card with its about/details/progress tabs, and the daily
/// streak card; badge collection follows later.
///
/// [learnerName], [grade], [userCode], [createdAt], [lessonsFinished],
/// [stickersEarned], [badgesEarned], and [currentStreak] are explicit
/// overrides -- mainly for tests. Real app code shouldn't need these: when
/// omitted, they fall back to the current learner from [LearnerScope], then
/// to the original hardcoded placeholders if no learner is loaded either
/// (`createdAt` falls back to now, so the "details" tab's age reads
/// "today"; the progress counts and streak default honestly, 0 and 1,
/// rather than fabricated numbers).
class MeScreen extends StatefulWidget {
  const MeScreen({
    this.learnerName,
    this.grade,
    this.userCode,
    this.lessonsFinished,
    this.stickersEarned,
    this.badgesEarned,
    this.currentStreak,
    this.createdAt,
    super.key,
  });

  final String? learnerName;
  final int? grade;
  final String? userCode;
  final DateTime? createdAt;
  final int? lessonsFinished;
  final int? stickersEarned;
  final int? badgesEarned;
  final int? currentStreak;

  static const _topBackgroundColor = Color(0xFFE5D5A9);
  static const _bottomBackgroundColor = Color(0xFFDCCB8C);
  static const _designWidth = 412.0;

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  var _selectedTab = MeCardTab.about;

  String get _learnerName =>
      widget.learnerName ?? LearnerScope.of(context).profile?.name ?? 'Koka';
  int get _grade =>
      widget.grade ?? LearnerScope.of(context).profile?.grade ?? 1;
  String get _userCode =>
      widget.userCode ?? LearnerScope.of(context).profile?.id ?? '0000001';
  DateTime get _createdAt =>
      widget.createdAt ??
      LearnerScope.of(context).profile?.createdAt ??
      DateTime.now();
  int get _lessonsFinished =>
      widget.lessonsFinished ??
      LearnerScope.of(context).profile?.lessonsFinished ??
      0;
  int get _stickersEarned =>
      widget.stickersEarned ??
      LearnerScope.of(context).profile?.stickersEarned ??
      0;
  int get _badgesEarned =>
      widget.badgesEarned ??
      LearnerScope.of(context).profile?.badgesEarned ??
      0;
  int get _currentStreak =>
      widget.currentStreak ??
      LearnerScope.of(context).profile?.currentStreak ??
      1;

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
      // Full-bleed behind the status bar, same as Home: the top buttons'
      // own `51 * topControlScale` offset alone clears it, so wrapping in
      // SafeArea here would double that clearance.
      body: LayoutBuilder(
        builder: (context, viewport) {
          final canvasWidth = math.min(viewport.maxWidth, 720.0);
          final topControlScale = (canvasWidth / 460).clamp(.82, 1.12);
          final sceneScale = canvasWidth / MeScreen._designWidth;
          return SingleChildScrollView(
            key: const Key('me-content-scroll-view'),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: canvasWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ColoredBox(
                      color: MeScreen._topBackgroundColor,
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
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
                                      learnerName: _learnerName,
                                      grade: _grade,
                                      userCode: _userCode,
                                      selectedTab: _selectedTab,
                                      onTabSelected: (tab) => setState(
                                        () => _selectedTab = tab,
                                      ),
                                      createdAt: _createdAt,
                                      lessonsFinished: _lessonsFinished,
                                      stickersEarned: _stickersEarned,
                                      badgesEarned: _badgesEarned,
                                    ),
                                    SizedBox(height: 16 * sceneScale),
                                    MeDailyStreakCard(
                                      currentStreak: _currentStreak,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 48 * sceneScale,
                                child: const MeSectionWaveDivider(
                                  color: MeScreen._bottomBackgroundColor,
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            top: 51 * topControlScale,
                            left: 30 * topControlScale,
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
                            right: 30 * topControlScale,
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
          );
        },
      ),
    );
  }
}
