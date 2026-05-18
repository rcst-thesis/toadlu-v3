/// Lightweight in-memory progress store for the demo app.
///
/// The app currently keeps progress here instead of a database, so values reset
/// when the app restarts. If the team later adds persistence, this is the main
/// place to replace with SharedPreferences/Firebase/local storage calls.
class AppData {
  /// Tutorial flags prevent one-time helper overlays from showing repeatedly.
  static bool translateTutorialDone = false;
  static bool mapTutorialDone = false;
  static bool testTutorialDone = false;

  static const int maxLevel = 50;

  /// Core gamification/progress values shared by map, lessons, and profile.
  static int energyPoints = 0;
  static int streakDays = 0;
  static int unlockedLevel = 1;
  static final Map<int, int> levelStars = {};

  static int starsForLevel(int level) {
    return levelStars[level] ?? 0;
  }

  /// Converts a lesson score into 0-3 stars and keeps the best result.
  ///
  /// Replaying an old level should never lower the user's existing star count.
  static void saveLevelScore(int level, int score, int total) {
    final percent = total == 0 ? 0.0 : score / total;
    final stars = percent >= .9
        ? 3
        : percent >= .7
        ? 2
        : percent >= .4
        ? 1
        : 0;
    final previous = levelStars[level] ?? 0;
    if (stars > previous) {
      levelStars[level] = stars;
    }
  }
}
