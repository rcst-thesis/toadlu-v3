# Rive Integration Status and Rules

## Confirmed State

There is no active Rive integration in this repository:

- `pubspec.yaml` has no `rive` dependency.
- `assets/` has no `.riv` files.
- Dart creates no Rive widget, artboard, state machine, animation controller,
  event listener, View Model, or data binding.
- No artboard/state-machine/input/event/View Model names can be derived.

The current runtime-contract inventory is therefore intentionally empty:

| `.riv` file | Artboard | State machine | Inputs/events/bindings | Flutter owner |
| --- | --- | --- | --- | --- |
| None | None | None | None | None |

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

The only explicit future placeholders are Settings (Main Menu/Home) and the
Welcome tutorial destination. `RivePlaceholder` suggests future animation but
defines no files or contracts. Do not replace working Flutter motion by default.

## NEEDS PROJECT CONTEXT

- Production `.riv` locations and exact contracts.
- Which screens/components are approved for Rive.
- Selected Flutter Rive package/runtime version.
- Per-component choice of legacy inputs versus data binding/View Models.
- Fit, resize, orientation, SafeArea, fallback, and reduced-motion contracts.

