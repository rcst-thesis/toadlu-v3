class AppData {
  static bool translateTutorialDone = false;
  static bool mapTutorialDone = false;
  static bool testTutorialDone = false;

  static const int maxLevel = 50;

  static int energyPoints = 0;
  static int streakDays = 0;
  static int unlockedLevel = 1;
  static final Map<int, int> levelStars = {};

  static int starsForLevel(int level) {
    return levelStars[level] ?? 0;
  }

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
