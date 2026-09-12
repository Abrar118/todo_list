import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/domain/logic/notification_planner.dart';
import 'package:todo_list/domain/logic/quiet_hours.dart';
import 'package:todo_list/domain/models/date_only.dart';
import 'package:todo_list/domain/models/notification_tone.dart';
import 'package:todo_list/domain/models/priority.dart';
import 'package:todo_list/domain/models/reminders.dart';
import 'package:todo_list/domain/models/task.dart';

Task makeTask({
  String id = 't1',
  DateOnly? due,
  int? dueMinutes,
  List<ReminderEntry> reminders = const [],
  AlarmConfig alarm = const AlarmConfig(),
  DateTime? snoozedUntil,
  bool completed = false,
  TaskKind kind = TaskKind.single,
  TaskPriority priority = TaskPriority.none,
  TaskBackground background = TaskBackground.automatic,
}) {
  final now = DateTime(2026, 7, 11, 8);
  return Task(
    id: id,
    kind: kind,
    title: 'Task $id',
    priority: priority,
    background: background,
    dueDate: due,
    dueMinutes: dueMinutes,
    reminders: reminders,
    alarm: alarm,
    snoozedUntil: snoozedUntil,
    isCompleted: completed,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  const planner = NotificationPlanner();
  final now = DateTime(2026, 7, 11, 8, 0);

  test('at-deadline and before-deadline reminders', () {
    final task = makeTask(
      due: const DateOnly(2026, 7, 11),
      dueMinutes: 15 * 60,
      reminders: const [ReminderEntry.atDeadline(), ReminderEntry.before(60)],
    );
    final plan = planner.plan([task], now);
    expect(plan.map((p) => p.fireAt), [
      DateTime(2026, 7, 11, 14, 0),
      DateTime(2026, 7, 11, 15, 0),
    ]);
    expect(plan.every((p) => p.kind == PlannedKind.reminder), isTrue);
  });

  test('date-only task uses the default reminder time of day', () {
    const p = NotificationPlanner(dateOnlyReminderMinutes: 10 * 60);
    final task = makeTask(
      due: const DateOnly(2026, 7, 12),
      reminders: const [ReminderEntry.atDeadline()],
    );
    final plan = p.plan([task], now);
    expect(plan.single.fireAt, DateTime(2026, 7, 12, 10, 0));
  });

  test('custom reminder time is used verbatim', () {
    final task = makeTask(
      due: const DateOnly(2026, 7, 20),
      dueMinutes: 9 * 60,
      reminders: [ReminderEntry.custom(DateTime(2026, 7, 15, 12, 30))],
    );
    final plan = planner.plan([task], now);
    expect(plan.single.fireAt, DateTime(2026, 7, 15, 12, 30));
  });

  test('past reminders are not scheduled', () {
    final task = makeTask(
      due: const DateOnly(2026, 7, 11),
      dueMinutes: 7 * 60, // already past at 08:00
      reminders: const [ReminderEntry.atDeadline()],
    );
    expect(planner.plan([task], now), isEmpty);
  });

  test('completed tasks and templates produce nothing', () {
    final done = makeTask(
      id: 'done',
      due: const DateOnly(2026, 7, 12),
      dueMinutes: 9 * 60,
      reminders: const [ReminderEntry.atDeadline()],
      completed: true,
    );
    final template = makeTask(
      id: 'tmpl',
      kind: TaskKind.seriesTemplate,
      due: const DateOnly(2026, 7, 12),
      dueMinutes: 9 * 60,
      reminders: const [ReminderEntry.atDeadline()],
    );
    expect(planner.plan([done, template], now), isEmpty);
  });

  test('snooze replaces reminders due before it and adds a snooze fire', () {
    final task = makeTask(
      due: const DateOnly(2026, 7, 11),
      dueMinutes: 9 * 60,
      reminders: const [ReminderEntry.atDeadline()],
      snoozedUntil: DateTime(2026, 7, 11, 9, 30),
    );
    final plan = planner.plan([task], now);
    expect(plan.single.kind, PlannedKind.snooze);
    expect(plan.single.fireAt, DateTime(2026, 7, 11, 9, 30));
  });

  test('quiet hours shift reminder delivery', () {
    const p = NotificationPlanner(quietHours: QuietHours(enabled: true));
    final task = makeTask(
      due: const DateOnly(2026, 7, 11),
      dueMinutes: 23 * 60 + 30,
      reminders: const [ReminderEntry.atDeadline()],
    );
    final plan = p.plan([task], now);
    expect(plan.single.fireAt, DateTime(2026, 7, 12, 7, 0));
  });

  test('persistent alarm repeats on cadence from the deadline', () {
    final task = makeTask(
      due: const DateOnly(2026, 7, 11),
      dueMinutes: 9 * 60,
      alarm: const AlarmConfig(enabled: true, cadenceMinutes: 60),
    );
    final plan = planner.plan([task], now);
    final alarms = plan.where((p) => p.kind == PlannedKind.alarm).toList();
    expect(alarms.length, NotificationPlanner.maxAlarmsPerTask);
    expect(alarms.first.fireAt, DateTime(2026, 7, 11, 9, 0));
    expect(alarms[1].fireAt, DateTime(2026, 7, 11, 10, 0));
  });

  test('overdue alarm resumes on cadence instead of dumping a backlog', () {
    final task = makeTask(
      due: const DateOnly(2026, 7, 10),
      dueMinutes: 9 * 60, // 23 hours overdue
      alarm: const AlarmConfig(enabled: true, cadenceMinutes: 360),
    );
    final plan = planner.plan([task], now);
    expect(plan, isNotEmpty);
    expect(plan.every((p) => p.fireAt.isAfter(now)), isTrue);
  });

  test('alarm respects its daily stop window', () {
    final task = makeTask(
      due: const DateOnly(2026, 7, 11),
      dueMinutes: 9 * 60,
      alarm: const AlarmConfig(
        enabled: true,
        cadenceMinutes: 60,
        startMinutesOfDay: 9 * 60,
        stopMinutesOfDay: 12 * 60,
      ),
    );
    final plan = planner.plan([task], now);
    expect(plan, isNotEmpty);
    for (final p in plan) {
      final m = p.fireAt.hour * 60 + p.fireAt.minute;
      expect(m, inInclusiveRange(9 * 60, 12 * 60 - 1));
    }
  });

  test('alarm skips quiet hours unless explicitly allowed', () {
    const quiet = QuietHours(enabled: true); // 23:00-07:00
    const p = NotificationPlanner(quietHours: quiet);
    final blocked = makeTask(
      id: 'blocked',
      due: const DateOnly(2026, 7, 11),
      dueMinutes: 22 * 60,
      alarm: const AlarmConfig(enabled: true, cadenceMinutes: 120),
    );
    final allowed = makeTask(
      id: 'allowed',
      due: const DateOnly(2026, 7, 11),
      dueMinutes: 22 * 60,
      alarm: const AlarmConfig(
        enabled: true,
        cadenceMinutes: 120,
        allowInQuietHours: true,
      ),
    );
    final blockedPlan = p.plan([blocked], now);
    expect(blockedPlan.every((n) => !quiet.contains(n.fireAt)), isTrue);
    final allowedPlan = p.plan([allowed], now);
    expect(allowedPlan.any((n) => quiet.contains(n.fireAt)), isTrue);
  });

  test('global cap keeps the earliest notifications', () {
    final tasks = [
      for (var i = 0; i < 10; i++)
        makeTask(
          id: 'task$i',
          due: const DateOnly(2026, 7, 11),
          dueMinutes: 9 * 60,
          alarm: const AlarmConfig(enabled: true, cadenceMinutes: 15),
        ),
    ];
    final plan = planner.plan(tasks, now);
    expect(plan.length, NotificationPlanner.maxScheduled);
    for (var i = 1; i < plan.length; i++) {
      expect(plan[i].fireAt.isBefore(plan[i - 1].fireAt), isFalse);
    }
  });

  test('stable ids are deterministic and distinct per slot', () {
    final t = DateTime(2026, 7, 11, 9);
    final a = NotificationPlanner.stableId('abc', PlannedKind.reminder, t);
    final b = NotificationPlanner.stableId('abc', PlannedKind.reminder, t);
    final c = NotificationPlanner.stableId('abc', PlannedKind.alarm, t);
    final d = NotificationPlanner.stableId('xyz', PlannedKind.reminder, t);
    expect(a, b);
    expect(a, isNot(c));
    expect(a, isNot(d));
  });

  test('custom task background colors its planned notification', () {
    final task = makeTask(
      due: const DateOnly(2026, 7, 12),
      reminders: const [ReminderEntry.atDeadline()],
      background: TaskBackground.cyan,
    );

    expect(planner.plan([task], now).single.tone, NotificationTone.cyan);
  });

  test('automatic task background follows priority notification tone', () {
    final task = makeTask(
      due: const DateOnly(2026, 7, 12),
      reminders: const [ReminderEntry.atDeadline()],
      priority: TaskPriority.high,
    );

    expect(planner.plan([task], now).single.tone, NotificationTone.coral);
  });
}
