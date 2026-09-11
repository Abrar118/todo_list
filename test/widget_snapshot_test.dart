import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/domain/models/date_only.dart';
import 'package:todo_list/domain/models/priority.dart';
import 'package:todo_list/domain/models/reminders.dart';
import 'package:todo_list/domain/models/subtask.dart';
import 'package:todo_list/domain/models/task.dart';
import 'package:todo_list/services/widget_snapshot.dart';

Task make(
  String id, {
  TaskPriority priority = TaskPriority.none,
  DateOnly? due,
  int? dueMinutes,
  bool completed = false,
  bool alarm = false,
  List<ReminderEntry> reminders = const [],
  List<Subtask> subtasks = const [],
  List<String> tags = const [],
  int? progressPercent,
  int timeSpentSeconds = 0,
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
    isCompleted: completed,
    alarm: AlarmConfig(enabled: alarm),
    reminders: reminders,
    subtasks: subtasks,
    tags: tags,
    progressPercent: progressPercent,
    timeSpentSeconds: timeSpentSeconds,
    createdAt: created,
    updatedAt: created,
  );
}

void main() {
  final now = DateTime(2026, 7, 11, 12);
  const today = DateOnly(2026, 7, 11);

  test('empty state exports empty flags', () {
    final snapshot = WidgetSnapshot.build([], now);
    expect(jsonDecode(snapshot.upNextJson), {'empty': true});
    expect(jsonDecode(snapshot.focusJson), {
      'items': [],
      'total': 0,
      'overdue': 0,
      'today': 0,
    });
  });

  test('up next is the top spotlight task with raw fields', () {
    final snapshot = WidgetSnapshot.build([
      make('later', due: today.addDays(3)),
      make(
        'urgent',
        priority: TaskPriority.high,
        due: today.addDays(-1),
        dueMinutes: 9 * 60,
        alarm: true,
        reminders: const [ReminderEntry.atDeadline()],
        tags: const ['Work', 'Launch'],
        timeSpentSeconds: 25 * 60,
        subtasks: [
          Subtask(
            id: 's1',
            title: 'a',
            sortIndex: 0,
            createdAt: now,
            isCompleted: true,
            completedAt: now,
          ),
          Subtask(id: 's2', title: 'b', sortIndex: 1, createdAt: now),
        ],
      ),
    ], now);
    final upNext = jsonDecode(snapshot.upNextJson) as Map<String, dynamic>;
    expect(upNext['id'], 'urgent');
    expect(upNext['title'], 'Task urgent');
    expect(upNext['due'], '2026-07-10');
    expect(upNext['dueMinutes'], 9 * 60);
    expect(upNext['priority'], 'high');
    expect(upNext['subtasks'], '1 of 2');
    expect(upNext['progress'], 50);
    expect(upNext['tags'], ['Work', 'Launch']);
    expect(upNext['reminders'], true);
    expect(upNext['focusedMinutes'], 25);
    expect(upNext['alarm'], true);
    expect(upNext.containsKey('recurring'), isFalse);
  });

  test('list excludes completed tasks and templates, caps length', () {
    final tasks = [
      make('done', due: today, completed: true),
      make('template', due: today, kind: TaskKind.seriesTemplate),
      // Many tasks needing attention today: the widget list caps out.
      for (var i = 0; i < 20; i++)
        make('t$i', due: today, dueMinutes: 13 * 60 + i),
    ];
    final snapshot = WidgetSnapshot.build(tasks, now);
    final items = (jsonDecode(snapshot.focusJson) as Map)['items'] as List;
    expect(items.length, WidgetSnapshot.maxListItems);
    final ids = items.map((e) => e['id']).toSet();
    expect(ids.contains('done'), isFalse);
    expect(ids.contains('template'), isFalse);
    final payload = jsonDecode(snapshot.focusJson) as Map<String, dynamic>;
    expect(payload['total'], 20);
    expect(payload['today'], 20);
    expect(payload['overdue'], 0);
  });

  test('list summary counts overdue spotlight tasks before the row cap', () {
    final tasks = [
      for (var i = 0; i < 14; i++)
        make(
          'late$i',
          priority: i == 0 ? TaskPriority.high : TaskPriority.none,
          due: today.addDays(-1),
        ),
      for (var i = 0; i < 5; i++) make('today$i', due: today),
    ];

    final payload =
        jsonDecode(WidgetSnapshot.build(tasks, now).focusJson)
            as Map<String, dynamic>;
    expect((payload['items'] as List).length, WidgetSnapshot.maxListItems);
    expect(payload['total'], 19);
    expect(payload['overdue'], 14);
    expect(payload['today'], 5);
  });

  test('list ordering follows the Focus screen and never duplicates', () {
    final snapshot = WidgetSnapshot.build([
      make('today1', due: today, dueMinutes: 20 * 60),
      make('overdueHigh', priority: TaskPriority.high, due: today.addDays(-2)),
      make('upcoming', due: today.addDays(2)),
      make('overdueLow', due: today.addDays(-1)),
    ], now);
    final items = (jsonDecode(snapshot.focusJson) as Map)['items'] as List;
    final ids = [for (final e in items) e['id']];
    expect(ids.first, 'overdueHigh');
    expect(ids.toSet().length, ids.length);
    expect(ids.toSet(), {'overdueHigh', 'overdueLow', 'today1', 'upcoming'});
  });
}
