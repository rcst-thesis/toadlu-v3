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
- Home energy defaults to 60 and is constructor-carried; it is not connected to
  durable learner state.
- All six bottom-navigation tabs now reach a destination via the centralized
  `AppBottomTabNavigation` router. Lessons, Map, Translate, and Dictionary are
  `PlaceholderScreen` shells pending real content; Me is a real screen shell
  (Settings/Edit buttons only).
- Voice-over callback UI exists without audio implementation.
- Hardware sensor support exists but Welcome disables it in favor of touch.
- Onboarding data is constructor-carried and not persisted.

## Placeholder-Only

- Welcome Next/tutorial destination.
- `RivePlaceholder` visuals in generic placeholder screens.

## Not Implemented

- Persistent saves, actual load/delete mutation, Continue restoration.
- Durable session/application state.
- Backend, NMT, APIs, auth, synchronization, or offline storage.
- Lesson models/repository/content/progression/completion.
- Real Translate, Dictionary, and Me content (all currently shells).
- Dynamic Home energy/session state, production lesson model/content,
  speaker/favorite behavior, and final ambient polish.
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

1. Final Settings, tutorial, Translate, Lessons, Map, Dictionary, and Me routes.
2. Persistent learner/save schema and Continue selection behavior.
3. Lesson/curriculum/progression/energy rules.
4. Backend/NMT/API/auth/offline contracts.
5. Production `.riv` files and exact runtime contracts.
6. Audio files/scripts/service and accessibility behavior.
7. Portrait-only versus landscape requirements.
8. Canonical Figma file/frame and asset archival policy.
9. Remaining Home implementation order after wall, lamp, and window.
