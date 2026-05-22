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

  static const int maxLevel = 30;
  static const unitLevels = 5;
  static const units = [
    AppUnit(number: 1, startLevel: 1, title: 'Everyday Conversation'),
    AppUnit(number: 2, startLevel: 6, title: 'Talk to Locals'),
    AppUnit(number: 3, startLevel: 11, title: 'Conversation with Friends'),
    AppUnit(number: 4, startLevel: 16, title: 'Family is Love'),
    AppUnit(number: 5, startLevel: 21, title: 'Daily Life'),
    AppUnit(number: 6, startLevel: 26, title: 'Community'),
  ];

  /// Core gamification/progress values shared by map, lessons, and profile.
  static int energyPoints = 0;
  static int totalXpCollected = 0;
  static int streakDays = 0;
  static int unlockedLevel = 1;
  static final Map<int, int> levelStars = {};
  static final Set<int> completedLevels = {};

  /// Pet-care state stays with shared app data so Koka keeps the same status
  /// when users leave and reopen the Pet tab in the current app session.
  static int kokaHealth = 100;
  static int kokaHungry = 100;
  static DateTime kokaLastUpdatedAt = DateTime.now();
  static DateTime _kokaHungryUpdatedAt = kokaLastUpdatedAt;
  static DateTime _kokaHealthUpdatedAt = kokaLastUpdatedAt;

  static bool isUnitStartLevel(int level) {
    return level >= 1 && level <= maxLevel && (level - 1) % 5 == 0;
  }

  static bool isLevelUnlocked(int level) {
    if (level < 1 || level > maxLevel) return false;
    if (isUnitStartLevel(level)) return true;
    if (completedLevels.contains(level)) return true;
    final previousLevel = level - 1;
    final sameUnit = (previousLevel - 1) ~/ 5 == (level - 1) ~/ 5;
    return sameUnit && completedLevels.contains(previousLevel);
  }

  static int starsForLevel(int level) {
    return levelStars[level] ?? 0;
  }

  static AppUnit unitForNumber(int number) {
    return units.firstWhere((unit) => unit.number == number);
  }

  static void updateKokaStatus({DateTime? now}) {
    final updatedAt = now ?? DateTime.now();
    final hungryIntervals =
        updatedAt.difference(_kokaHungryUpdatedAt).inHours ~/ 2;
    final healthIntervals =
        updatedAt.difference(_kokaHealthUpdatedAt).inHours ~/ 4;

    if (hungryIntervals > 0) {
      kokaHungry = (kokaHungry - hungryIntervals * 10).clamp(0, 100);
      _kokaHungryUpdatedAt = _kokaHungryUpdatedAt.add(
        Duration(hours: hungryIntervals * 2),
      );
    }

    if (healthIntervals > 0) {
      kokaHealth = (kokaHealth - healthIntervals * 10).clamp(0, 100);
      _kokaHealthUpdatedAt = _kokaHealthUpdatedAt.add(
        Duration(hours: healthIntervals * 4),
      );
    }

    kokaLastUpdatedAt = updatedAt;
  }

  static bool feedKoka() {
    return _spendPetXp(
      cost: 50,
      onCare: () {
        kokaHungry = (kokaHungry + 40).clamp(0, 100);
      },
    );
  }

  static bool cleanKokaPond() {
    return _spendPetXp(
      cost: 70,
      onCare: () {
        kokaHealth = (kokaHealth + 30).clamp(0, 100);
      },
    );
  }

  static bool restKoka() {
    return _spendPetXp(
      cost: 60,
      onCare: () {
        kokaHealth = (kokaHealth + 40).clamp(0, 100);
      },
    );
  }

  static bool _spendPetXp({
    required int cost,
    required void Function() onCare,
  }) {
    updateKokaStatus();
    if (energyPoints < cost) return false;
    energyPoints -= cost;
    onCare();
    return true;
  }

  /// Converts a lesson score into 0-3 stars and keeps the best result.
  ///
  /// Replaying an old level should never lower the user's existing star count.
  static void saveLevelScore(int level, int score, int total) {
    completedLevels.add(level);
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

class AppUnit {
  final int number;
  final int startLevel;
  final String title;

  const AppUnit({
    required this.number,
    required this.startLevel,
    required this.title,
  });

  int get endLevel => startLevel + AppData.unitLevels - 1;
}
