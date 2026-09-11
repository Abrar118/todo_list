# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Nudge — a local-first Flutter task manager for **Android and iOS only** (web/desktop platform dirs were deliberately removed; don't recreate them). No backend, no accounts, no analytics. Package name is still `todo_list` (`com.example.todo_list`); the product name is Nudge.

## Commands

```sh
flutter test                          # full suite
flutter test test/recurrence_engine_test.dart   # single file
flutter analyze                       # must stay at "No issues found"
dart format lib test                  # formatter (CI-style check: --set-exit-if-changed)
flutter build apk --debug             # Android build check (also compiles the Kotlin widget code)
```

iOS builds require Xcode (not present on this machine historically — verify before promising iOS verification).

Dependency constraints are delicate: `flutter_quill` requires `intl 0.20.2` and `share_plus ^12` (v13 conflicts via `win32`). Don't bulk-upgrade without re-resolving this triangle.

## Architecture

Layers (dependencies point downward only):

- `lib/domain/` — pure Dart, no Flutter/plugin imports. Models plus all date/recurrence/notification/ordering logic. Everything here is unit-testable without mocks and most of the spec's tricky behavior lives here.
- `lib/data/` — sqflite repository (`TaskRepository` interface), settings on shared_preferences, JSON backup codec. Tasks are stored as one row per task with the full state in a JSON `payload` column; `Task.toJson/fromJson` is the single serialization path shared with import/export.
- `lib/services/` — platform boundaries behind interfaces (`NotificationService`, `HomeWidgetService`) so implementations can be swapped (and are faked in tests: `test/helpers/fakes.dart`).
- `lib/state/` — `AppState` (single ChangeNotifier owning the task list and coordinating persistence + notification/widget sync) and `SettingsController`.
- `lib/ui/` — screens/widgets; no business logic.

### Key invariants (break these and tests will catch you)

**Dates are calendar dates, not instants.** Deadlines are stored as `DateOnly` (y/m/d) plus optional `dueMinutes` (minutes-of-day). All recurrence math operates on calendar dates, which makes it immune to DST and timezone changes; conversion to an instant happens only at the edges (notification scheduling, overdue checks) via the device's current local zone.

**Recurring tasks materialize one active occurrence at a time.** Three `TaskKind`s: `single`, `seriesTemplate` (holds the `RecurrenceRule`; never rendered as a task), `occurrence` (points at its template via `seriesId`). Completing/deleting the active occurrence generates the next one; future occurrences shown on the calendar are *projections* computed on the fly (`AgendaItem.isProjection`), not rows. This is what prevents a neglected daily task from piling up hundreds of overdue rows. Series edit scopes: "this occurrence" edits the row, "this and future" propagates to the template, rule changes go through `AppState.updateSeriesRule` (which also converts single↔series).

**Completion/snooze/defer logic lives in `TaskMutations` only.** It is shared by `AppState` and `lib/services/headless_actions.dart` — the single DB-bootstrapping path for background isolates, used by both notification actions (`background_action_handler.dart`) and widget complete-buttons (`widget_action_handler.dart`, registered via `HomeWidget.registerInteractivityCallback`). Never reimplement completion behavior in any caller. `AppState.onAppResumed` reloads tasks from storage because those isolates may have mutated the DB while the app was paused.

**Escalation is derived, not stored (except the counter).** `Task.deferralCount` is incremented by snooze/defer and starts at 0 on each new materialized occurrence; `Escalation.score` (deferrals + days overdue) and its levels are computed at read time. Escalation lifts spotlight tiers in `FocusArranger`, adds daily "still waiting" nudges in `NotificationPlanner` (only for overdue tasks that have reminders and no alarm), and shows a row chip.

**The focus timer derives time from wall clocks, not ticks.** `FocusTimerController` stores `endsAt`; the 1s ticker only repaints, so backgrounding never skews the countdown. Its session-end alert uses the reserved OS id `LocalNotificationService.timerAlertId`, which `syncPlan` explicitly spares — without that, any task mutation would silently cancel the running timer's alert. Time credits go through `AppState.addTimeSpent`.

**Calendar integration is one-way by design.** `IcsCodec` (pure, tested) exports open deadline tasks; `addTaskToDeviceCalendar` uses the system intent via add_2_calendar (no permissions). No RRULEs are exported — the app owns recurrence; exporting rules would fork the series. Don't add device-calendar read/sync without revisiting the local-first decision.

**Colors are theme-resolved, never static.** `AppColors` is a `ThemeExtension` with `dark`/`light` palettes; always use `context.colors.x` (and `priorityColor(context, p)`), never a hardcoded palette constant, or the light theme breaks. The theme choice is `AppSettings.themeMode` (default dark).

**Notification scheduling is a full-plan sync, never incremental.** `NotificationPlanner` (pure) computes the entire desired set (capped at 56 for the iOS 64-pending limit, alarms planned ~24h ahead); `LocalNotificationService.syncPlan` cancels all *pending* schedules and reschedules, while *displayed* notifications are dismissed only for tasks no longer in `keepDisplayedForTaskIds` (completed/deleted/snoozed). This idempotence is the duplicate-prevention strategy — every mutation just calls `AppState.resyncNotifications()`.

**Home-screen widgets have a cross-language data contract.** `WidgetSnapshot` (pure, reuses `FocusArranger` so widgets always match the Focus screen) writes JSON under keys `widget_up_next` / `widget_focus`; Kotlin (`android/.../WidgetData.kt`) and Swift (`ios/NudgeWidgets/`) parse it and compute relative labels at render time. Keys, provider class names (`UpNextWidgetProvider`, `FocusListWidgetProvider`), iOS kinds (`NudgeUpNextWidget`, `NudgeFocusWidget`), deep-link URIs (`nudge://task/<id>`, `nudge://quickadd`, `nudge://complete/<id>`), and the App Group id must stay in sync across all three languages. The Android focus-list widget builds rows statically (no ListView) on purpose: a collection widget has a single PendingIntent template, which can't mix open-activity row taps with background-broadcast complete buttons. The iOS widget extension target must be created in Xcode (steps in `ios/NudgeWidgets/README.md`); the complete button is Android-only.

### Behavioral rules from the spec (do not regress)

- Notification permission is requested only when the user enables their first reminder/alarm — never at launch — and always preceded by the in-app explanation dialog (`ensureNotificationPermission` in `lib/ui/widgets/task_flows.dart`).
- Sample tasks are seeded once; the first-launch flag survives "Delete all local data" so deleted samples never return.
- Overdue tasks stay on their original date (Calendar) and surface on Focus; never silently move them to today.
- Never claim a notification was scheduled when it failed — `ScheduleResult` and the Settings "Exact delivery unavailable" row exist for this.
- Task editor autosaves (debounced 500ms); Done additionally prompts for series scope on recurring occurrences.

### Testing notes

- sqflite tests run on the host via `sqflite_common_ffi` (`test/persistence_test.dart`).
- Widget tests build `NudgeApp` directly with the in-memory fakes — platform channels are never touched (`HomeWidgetService`/plugins no-op off Android/iOS).
- When adding domain behavior, put the logic in `lib/domain/logic/` and test it there; UI tests only cover flows.
