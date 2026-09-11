import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/domain/logic/recurrence_engine.dart';
import 'package:todo_list/domain/logic/task_mutations.dart';
import 'package:todo_list/domain/models/date_only.dart';
import 'package:todo_list/domain/models/recurrence.dart';
import 'package:todo_list/domain/models/subtask.dart';
import 'package:todo_list/domain/models/task.dart';

void main() {
  var counter = 0;
  final mutations = TaskMutations(
    engine: const RecurrenceEngine(),
    newId: () => 'gen-${counter++}',
  );
  final now = DateTime(2026, 7, 11, 12);

  setUp(() => counter = 0);

  Task template({RecurrenceRule? rule}) => Task(
    id: 'series',
    kind: TaskKind.seriesTemplate,
    title: 'Weekly review',
    recurrence: rule ?? RecurrenceRule.weekly(),
    dueDate: const DateOnly(2026, 7, 13),
    dueMinutes: 9 * 60,
    subtasks: [
      Subtask(id: 's1', title: 'Step 1', sortIndex: 0, createdAt: now),
      Subtask(id: 's2', title: 'Step 2', sortIndex: 1, createdAt: now),
    ],
    createdAt: now,
    updatedAt: now,
  );

  Task occurrence({int index = 1, DateOnly? date}) => Task(
    id: 'occ-$index',
    kind: TaskKind.occurrence,
    title: 'Weekly review',
    seriesId: 'series',
    dueDate: date ?? const DateOnly(2026, 7, 13),
    occurrenceDate: date ?? const DateOnly(2026, 7, 13),
    occurrenceIndex: index,
    dueMinutes: 9 * 60,
    subtasks: [
      Subtask(
        id: 'o-s1',
        title: 'Step 1',
        sortIndex: 0,
        createdAt: now,
        isCompleted: true,
        completedAt: now,
      ),
      Subtask(id: 'o-s2', title: 'Step 2', sortIndex: 1, createdAt: now),
    ],
    createdAt: now,
    updatedAt: now,
  );

  test('completing a plain task sets completion state and clears snooze', () {
    final task = Task(
      id: 't',
      title: 'One-off',
      snoozedUntil: now.add(const Duration(hours: 1)),
      createdAt: now,
      updatedAt: now,
    );
    final result = mutations.complete(task, all: [task], now: now);
    final completed = result.upserts.single;
    expect(completed.isCompleted, isTrue);
    expect(completed.completedAt, now);
    expect(completed.snoozedUntil, isNull);
  });

  test('completeSubtasks marks remaining subtasks complete', () {
    final occ = occurrence();
    final result = mutations.complete(
      occ,
      all: [template(), occ],
      now: now,
      completeSubtasks: true,
    );
    final completed = result.upserts.first;
    expect(completed.subtasks.every((s) => s.isCompleted), isTrue);
    // Pre-existing completion timestamps are preserved.
    expect(completed.subtasks.first.completedAt, now);
  });

  test('completing an occurrence materializes the next one', () {
    final occ = occurrence();
    final result = mutations.complete(occ, all: [template(), occ], now: now);
    expect(result.upserts.length, 2);
    final next = result.upserts[1];
    expect(next.kind, TaskKind.occurrence);
    expect(next.seriesId, 'series');
    expect(next.dueDate, const DateOnly(2026, 7, 20));
    expect(next.occurrenceIndex, 2);
    expect(next.dueMinutes, 9 * 60);
    expect(next.isCompleted, isFalse);
    // Subtasks copied from the template and reset.
    expect(next.subtasks.length, 2);
    expect(next.subtasks.every((s) => !s.isCompleted), isTrue);
    expect(next.subtasks.map((s) => s.title), ['Step 1', 'Step 2']);
  });

  test('repeat-after-completion counts from the completion date', () {
    final rule = RecurrenceRule.daily(
      interval: 3,
    ).copyWith(behavior: RecurrenceBehavior.afterCompletion);
    final tpl = template(rule: rule);
    final occ = occurrence(date: const DateOnly(2026, 7, 1)); // long overdue
    final result = mutations.complete(occ, all: [tpl, occ], now: now);
    expect(result.upserts[1].dueDate, const DateOnly(2026, 7, 14));
  });

  test('series end stops generating occurrences', () {
    final rule = RecurrenceRule.weekly().copyWith(
      endDate: const DateOnly(2026, 7, 15),
    );
    final tpl = template(rule: rule);
    final occ = occurrence();
    final result = mutations.complete(occ, all: [tpl, occ], now: now);
    expect(result.upserts.length, 1);
  });

  test('max occurrences stops generating', () {
    final rule = RecurrenceRule.weekly().copyWith(maxOccurrences: 2);
    final tpl = template(rule: rule);
    final second = occurrence(index: 2, date: const DateOnly(2026, 7, 20));
    final result = mutations.complete(second, all: [tpl, second], now: now);
    expect(result.upserts.length, 1);
  });

  test('no duplicate generation when an active sibling exists', () {
    final tpl = template();
    final occ = occurrence();
    final sibling = occurrence(index: 2, date: const DateOnly(2026, 7, 20));
    final result = mutations.complete(occ, all: [tpl, occ, sibling], now: now);
    expect(result.upserts.length, 1);
  });

  test('restore flips completion without touching the series', () {
    final occ = occurrence().copyWith(isCompleted: true, completedAt: now);
    final result = mutations.restore(occ, now);
    final restored = result.upserts.single;
    expect(restored.isCompleted, isFalse);
    expect(restored.completedAt, isNull);
    expect(result.deletes, isEmpty);
  });

  test('snooze sets snoozedUntil relative to now and counts a deferral', () {
    final task = Task(id: 't', title: 'x', createdAt: now, updatedAt: now);
    final result = mutations.snooze(task, const Duration(minutes: 15), now);
    expect(
      result.upserts.single.snoozedUntil,
      now.add(const Duration(minutes: 15)),
    );
    expect(result.upserts.single.deferralCount, 1);
  });

  test('defer moves the deadline, clears snooze and counts a deferral', () {
    final task = Task(
      id: 't',
      title: 'x',
      dueDate: const DateOnly(2026, 7, 10),
      dueMinutes: 17 * 60,
      snoozedUntil: now.add(const Duration(hours: 1)),
      deferralCount: 2,
      createdAt: now,
      updatedAt: now,
    );
    final deferred = mutations
        .defer(task, const DateOnly(2026, 7, 12), now)
        .upserts
        .single;
    expect(deferred.dueDate, const DateOnly(2026, 7, 12));
    expect(deferred.dueMinutes, 17 * 60, reason: 'time-of-day is kept');
    expect(deferred.snoozedUntil, isNull);
    expect(deferred.deferralCount, 3);
  });

  test('deferring an occurrence keeps the schedule anchor', () {
    final occ = occurrence();
    final deferred = mutations
        .defer(occ, const DateOnly(2026, 7, 20), now)
        .upserts
        .single;
    expect(deferred.dueDate, const DateOnly(2026, 7, 20));
    expect(
      deferred.occurrenceDate,
      const DateOnly(2026, 7, 13),
      reason: 'the series rhythm is computed from occurrenceDate',
    );
  });

  test('materialized occurrences start with a fresh deferral count', () {
    final occ = occurrence().copyWith(deferralCount: 5);
    final result = mutations.complete(occ, all: [template(), occ], now: now);
    final next = result.upserts[1];
    expect(next.deferralCount, 0);
  });

  test('materialized occurrences inherit tags but reset progress and time', () {
    final tagged = template().copyWith(tags: ['work']);
    final occ = occurrence().copyWith(
      progressPercent: 60,
      timeSpentSeconds: 900,
    );
    final result = mutations.complete(occ, all: [tagged, occ], now: now);
    final next = result.upserts[1];
    expect(next.tags, ['work']);
    expect(next.progressPercent, isNull);
    expect(next.timeSpentSeconds, 0);
  });

  test('progress derives from subtasks, else the manual percent', () {
    final task = Task(id: 't', title: 'x', createdAt: now, updatedAt: now);
    expect(task.progress, isNull);
    expect(task.copyWith(progressPercent: 40).progress, 0.4);
    // Subtasks win over any manual percent.
    final withSubs = occurrence().copyWith(progressPercent: 90);
    expect(withSubs.progress, 0.5);
  });
}
