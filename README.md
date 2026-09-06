# Tudlo Flutter application

This application implements the Tudlo startup, onboarding, and navigation flow:

1. Maral MT splash — minimum 5 seconds.
2. Tudlo splash — minimum 5 seconds while onboarding images are decoded and cached.
3. Main menu — functional Start New Koka, Continue, Load, and Settings navigation.
4. Onboarding — name, grade, energy, preparation, and learner-card screens.
5. Load screen — functional load/delete confirmation dialogs.

The outlined animation panels are deliberate placeholders for future Rive widgets.

## Run

```shell
flutter pub get
flutter run
```

## Project structure

```text
lib/
├── app/       # Application widget and app-wide setup
├── core/      # Theme and navigation infrastructure
├── features/  # Self-contained product features
├── shared/    # Reusable widgets shared by multiple features
├── tudlo.dart # Public library exports
└── main.dart  # Application entry point only
```

New feature-specific models and widgets should remain inside their feature.
Only code reused by multiple features belongs in `core` or `shared`.

## Replace a placeholder with Rive later

Search `lib/features` for `RivePlaceholder`. Each occurrence marks an area
intended for a future Rive widget. The surrounding responsive constraints and
navigation can remain unchanged.
