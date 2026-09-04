# Smart Workspace

A Flutter productivity app built for the take-home assignment: a dashboard
with draggable/persisted cards, notes with checklists/images/reminders,
debounced search over a 5,000+ row local dataset, offline-first writes with
a sync queue, and four native Method Channel integrations (native date
picker, native options sheet, device info, and local notifications).

No backend was provided or used — everything runs against a local SQLite
database. Where the spec calls for something like weather or "network
sync," it's a labeled mock (see [Known limitations](#known-limitations)).

## Project overview

- **Dashboard** — Greeting, Today's Tasks, Notes count, mock Weather,
  Water Intake, Focus Timer, and Device Info cards, in a drag-to-reorder
  grid whose order and column count (1/2/3, by width) persist and respond
  to screen size.
- **Notes** — Create/edit/delete/archive, with a checklist, image
  attachments, a PDF attachment (reusing the same attachment model), and
  an optional reminder date that's wired through to a real local
  notification.
- **Search** — Debounced, keyword-highlighted search over 5,000+ generated
  records stored in SQLite (not a linear scan over an in-memory list, and
  not a giant shipped JSON asset).
- **Theme** — Light/dark/custom seed color, persisted.
- **Offline mode** — Every write applies to SQLite immediately regardless
  of connectivity; a `sync_queue` table tracks what still needs to reach
  the (simulated) server, and a banner shows "Working Offline" /
  "Syncing…" / "Synced" as connectivity changes.
- **Native integration** — Native date picker, native bottom sheet
  (Camera/Gallery/File Picker), device info (name/OS version/battery),
  all through one Method Channel, implemented on both Android (Kotlin) and
  iOS (Swift).
- **Notifications** — Daily reminder, per-note reminder, and a progress
  notification, via `flutter_local_notifications`.

## Folder structure

```
lib/
  main.dart                        # WidgetsFlutterBinding, DI setup, runApp
  app/
    app.dart                       # MaterialApp.router + theme wiring
    router/app_router.dart         # GoRouter route table (StatefulShellRoute)
    router/app_shell.dart          # bottom-nav scaffold, theme/offline toggles
    di/injection.dart              # get_it registrations
    theme/                         # ThemeData builders + persisted ThemeCubit
  core/
    constants/                     # route paths, db table/column names
    database/app_database.dart     # sqflite singleton, schema, migrations
    error/                         # Failure types + exception→Failure mapper
    network/connectivity_service.dart
    sync/                          # SyncQueue (pending writes) + SyncCubit (drain loop)
    platform/native_channels.dart  # MethodChannel wrapper
    notifications/notification_service.dart
    utils/                         # Debouncer, id generator
    widgets/                       # EmptyState, ErrorState, LoadingSkeleton, SyncBanner
  features/
    dashboard/
      data/        # local datasource + repository for card order
      domain/      # DashboardCardConfig, card type enum
      presentation/ # bloc, page, the draggable card grid, each card widget
    notes/
      data/        # sqflite datasource, models (fromMap/toMap)
      domain/      # Note, ChecklistItem, NoteImage entities
      presentation/ # bloc, list page, editor page, widgets
    search/
      data/        # mock dataset generator + sqflite-backed datasource
      domain/      # entities
      presentation/ # bloc, search page, highlighted result tile
test/                              # mirrors lib/, one test file per unit under test
android/app/src/main/kotlin/.../MainActivity.kt   # native channel handlers
ios/Runner/AppDelegate.swift                       # same contract, Swift side
```

There's no separate `native/`, `notifications/`, or `files/` feature
folder. I sketched those early on, but by the time I got there each one
was thin enough — a single wrapper service, or a couple of picker calls
inline in the note editor — that a dedicated feature layer around them
would have been pure ceremony with one call site each. The device info
card lives in `dashboard/presentation/widgets/cards/device_info_card.dart`;
the note editor drives the date picker, the options sheet, and the
image/file pickers directly through `getIt`.

## Architecture

**Feature-first, with light Clean Architecture layering inside each
feature** — not full Clean Architecture, not MVVM.

The assignment explicitly says not to over-engineer simple problems, and
full Clean Architecture (a dedicated use-case class per action, entity/DTO
mapping at every boundary) is a lot of ceremony for what is, underneath
the UI, a handful of CRUD and read operations. Feature-first keeps
everything about one feature — dashboard, notes, search — in one place,
which is easier to onboard into and easier to delete or replace than a
layer-first split where all the blocs live in one folder and all the
repositories in another. Inside each feature, `data` / `domain` /
`presentation` are still separated, so the actual benefit of Clean
Architecture — a bloc never touches `sqflite` directly, it always goes
through a repository interface — is retained where it matters.

**State management** is Bloc everywhere, per the spec, but not
uniformly `Bloc`: `Cubit` for things that are just a value that changes
(theme mode, the online/offline flag), and full `Bloc` for things with a
real event → state flow worth naming explicitly (notes CRUD, debounced
search, dashboard reorder). Being consistent about *which* one applies
where matters more than picking one and using it everywhere.

**Local database** is a single `sqflite` `AppDatabase`, opened once
through `get_it`, with `notes` / `checklist_items` / `note_images` as real
child tables (not a JSON blob column) so they're independently queryable
and editable, plus `dashboard_cards`, `sync_queue`, and `search_items`
(the generated 5,000-row dataset lives here too, so search demonstrates an
indexed SQL query rather than a linear scan). `PRAGMA foreign_keys = ON`
is set explicitly — it's off by default in sqflite — so the
`ON DELETE CASCADE` on the notes' child tables actually cascades instead
of leaving orphaned rows.

**Offline mode** uses "optimistic local write + replay queue," which the
assignment itself calls out as the better answer for a productivity app,
over "queue instead of writing." Every mutating repository call (notes
create/update/delete/archive, dashboard reorder) writes to SQLite
immediately no matter what connectivity looks like — nothing ever blocks
because you're offline — and also appends a row to `sync_queue`. That
queue drains on the same code path whether it's one fresh write while
already online (near-instant) or a backlog built up while offline
(visible "Syncing N changes…" → "Synced" banner) — there's no special
case for what triggered the drain.

**Dashboard drag-and-reorder** uses a small custom `DraggableCardGrid`
(`LongPressDraggable` + `DragTarget` over a `Wrap`) instead of
`ReorderableListView` or a third-party package. `ReorderableListView` is
single-column only, and the dashboard needs 2-3 columns on wider screens;
a `Wrap` also lets each card size to its own content instead of forcing a
uniform aspect ratio across six visually different cards. It's about 90
lines on top of SDK widgets — not worth a dependency for. `LongPressDraggable`
specifically (not plain `Draggable`) so a normal scroll or tap doesn't get
mistaken for a drag start, and each cell carries `ValueKey(cardType)` so
widgets with local state (the water count, the focus timer) survive being
dragged to a new position instead of resetting.

**Navigation** is GoRouter with a single `StatefulShellRoute.indexedStack`
for the bottom-nav shell, so each tab keeps its own navigation stack and
scroll position. One caveat this caused, and how it was fixed, is under
[Known limitations](#known-limitations).

**Performance**: `const` constructors wherever valid; the search list is
`ListView.builder`, not 5,000 eagerly-built widgets; search input is
debounced (~350ms) before it hits the database; blocs use `buildWhen` to
avoid rebuilding widgets that don't care about a given state field; image
thumbnails use `cacheWidth`/`cacheHeight` instead of decoding full
resolution into memory.

## Packages used

| Package | Why |
|---|---|
| `flutter_bloc`, `equatable` | Required state management approach; `equatable` keeps state/event classes' `==` correct without hand-writing it |
| `get_it` | Required DI approach — a plain service locator, registered once in `app/di/injection.dart` |
| `go_router` | Required navigation approach; `StatefulShellRoute` gives the bottom nav persistent per-tab state for free |
| `sqflite`, `path`, `path_provider` | Required local database; `path`/`path_provider` for locating the db file cross-platform |
| `shared_preferences` | Theme mode/color is a single key-value pair — didn't need a table for that |
| `connectivity_plus` | Real connectivity signal for offline mode, alongside the manual debug toggle used for the demo |
| `intl` | Date formatting (note timestamps, reminder dates, dashboard greeting) |
| `uuid` | Primary keys for notes/checklist items/images — generated client-side since there's no backend to assign IDs |
| `flutter_local_notifications`, `timezone`, `flutter_timezone` | Local notifications module; `timezone`/`flutter_timezone` because scheduled notifications need real timezone data, not just the device's UTC offset |
| `file_picker`, `image_picker` | The actual OS pickers behind the native options sheet's Camera/Gallery/File choices |
| `permission_handler` | Runtime camera/photo permission requests before invoking the pickers |
| `flutter_lints` | Default recommended lint set |
| `bloc_test`, `mocktail`, `sqflite_common_ffi` | Testing: `bloc_test` for bloc state-machine assertions, `mocktail` for repository/service mocks, `sqflite_common_ffi` to run real (file-backed) sqflite in a VM test instead of on a device |

## Setup instructions

Requires the latest stable Flutter SDK (built and tested against Flutter
3.47.2 / Dart 3.13.2).

```bash
flutter pub get
flutter run                    # debug, any connected device/emulator
flutter build apk --release    # release APK, output under build/app/outputs/flutter-apk/
```

No signing, API keys, or environment setup is required — there's no
backend. The release APK is signed with the debug keystore (the
`TODO: Add your own signing config` in `android/app/build.gradle.kts` was
left as-is; a real release config wasn't in scope for a take-home). Camera
and photo library usage strings are already declared in both the Android
manifest and iOS `Info.plist`, and `permission_handler` prompts at the
point of use (tapping Camera/Gallery in the native options sheet), so no
manual permission setup is needed to try those flows.

## Known limitations

- **iOS is written but not locally build-tested.** The dev machine is
  Windows, so `ios/Runner/AppDelegate.swift` implements the same Method
  Channel contract as the Android side (date picker, options sheet,
  device info) but has never been run on a simulator or device. This is a
  real constraint of the setup, not a shortcut — worth being upfront
  about rather than claiming iOS parity I couldn't verify.
- **Weather is a mock.** No backend was provided; the Weather card shows a
  small hardcoded/cycled dataset, labeled "Mock data, not a live forecast"
  in the UI so it's not mistaken for a real API call.
- **Sync is simulated.** "Reaching the server" is a `Future.delayed` in
  the sync queue drain, not an actual network request — there's no server
  to call.
- **Voice recording (optional in the spec) was cut.** The four mandatory
  notes features (CRUD, checklist, images, archive) plus getting the
  dashboard/search/offline/native modules solid filled the time budget;
  this was the one optional item I chose to drop rather than ship
  half-finished.
- **Dashboard stats refresh on tab reselect, not on every keystroke.**
  Because the bottom nav keeps each tab's widget tree alive
  (`StatefulShellRoute.indexedStack`), the dashboard's Notes/Today's Tasks
  counts refresh when you switch back to the Dashboard tab, not the
  instant a note changes on another tab in the background. This was
  actually a real bug I caught doing the release-build smoke test for
  this module (the counts weren't refreshing *at all* before the fix) —
  see the commit that wires `DashboardStarted` into
  `AppShell.onDestinationSelected`.
- **PDF attachments preview only, no "open."** Opening a locally-picked
  file on Android needs a `FileProvider` content URI (or another
  dependency) — more than a preview card justifies for this scope.
- **Reminder notifications fire at a fixed 9am**, not a user-chosen time —
  the native date picker (Module 6) is date-only, and a second native time
  picker for a bonus-tier feature wasn't worth adding.
- **Cell tower location (the bonus "most important" item) wasn't
  attempted.** It needed `TelephonyManager` plus
  `ACCESS_FINE_LOCATION`/`READ_PHONE_STATE` and varies a lot by OEM; it
  was explicitly lower priority than getting the four mandatory Method
  Channel features solid, and time ran out before it became a stretch
  item worth doing properly.

## Future improvements

- A real push-based refresh for dashboard stats (listen for note-repository
  changes directly) instead of refresh-on-tab-select, if the dashboard
  ever needs to reflect changes made from somewhere other than the Notes
  tab.
- Swap the mock weather/sync for real endpoints if a backend is ever
  provided — the repository interfaces are already the seam for that; no
  UI code would need to change.
- Actual iOS device/simulator verification once there's access to a Mac.
- A `FileProvider`-backed "open" action for PDF attachments.
- Proper release signing config instead of debug-key signing, before any
  real distribution.
- Cell tower location as a genuine Android-only bonus feature, tested
  across a couple of OEMs rather than just the emulator.

## Assumptions

The full list of judgment calls made along the way — how "Today's Tasks"
is defined, dashboard breakpoints, why notes use an explicit Save instead
of autosave, and so on — is in `docs/assumptions-log.md` locally (that
folder is git-ignored, since it's working notes rather than submission
content). The ones with real user-facing or architectural weight are
folded into this README already; the rest were smaller open-ended calls
the spec left to interpretation.
