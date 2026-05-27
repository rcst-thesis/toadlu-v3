import 'package:flutter/material.dart';
import 'package:tudloapp/core/models/proficiency.dart';
import 'package:tudloapp/core/services/app_storage.dart';

/// App-wide onboarding/profile state.
///
/// This is intentionally small and simple: screens update it through setters,
/// and any widget that reads `AppStateScope.of(context)` rebuilds when it
/// changes because this class extends [ChangeNotifier].
class AppState extends ChangeNotifier {
  String username = '';
  String ageRange = '';
  String knowledgeLabel = knowledgeOptions.first.label;
  int knowledgeLevel = 1;
  HomeMapDataset homeMapDataset = HomeMapDataset.easy;
  final DateTime joinedOn = DateTime.now();
  bool onboardingComplete = false;

  Future<void> initialize() async {
    final data = await AppStorage.readAppState();
    username = data['username'] as String;
    ageRange = data['ageRange'] as String;
    knowledgeLabel = (data['knowledgeLabel'] as String).isEmpty
        ? knowledgeOptions.first.label
        : data['knowledgeLabel'] as String;
    knowledgeLevel = data['knowledgeLevel'] as int;
    homeMapDataset = _parseDataset(data['homeMapDataset'] as String);
    onboardingComplete = data['onboardingComplete'] as bool;

    notifyListeners();
  }

  static HomeMapDataset _parseDataset(String value) {
    return switch (value) {
      'medium' => HomeMapDataset.medium,
      'hard' => HomeMapDataset.hard,
      _ => HomeMapDataset.easy,
    };
  }

  Future<void> _persist() => AppStorage.writeAppState(
    username: username,
    ageRange: ageRange,
    knowledgeLabel: knowledgeLabel,
    knowledgeLevel: knowledgeLevel,
    homeMapDataset: homeMapDataset.name,
    onboardingComplete: onboardingComplete,
  );

  void completeOnboarding() {
    onboardingComplete = true;
    notifyListeners();
    _persist();
  }

  void setUsername(String value) {
    username = value.trim();
    notifyListeners();
    _persist();
  }

  void setAgeRange(String value) {
    ageRange = value;
    notifyListeners();
    _persist();
  }

  void setKnowledgeOption(KnowledgeOption value) {
    knowledgeLabel = value.label;
    knowledgeLevel = value.level;
    notifyListeners();
    _persist();
  }

  void saveEvaluationScore(int score) {
    homeMapDataset = score <= 4
        ? HomeMapDataset.easy
        : score <= 7
        ? HomeMapDataset.medium
        : HomeMapDataset.hard;
    notifyListeners();
    _persist();
  }

  void skipEvaluation() {
    homeMapDataset = HomeMapDataset.easy;
    notifyListeners();
    _persist();
  }

  String get displayUsername => username.trim().isEmpty ? 'friend' : username;
}

/// Makes [AppState] available below `MaterialApp` without passing it manually.
///
/// This is the app's lightweight alternative to Provider/Riverpod. Put values
/// that many screens need here; keep screen-only state inside that screen.
class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState super.notifier,
    required super.child,
  });

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'No AppStateScope found in context');
    return scope!.notifier!;
  }
}
