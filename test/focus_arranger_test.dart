import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/domain/logic/focus_arranger.dart';
import 'package:todo_list/domain/models/date_only.dart';
import 'package:todo_list/domain/models/priority.dart';
import 'package:todo_list/domain/models/reminders.dart';
import 'package:todo_list/domain/models/task.dart';

Task make(
  String id, {
  TaskPriority priority = TaskPriority.none,
  DateOnly? due,
  int? dueMinutes,
  bool alarm = false,
  bool completed = false,
  DateTime? createdAt,
}) {
  final created = createdAt ?? DateTime(2026, 7, 1);
  return Task(
    id: id,
    title: id,
    priority: priority,
    dueDate: due,
    dueMinutes: dueMinutes,
    alarm: AlarmConfig(enabled: alarm),
    isCompleted: completed,
    createdAt: created,
    updatedAt: created,
  );
}

void main() {
  const arranger = FocusArranger();
  final now = DateTime(2026, 7, 11, 12, 0);
  const today = DateOnly(2026, 7, 11);
  const yesterday = DateOnly(2026, 7, 10);
  const tomorrow = DateOnly(2026, 7, 12);

  test('spotlight tier order follows the spec', () {
    final tasks = [
      make('nearest', due: tomorrow),
      make('alarmed', due: const DateOnly(2026, 7, 20), alarm: true),
      make('highUpcoming', priority: TaskPriority.high, due: tomorrow),
      make('overdueLow', due: yesterday),
      make(
        'highToday',
        priority: TaskPriority.high,
        due: today,
        dueMinutes: 23 * 60,
      ),
      make('overdueHigh', priority: TaskPriority.high, due: yesterday),
    ];
    final sections = arranger.arrange(tasks, now);
    expect(sections.spotlight.map((t) => t.id), [
      'overdueHigh',
      'highToday',
      'overdueLow',
    ]);
  });

  test('spotlight is capped at three and excludes completed', () {
    final tasks = [
      for (var i = 0; i < 5; i++)
        make('overdue$i', due: yesterday, priority: TaskPriority.high),
      make('done', due: yesterday, completed: true),
    ];
    final sections = arranger.arrange(tasks, now);
    expect(sections.spotlight.length, 3);
    expect(sections.spotlight.any((t) => t.id == 'done'), isFalse);
  });

  test('overdue grouping: date-only tasks become overdue the next day', () {
    final tasks = [
      make('dateOnlyToday', due: today), // not overdue yet
      make('dateOnlyYesterday', due: yesterday),
      make('timedEarlier', due: today, dueMinutes: 9 * 60),
      make('timedLater', due: today, dueMinutes: 18 * 60),
    ];
    final sections = arranger.arrange(tasks, now);
    final overdueIds = [
      ...sections.spotlight,
      ...sections.overdue,
    ].where((t) => t.isOverdue(now)).map((t) => t.id).toSet();
    expect(overdueIds, {'dateOnlyYesterday', 'timedEarlier'});
    final todayIds = sections.today.map((t) => t.id).toList();
    expect(todayIds, isNot(contains('dateOnlyYesterday')));
  });

  test('today section sorts by priority then time then creation', () {
    final tasks = [
      // Push spotlight elsewhere so today's ordering is observable.
      make('spot1', priority: TaskPriority.high, due: yesterday),
      make('spot2', priority: TaskPriority.high, due: yesterday),
      make('spot3', priority: TaskPriority.high, due: yesterday),
      make(
        'lowLate',
        priority: TaskPriority.low,
        due: today,
        dueMinutes: 22 * 60,
      ),
      make(
        'medEarly',
        priority: TaskPriority.medium,
        due: today,
        dueMinutes: 20 * 60,
      ),
      make(
        'medLate',
        priority: TaskPriority.medium,
        due: today,
        dueMinutes: 23 * 60,
      ),
      make('noneEarly', due: today, dueMinutes: 13 * 60),
    ];
    final sections = arranger.arrange(tasks, now);
    expect(sections.today.map((t) => t.id), [
      'medEarly',
      'medLate',
      'lowLate',
      'noneEarly',
    ]);
  });

  test('upcoming preview is limited and sorted by deadline', () {
    final tasks = [
      for (var i = 9; i >= 1; i--)
        make('up$i', due: today.addDays(i), createdAt: DateTime(2026, 7, i)),
    ];
    final sections = arranger.arrange(tasks, now);
    // The three nearest deadlines fill the spotlight; the preview continues
    // from there, sorted by deadline.
    expect(sections.spotlight.map((t) => t.id), ['up1', 'up2', 'up3']);
    expect(sections.upcoming.length, FocusArranger.upcomingPreviewSize);
    expect(sections.upcoming.first.dueDate, today.addDays(4));
    expect(sections.upcoming.last.dueDate, today.addDays(7));
  });

  test('overdue labels', () {
    expect(
      FocusArranger.overdueLabel(
        make('a', due: today, dueMinutes: 10 * 60),
        now,
      ),
      '2 hours overdue',
    );
    expect(
      FocusArranger.overdueLabel(make('b', due: yesterday), now),
      '1 day overdue',
    );
    expect(
      FocusArranger.overdueLabel(make('c', due: today.addDays(-4)), now),
      '4 days overdue',
    );
  });

  test('empty state', () {
    final sections = arranger.arrange([], now);
    expect(sections.isEmpty, isTrue);
  });
}
