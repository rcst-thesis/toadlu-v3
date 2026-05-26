import 'package:flutter/material.dart';
import 'package:tudloapp/core/models/proficiency.dart';

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

  String get displayUsername => username.trim().isEmpty ? 'friend' : username;

  /// Saves the typed username from onboarding or the Profile edit dialog.
  void setUsername(String value) {
    username = value.trim();
    notifyListeners();
  }

  /// Saves the selected age range for display on the Profile page.
  void setAgeRange(String value) {
    ageRange = value;
    notifyListeners();
  }

  /// Stores the visible knowledge label and its hidden numeric level.
  void setKnowledgeOption(KnowledgeOption value) {
    knowledgeLabel = value.label;
    knowledgeLevel = value.level;
    notifyListeners();
  }

  /// Converts the evaluation score into the internal Home Map dataset.
  ///
  /// The user only moves forward after the evaluation; dataset names like
  /// easy/medium/hard are intentionally kept hidden from the UI.
  void saveEvaluationScore(int score) {
    if (score <= 6) {
      homeMapDataset = HomeMapDataset.easy;
    } else if (score <= 11) {
      homeMapDataset = HomeMapDataset.medium;
    } else {
      homeMapDataset = HomeMapDataset.hard;
    }
    notifyListeners();
  }

  /// Skipping the evaluation starts the user on the default/easy dataset.
  void skipEvaluation() {
    homeMapDataset = HomeMapDataset.easy;
    notifyListeners();
  }
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
