/// Small read model for learning streak display.
///
/// Streak is separate from the Pet/Koka feature. Profile can show streak
/// summaries, but pet care should not own streak state or naming.
class StreakModel {
  final int days;
  final int completedDaysThisWeek;

  const StreakModel({required this.days, required this.completedDaysThisWeek});
}
