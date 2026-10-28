# AGENTS.md

Guidance for coding agents (Claude Code, Codex, and friends) working in this
repository. `CLAUDE.md` just points here — keep this file as the single source.

## Project

Nudge — a local-first Flutter task manager for **Android and iOS only**
(web/desktop platform dirs were deliberately removed; don't recreate them).
No backend, no accounts, no analytics. Package name is still `todo_list`
(`com.example.todo_list`); the product name is Nudge.

## Commands

```sh
flutter test                          # full suite
flutter test test/recurrence_engine_test.dart   # single file
flutter analyze                       # must stay at "No issues found"
dart format lib test                  # formatter (CI-style check: --set-exit-if-changed)
flutter build apk --debug             # Android build check (also compiles the Kotlin widget code)
```

### Verification reality (read before promising anything)

- Dev machine is **Windows**. `flutter test`, `flutter analyze`,
  `dart format` and `flutter build apk` are the only checks runnable here.
- **iOS cannot be built from this machine** (needs macOS + Xcode), but the
  user has Mac access, so iOS changes do get a real compile check — write
  them, then ask the user to run `flutter build ios` / open Xcode and report
  errors back. Until they do, treat Swift and `.pbxproj` edits as unverified
  and say so.
- The user's phone is an **iPhone 17 (base model)**; there is no longer an
  Android device on hand (previously a Galaxy S25). So nothing Android-only is
  user-testable right now — don't ask the user to confirm Android behaviour on
  a device. The iOS widget extension target still has to be created in Xcode
  (`ios/NudgeWidgets/README.md`) before iOS widgets work at all; it is
  deliberately not hand-written into `project.pbxproj`.
- Dart analysis excludes `android/**` and `ios/**` (`analysis_options.yaml`),
  so native mistakes surface only at build time.

### Dependencies

`flutter_quill` historically pinned `intl` and blocked `share_plus` 13 (via
`win32`). That triangle has since resolved: the lockfile is now
`flutter_quill 11.5.1` + `intl 0.20.3` + `share_plus 13.3.0`. It is still the
fragile corner of the graph — re-resolve deliberately, don't bulk-upgrade.

## Architecture

Layers (dependencies point downward only):

- `lib/core/` — theme, colors, date/duration formatting.
- `lib/domain/` — pure Dart, no Flutter/plugin imports. Models plus all
  date/recurrence/notification/ordering logic. Everything here is
  unit-testable without mocks and most of the spec's tricky behavior lives here.
- `lib/data/` — sqflite repository for tasks (`TaskRepository` interface),
  shared_preferences for settings, habits (`nudge.habits.v1`) and goals
  (`nudge.goals.v1`), plus the JSON backup codec. Tasks are stored as one row
  per task with the full state in a JSON `payload` column; `Task.toJson/fromJson`
  is the single serialization path shared with import/export.
- `lib/services/` — platform boundaries behind interfaces
  (`NotificationService`, `HabitReminderService`, `HomeWidgetService`) so
  implementations can be swapped (and are faked in tests:
  `test/helpers/fakes.dart`).
- `lib/state/` — `AppState` (single ChangeNotifier owning the task list and
  coordinating persistence + notification/widget sync), `SettingsController`,
  `HabitController`, `GoalController`, `FocusTimerController`. All provided
  from `main.dart` via `provider`.
- `lib/ui/` — screens/widgets; no business logic.

### Key invariants (break these and tests will catch you)

**Dates are calendar dates, not instants.** Deadlines are stored as `DateOnly`
(y/m/d) plus optional `dueMinutes` (minutes-of-day). All recurrence math
operates on calendar dates, which makes it immune to DST and timezone changes;
conversion to an instant happens only at the edges (notification scheduling,
overdue checks) via the device's current local zone.

**Recurring tasks materialize one active occurrence at a time.** Three
`TaskKind`s: `single`, `seriesTemplate` (holds the `RecurrenceRule`; never
rendered as a task), `occurrence` (points at its template via `seriesId`).
Completing/deleting the active occurrence generates the next one; future
occurrences shown on the calendar are *projections* computed on the fly
(`AgendaItem.isProjection`), not rows. This is what prevents a neglected daily
task from piling up hundreds of overdue rows. Series edit scopes: "this
occurrence" edits the row, "this and future" propagates to the template, rule
changes go through `AppState.updateSeriesRule` (which also converts
single↔series).

**Completion/snooze/defer logic lives in `TaskMutations` only.** It is shared
by `AppState` and `lib/services/headless_actions.dart` — the single
DB-bootstrapping path for background isolates, used by both notification
actions (`background_action_handler.dart`) and widget complete-buttons
(`widget_action_handler.dart`, registered via
`HomeWidget.registerInteractivityCallback`). Never reimplement completion
behavior in any caller. `AppState.onAppResumed` reloads tasks from storage
because those isolates may have mutated the DB while the app was paused.

**Escalation is derived, not stored (except the counter).**
`Task.deferralCount` is incremented by snooze/defer and starts at 0 on each new
materialized occurrence; `Escalation.score` (deferrals + days overdue) and its
levels are computed at read time. Escalation lifts spotlight tiers in
`FocusArranger`, adds daily "still waiting" nudges in `NotificationPlanner`
(only for overdue tasks that have reminders and no alarm), and shows a row chip.

**Notification scheduling is a full-plan sync, never incremental.**
`NotificationPlanner` (pure) computes the entire desired set (capped at
`maxScheduled = 56` for the iOS 64-pending limit, alarms planned ~24h ahead);
`LocalNotificationService.syncPlan` cancels all *pending* schedules and
reschedules, while *displayed* notifications are dismissed only for tasks no
longer in `keepDisplayedForTaskIds` (completed/deleted/snoozed). This
idempotence is the duplicate-prevention strategy — every mutation just calls
`AppState.resyncNotifications()`.

**Reserved notification ids survive the sync.** `syncPlan` explicitly spares
the focus timer's alert (`LocalNotificationService.timerAlertId`) and anything
in the habit-reminder id space (`HabitReminderPlanner.ownsId`, prefix
`0x60000000`, ids hashed stably from `habitId:slotId`). Without those
exemptions a task mutation would silently cancel a running timer's alert or
every habit reminder. New notification families need their own reserved range
and an exemption here.

**Quiet hours shift, never drop.** `QuietHours.adjust` pushes a reminder to the
end of the window (handling midnight-crossing ranges) rather than cancelling
it, so nothing is lost silently.

**The focus timer derives time from wall clocks, not ticks.**
`FocusTimerController` stores `endsAt`; the 1s ticker only repaints, so
backgrounding never skews the countdown. Time credits go through
`AppState.addTimeSpent`.

**Habits and goals are separate subsystems, stored outside the DB.**
`HabitController`/`GoalController` persist whole lists as JSON in
shared_preferences, independent of `AppState` and the sqflite DB. Habits carry
`HabitType` (`checkIn`/`timer`), `HabitCadence` (`daily`/`monthly`),
checkpoints with their own completed-date sets, tracked seconds per date, and a
derived `currentStreak`; toggling the last checkpoint for a date marks the
whole day done. Goal `progress` comes from checkpoints when any exist,
otherwise `manualProgress` (0–100). Note: the JSON backup (`TaskJsonCodec`,
`app: nudge`, `version: 1`) covers **tasks only** — habits and goals are not
exported. "Delete all local data" does clear all three.

**Calendar integration is one-way by design.** `IcsCodec` (pure, tested)
exports open deadline tasks; `addTaskToDeviceCalendar` uses the system intent
via add_2_calendar (no permissions). No RRULEs are exported — the app owns
recurrence; exporting rules would fork the series. Don't add device-calendar
read/sync without revisiting the local-first decision.

**Colors are theme-resolved, never static.** `AppColors` is a `ThemeExtension`
with `dark`/`light` palettes; always use `context.colors.x` (and
`priorityColor(context, p)`), never a hardcoded palette constant, or the light
theme breaks. Tasks, habits and goals share one user-pickable identity enum,
`Swatch` (`lib/domain/models/swatch.dart`), whose declaration order is parallel
to `AppColors.decorative` — a swatch resolves by index via
`swatchColor(colors, s)`, so the enum and both palettes must be reordered
together (`test/swatch_test.dart` pins their lengths). All three editors use the
one `SwatchPicker`. A task's `background` is `Swatch?`, where null means
automatic (priority-derived). The per-subsystem legacy name maps in
`swatch.dart` exist because the old enums collided — `violet` rendered sage on a
habit but lilac on a goal — so don't merge them. New swatches need a hex in both
palettes (contrast- and saturation-checked by `test/design_tokens_test.dart`),
a `NotificationTone.forSwatch` group and a motif group in `task_row.dart`; both
switches are exhaustive so the compiler will say so. The theme choice is `AppSettings.themeMode` (default dark).
`AppSettings.reduceMotion` is honored app-wide in `main.dart` by reporting
`disableAnimations` through `MediaQuery`.

**Home-screen widgets have a cross-language data contract.** `WidgetSnapshot`
(pure, reuses `FocusArranger` so widgets always match the Focus screen) writes
JSON under keys `widget_up_next` / `widget_focus`; Kotlin
(`android/.../WidgetData.kt`) and Swift (`ios/NudgeWidgets/`) parse it and
compute relative labels at render time. Keys, provider class names
(`UpNextWidgetProvider`, `FocusListWidgetProvider`), iOS kinds
(`NudgeUpNextWidget`, `NudgeFocusWidget`), deep-link URIs (`nudge://task/<id>`,
`nudge://quickadd`, `nudge://focus`, `nudge://complete/<id>`), and the App Group
id (`group.com.example.todoList`) must stay in sync across all three languages.
Deep links are parsed by `WidgetDeepLink` (pure, tested) — route new ones
there, not in the service.
The Android focus-list widget builds rows statically (no ListView) on purpose: a
collection widget has a single PendingIntent template, which can't mix
open-activity row taps with background-broadcast complete buttons. The complete
button is Android-only.

**iOS needs four things Android doesn't, and fails silently without them.**
Each is already in the repo; don't drop them when touching the iOS target.

1. `Runner/Info.plist` registers the `nudge` scheme under `CFBundleURLTypes`.
   Android gets the URI straight off the launch intent; on iOS an
   unregistered scheme never reaches the app.
2. Widget links must carry a `homeWidget` query item — the plugin's iOS
   `isWidgetUrl` drops anything else. `NudgeWidgets.swift` builds every link
   through its `deepLink(_:)` helper for this reason; `WidgetDeepLink` ignores
   the marker so both platforms route identically.
3. `Runner/Runner.entitlements` (wired via `CODE_SIGN_ENTITLEMENTS` in all
   three Runner configs) declares the App Group — without it the widget
   extension reads an empty container — and
   `com.apple.developer.usernotifications.time-sensitive`, without which iOS
   quietly downgrades alarm notifications from `.timeSensitive` to `.active`.
4. `IPHONEOS_DEPLOYMENT_TARGET` is **15.0**: `home_widget` requires ≥14 and
   `InterruptionLevel.timeSensitive` requires ≥15. It also matches the
   Flutter 3.47 Podfile template. The widget extension target itself needs
   iOS 17 for `containerBackground`.

### Behavioral rules from the spec (do not regress)

- Notification permission is requested only when the user enables their first
  reminder/alarm/habit schedule — never at launch — and always preceded by the
  in-app explanation dialog (`ensureNotificationPermission` in
  `lib/ui/widgets/task_flows.dart`).
- Sample tasks are seeded once; the first-launch flag is written *before*
  seeding and survives "Delete all local data", so deleted samples never return.
- Overdue tasks stay on their original date (Calendar) and surface on Focus;
  never silently move them to today.
- Never claim a notification was scheduled when it failed — `ScheduleResult`
  and the Settings "Exact delivery unavailable" row exist for this.
- Task editor autosaves (debounced 500ms); Done additionally prompts for series
  scope on recurring occurrences.
- Quick add parses natural-language deadlines and `#tags`
  (`QuickAddParser`); search spans titles, rich-text details, subtasks and tags
  including completed history (`TaskSearch`). Both are pure and tested — extend
  them there, not in the UI.

### Testing notes

- sqflite tests run on the host via `sqflite_common_ffi`
  (`test/persistence_test.dart`).
- Widget tests build `NudgeApp` directly with the in-memory fakes — platform
  channels are never touched (`HomeWidgetService`/plugins no-op off
  Android/iOS).
- When adding domain behavior, put the logic in `lib/domain/logic/` and test it
  there; UI tests only cover flows.
