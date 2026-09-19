import 'package:flutter/widgets.dart';

import 'package:tudlo/features/settings/domain/app_settings.dart';
import 'package:tudlo/features/settings/domain/app_settings_repository.dart';

/// The app's one device-wide [AppSettings] -- in effect whenever nobody is
/// signed in (the main menu), and what a brand new learner's own settings
/// are seeded from at creation (see `LearnerController.createAndSave`'s
/// `initialSettings` param). Same shape/best-effort-persist convention as
/// `LearnerController` (`lib/features/learner/domain/learner_scope.dart`).
class AppSettingsController extends ChangeNotifier {
  AppSettingsController({
    AppSettingsRepository repository = const AppSettingsRepository(),
  }) : _repository = repository;

  final AppSettingsRepository _repository;
  AppSettings _settings = AppSettings.defaults;

  AppSettings get settings => _settings;

  /// Loads whatever was last saved, if any. Safe to call even if nothing
  /// has ever been saved, or storage isn't available at all -- [settings]
  /// is just left at [AppSettings.defaults], same as a fresh install.
  Future<void> loadSaved() async {
    try {
      final loaded = await _repository.load();
      if (loaded == null) return;
      _settings = loaded;
      notifyListeners();
    } catch (_) {
      // Storage unavailable/corrupt: proceed with defaults rather than
      // crashing startup over it.
    }
  }

  Future<void> update(AppSettings settings) async {
    _settings = settings;
    notifyListeners();
    try {
      await _repository.save(settings);
    } catch (_) {
      // Best-effort: the app keeps using the in-memory value either way.
    }
  }
}

/// Makes the app's one [AppSettingsController] available to every screen,
/// without threading it through navigation call sites. Same pattern as
/// `LearnerScope` (`lib/features/learner/domain/learner_scope.dart`).
class AppSettingsScope extends InheritedNotifier<AppSettingsController> {
  const AppSettingsScope({
    required AppSettingsController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  /// Returns the shared controller if one is above [context], otherwise a
  /// fresh standalone one with just [AppSettings.defaults] -- e.g. a
  /// widget test that pumps `SettingsScreen` inside a bare `MaterialApp`
  /// rather than the full `TudloApp` shell.
  static AppSettingsController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    return scope?.notifier ?? AppSettingsController();
  }
}
