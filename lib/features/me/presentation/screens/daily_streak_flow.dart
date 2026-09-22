import 'package:flutter/material.dart';

import 'package:tudlo/features/learner/domain/learner_scope.dart';
import 'package:tudlo/features/me/presentation/screens/daily_checkin_screen.dart';
import 'package:tudlo/features/me/presentation/screens/daily_streak_screen.dart';

/// Chains [DailyCheckInScreen] into [DailyStreakScreen] for the currently
/// signed-in learner, then hands off to [onFinished].
///
/// Callers (Main Menu's "continue", Load's "load a save") are responsible
/// for only routing here when [LearnerProfile.needsStreakCheckInToday] is
/// true and for calling [LearnerController.recordStreakCheckIn] before
/// pushing this -- this widget just renders the two screens back to back,
/// it doesn't own the once-per-day gate itself.
class DailyStreakFlow extends StatefulWidget {
  const DailyStreakFlow({required this.onFinished, super.key});

  /// Called once the learner taps through both screens, with this widget's
  /// own (still-mounted) [BuildContext] -- not whatever context the caller
  /// pushed this from, which is long gone by the time a learner actually
  /// finishes clicking through. The caller decides how to navigate onward
  /// (a plain replace vs. clearing the whole stack differs between the
  /// "continue" and "load" call sites).
  final void Function(BuildContext context) onFinished;

  @override
  State<DailyStreakFlow> createState() => _DailyStreakFlowState();
}

class _DailyStreakFlowState extends State<DailyStreakFlow> {
  var _showingStreak = false;

  @override
  Widget build(BuildContext context) {
    final profile = LearnerScope.of(context).profile;
    if (profile == null) {
      // Shouldn't happen -- both call sites switch to a profile before
      // pushing this -- but fail open onto the normal path rather than
      // show a broken screen if it ever does.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onFinished(context);
      });
      return const SizedBox.shrink();
    }

    if (!_showingStreak) {
      return DailyCheckInScreen(
        createdAt: profile.createdAt,
        onStart: () => setState(() => _showingStreak = true),
      );
    }

    return DailyStreakScreen(
      streakCount: profile.effectiveStreak(),
      onContinue: () => widget.onFinished(context),
    );
  }
}
