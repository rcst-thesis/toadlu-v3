import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/features/streak/models/streak_model.dart';

/// Learning streak helper used by Profile and future streak screens.
class StreakHelper {
  const StreakHelper._();

  static StreakModel current() {
    final days = AppData.streakDays < 1 ? 1 : AppData.streakDays;
    return StreakModel(days: days, completedDaysThisWeek: days.clamp(1, 7));
  }
}
