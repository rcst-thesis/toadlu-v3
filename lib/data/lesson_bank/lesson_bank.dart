import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/data/lesson_bank/grade1/lesson_bank/dataset.dart';
import 'package:tudloapp/data/lesson_bank/grade2/lesson_bank/dataset.dart';
import 'package:tudloapp/data/lesson_bank/grade3/lesson_bank/dataset.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank_item.dart';

export 'package:tudloapp/data/lesson_bank/lesson_bank_item.dart';

/// JSON-backed lesson content source.
///
/// Grade lesson data lives in JSON assets. Grade-specific `dataset.dart` files
/// contain only the asset paths, not hardcoded lesson content.
class LessonBank {
  static const _jsonDatasetAssets = {
    GradeLevel.grade1: grade1LessonDatasetAsset,
    GradeLevel.grade2: grade2LessonDatasetAsset,
    GradeLevel.grade3: grade3LessonDatasetAsset,
  };

  static Future<LevelContent> loadLevelContentForLevel(int level) async {
    try {
      final asset = _jsonDatasetAssets[AppData.selectedGradeLevel]!;
      final raw = await rootBundle.loadString(asset);
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return _levelContentFromJson(data, level);
    } catch (_) {
      return _fallbackLevelContent(level);
    }
  }

  static Future<List<LevelContent>> loadAllLevelContentForActiveGrade() async {
    final asset = _jsonDatasetAssets[AppData.selectedGradeLevel]!;
    final raw = await rootBundle.loadString(asset);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return [
      for (var level = 1; level <= AppData.maxLevel; level++)
        _levelContentFromJson(data, level),
    ];
  }

  static String lessonTitleForLevel(int level) {
    final localLesson = ((level - 1) % AppData.unitLevels) + 1;
    return 'Leksyon $localLesson';
  }

  static LevelContent _levelContentFromJson(
    Map<String, dynamic> data,
    int level,
  ) {
    final grade = AppData.selectedGradeLevel.number;
    final unit = unitForLevel(level);
    final lesson = ((level - 1) % AppData.unitLevels) + 1;
    final grades = _jsonList(data['grades']);
    final gradeData = grades.cast<Map<String, dynamic>>().firstWhere(
      (item) => item['gradeLevel'] == grade,
      orElse: () => throw StateError('Grade $grade not found in lesson JSON.'),
    );
    final unitData = _jsonList(gradeData['units'])
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (item) => item['unitNumber'] == unit,
          orElse: () =>
              throw StateError('Grade $grade unit $unit not found in JSON.'),
        );
    final lessons = _jsonList(unitData['lessons'])
        .cast<Map<String, dynamic>>()
        .toList();
    if (lessons.isEmpty) {
      throw StateError('Grade $grade unit $unit has no JSON lessons.');
    }
    final lessonData = lessons.firstWhere(
      (item) => item['lessonNumber'] == lesson,
      orElse: () => lessons[(lesson - 1) % lessons.length],
    );

    final quizItems = _jsonList(lessonData['shortQuiz'])
        .cast<Map<String, dynamic>>()
        .map((item) => _quizItemFromJson(item, grade, unit, lesson))
        .toList();

    return LevelContent(
      id: _jsonString(lessonData['id'], 'g${grade}_u${unit}_l$lesson'),
      gradeLevel: grade,
      unitNumber: unit,
      lessonNumber: lesson,
      title: _jsonString(lessonData['title'], 'Leksyon $lesson'),
      storyTitle: _storyTitleFromJson(lessonData),
      story: _nullableJsonString(lessonData['story']),
      storyImageAsset: _nullableJsonString(lessonData['storyImageAsset']),
      lesson: _jsonString(
        lessonData['lesson'],
        'Basaha kag pamatii ang sini nga leksiyon antes magsabat.',
      ),
      examples: _jsonList(
        lessonData['examples'],
      ).cast<Map<String, dynamic>>().map(_lessonExampleFromJson).toList(),
      quizItems: quizItems.isEmpty
          ? [_fallbackQuizItem(grade, unit, lesson)]
          : quizItems,
    );
  }

  static LessonExample _lessonExampleFromJson(Map<String, dynamic> data) {
    return LessonExample(
      category: _jsonString(data['category'], 'Example'),
      hiligaynon: _jsonString(data['hiligaynon'], ''),
      english: _jsonString(data['english'], ''),
      note: _jsonString(data['note'], ''),
      imageAsset: _nullableJsonString(data['imageAsset']),
      audioAsset: _nullableJsonString(data['audioAsset']),
    );
  }

  static QuizItem _quizItemFromJson(
    Map<String, dynamic> data,
    int grade,
    int unit,
    int lesson,
  ) {
    final choices = _jsonList(data['choices']).map((item) => '$item').toList();
    final answer = _nullableJsonString(data['answer']);
    final fallbackAnswer = choices.isEmpty ? 'Natapos ko ini' : choices.first;
    final pairs = _jsonMap(
      data['pairs'],
    ).map((key, value) => MapEntry(key, '$value'));
    final leftItems = pairs.isEmpty
        ? _jsonList(data['leftItems']).map((item) => '$item').toList()
        : pairs.keys.toList();
    final rightItems = pairs.isEmpty
        ? _jsonList(data['rightItems']).map((item) => '$item').toList()
        : pairs.values.toList();

    return QuizItem(
      id: _jsonString(data['id'], 'g${grade}_u${unit}_l${lesson}_quiz'),
      type: _quizTypeFromJson(_jsonString(data['type'], 'tapChoice'), pairs),
      question: _jsonString(data['question'], _jsonString(data['raw'], '')),
      choices: choices.isEmpty ? [fallbackAnswer] : choices,
      answer: answer ?? fallbackAnswer,
      audioAsset: _nullableJsonString(data['audioAsset']),
      imageAsset: _nullableJsonString(data['imageAsset']),
      leftItems: leftItems,
      rightItems: rightItems,
      matchingPairs: pairs,
    );
  }

  static QuizType _quizTypeFromJson(String type, Map<String, String> pairs) {
    if (pairs.isNotEmpty) return QuizType.matching;
    return switch (type.trim()) {
      'activity' => QuizType.tapCorrectWord,
      'tapChoice' => QuizType.multipleChoice,
      'pictureChoice' => QuizType.pictureChoice,
      'matching' => QuizType.matching,
      'arrangeWords' => QuizType.arrangeWords,
      'fillBlankChoice' => QuizType.fillBlankChoice,
      'listenAndChoose' => QuizType.listenAndChoose,
      _ => QuizType.multipleChoice,
    };
  }

  static int unitForLevel(int level) {
    final unit = ((level - 1) ~/ AppData.unitLevels) + 1;
    return unit.clamp(1, AppData.units.length);
  }

  static List<dynamic> _jsonList(Object? value) {
    return value is List ? value : const [];
  }

  static Map<String, dynamic> _jsonMap(Object? value) {
    return value is Map<String, dynamic> ? value : const {};
  }

  static String _jsonString(Object? value, String fallback) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty || text == 'null' ? fallback : text;
  }

  static String? _nullableJsonString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty || text == 'null' ? null : text;
  }

  static String? _storyTitleFromJson(Map<String, dynamic> data) {
    final title = _nullableJsonString(data['storyTitle']);
    if (title != null) return title;
    final story = _nullableJsonString(data['story']);
    return story == null ? null : _jsonString(data['title'], 'Istorya');
  }

  static LevelContent _fallbackLevelContent(int level) {
    final grade = AppData.selectedGradeLevel.number;
    final unit = unitForLevel(level);
    final lesson = ((level - 1) % AppData.unitLevels) + 1;
    return LevelContent(
      id: 'g${grade}_u${unit}_l${lesson}_fallback',
      gradeLevel: grade,
      unitNumber: unit,
      lessonNumber: lesson,
      title: 'Leksyon $lesson',
      lesson: 'Wala nakita ang JSON lesson data para sa sini nga leksiyon.',
      examples: const [],
      quizItems: [_fallbackQuizItem(grade, unit, lesson)],
    );
  }

  static QuizItem _fallbackQuizItem(int grade, int unit, int lesson) {
    return QuizItem(
      id: 'g${grade}_u${unit}_l${lesson}_fallback_quiz',
      type: QuizType.multipleChoice,
      question: 'Handa ka na?',
      choices: const ['Handa na', 'Wala pa'],
      answer: 'Handa na',
    );
  }
}
