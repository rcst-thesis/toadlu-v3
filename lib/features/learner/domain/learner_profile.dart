/// A saved learner: everything onboarding collects, plus progression data
/// that accumulates afterward (lessons, stickers, badges, streak, and which
/// map locations an event has permanently unlocked).
///
/// Deliberately holds no dependency on any other feature's domain types --
/// [unlockedMapLocations] stores raw location ids (`MapLocation.riveId`
/// strings), not `MapLocation` values, so this stays a plain, storable data
/// shape that `map`'s domain doesn't need to know exists and vice versa.
/// Whatever bridges the two lives in presentation code (`MapScreen`).
class LearnerProfile {
  const LearnerProfile({
    required this.id,
    required this.name,
    required this.grade,
    required this.energy,
    required this.createdAt,
    this.lessonsFinished = 0,
    this.stickersEarned = 0,
    this.badgesEarned = 0,
    this.currentStreak = 1,
    this.unlockedMapLocations = const {},
  });

  final String id;
  final String name;
  final int grade;
  final int energy;
  final DateTime createdAt;
  final int lessonsFinished;
  final int stickersEarned;
  final int badgesEarned;
  final int currentStreak;
  final Set<String> unlockedMapLocations;

  LearnerProfile copyWith({
    int? lessonsFinished,
    int? stickersEarned,
    int? badgesEarned,
    int? currentStreak,
    Set<String>? unlockedMapLocations,
  }) {
    return LearnerProfile(
      id: id,
      name: name,
      grade: grade,
      energy: energy,
      createdAt: createdAt,
      lessonsFinished: lessonsFinished ?? this.lessonsFinished,
      stickersEarned: stickersEarned ?? this.stickersEarned,
      badgesEarned: badgesEarned ?? this.badgesEarned,
      currentStreak: currentStreak ?? this.currentStreak,
      unlockedMapLocations: unlockedMapLocations ?? this.unlockedMapLocations,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'grade': grade,
        'energy': energy,
        'createdAt': createdAt.toIso8601String(),
        'lessonsFinished': lessonsFinished,
        'stickersEarned': stickersEarned,
        'badgesEarned': badgesEarned,
        'currentStreak': currentStreak,
        'unlockedMapLocations': unlockedMapLocations.toList(),
      };

  factory LearnerProfile.fromJson(Map<String, Object?> json) {
    return LearnerProfile(
      id: json['id']! as String,
      name: json['name']! as String,
      grade: json['grade']! as int,
      energy: json['energy']! as int,
      createdAt: DateTime.parse(json['createdAt']! as String),
      lessonsFinished: json['lessonsFinished'] as int? ?? 0,
      stickersEarned: json['stickersEarned'] as int? ?? 0,
      badgesEarned: json['badgesEarned'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 1,
      unlockedMapLocations:
          (json['unlockedMapLocations'] as List<Object?>? ?? const [])
              .cast<String>()
              .toSet(),
    );
  }
}
