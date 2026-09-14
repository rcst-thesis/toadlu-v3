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
| `assets/images/mapvtwo.riv` | `Brgy. Koka` (2400 × 1400) | `MapAvailabilityStateMachine` | View Model `MapLocationStates`: per-location (`house`, `school`, `plaza`, `market`, `farm`, `beach`, `church`, `hospital`) `isAvailable` boolean and `eventTriggered` trigger (200ms squash). No click listeners in the asset. | `RiveMapScene` (via `MapScreen`) |

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

### Barangay map contract

`RiveMapScene` in `lib/features/map/presentation/widgets/rive_map_scene.dart`
loads `mapvtwo.riv`'s `Brgy. Koka` artboard and `MapAvailabilityStateMachine`,
rendered with `Fit.contain` at its native 2400 × 1400 aspect ratio so it's
never stretched or cropped. The asset has no click listeners, so Flutter lays
one transparent `GestureDetector` tap zone per `MapLocation` over the scene,
positioned in the artboard's own 2400 × 1400 coordinate space (calibrated
against the exported art) rather than fixed phone pixels, so the zones
scale/pan together with `MapScreen`'s `InteractiveViewer` transform.

Do not modify `MapLocationStates` or the existing availability/activation
state machine layers from Flutter; Rive owns the *visuals* entirely, but
Flutter is the source of truth for two of the booleans that drive them:

- `<location>/isAvailable` -- **normally Rive-owned, Flutter reads it** to
  gate taps: `RiveMapScene`'s tap zone for a location only calls
  `onLocationTapped` (and only then does `MapScreen` fire the squash
  trigger, wait, and navigate) while it's `true`. A location missing the
  property entirely fails closed (not tappable). The one exception: the
  moment an active lesson/event sets an override for a location, Flutter
  *writes* this to `true` too, so the event's stop is reachable even if that
  location isn't normally unlocked yet -- and leaves it `true` afterwards.
  An event permanently unlocks a location it touches; it never re-locks one.
  This is session-only (see the persistence note below).
- `<location>/isActive` -- **Flutter-owned, Rive reads it.** Drives that
  location's golden/bouncy "active event" visual, `true` exactly while that
  location currently has an override, `false` once it's cleared (unlike
  `isAvailable`, this one *does* revert -- the golden hint is about the
  event being active right now, not about permanent access).

Both are kept in sync with `MapEventOverrides` and `MapProgressController`
(`lib/features/map/domain/map_progress.dart`) by
`MapScreen._syncEventVisuals`, called on every `MapEventOverrides` change and
once more when the Rive scene finishes loading (to pick up overrides/unlocks
that already existed before this particular `MapScreen`/Rive scene instance
existed -- which happens on every tab switch, since `MapScreen` is rebuilt
fresh each time).

**Persistence:** `MapProgressController.unlockedLocations` is what makes a
location's unlock survive leaving and returning to the Map tab within a
session -- it's an app-wide instance (`MapProgressScope`, wired once in
`tudlo_app.dart`), not tied to any one `MapScreen`/Rive scene instance. It's
still just an in-memory `Set` driving the visuals, but it's backed by real,
per-learner persistence now: `MapScreen` syncs it with the current learner's
`LearnerProfile.unlockedMapLocations` via `LearnerScope`, so it also
survives an app restart, correctly scoped to whichever learner is signed in.
See [`LEARNER_GUIDE.md`](LEARNER_GUIDE.md) for how that system works and how
to extend it.

On a tap that passes the `isAvailable` check, `MapScreen`:

1. Ignores the tap if a previous one is still being handled
   (`_isHandlingTap`), preventing double taps.
2. Fires that location's `<location>/eventTriggered` trigger via
   `RiveMapSceneController.fireTrigger` to play its existing 200ms squash
   press animation. Rive owns only that visual; Flutter decides what happens
   next.
3. Waits ~120ms, then resolves the destination through
   `MapEventOverrides.resolve` (`lib/features/map/domain/map_route_resolver.dart`):
   an active lesson/event's override for that location if one is set,
   otherwise its entry in `MapDefaultRoutes`. House's default is "go home"
   (`GoHomeRouteAction`, same as the Home tab); every other location's
   default currently opens a temporary `PlaceholderScreen` shell, matching
   the other not-yet-built bottom-tab destinations, until those screens
   exist. `MapEventOverrides` starts empty (no active event) and is cleared
   by whatever owns a lesson/event's lifecycle when it ends, restoring every
   location to its default.
4. Navigates via `Navigator.push`/`popUntil`.

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
