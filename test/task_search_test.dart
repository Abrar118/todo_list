import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/domain/logic/task_search.dart';
import 'package:todo_list/domain/models/subtask.dart';
import 'package:todo_list/domain/models/task.dart';

Task make(
  String id,
  String title, {
  String? details,
  List<String> subtasks = const [],
  bool completed = false,
  TaskKind kind = TaskKind.single,
  DateTime? updatedAt,
}) {
  final t = DateTime(2026, 7, 1);
  return Task(
    id: id,
    kind: kind,
    title: title,
    detailsJson: details == null
        ? null
        : jsonEncode([
            {'insert': '$details\n'},
          ]),
    subtasks: [
      for (final (i, s) in subtasks.indexed)
        Subtask(id: '$id-$i', title: s, sortIndex: i, createdAt: t),
    ],
    isCompleted: completed,
    createdAt: t,
    updatedAt: updatedAt ?? t,
  );
}

void main() {
  test('empty query returns nothing', () {
    expect(TaskSearch.search([make('a', 'Anything')], '  '), isEmpty);
  });

  test('matches title, details and subtasks case-insensitively', () {
    final tasks = [
      make('t1', 'Call the plumber'),
      make('t2', 'Kitchen work', details: 'ask the PLUMBER about the sink'),
      make('t3', 'Renovation', subtasks: ['find plumber', 'buy tiles']),
      make('t4', 'Unrelated'),
    ];
    final ids = TaskSearch.search(tasks, 'plumber').map((t) => t.id).toList();
    expect(ids.toSet(), {'t1', 't2', 't3'});
    expect(ids.first, 't1', reason: 'title matches rank first');
  });

  test('active results come before completed history', () {
    final tasks = [
      make('done', 'Change water filter', completed: true),
      make('open', 'Order water filter'),
    ];
    final ids = TaskSearch.search(tasks, 'filter').map((t) => t.id).toList();
    expect(ids, ['open', 'done']);
  });

  test('series templates are excluded', () {
    final tasks = [
      make('template', 'Weekly review', kind: TaskKind.seriesTemplate),
      make('occ', 'Weekly review', kind: TaskKind.occurrence),
    ];
    final ids = TaskSearch.search(tasks, 'review').map((t) => t.id).toList();
    expect(ids, ['occ']);
  });

  test('ties break by recency', () {
    final tasks = [
      make('old', 'Water plants', updatedAt: DateTime(2026, 6, 1)),
      make('new', 'Water flowers', updatedAt: DateTime(2026, 7, 10)),
    ];
    final ids = TaskSearch.search(tasks, 'water').map((t) => t.id).toList();
    expect(ids, ['new', 'old']);
  });

  test('matches tags, with or without the # prefix', () {
    final tagged = make('t', 'Untitled errand').copyWith(tags: ['Errands']);
    expect(TaskSearch.search([tagged], 'errands'), hasLength(1));
    expect(TaskSearch.search([tagged], '#errands'), hasLength(1));
    expect(TaskSearch.search([tagged], 'groceries'), isEmpty);
  });

  test('malformed details JSON never throws', () {
    final broken = make('b', 'Broken').copyWith(detailsJson: '{not json');
    expect(TaskSearch.search([broken], 'anything'), isEmpty);
    expect(TaskSearch.search([broken], 'broken'), hasLength(1));
  });
}
