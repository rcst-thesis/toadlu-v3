# Tudlo Project Overview

## Purpose and Audience

Tudlo is a Flutter learning application prototype for Grade 1–3 children. It
currently covers an illustrated startup/onboarding experience, learner
identity/grade/energy selection, save-slot presentation, a welcome scene, and a
room-like Home shell intended to host future lessons.

This document reports only repository evidence. It does not claim persistence,
curriculum, translation, backend, audio, or Rive systems exist.

## Platforms and Dependencies

The project contains Android, iOS, web, and Windows runners. Runtime orientation
is restricted in `lib/main.dart`; Android and iOS also specify portrait behavior.

Direct dependencies in `pubspec.yaml`:

- Flutter SDK — UI/runtime.
- `flutter_svg` — SVG rendering.
- `vector_graphics` — raster rendering strategy for complex SVG scenes.
- `sensors_plus` — optional accelerometer input in `FarmDepthBackground`.

Development dependencies are `flutter_test` and `flutter_lints`. Dart is
constrained to `>=3.3.0 <4.0.0`. The app uses Material 3 and bundled Comic Relief.
There is no Rive, storage, networking, audio, state-management, or router package.

## Main User Flows

### Startup

`TudloApp` opens `StartupFlow`:

1. Maral MT splash for at least five seconds while the Tudlo splash decodes.
2. Tudlo splash for at least five seconds while the immediate Main Menu artwork
   precaches. Later flows prepare their own next-screen assets.
3. Main Menu.

Stages use a 550 ms `AnimatedSwitcher` fade.

### Main Menu

`MainMenuScreen` scales a 412×917 reference composition and overlays accessible
hit targets:

- Start New Koka → `NameScreen`.
- Continue → replaces Main Menu with `FourthLoadingScreen`, then Home.
- Load → `LoadScreen`.
- Settings → `PlaceholderScreen`.

### New Learner Onboarding

```text
NameScreen → GradeSelectionScreen → EnergySetterScreen
→ SecondLoadingScreen → LearnerCardScreen
→ HomeLoadingScreen (Loading 3) → WelcomeAboardScreen
```

- Name is trimmed and must be non-empty.
- Grade uses a looping three-card carousel.
- Energy changes in 10% steps and is constrained to 10–100%.
- Loading 2 waits at least five seconds and precaches learner-card assets.
- Learner Card displays learner data, grade art, progress, badges, touch tilt,
  and Flutter-painted ambient effects.
- Continue clears prior onboarding routes before Loading 3.
- Loading 3 waits at least five seconds, releases onboarding raster assets,
  precaches Welcome SVGs, supports a 30-second timeout/retry, then opens Welcome.

### Existing Learner Shortcut

```text
MainMenuScreen → FourthLoadingScreen (Loading 4) → HomeScreen
```

This is a development shortcut, not save restoration. It removes Main Menu,
uses the red loading SVG, shares Loading 3's animated labels/lifecycle, precaches
Home assets, and constructs Home only after loading completes.

### Welcome

`WelcomeAboardScreen` renders a responsive layered SVG landscape. Touch tilts
the scene; hardware tilt support exists in `FarmDepthBackground` but the screen
disables it. Flutter drives ambient sun/cloud motion.

- Next → tutorial placeholder.
- Skip → replaces Welcome with Home.

### Load

`LoadScreen` shows seven hard-coded `SavePreview` records, four per page. It has
responsive two-column cards, pagination, and load/delete dialogs. Confirmation
shows a SnackBar but does not alter or persist data.

### Home

`HomeScreen` currently includes:

- Wall color `#EADF99`.
- Vertically scrollable centered scene capped at 720 logical pixels.
- Stationary energy indicator (60%) and Settings button.
- Scroll-bound interactive lamp with animated beam.
- Scroll-bound circular window with rotating sun/drifting clouds.
- Stationary six-item navigation with Home selected.

Room contents and lesson features remain unfinished.

## Major Directories

| Path | Responsibility |
| --- | --- |
| `lib/app/` | Root application widget/global theme |
| `lib/core/` | Cross-feature colors and fade route |
| `lib/features/startup/` | Splash sequence/initial preload |
| `lib/features/main_menu/` | Main menu and entry routes |
| `lib/features/onboarding/` | Learner creation flow |
| `lib/features/load/` | Save previews/dialogs |
| `lib/features/welcome/` | Welcome scene and motion |
| `lib/features/home/` | Loading 3/4 and Home |
| `lib/features/placeholder/` | Explicit unfinished destinations |
| `lib/shared/` | Reused controls/placeholders |
| `assets/images/` | PNG/SVG art and versioned variants |
| `assets/fonts/` | Comic Relief fonts |
| `test/` | Widget/responsive regressions |
| `.magicpath/` | Generated/reference artifacts, not Flutter runtime |

## Status Summary

Implemented and tested: timed startup, menu hit targets, new-learner UI flow,
energy bounds, Loading 2/3/4 transitions, learner-card interactions, save grid
and dialogs, Welcome motion, Home shell/fixed UI, lamp, and animated window.

Partial or placeholder: Settings, tutorial, Home contents/tab routing,
voice-over playback, persistence/save restoration, and lessons.

See `docs/CURRENT_STATUS.md` for a detailed inventory.

## NEEDS PROJECT CONTEXT

- Final educational scope, curriculum, language, and lesson progression.
- Authoritative design/Figma source and final screen list.
- Production persistence, save selection, backend/NMT, and audio systems.
- Whether landscape is a target or portrait-only is intentional.
