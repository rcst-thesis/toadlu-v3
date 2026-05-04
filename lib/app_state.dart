import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  String username = '';
  String ageRange = '';
  int knowledgeLevel = 1;

  void setUsername(String value) {
    username = value;
    notifyListeners();
  }

  void setAgeRange(String value) {
    ageRange = value;
    notifyListeners();
  }

  void setKnowledgeLevel(int value) {
    knowledgeLevel = value;
    notifyListeners();
  }
}

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
