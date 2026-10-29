import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/domain/logic/ticket_age.dart';
import 'package:todo_list/domain/models/date_only.dart';
import 'package:todo_list/domain/models/task.dart';

Task make({
  DateOnly? due,
  int? dueMinutes,
  int deferrals = 0,
  bool completed = false,
}) {
  final created = DateTime(2026, 7, 1);
  return Task(
    id: 't',
    kind: TaskKind.single,
    title: 'Task',
    dueDate: due,
    dueMinutes: dueMinutes,
    deferralCount: deferrals,
    isCompleted: completed,
    createdAt: created,
    updatedAt: created,
  );
}

void main() {
  final now = DateTime(2026, 7, 11, 12);
  const today = DateOnly(2026, 7, 11);

  test('no deadline prints no stamp but still carries deferral heat', () {
    expect(TicketAge.of(make(), now).timing, TicketTiming.none);
    expect(TicketAge.of(make(deferrals: 3), now).heat, 1);
  });

  test('late tasks count whole days and are always at least warming', () {
    final age = TicketAge.of(make(due: today.addDays(-1)), now);
    expect(age.timing, TicketTiming.late);
    expect(age.daysLate, 1);
    expect(age.heat, 1, reason: 'one day late has no escalation level yet');
  });

  test('a time that passed earlier today is late by zero days', () {
    final age = TicketAge.of(make(due: today, dueMinutes: 9 * 60), now);
    expect(age.timing, TicketTiming.late);
    expect(age.daysLate, 0);
  });

  test('heat follows escalation once it outgrows lateness', () {
    expect(TicketAge.of(make(due: today.addDays(-3)), now).heat, 1);
    expect(TicketAge.of(make(due: today.addDays(-6)), now).heat, 2);
    expect(
      TicketAge.of(make(due: today.addDays(-2), deferrals: 4), now).heat,
      2,
    );
  });

  test('due later today and upcoming tasks stay cold until put off', () {
    final later = TicketAge.of(make(due: today, dueMinutes: 18 * 60), now);
    expect(later.timing, TicketTiming.dueToday);
    expect(later.heat, 0);

    final upcoming = TicketAge.of(make(due: today.addDays(3)), now);
    expect(upcoming.timing, TicketTiming.upcoming);
    expect(upcoming.daysUntil, 3);
    expect(upcoming.heat, 0);

    expect(
      TicketAge.of(make(due: today.addDays(3), deferrals: 3), now).heat,
      1,
    );
  });

  test('completed tasks print no stamp', () {
    final age = TicketAge.of(
      make(due: today.addDays(-4), completed: true),
      now,
    );
    expect(age.timing, TicketTiming.none);
    expect(age.heat, 0);
  });
}
