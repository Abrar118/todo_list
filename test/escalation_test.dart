import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/domain/logic/escalation.dart';
import 'package:todo_list/domain/logic/focus_arranger.dart';
import 'package:todo_list/domain/logic/notification_planner.dart';
import 'package:todo_list/domain/models/date_only.dart';
import 'package:todo_list/domain/models/priority.dart';
import 'package:todo_list/domain/models/reminders.dart';
import 'package:todo_list/domain/models/task.dart';

Task make(
  String id, {
  DateOnly? due,
  int? dueMinutes,
  int deferrals = 0,
  TaskPriority priority = TaskPriority.none,
  List<ReminderEntry> reminders = const [],
  bool alarm = false,
  bool completed = false,
  TaskKind kind = TaskKind.single,
}) {
  final created = DateTime(2026, 7, 1);
  return Task(
    id: id,
    kind: kind,
    title: 'Task $id',
    priority: priority,
    dueDate: due,
    dueMinutes: dueMinutes,
    deferralCount: deferrals,
    reminders: reminders,
    alarm: AlarmConfig(enabled: alarm),
    isCompleted: completed,
    createdAt: created,
    updatedAt: created,
  );
}

void main() {
  final now = DateTime(2026, 7, 11, 12);
  const today = DateOnly(2026, 7, 11);

  group('score and level', () {
    test('counts deferrals plus full days overdue', () {
      expect(Escalation.score(make('a'), now), 0);
      expect(Escalation.score(make('a', deferrals: 2), now), 2);
      expect(Escalation.score(make('a', due: today.addDays(-4)), now), 4);
      expect(
        Escalation.score(make('a', deferrals: 3, due: today.addDays(-2)), now),
        5,
      );
    });

    test('same-day time-overdue adds no day score', () {
      final task = make('a', due: today, dueMinutes: 9 * 60);
      expect(Escalation.score(task, now), 0);
    });

    test('completed tasks and templates never escalate', () {
      expect(
        Escalation.score(
          make('a', deferrals: 9, due: today.addDays(-9), completed: true),
          now,
        ),
        0,
      );
      expect(
        Escalation.score(
          make('a', deferrals: 9, kind: TaskKind.seriesTemplate),
          now,
        ),
        0,
      );
    });

    test('levels at 3 and 6', () {
      expect(Escalation.level(make('a', deferrals: 2), now), 0);
      expect(Escalation.level(make('a', deferrals: 3), now), 1);
      expect(Escalation.level(make('a', deferrals: 6), now), 2);
    });

    test('describe reports deferrals, falls back to needs-attention', () {
      expect(Escalation.describe(make('a'), now), isNull);
      expect(Escalation.describe(make('a', deferrals: 1), now), isNull);
      expect(
        Escalation.describe(make('a', deferrals: 4), now),
        'Put off 4 times',
      );
      expect(
        Escalation.describe(make('a', due: today.addDays(-3)), now),
        'Needs attention',
      );
    });
  });

  group('focus arranger boost', () {
    const arranger = FocusArranger();

    test('critically escalated plain overdue task beats overdue-high', () {
      // Plain overdue is tier 2; six deferrals lift it to tier 0 where the
      // earlier deadline (or here: the escalated task's older date) wins.
      final sections = arranger.arrange([
        make('high', priority: TaskPriority.high, due: today.addDays(-1)),
        make('ignored', deferrals: 6, due: today.addDays(-2)),
      ], now);
      expect(sections.spotlight.first.id, 'ignored');
    });

    test('unescalated ordering is unchanged', () {
      final sections = arranger.arrange([
        make('plain', due: today.addDays(-2)),
        make('high', priority: TaskPriority.high, due: today.addDays(-1)),
      ], now);
      expect(sections.spotlight.first.id, 'high');
    });
  });

  group('planner escalation nudges', () {
    const planner = NotificationPlanner();

    test(
      'escalated overdue task with burned-off reminders gets daily nudges',
      () {
        final task = make(
          'a',
          due: today.addDays(-4),
          dueMinutes: 10 * 60,
          reminders: const [ReminderEntry.atDeadline()],
        );
        final plan = planner.plan([task], now);
        // The one-shot reminder is in the past; only nudges remain, one per
        // upcoming day at the deadline's time-of-day (today's 10:00 already
        // passed at noon).
        expect(plan, hasLength(2));
        expect(plan.every((p) => p.kind == PlannedKind.reminder), isTrue);
        expect(plan.every((p) => p.body.startsWith('Still waiting')), isTrue);
        expect(plan.first.fireAt, DateTime(2026, 7, 12, 10));
        expect(plan.last.fireAt, DateTime(2026, 7, 13, 10));
      },
    );

    test('no nudges without reminders, with an alarm, or when snoozed', () {
      expect(
        planner.plan([make('a', due: today.addDays(-4))], now),
        isEmpty,
        reason: 'user never asked to be reminded',
      );
      final alarmed = make(
        'a',
        due: today.addDays(-4),
        reminders: const [ReminderEntry.atDeadline()],
        alarm: true,
      );
      expect(
        planner
            .plan([alarmed], now)
            .where((p) => p.kind == PlannedKind.reminder),
        isEmpty,
        reason: 'alarms already re-fire on cadence',
      );
      final snoozed = make(
        'a',
        due: today.addDays(-4),
        reminders: const [ReminderEntry.atDeadline()],
      ).copyWith(snoozedUntil: now.add(const Duration(hours: 1)));
      expect(
        planner.plan([snoozed], now).where((p) => p.kind != PlannedKind.snooze),
        isEmpty,
        reason: 'the snooze wake-up replaces everything else',
      );
    });

    test('unescalated overdue task gets no nudges', () {
      final task = make(
        'a',
        due: today.addDays(-1),
        reminders: const [ReminderEntry.atDeadline()],
      );
      expect(planner.plan([task], now), isEmpty);
    });
  });
}
