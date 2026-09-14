# Barangay Map — Developer Guide

Practical instructions for working with Koka's interactive barangay map.
For the Rive asset contract itself (artboard/state machine/view model
names), see [`RIVE_INTEGRATION.md`](RIVE_INTEGRATION.md#barangay-map-contract) —
this doc is about using and extending the Flutter side.

## Files

```
lib/features/map/
  domain/
    map_location.dart        # MapLocation enum (house, school, plaza, ...)
    map_route_resolver.dart  # MapDefaultRoutes, MapEventOverrides, route actions
  presentation/
    screens/map_screen.dart          # Owns navigation, tap debounce, camera framing
    widgets/rive_map_scene.dart      # Loads the .riv, tap zones, availability gating
    widgets/map_expand_button.dart   # Fullscreen toggle (portrait -> landscape)
    widgets/map_exit_landscape_button.dart
```

Asset: `assets/images/mapvtwo.riv`.

## How a tap becomes a navigation

1. `RiveMapScene` lays one invisible tap zone per `MapLocation`, positioned
   in the artboard's native 2400x1400 coordinate space (calibrated against
   the exported art — see `RiveMapScene._tapZones`).
2. On tap, it checks that location's `isAvailable` (read from the Rive view
   model). **Not available → the tap does nothing.** This is Rive-owned data;
   Flutter only reads it, never writes it (except for local testing — see
   below).
3. If available, `MapScreen._handleLocationTapped` runs:
   - blocks a second tap while one is in flight (no double-navigation),
   - fires that location's squash-feedback trigger (`<location>/eventTriggered`),
   - waits ~120ms for the animation,
   - resolves the destination (see next section),
   - navigates.

## Adding a real screen for a location

Right now every location except House opens a temporary `PlaceholderScreen`
(same pattern as the not-yet-built Translate/Lessons/Dictionary bottom
tabs). To wire up a real screen, edit `MapDefaultRoutes` in
`lib/features/map/domain/map_route_resolver.dart`:

```dart
static Widget _plaza(BuildContext context) => const PlazaScreen();
```

Just replace the `PlaceholderScreen(...)` body of that location's static
builder method with your real screen. Nothing else needs to change — the
tap-handling flow in `MapScreen` and the availability gating stay the same.

House is different: its default isn't a pushed screen, it's
`GoHomeRouteAction()`, which pops back to the app's root (same as tapping
the Home tab). Only change that if House itself should open a real screen
someday.

## The event/lesson override system

Every location has a **default** route (`MapDefaultRoutes`, above). An
active lesson or event can **temporarily override** where a location goes,
without touching the default. This is what `MapEventOverrides` is for.

### The rule

```
active event's route for this location, if one is set
otherwise
the location's default route
```

That's it — `MapEventOverrides.resolve(location)` implements exactly this.

### Example: a house-specific lesson

```dart
// When the lesson becomes active:
eventOverrides.setOverride(
  MapLocation.house,
  PushScreenRouteAction((context) => const HouseLessonScreen()),
);

// When the lesson ends (completed, skipped, whatever):
eventOverrides.clearOverride(MapLocation.house);
// House automatically goes back to GoHomeRouteAction() -- its default.
```

### Example: a multi-stop event (e.g. "find the dog")

```dart
void startDogFindingEvent(MapEventOverrides overrides) {
  overrides.setOverride(
    MapLocation.market,
    PushScreenRouteAction((context) => const DogFindingMarketStopScreen()),
  );
  overrides.setOverride(
    MapLocation.farm,
    PushScreenRouteAction((context) => const DogFindingFarmStopScreen()),
  );
}

void endDogFindingEvent(MapEventOverrides overrides) {
  overrides.clearOverride(MapLocation.market);
  overrides.clearOverride(MapLocation.farm);
  // Or just overrides.clearAll() if nothing else has an override active.
}
```

Every location not explicitly overridden keeps working normally the whole
time — you only ever touch the locations the event actually affects.

### The visual side: isActive, and permanently unlocking on first activation

Setting an override doesn't just change where a tap goes — it also:

1. makes Rive render that location as **active**: a golden, bouncy visual
   distinct from its normal idle look, so the player can see at a glance
   where the event's stop is — **only while the override is set**, same as
   the tap-redirect itself;
2. **permanently unlocks it**, the first time it gets an override, even if
   it wasn't normally available yet — an event shouldn't be unreachable just
   because the player hasn't progressed far enough to unlock that location
   the normal way. Unlike the golden visual, this does **not** revert when
   the override clears: once an event has touched a location, it stays
   tappable for good, not just for that event's duration.

Both are wired automatically by `MapScreen._syncEventVisuals`, which runs on
every `MapEventOverrides` change (and once more when the Rive scene finishes
loading, to catch overrides set before the map was even on screen):

```
for every location:
  hasOverride = overrides.overrideFor(location) != null
  isActive    = hasOverride           // follows it exactly, on and off
  if hasOverride: isAvailable = true  // one-way -- never set back to false
```

**No active event, nothing overridden → `isActive` stays `false`
everywhere**, and every location's `isAvailable` is whatever it naturally
is (Rive's own unlock logic, or `true` for good if some earlier event
already touched it). This only ever changes for locations an event
explicitly targets.

**Persistence: real, and per-learner.** `MapProgressController.unlockedLocations`
(`lib/features/map/domain/map_progress.dart`) is still just an in-memory
`Set` -- it's what drives the visuals -- but `MapScreen` keeps it in sync
with the real, persisted source of truth: the current learner's
`LearnerProfile.unlockedMapLocations`, via `LearnerScope`. Full details,
including how to add new persisted learner data, are in
[`LEARNER_GUIDE.md`](LEARNER_GUIDE.md). Short version: don't write to
`MapProgressController.unlockedLocations` from anywhere except
`MapScreen`'s existing `_syncEventVisuals` -- it's not the thing that
actually persists.

You don't call any of this yourself — just call `setOverride`/
`clearOverride` as shown above and both the golden/bouncy visual and the
permanent unlock follow automatically, for every location you touch. This
also means: don't call `setActive`/`setAvailable` on the Rive scene directly
from your own code, and don't set an override "just for the visual" without
meaning to also redirect and permanently unlock that location — all three
are the same signal by design.

### Wiring it up — already done, here's how

`AppBottomTabNavigation` builds a fresh `MapScreen()` every time the Map tab
is selected, which would normally mean any override/unlock set while Map
isn't on screen gets lost by the time the player reopens it. That's solved:
`MapScreen` finds the app's one shared `MapProgressController` for itself,
via `MapProgressScope.of(context)`, and uses its `eventOverrides` and
`unlockedLocations`. You don't need to pass anything into `MapScreen` or
touch `app_bottom_tab_navigation.dart` at all.

```
lib/features/map/domain/map_progress.dart
  MapProgressController  -- owns the shared MapEventOverrides + unlockedLocations
  MapProgressScope        -- InheritedWidget making it reachable from anywhere

lib/app/tudlo_app.dart
  Instantiates MapProgressController once, wraps the app in MapProgressScope
  (same pattern as the existing AppAnimationController/AppAnimationScope).
```

To actually trigger an event from your lesson/event system, get the shared
overrides from wherever you have a `BuildContext` and call `setOverride`/
`clearOverride` exactly as shown above:

```dart
final overrides = MapProgressScope.of(context).eventOverrides;
overrides.setOverride(
  MapLocation.house,
  PushScreenRouteAction((context) => const HouseLessonScreen()),
);
// ...and later:
overrides.clearOverride(MapLocation.house);
```

`MapScreen` never disposes `MapProgressController`'s `eventOverrides` (it's
owned by `TudloApp`, not the screen) — this is safe to call from anywhere,
any number of times, across as many Map visits as you like.

`MapScreen`'s own `eventOverrides` constructor parameter still exists, but
it's for tests only (supply an isolated instance instead of reaching into
the shared one). Real app code shouldn't need it.

### What NOT to do

- Don't put per-lesson/per-event navigation logic inside `RiveMapScene` or
  the Rive asset. Rive only renders visuals (availability, active/golden
  state, squash press); Flutter decides what each boolean means and when to
  set it. Route resolution is 100% Flutter's job, via `MapEventOverrides`.
- Don't forget to clear an override when its event ends. A forgotten
  override permanently hijacks that location's tap *and* leaves it stuck
  golden/bouncy until the app restarts.
- Don't hand-roll a second "is there an active event" check elsewhere —
  `MapEventOverrides.resolve()` is the single source of truth Map already
  consults on every tap, and `overrideFor()` is what drives the visual.

## Availability (isAvailable)

Each location's *normal* availability is Rive-owned data
(`<location>/isAvailable` in the `MapLocationStates` view model) — Flutter
reads it to decide whether a tap does anything, but doesn't drive it.
Whatever unlocks a location (finishing a prior lesson, reaching some
milestone, etc.) needs to set that boolean through Rive's own data binding
for the location to become tappable.

The one exception is the active-event override system described above,
which permanently unlocks a location the first time it gets an event
override -- that's the *only* place Flutter is allowed to write this
boolean. Don't add a second place that does.

For **local testing only**, you can force a location available by setting
its bound boolean's `.value` directly in `RiveMapScene._load()` (this is a
runtime write to the view model instance, not an edit to the `.riv` file
itself, so it's safe/reversible):

```dart
// TEMP: force <location> available for testing. Remove when done.
availability[MapLocation.plaza]?.value = true;
```

Remove it before shipping — it's a debug convenience, not a feature.

## Tap zone calibration

If the map art changes (new export, moved buildings), the tap zones in
`RiveMapScene._tapZones` need recalibrating — they're plain `Rect`s in the
2400x1400 artboard coordinate space, hand-measured against the exported
art. There's no automatic way to derive them from the `.riv` file's hit
regions since (per the asset's contract) it has no click listeners of its
own.

To recalibrate: render the artboard (e.g. a throwaway `flutter test`
`matchesGoldenFile` on `RiveWidget` at native 2400x1400 resolution),
identify each location's marker/building center in the image, and convert
pixel coordinates back to artboard space using the image's known scale.

## Hot reload vs. restart

Rive loading happens in `RiveMapScene`'s `initState()`, which only runs
once per State instance. **Hot reload will not pick up changes to:**
- the `.riv` asset file itself,
- tap zone rects,
- availability-gating logic,
- anything else inside `_load()`.

Use a **full restart** (`R` in `flutter run`, or stop + rerun if a hot
restart doesn't pick up a brand-new/removed asset file) for those. Pure
`build()`-level tweaks (sizes, colors, layout) are fine with a plain hot
reload.
