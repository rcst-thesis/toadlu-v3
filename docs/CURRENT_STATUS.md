# Current Implementation Status

This status is based only on current code and tests.

## Completed in the Prototype

### Shell and Startup

- `TudloApp` theme, Comic Relief, Material 3, and portrait request.
- Maral/Tudlo timed splashes, immediate-destination asset warm-up, fade
  switching, and retry for critical preparation failures.

### Main Menu

- Reference composition with accessible hit targets.
- Rive long-button controls and Rive Settings button, with Flutter retaining
  gesture recognition and navigation ownership.
- Start New Koka, Continue, Load, and Settings taps.
- Continue uses Loading 4 as a hard navigation boundary.

### New Learner

- Required trimmed name.
- Animated three-grade wraparound carousel and active-card continuation.
- Energy in 10% steps, bounded 10–100%.
- Voice-over callback seams and busy protection.
- Loading 2 minimum duration/learner-card preload.
- Learner card with learner data, progress/counters, badges, touch tilt,
  rays/holofoil motion, reset confirmation, and reduced motion.

### Loading 3 and Welcome

- Loading 3 animated lowercase labels and Koka artwork.
- Five-second minimum, 30-second timeout, retry, asset eviction/preload, and
  replacement navigation.
- Responsive normal/wide Welcome SVG scene, touch depth, ambient sky, and
  reduced-motion support.
- Welcome Skip route to Home.

### Loading 4

- Main Menu Continue removes Main Menu and opens Loading 4.
- Red Koka SVG using Loading 3's animated label/lifecycle engine.
- Home SVG/PNG precache; Home constructed after preparation.
- Loading 4 replaces itself with Home.

### Load UI

- Grade-aware `SavePreview` model.
- Seven demo saves, four per page, two-column cards, pagination.
- Load/delete confirmation dialogs and SnackBar feedback.

### Barangay Map

- Real interactive Rive map (`toadlu_map.riv`), pan/zoom framed on Koka's
  house by default, fullscreen landscape toggle.
- Rive-side tap detection (this asset has its own internal Listener
  components per location, unlike the previous map asset); Flutter reacts to
  `locationTapped`, gated by each location's Flutter-owned `isUnlocked` --
  shows a locked explanation instead of navigating when not unlocked,
  otherwise debounces double taps, resolves destination, navigates.
- Active-event system: an event can temporarily override a location's
  destination (`MapEventOverrides`) and marks it `hasEvent` (golden glow
  visual) for the override's duration; the first time an event touches a
  location it also permanently force-unlocks it (`isUnlocked`), which does
  not revert when the override clears.
- Full details, including how to trigger an event and add a real screen for
  a location: `docs/MAP_GUIDE.md`. Rive asset contract: `docs/RIVE_INTEGRATION.md`.

### Learner Save System

- `LearnerProfile`/`LearnerController`/`LearnerScope`
  (`lib/features/learner/`) persist the current learner (name, grade,
  energy, lessons/stickers/badges/streak counts, unlocked map locations) to
  on-device storage (`shared_preferences`), keyed by a generated learner id.
- Created at the real end of onboarding (`LearnerCardScreen._finish()`);
  restored on app startup (`TudloApp`); `HomeScreen`/`MeScreen` read from it
  automatically when no explicit override is supplied.
- Local-only, single active learner at a time; no cloud sync, no
  profile-switcher UI yet (storage already supports multiple profiles by
  id). Full details: `docs/LEARNER_GUIDE.md`.

### Home Increment

- Scrollable centered scene, max width 720.
- Stationary navigation and top controls.
- Six navigation items with optical icon sizes/shared label size; Home selected.
- Wall `#EADF99`, 60% indicator, and Settings button.
- Scroll-bound lamp with toggleable beam.
- Scroll-bound layered window at the 412-wide reference location.
- Ten-second sun/cloud animation and reduced motion.
- Furniture, door-to-Map action, bookshelf-to-Lessons action, word-of-the-day,
  sticker container, developer panel, and scroll footer.
- Rive Koka mascot reactions with Flutter speech bubbles and repeated-tap
  escalation.
- Energy-derived lesson availability, expandable/collapsible lesson cards, and
  a Flutter lesson-preview dialog.

## Partial

- Home scene height/content is temporary verification structure.
- Home energy defaults to 60 when no learner is loaded (`LearnerScope`),
  same as before this constructor-carried default existed -- see Learner
  Save System above.
- All six bottom-navigation tabs now reach a destination via the centralized
  `AppBottomTabNavigation` router. Map is a real screen (see above); Lessons,
  Translate, and Dictionary are still `PlaceholderScreen` shells pending real
  content; Me is a real screen shell showing real learner data where
  loaded (Settings/Edit buttons functional; Edit opens a real popup that
  renames the learner and picks a Koka avatar from `assets/images/avatar.riv`
  -- persisted via `LearnerController.updateName`/`updateAvatar` -- badge
  collection UI is still incomplete).
- Voice-over callback UI exists without audio implementation.
- Hardware sensor support exists but Welcome disables it in favor of touch.
- Onboarding data now persists via the Learner Save System (above), but
  only the current learner -- no profile switching, no cloud sync.

## Placeholder-Only

- Welcome Next/tutorial destination.
- `RivePlaceholder` visuals in generic placeholder screens.

## Not Implemented

- The Load screen's save browser is still demo data, unconnected to the
  real Learner Save System (above) -- no actual load/delete mutation there.
- Multi-learner profile switching UI (storage supports multiple profiles
  by id; there's no screen to create/switch between them).
- Backend, NMT, APIs, auth, synchronization, or offline/cloud storage --
  the Learner Save System is local-only, on-device.
- Lesson models/repository/content/progression/completion (lesson
  completion incrementing a learner's `lessonsFinished`, specifically, is
  not wired -- the save system supports it, nothing calls it yet).
- Real Translate, Dictionary, and Lessons content (still shells); Me's
  badge collection UI. (Me's name/avatar profile editing is now real -- see
  Partial above.)
- Production lesson model/content, speaker/favorite behavior, and final
  ambient polish.
- Audio assets/service.
- Release identity/signing: Android is `com.maralmt.tudlo_prototype` and release
  currently uses debug signing.

## Tests

- `test/widget_test.dart`: startup, menu, onboarding, loading, learner card,
  Load, Welcome, and portrait overflow.
- `test/home_screen_shell_test.dart`: Home scrolling/fixed layout, responsive
  overflow, room placement, Settings, energy/lesson cards, lamp, and navigation.
- `test/animated_home_window_test.dart`: window timing and reduced motion.
- `test/home_word_of_the_day_test.dart`: word-of-the-day presentation.
- `test/long_button_contract_test.dart`: long-button Data Binding and Flutter
  action reachability.
- `test/koka_mascot_contract_test.dart`: Koka State Machine contract and
  escalating interaction behavior.
- `test/me_screen_test.dart`: Me screen's tabs, progress counts, and daily
  streak card.

There is no dedicated map or learner-save test file yet -- coverage for
both exists only as ad hoc verification during development (see
`docs/MAP_GUIDE.md`/`docs/LEARNER_GUIDE.md`), not as committed tests.

Standard checks are `flutter analyze` and `flutter test`. This documentation
task changes no Dart behavior; release work should still run the full suite.

## Repository and Platform Limitations

- This managed directory has no local `.git`; Git can resolve unrelated parent
  metadata and fail. Open a real clone/repository root in standalone Codex.
- `sources/` and `tool/` are empty at this audit.
- `.magicpath/` is reference/generated content, not Flutter runtime.
- Portrait locks mean landscape is unverified and currently disabled.
- Web metadata still has generic prototype name/description/colors.

## NEEDS PROJECT CONTEXT

1. Final Settings, tutorial, Translate, Lessons, and Dictionary routes; the
   real screens each Map location should open (currently `PlaceholderScreen`
   shells via `MapDefaultRoutes` -- see `docs/MAP_GUIDE.md`).
2. Multi-learner profile switching / Load screen reconciling with the real
   Learner Save System (schema and single-learner persistence already exist
   -- see `docs/LEARNER_GUIDE.md`); Continue selection among saves.
3. Lesson/curriculum/progression/energy rules, and wiring lesson completion
   to `LearnerController` (supported, nothing calls it yet).
4. Backend/NMT/API/auth/offline contracts.
5. Production `.riv` files and exact runtime contracts.
6. Audio files/scripts/service and accessibility behavior.
7. Portrait-only versus landscape requirements.
8. Canonical Figma file/frame and asset archival policy.
9. Remaining Home implementation order after wall, lamp, and window.
