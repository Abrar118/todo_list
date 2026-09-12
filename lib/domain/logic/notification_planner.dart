import '../models/date_only.dart';
import '../models/notification_tone.dart';
import '../models/priority.dart';
import '../models/task.dart';
import 'escalation.dart';
import 'quiet_hours.dart';

enum PlannedKind { reminder, alarm, snooze }

/// One notification the app intends to have scheduled with the OS.
class PlannedNotification {
  final int id;
  final String taskId;
  final DateTime fireAt;
  final PlannedKind kind;
  final String title;
  final String body;
  final bool sound;
  final bool vibration;
  final NotificationTone tone;

  const PlannedNotification({
    required this.id,
    required this.taskId,
    required this.fireAt,
    required this.kind,
    required this.title,
    required this.body,
    this.sound = true,
    this.vibration = true,
    this.tone = NotificationTone.lime,
  });
}

/// Computes the full set of notifications that should currently be scheduled.
///
/// The scheduler syncs by cancelling everything and re-scheduling this plan,
/// which is idempotent: it can never produce duplicates, and obsolete
/// notifications (completed/deleted tasks, changed deadlines) disappear
/// because they are simply no longer in the plan.
///
/// Pure Dart — injected [now] makes every rule unit-testable.
class NotificationPlanner {
  /// iOS silently drops requests beyond 64 pending notifications; stay under
  /// it and rely on re-syncs (app open/resume, notification actions) to roll
  /// the window forward.
  static const int maxScheduled = 56;

  /// Persistent alarms are planned this far ahead per task; re-syncs extend
  /// the series.
  static const Duration alarmWindow = Duration(hours: 24);
  static const int maxAlarmsPerTask = 16;

  /// Escalated overdue tasks get one extra nudge per day for this many days.
  static const int escalationNudgeDays = 3;

  final QuietHours quietHours;
  final int dateOnlyReminderMinutes;

  const NotificationPlanner({
    this.quietHours = const QuietHours(),
    this.dateOnlyReminderMinutes = 9 * 60,
  });

  List<PlannedNotification> plan(List<Task> tasks, DateTime now) {
    final planned = <PlannedNotification>[];
    for (final task in tasks) {
      if (task.isCompleted || task.kind == TaskKind.seriesTemplate) continue;
      planned.addAll(_planForTask(task, now));
    }
    planned.sort((a, b) => a.fireAt.compareTo(b.fireAt));
    if (planned.length > maxScheduled) {
      planned.removeRange(maxScheduled, planned.length);
    }
    return planned;
  }

  List<PlannedNotification> _planForTask(Task task, DateTime now) {
    final result = <PlannedNotification>[];
    final due = task.dueInstant(dateOnlyMinutes: dateOnlyReminderMinutes);
    final snoozedUntil = task.snoozedUntil;
    final snoozeActive = snoozedUntil != null && snoozedUntil.isAfter(now);

    // Snoozed: one notification when the snooze elapses replaces anything
    // that would have fired during the snooze window.
    if (snoozeActive) {
      result.add(
        _make(
          task,
          snoozedUntil,
          PlannedKind.snooze,
          body: _deadlineBody(task, due),
        ),
      );
    }

    // Standard reminders.
    if (due != null) {
      for (final entry in task.reminders) {
        final at = entry.isCustom
            ? entry.customTime!
            : due.subtract(Duration(minutes: entry.offsetMinutes!));
        final adjusted = quietHours.adjust(at);
        if (!adjusted.isAfter(now)) continue;
        if (snoozeActive && !adjusted.isAfter(snoozedUntil)) continue;
        result.add(
          _make(
            task,
            adjusted,
            PlannedKind.reminder,
            body: _deadlineBody(task, due),
          ),
        );
      }
    }

    // Escalation: a task that keeps being put off has burned through its
    // one-shot reminders, so it would go silent exactly when it most needs
    // nagging. Re-nag once a day at the deadline's time-of-day. Only for
    // tasks the user asked to be reminded about; alarms already re-fire on
    // their own cadence.
    if (due != null &&
        !snoozeActive &&
        task.hasReminders &&
        !task.alarm.enabled &&
        task.isOverdue(now) &&
        Escalation.level(task, now) >= 1) {
      final minutes = task.dueMinutes ?? dateOnlyReminderMinutes;
      final today = DateOnly.fromDateTime(now);
      for (var day = 0; day < escalationNudgeDays; day++) {
        final at = quietHours.adjust(today.addDays(day).atMinutes(minutes));
        if (!at.isAfter(now)) continue;
        result.add(
          _make(
            task,
            at,
            PlannedKind.reminder,
            body: 'Still waiting: ${_deadlineBody(task, due)}',
          ),
        );
      }
    }

    // Persistent alarm series: repeats every cadence from the deadline (or
    // the snooze end) until handled, bounded by the planning window.
    if (task.alarm.enabled && due != null) {
      var t = snoozeActive ? snoozedUntil : due;
      final horizon = now.add(alarmWindow);
      var count = 0;
      // Walk forward in cadence steps; skip past fires so a long-overdue task
      // resumes on its cadence instead of dumping a backlog.
      while (count < maxAlarmsPerTask && !t.isAfter(horizon)) {
        if (t.isAfter(now)) {
          final adjusted = _adjustAlarmTime(task, t);
          if (adjusted != null) {
            result.add(
              _make(
                task,
                adjusted,
                PlannedKind.alarm,
                body: 'Still waiting: ${_deadlineBody(task, due)}',
                sound: task.alarm.soundEnabled,
                vibration: task.alarm.vibrationEnabled,
              ),
            );
            count++;
          }
        }
        t = t.add(Duration(minutes: task.alarm.cadenceMinutes));
      }
    }

    // Dedup identical fire times (e.g. reminder + alarm at the deadline).
    final seen = <int>{};
    result.retainWhere((n) => seen.add(n.id));
    return result;
  }

  /// Applies the alarm's optional daily window and quiet hours. Returns null
  /// when this slot should be skipped entirely (outside the daily window).
  DateTime? _adjustAlarmTime(Task task, DateTime t) {
    final alarm = task.alarm;
    final m = t.hour * 60 + t.minute;
    final start = alarm.startMinutesOfDay;
    final stop = alarm.stopMinutesOfDay;
    if (start != null && m < start) return null;
    if (stop != null && m >= stop) return null;
    if (!alarm.allowInQuietHours) {
      final adjusted = quietHours.adjust(t);
      // Skip slots inside quiet hours rather than bunching them at the end;
      // the first slot after quiet hours still fires on cadence.
      if (adjusted != t) return null;
    }
    return t;
  }

  String _deadlineBody(Task task, DateTime? due) {
    if (due == null) return task.title;
    if (task.dueMinutes == null) return 'Due today';
    final h = due.hour % 12 == 0 ? 12 : due.hour % 12;
    final ampm = due.hour < 12 ? 'AM' : 'PM';
    return 'Due at $h:${due.minute.toString().padLeft(2, '0')} $ampm';
  }

  PlannedNotification _make(
    Task task,
    DateTime at,
    PlannedKind kind, {
    required String body,
    bool sound = true,
    bool vibration = true,
  }) => PlannedNotification(
    id: stableId(task.id, kind, at),
    taskId: task.id,
    fireAt: at,
    kind: kind,
    title: task.title,
    body: body,
    sound: sound,
    vibration: vibration,
    tone: _toneForTask(task),
  );

  NotificationTone _toneForTask(Task task) => switch (task.background) {
    TaskBackground.lime => NotificationTone.lime,
    TaskBackground.cyan => NotificationTone.cyan,
    TaskBackground.sand => NotificationTone.sand,
    TaskBackground.coral => NotificationTone.coral,
    TaskBackground.automatic => switch (task.priority) {
      TaskPriority.high => NotificationTone.coral,
      TaskPriority.medium => NotificationTone.sand,
      TaskPriority.low => NotificationTone.cyan,
      TaskPriority.none => NotificationTone.lime,
    },
  };

  /// Deterministic 31-bit id from task, kind and fire time so the same
  /// logical notification always maps to the same OS identifier.
  static int stableId(String taskId, PlannedKind kind, DateTime at) {
    var h = 17;
    for (final c in taskId.codeUnits) {
      h = (h * 31 + c) % 0x50000000;
    }
    h = (h * 31 + kind.index) % 0x50000000;
    h = (h * 31 + at.millisecondsSinceEpoch ~/ 60000) % 0x50000000;
    return h;
  }
}
