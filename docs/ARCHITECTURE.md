# Tudlo Architecture

## Style

Tudlo uses a small feature-oriented Flutter architecture. Features own their
presentation widgets/private helpers. Load also has a minimal domain model.
Shared controls and infrastructure live in `shared/` and `core/`.

There is no formal clean-architecture stack, DI container, Provider/BLoC/
Riverpod, router, repository, or backend layer. Do not describe these as present.

## Composition Root

```text
main()
└── Flutter initialization + portrait orientation
└── TudloApp
    └── MaterialApp (Material 3, ComicRelief, green/mint theme)
        └── StartupFlow
```

## State and Feature Communication

- `StartupFlow`: local integer stage and async warm-up callbacks.
- `NameScreen`: text/focus controllers and voice-over busy flag.
- `GradeSelectionScreen`: carousel selection/order and voice-over state.
- `EnergySetterScreen`: energy value and voice-over state.
- Loading screens: one-shot async preparation state.
- `LearnerCardScreen`: immutable learner inputs; nested animation/tilt state.
- `LoadScreen`: constant demo saves and local current page.
- Welcome/Home widgets: local interaction and animation controllers.

Onboarding data is passed through constructors:

```text
learnerName: String
grade: int (1, 2, or 3)
energy: int (10–100 in 10-point increments)
```

No learner/session state persists after termination.

## Home Structure

```text
Scaffold
└── Column
    ├── Expanded
    │   └── Stack
    │       ├── SingleChildScrollView
    │       │   └── centered scene (max width 720)
    │       │       ├── temporary content/wall
    │       │       ├── InteractiveHomeLamp
    │       │       └── AnimatedHomeWindow
    │       ├── HomeSettingsButton (stationary)
    │       └── HomeEnergyIndicator (stationary)
    └── HomeBottomNavigation (stationary)
```

`HomeBottomNavigation` exposes `ValueChanged<int>? onItemTapped`, but Home does
not supply it yet. Home remains visually selected.

## Loading Boundaries

- `SecondLoadingScreen` precaches learner-card images, shows a retry action if
  that critical preparation fails, and replaces itself.
- `HomeLoadingScreen` is the Loading 3 engine: minimum display, animated labels,
  onboarding asset eviction, destination-specific preload, timeout/retry, and
  replacement.
- `FourthLoadingScreen` configures that engine with red art, Home preloading,
  and `HomeScreen` as destination.

Loading 3 is reached with `pushAndRemoveUntil(..., false)`. Loading 4 replaces
Main Menu. Both later replace themselves; destination widgets are built after
preparation.

## Navigation Map

```text
StartupFlow
└── MainMenuScreen
    ├── Settings → placeholder
    ├── Load → LoadScreen
    ├── Start New Koka → Name → Grade → Energy → Loading 2
    │                   → Learner Card → Loading 3 → Welcome
    │                                              ├── Next → tutorial placeholder
    │                                              └── Skip → Home
    └── Continue → Loading 4 → Home

Home
├── Settings → placeholder
└── Bottom tabs → no HomeScreen routes/callback yet
```

Page navigation uses `FadePageRoute`; dialogs and Startup switching use their
own fades.

## Rendering and Motion

- PNGs use `Image.asset`, usually `BoxFit.contain`.
- SVGs use `SvgPicture.asset`; layered scenes can request raster rendering via
  `vector_graphics`.
- All motion currently uses Flutter controllers, transforms, implicit animation,
  sensors, and custom painters—not Rive.
- Animated components should honor `MediaQuery.disableAnimations`.

## Widget Composition and Rebuild Boundaries

- Split a screen into focused `StatelessWidget` or `StatefulWidget` classes
  when a region has independent state, a distinct lifecycle, an animation, a
  reusable layout contract, or a stable visual responsibility. Keep the
  `StatefulWidget` boundary as close as practical to the state it owns.
- Use helper methods only for small, local structural fragments that depend on
  the same state and are not useful as a separate boundary. A helper method is
  not a rebuild boundary; extracting one mechanically does not improve runtime
  work on its own.
- Use `const` constructors and `const` child widgets whenever their inputs are
  compile-time constants. This lets Flutter reuse the identical widget
  configuration during an ancestor rebuild. Do not remove a needed runtime
  input merely to make a widget `const`.
- Keep fast-changing state local. For example, touch feedback belongs in the
  control that renders it, and ambient animation should rebuild only through a
  narrow `AnimatedBuilder`/`ListenableBuilder` subtree. Supply an invariant
  `child` to those builders when possible.
- A separate widget class improves organization and can create a useful state
  boundary, but it does not automatically prevent its `build` method from
  running when an ancestor supplies a new configuration. Measure before making
  a performance-driven refactor; preserve stable keys, semantics, callbacks,
  and responsive constraints.
- Use `RepaintBoundary` around independently animated or expensive artwork
  only when it limits repaint work without breaking compositing or memory
  behavior. It is a paint optimization, not a substitute for correct rebuild
  boundaries.

## Testing

Tests import public API through `lib/tudlo.dart` or focused widgets directly.
Configurable durations/callbacks avoid real audio and long waits. Stable keys and
semantics support interaction and geometry assertions.

Coverage emphasizes route boundaries, loading/preparation, form logic, fixed vs
scrolling Home content, portrait overflow, Figma placement, animation timing,
and reduced motion.

## Extension Rules

- Add `domain/`, `data/`, or `application/` only when real behavior requires it.
- Define persistence/backend interfaces before extracting demo widget state.
- Keep route ownership in Flutter even when Rive supplies visuals.
- Preserve or replace callback test seams with equally testable abstractions.
- Export new public test-facing types from `lib/tudlo.dart` when appropriate.

## NEEDS PROJECT CONTEXT

- Persistence/repository choice and save schema.
- Backend/NMT interface and error/offline policy.
- Application-wide learner/session state owner.
- Final route/deep-link/back-stack requirements.
- Whether state management should remain local or adopt a chosen solution.
