import 'package:flutter/foundation.dart';
import 'package:tudloapp/core/services/app_storage.dart';
import 'package:tudloapp/features/energy/services/energy_storage.dart';

/// Shared in-app progress and energy state.
///
/// Energy is the only mechanic that gates lesson access. Koka reads from this
/// same state for mood and has no separate care-needs data.
class AppData {
  /// Tutorial flags prevent one-time helper overlays from showing repeatedly.
  static bool translateTutorialDone = false;
  static bool mapTutorialDone = false;
  static bool testTutorialDone = false;

  static const int maxLevel = 36;
  static const unitLevels = 6;

  /// Duolingo-style energy rules.
  ///
  /// A full unit/lesson has 15 questions, so starting requires 15 energy and
  /// each checked question deducts 1 energy.
  static const int maxEnergy = 30;
  static const int energyPerQuestion = 1;
  static const int questionsPerUnit = 15;
  static const int minimumEnergyToStartUnit = 15;
  static const Duration rechargeInterval = Duration(minutes: 24);
  static const Duration fullRechargeTime = Duration(hours: 12);

  /// Notifies energy widgets after recharge, spend, or restore.
  static final ValueNotifier<int> energyRevision = ValueNotifier<int>(0);

  /// Current saved energy. Use [refreshEnergy] before reading in UI flows that
  /// care about real elapsed time.
  static int currentEnergy = maxEnergy;
  static DateTime _lastEnergyAt = DateTime.now();

  static int streakDays = 0;
  static int unlockedLevel = 1;
  static Map<int, int> levelStars = {};
  static Map<int, int> bestTestScores = {};
  static Set<int> completedLevels = {};

  /// Home Map unit definitions shared by the Map, Test, and Profile screens.
  static const units = [
    AppUnit(number: 1, startLevel: 1, title: 'Everyday Conversation'),
    AppUnit(number: 2, startLevel: 7, title: 'Talk to Locals'),
    AppUnit(number: 3, startLevel: 13, title: 'Conversation with Friends'),
    AppUnit(number: 4, startLevel: 19, title: 'Family is Love'),
    AppUnit(number: 5, startLevel: 25, title: 'Daily Life'),
    AppUnit(number: 6, startLevel: 31, title: 'Community'),
  ];

  static Future<void> initialize() async {
    final energyValues = await EnergyStorage.read();
    currentEnergy =
        int.tryParse(
          energyValues['currentEnergy'] ?? '',
        )?.clamp(0, maxEnergy).toInt() ??
        maxEnergy;
    _lastEnergyAt =
        DateTime.tryParse(energyValues['lastEnergyAt'] ?? '') ?? DateTime.now();
    await refreshEnergy(save: true);

    final data = await AppStorage.readAppState();
    streakDays = data['streakDays'] ?? 1;
    unlockedLevel = data['unlockedLevel'] ?? 1;
    levelStars
      ..clear()
      ..addAll(AppStorage.parseIntPairMap(data['levelStars'] ?? ''));
    bestTestScores
      ..clear()
      ..addAll(AppStorage.parseIntPairMap(data['bestTestScores'] ?? ''));
    completedLevels
      ..clear()
      ..addAll(AppStorage.parseIntSet(data['completedLevels'] ?? ''));
  }

  /// Recharges energy based on elapsed real time.
  ///
  /// The saved timestamp marks the last recharge boundary. If the app was
  /// closed for 72 minutes, this adds 3 energy because 72 / 24 = 3 intervals.
  static Future<void> refreshEnergy({DateTime? now, bool save = false}) async {
    final updatedAt = now ?? DateTime.now();
    final changed = _applyRecharge(updatedAt);
    if (save) await saveEnergyState();
    if (changed) energyRevision.value++;
  }

  static bool _applyRecharge(DateTime updatedAt) {
    if (currentEnergy >= maxEnergy) {
      currentEnergy = maxEnergy;
      _lastEnergyAt = updatedAt;
      return true;
    }

    final intervals =
        updatedAt.difference(_lastEnergyAt).inMinutes ~/
        rechargeInterval.inMinutes;
    if (intervals <= 0) return false;

    currentEnergy = (currentEnergy + intervals).clamp(0, maxEnergy).toInt();
    _lastEnergyAt = currentEnergy >= maxEnergy
        ? updatedAt
        : _lastEnergyAt.add(
            Duration(minutes: rechargeInterval.inMinutes * intervals),
          );
    return true;
  }

  /// Persists the current energy count and timestamp used for restore logic.
  static Future<void> saveEnergyState() {
    return EnergyStorage.write({
      'currentEnergy': '$currentEnergy',
      'lastEnergyAt': _lastEnergyAt.toIso8601String(),
    });
  }

  /// Unit start restriction. Home Map calls this before opening a lesson.
  static bool canStartUnit() {
    return currentEnergy >= minimumEnergyToStartUnit;
  }

  /// Deducts energy when a question is checked.
  ///
  /// This is intentionally separate from correctness. Trying a question costs
  /// energy once, whether the answer is right or wrong.
  static Future<bool> spendQuestionEnergy() async {
    await refreshEnergy();
    if (currentEnergy < energyPerQuestion) return false;
    currentEnergy = (currentEnergy - energyPerQuestion)
        .clamp(0, maxEnergy)
        .toInt();
    _lastEnergyAt = DateTime.now();
    await saveEnergyState();
    energyRevision.value++;
    return true;
  }

  static Duration timeUntilNextEnergy({DateTime? now}) {
    final updatedAt = now ?? DateTime.now();
    _applyRecharge(updatedAt);
    if (currentEnergy >= maxEnergy) return Duration.zero;
    final elapsed = updatedAt.difference(_lastEnergyAt);
    final remaining = rechargeInterval - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  static Duration timeUntilFullEnergy({DateTime? now}) {
    _applyRecharge(now ?? DateTime.now());
    if (currentEnergy >= maxEnergy) return Duration.zero;
    final missing = maxEnergy - currentEnergy;
    return timeUntilNextEnergy(now: now) +
        Duration(minutes: rechargeInterval.inMinutes * (missing - 1));
  }

  static String formatDurationShort(Duration duration) {
    if (duration <= Duration.zero) return 'now';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  static String get kokaMoodLabel {
    if (currentEnergy >= 20) return 'Full Energy Koka';
    if (currentEnergy >= 10) return 'Half Energy Koka';
    return 'Low Energy Koka';
  }

  static String get kokaPetAsset {
    // Koka uses dedicated pet-state art, not the shared mascot. These ranges
    // match the provided asset names and keep mood selection tied only to
    // current energy.
    if (currentEnergy >= 20) {
      return 'assets/images/pet/full energy 20-30 energy.png';
    }
    if (currentEnergy >= 10) {
      return 'assets/images/pet/half energy - 10 to 14.png';
    }
    return 'assets/images/pet/low energy - less than 10 energy.png';
  }

  static bool isUnitStartLevel(int level) {
    return level >= 1 && level <= maxLevel && (level - 1) % unitLevels == 0;
  }

  static bool isLevelUnlocked(int level) {
    if (level < 1 || level > maxLevel) return false;
    if (isUnitStartLevel(level)) return true;
    if (completedLevels.contains(level)) return true;
    final previousLevel = level - 1;
    final sameUnit =
        (previousLevel - 1) ~/ unitLevels == (level - 1) ~/ unitLevels;
    return sameUnit && completedLevels.contains(previousLevel);
  }

  static int starsForLevel(int level) {
    return levelStars[level] ?? 0;
  }

  static int bestScoreForTest(int test) {
    return bestTestScores[test] ?? 0;
  }

  static AppUnit unitForNumber(int number) {
    return units.firstWhere((unit) => unit.number == number);
  }

  static Future<void> saveProgressState() {
    return AppStorage.writeAppData(
      streakDays: streakDays,
      unlockedLevel: unlockedLevel,
      levelStars: levelStars,
      bestTestScores: bestTestScores,
      completedLevels: completedLevels,
    );
  }

  /// Converts a lesson score into 0-3 stars and keeps the best result.
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
    if (stars > previous) levelStars[level] = stars;

    saveProgressState();
  }

  static void saveTestScore(int test, int score) {
    final previous = bestTestScores[test] ?? 0;
    if (score > previous) bestTestScores[test] = score;

    saveProgressState();
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
