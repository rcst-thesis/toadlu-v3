# Rive Integration Status and Rules

## Confirmed State

The app uses `rive: ^0.14.10` (resolved to `0.14.11`) with the Flutter Rive
renderer. Runtime assets are stored under `assets/images/`, which is already
declared in `pubspec.yaml`. `main()` initializes `RiveNative` before the app
is shown so the first Rive control does not need to initialize the renderer on
its first interaction.

The current runtime-contract inventory is:

| `.riv` file | Artboard | State machine | Inputs/events/bindings | Flutter owner |
| --- | --- | --- | --- | --- |
| `assets/images/koka_mascot.riv` | Default artboard | `State Machine 1` | Legacy triggers `Hi`, `Curious`, `Annoyed` | `HomeKokaMascot` |
| `assets/images/longbtn.riv` | Default component artboard | Default exported machine | Data Binding: `buttonLabel` string, `activated` trigger; legacy `isPressed` drives press motion | `RiveLongButton` |
| `assets/images/settings_button.riv` | `SettingsButton` | `SettingsButtonStateMachine` | Data Binding: `activated` trigger; legacy `isPressed` drives press and gear rotation | `RiveSettingsButton` |
| `assets/images/settings_button_home.riv` | `SettingsButton` | `SettingsButtonStateMachine` | Home-specific Settings visual; same `activated` and `isPressed` contract | `HomeSettingsButton` |
| `assets/images/settings_button_me.riv` | `SettingsButton` | `SettingsButtonStateMachine` | View Model `SettingsButtonVM` (`activated` trigger); legacy `isPressed` boolean drives press and gear rotation | `MeSettingsButton` |
| `assets/images/green_back_button.riv` | `Artboard` (93 × 44) | `State Machine 1` | View Model `Button` (`pressed` boolean only; no trigger) drives press motion | `RiveBackButton` |
| `assets/images/edit_button_me.riv` | `Artboard` (190 × 198) | `State Machine 1` | View Model `Button` (`down` boolean only; no trigger) drives press motion | `RiveEditButton` (via `MeEditButton`) |

### Long button contract

`RiveLongButton` in `lib/shared/widgets/rive_long_button.dart` is the only
Flutter bridge for the exported long-button component. It deliberately uses
the default artboard, default state machine, and `DataBind.auto()` because the
export does not retain stable public names for those objects.

- Rive owns the raised/down visual press and the displayed `buttonLabel`.
- Flutter assigns `buttonLabel` and drives the component's exported legacy
  `isPressed` input on touch down/up. It keeps `activated` available in the
  asset for runtimes that consume it directly.
- Flutter invokes the existing callback from its recognised tap gesture, so
  navigation, form validation, persistence, and all application truth remain
  reliable even when the exported trigger is not emitted by a component
  listener.
- The Rive artboard is 353 × 52. Consumers reserve 52 logical pixels and place
  it four pixels higher than the legacy 44px visual slot, so the raised face
  remains aligned while the pressed face can move down over its shadow.
- The bridge preserves Flutter semantics and provides a static visual fallback
  while the asset initializes.

### Settings button contract

`RiveSettingsButton` in `lib/shared/widgets/rive_settings_button.dart` is used
by the Main Menu, Home, and Me Settings controls. The Main Menu uses
`settings_button.riv`; Home uses `settings_button_home.riv`; Me uses
`settings_button_me.riv` via `MeSettingsButton`. All three share the identical
inspected contract (View Model `SettingsButtonVM` with an `activated` trigger,
`SettingsButtonStateMachine` with a legacy `isPressed` boolean), just different
exported visuals. It renders at 47 × 49 logical pixels with `Fit.contain`,
preserving the circular button shape. Flutter sets the public `isPressed`
input on touch down, clears it on up/cancel, and invokes the existing
Settings navigation callback only on a completed Flutter tap.

### Back button contract

`RiveBackButton` in `lib/shared/widgets/rive_back_button.dart` is the runtime
bridge for the exported green back-button component and is the sole
implementation behind `LoadBackButton`/`AdaptiveBackButtonPlacement`, used on
every screen with a back action (Name, Grade, Energy, Settings, Load, and
generic `PlaceholderScreen` shells). Unlike the settings buttons, its View
Model (`Button`) only exposes a `pressed` boolean — there is no `activated`
trigger in this asset. Flutter's recognized tap fully owns invoking the
existing `onPressed` callback; the `pressed` boolean only drives the visual
press/release motion. It renders at 93 × 44 logical pixels with `Fit.contain`,
matching the legacy `DesignNavigationButton` footprint it replaced, so callers
did not need layout changes.

### Edit button contract

`RiveEditButton` in `lib/shared/widgets/rive_edit_button.dart` is the runtime
bridge for the Me screen's exported edit-button component, used via
`MeEditButton`. Same shape as the back button: its View Model (`Button`)
exposes only a `down` boolean, no trigger, so Flutter's recognized tap fully
owns invoking `onPressed`. The native artboard is 190 × 198 (~0.96 aspect,
matching the 47 × 49 display slot closely), rendered with `Fit.contain` at
47 × 49 logical pixels to align with `RiveSettingsButton`'s scale, per the
existing "same scale as Settings" requirement for Me's top buttons.

## What Is Not Rive

- `lib/shared/widgets/rive_placeholder.dart` is a bordered Flutter placeholder
  with a Material icon and label. It does not load Rive.
- `AnimatedHomeWindow`, `InteractiveHomeLamp`, and `FarmDepthBackground` animate
  static SVG layers with Flutter controllers/transforms/sensors.
- `.magicpath/` contains generated/reference settings artifacts and is not part
  of the Flutter runtime or a Rive contract.

Do not describe Flutter keys/controllers as Rive inputs.

## Responsibility Boundary

Flutter should own:

- Screen layout, constraints, SafeArea, and navigation.
- Learner/session/save truth and validation.
- Persistence, backend/NMT work, retries, and errors.
- Accessibility and non-visual fallback behavior.
- Forms, lists, lessons, dynamic text, and data-heavy UI.

Rive may own an approved component's character/icon animation, loading/success/
error visuals, press/state visuals, ambient motion, or interactive illustration
state synchronized with Flutter truth.

## Required Handoff for a Future `.riv`

Record this before integration:

```text
Feature:
Rive file path:
Rive package version:
Artboard/component:
State machine:
Timeline animations:
Boolean inputs:
Number inputs:
Trigger inputs:
Events:
View Model and properties/types:
Default instance:
Flutter widget/file:
Flutter-owned state:
Rive-owned state:
Fit/alignment and parent constraints:
Safe-area owner:
Reduced-motion behavior:
Fallback/error behavior:
```

Inspect the exported file; never copy names from a screenshot or old discussion.
Verify APIs against current official Rive Flutter documentation.

## Integration Rules

1. Add a supported `rive` dependency only after file contract/runtime targets are
   confirmed. Do not upgrade unrelated packages.
2. Store approved runtime assets in an agreed folder and declare them in
   `pubspec.yaml` when outside the current image directory.
3. Use exact inspected names and handle missing contracts safely.
4. Rive events may request an action; Flutter decides navigation/state mutation.
5. Avoid duplicating state across legacy inputs and View Models without need.
6. Dispose controllers/listeners and block post-disposal callbacks.
7. Preserve aspect ratio with deliberate constraints/fit.
8. Let Flutter own SafeArea unless the full-screen Rive contract says otherwise;
   never apply it twice.
9. Preserve accessible Flutter semantics and non-overlapping hit targets.
10. Test initialization, missing files, input/event wiring, repeated taps, resize,
    disposal, navigation ownership, and reduced motion where applicable.
11. Update this document with the actual contract in the same change.

## Potential Replacement Points (Not Approved)

The Welcome tutorial destination and other generic placeholder routes have no
approved Rive contracts. `RivePlaceholder` suggests future animation but defines
no files or contracts. Do not replace working Flutter motion by default.


## NEEDS PROJECT CONTEXT

- Production `.riv` locations and exact contracts.
- Which screens/components are approved for Rive.
- Selected Flutter Rive package/runtime version.
- Per-component choice of legacy inputs versus data binding/View Models.
- Fit, resize, orientation, SafeArea, fallback, and reduced-motion contracts.
