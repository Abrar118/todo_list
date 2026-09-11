# Nudge

A minimal, local-first task manager for Android and iOS. The central promise:
**important tasks remain visible and continue reminding you until they are
handled.**

## Features

- **Focus screen** — priority spotlight (max 3), overdue, today, and a short
  upcoming preview. Swipe a row left to defer it ("not today") instead of
  letting it rot in the overdue pile.
- **Escalation** — tasks that keep being put off (snoozed, deferred, or left
  overdue) climb back into the spotlight, get a "Put off N times" marker, and
  regain a daily "still waiting" nudge after their one-shot reminders have
  fired.
- **Quick add** — title plus optional deadline in seconds; understands
  natural language ("call mom tomorrow 5pm", "report friday", "in 3 days");
  full editor one tap away.
- **Search** — full-text over titles, rich-text details, subtasks and tags,
  including completed history.
- **Tags** — `#tag` straight in quick add, tag suggestions in the editor, a
  filter bar on Focus.
- **Calendar export** — "Add to device calendar" on any task (system intent,
  no permissions) and a one-tap `.ics` export of open tasks for any calendar
  app. One-way by design; Nudge stays local-first.
- **Focus timer & progress** — a Pomodoro timer (configurable focus/break
  lengths) that credits time spent to the task and alerts session end even
  in the background; progress bars derived from subtasks, or a manual
  percentage for tasks without them.
- **Full task editor** — subtasks (reorder, collapse completed), recurrence,
  multiple reminders, opt-in persistent alarms, lightweight rich-text details,
  autosave with a saved-state indicator.
- **Recurring tasks** — fixed-schedule or repeat-after-completion, presets and
  custom rules (intervals, weekdays, day-of-month/last-day, end date or count).
  Only one active occurrence is materialized at a time; future occurrences are
  projected on the calendar.
- **Calendar** — compact month grid with subtle indicators plus a per-day
  agenda grouped into all-day / scheduled / completed.
- **Notifications** — standard reminders and opt-in persistent alarms with
  cadence, quiet hours, snooze, and Complete/Snooze notification actions.
  Permission is requested only when the first reminder is enabled.
- **Completed** — grouped by completion date, restore, permanent delete, clear.
- **Settings** — notification defaults, quiet hours, appearance, task
  defaults, JSON export/import, delete-all.
- **Home-screen widgets** — "Up next" (single most important task) and
  "Tasks" (Focus-style list with a quick-add button). Live-updating, with
  deep links into the app and a complete button per task that works without
  opening the app. Android is fully wired (pin from Settings → Appearance);
  the iOS WidgetKit extension is scaffolded in `ios/NudgeWidgets/` (see its
  README for the three Xcode setup steps; the complete button is
  Android-only for now).
- **Themes** — the black brand look (default), a paper light theme, or
  follow the system.

## Architecture

```
lib/
  core/        theme, colors, date formatting
  domain/
    models/    Task, Subtask, RecurrenceRule, ReminderEntry, AlarmConfig, DateOnly
    logic/     RecurrenceEngine, NotificationPlanner, FocusArranger,
               QuietHours, TaskMutations   (pure Dart, unit tested)
  data/        sqflite repository, settings (shared_preferences), JSON codec
  services/    NotificationService interface + flutter_local_notifications impl,
               background notification-action handler
  state/       AppState + SettingsController (provider / ChangeNotifier)
  ui/          screens and shared widgets
```

Deadlines are stored as calendar dates plus optional minutes-of-day, which
makes recurrence math immune to daylight-saving and time-zone changes.
Notification scheduling syncs by replacing the full plan (cancel all +
reschedule), so schedules can never duplicate or orphan.

## Development

```sh
flutter pub get
flutter test
flutter run          # on an Android or iOS device/simulator
```
