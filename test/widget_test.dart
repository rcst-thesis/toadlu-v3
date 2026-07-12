import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('json lesson bank loads playable content for every map level', () async {
    for (final grade in GradeLevel.values) {
      AppData.selectedGradeLevel = grade;

      for (var level = 1; level <= AppData.maxLevel; level++) {
        final content = await LessonBank.loadLevelContentForLevel(level);

        expect(
          content.title.trim(),
          isNotEmpty,
          reason: '${grade.label} level $level title',
        );
        expect(
          content.lesson.trim(),
          isNotEmpty,
          reason: '${grade.label} level $level lesson body',
        );
        expect(
          content.quizItems,
          isNotEmpty,
          reason: '${grade.label} level $level quiz items',
        );
      }
    }
  });

  test('each grade reads from its own json dataset', () async {
    final titles = <String>{};
    final lessons = <String>{};

    for (final grade in GradeLevel.values) {
      AppData.selectedGradeLevel = grade;
      final content = await LessonBank.loadLevelContentForLevel(1);
      titles.add(content.title);
      lessons.add(content.lesson);
    }

    expect(titles, hasLength(GradeLevel.values.length));
    expect(lessons, hasLength(GradeLevel.values.length));
  });

  test('lesson json assets are valid and image paths match disk casing', () {
    final actualAssets = _assetFilesOnDisk();
    final referencedAssets = _referencedAssets();

    expect(
      referencedAssets.where((asset) => asset.contains('assets/Images/')),
      isEmpty,
      reason: 'Asset paths must use assets/images/... exactly.',
    );

    final missing = referencedAssets
        .where((asset) => !actualAssets.contains(asset))
        .toList();

    expect(
      missing,
      isEmpty,
      reason:
          'These asset references do not match files on disk exactly, including case.',
    );
  });
}

Set<String> _assetFilesOnDisk() {
  return Directory('assets')
      .listSync(recursive: true)
      .whereType<File>()
      .map((file) => file.path.replaceAll(r'\', '/'))
      .toSet();
}

Set<String> _referencedAssets() {
  final assets = <String>{};
  final assetLiteralPattern = RegExp(r'''assets/[^'")\s]+''');

  for (final file in Directory('lib').listSync(recursive: true)) {
    if (file is! File || !file.path.endsWith('.dart')) continue;
    final source = file.readAsStringSync();
    assets.addAll(
      assetLiteralPattern
          .allMatches(source)
          .map((match) => match.group(0)!)
          .where(_isImageAsset),
    );
  }

  for (final path in [
    'assets/data/grade1_dataset.json',
    'assets/data/grade2_dataset.json',
    'assets/data/grade3_dataset.json',
  ]) {
    final data = jsonDecode(File(path).readAsStringSync());
    _collectImageAssets(data, assets);
  }

  return assets.where(_isImageAsset).toSet();
}

void _collectImageAssets(Object? value, Set<String> assets) {
  if (value is Map) {
    for (final entry in value.entries) {
      if (entry.key.toString().toLowerCase().contains('asset')) {
        final asset = entry.value?.toString();
        if (asset != null) assets.add(asset);
      }
      _collectImageAssets(entry.value, assets);
    }
  } else if (value is List) {
    for (final item in value) {
      _collectImageAssets(item, assets);
    }
  }
}

bool _isImageAsset(String asset) {
  final lower = asset.toLowerCase();
  return lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp');
}
