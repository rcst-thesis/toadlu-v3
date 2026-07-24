import 'dart:convert';

import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/models/grade_level.dart';

class LearnerProfile {
  final String id;
  final String name;
  final String gradeLevel;
  final int unlockedLevel;
  final int streakDays;
  final int currentEnergy;
  final Map<int, int> levelStars;
  final Set<int> completedLevels;
  final Set<String> favoriteWords;
  final String avatarAsset;
  final bool hasSeenOnboarding;

  const LearnerProfile({
    required this.id,
    required this.name,
    required this.gradeLevel,
    required this.unlockedLevel,
    required this.streakDays,
    required this.currentEnergy,
    required this.levelStars,
    required this.completedLevels,
    required this.favoriteWords,
    required this.avatarAsset,
    required this.hasSeenOnboarding,
  });

  factory LearnerProfile.newProfile({
    required String name,
    required String gradeLevel,
  }) {
    return LearnerProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? 'Learner' : name.trim(),
      gradeLevel: gradeLevel,
      unlockedLevel: 1,
      streakDays: 0,
      currentEnergy: AppData.maxEnergy,
      levelStars: const {},
      completedLevels: const {},
      favoriteWords: const {},
      avatarAsset: '',
      hasSeenOnboarding: false,
    );
  }

  factory LearnerProfile.fromJson(Map<String, dynamic> json) {
    return LearnerProfile(
      id:
          json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Learner',
      gradeLevel: json['gradeLevel'] as String? ?? 'Grade 1',
      unlockedLevel: json['unlockedLevel'] as int? ?? 1,
      streakDays: json['streakDays'] as int? ?? 0,
      currentEnergy: json['currentEnergy'] as int? ?? AppData.maxEnergy,
      levelStars: _intMap(json['levelStars']),
      completedLevels: {
        for (final value in (json['completedLevels'] as List<dynamic>? ?? []))
          if (value is int) value,
      },
      favoriteWords: {
        for (final value in (json['favoriteWords'] as List<dynamic>? ?? []))
          if (value is String) value,
      },
      avatarAsset: json['avatarAsset'] as String? ?? '',
      hasSeenOnboarding: json['hasSeenOnboarding'] as bool? ?? true,
    );
  }

  LearnerProfile copyWith({
    String? name,
    String? gradeLevel,
    int? unlockedLevel,
    int? streakDays,
    int? currentEnergy,
    Map<int, int>? levelStars,
    Set<int>? completedLevels,
    Set<String>? favoriteWords,
    String? avatarAsset,
    bool? hasSeenOnboarding,
  }) {
    return LearnerProfile(
      id: id,
      name: name ?? this.name,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      unlockedLevel: unlockedLevel ?? this.unlockedLevel,
      streakDays: streakDays ?? this.streakDays,
      currentEnergy: currentEnergy ?? this.currentEnergy,
      levelStars: levelStars ?? this.levelStars,
      completedLevels: completedLevels ?? this.completedLevels,
      favoriteWords: favoriteWords ?? this.favoriteWords,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gradeLevel': gradeLevel,
      'unlockedLevel': unlockedLevel,
      'streakDays': streakDays,
      'currentEnergy': currentEnergy,
      'levelStars': {
        for (final entry in levelStars.entries) '${entry.key}': entry.value,
      },
      'completedLevels': completedLevels.toList()..sort(),
      'favoriteWords': favoriteWords.toList()..sort(),
      'avatarAsset': avatarAsset,
      'hasSeenOnboarding': hasSeenOnboarding,
    };
  }

  String get summary => '$name - $gradeLevel - Level $unlockedLevel';
  GradeLevel get parsedGrade => gradeLevelFromLabel(gradeLevel);

  static Map<int, int> _intMap(dynamic value) {
    final source = value is Map ? value : const {};
    return {
      for (final entry in source.entries)
        if (int.tryParse('${entry.key}') != null && entry.value is int)
          int.parse('${entry.key}'): entry.value as int,
    };
  }
}

String encodeProfiles(List<LearnerProfile> profiles, String? activeProfileId) {
  return jsonEncode({
    'activeProfileId': activeProfileId,
    'profiles': profiles.map((profile) => profile.toJson()).toList(),
  });
}

({List<LearnerProfile> profiles, String? activeProfileId}) decodeProfiles(
  String value,
) {
  if (value.trim().isEmpty) return (profiles: const [], activeProfileId: null);
  final data = jsonDecode(value) as Map<String, dynamic>;
  final profiles = (data['profiles'] as List<dynamic>? ?? [])
      .whereType<Map<String, dynamic>>()
      .map(LearnerProfile.fromJson)
      .toList();
  return (
    profiles: profiles,
    activeProfileId: data['activeProfileId'] as String?,
  );
}
