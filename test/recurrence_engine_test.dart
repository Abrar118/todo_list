import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/domain/logic/recurrence_engine.dart';
import 'package:todo_list/domain/models/date_only.dart';
import 'package:todo_list/domain/models/recurrence.dart';

void main() {
  const engine = RecurrenceEngine();

  group('DateOnly', () {
    test('leap year detection', () {
      expect(DateOnly.isLeapYear(2024), isTrue);
      expect(DateOnly.isLeapYear(2026), isFalse);
      expect(DateOnly.isLeapYear(2100), isFalse);
      expect(DateOnly.isLeapYear(2000), isTrue);
    });

    test('addMonthsClamped clamps to last valid day', () {
      expect(
        const DateOnly(2026, 1, 31).addMonthsClamped(1),
        const DateOnly(2026, 2, 28),
      );
      expect(
        const DateOnly(2024, 1, 31).addMonthsClamped(1),
        const DateOnly(2024, 2, 29),
      );
      expect(
        const DateOnly(2026, 1, 31).addMonthsClamped(2),
        const DateOnly(2026, 3, 31),
      );
    });

    test('addDays crosses month and year bounds', () {
      expect(
        const DateOnly(2026, 12, 31).addDays(1),
        const DateOnly(2027, 1, 1),
      );
      expect(
        const DateOnly(2026, 3, 1).addDays(-1),
        const DateOnly(2026, 2, 28),
      );
    });
  });

  group('daily recurrence', () {
    test('every day', () {
      final rule = RecurrenceRule.daily();
      expect(
        engine.nextOccurrence(rule, const DateOnly(2026, 7, 11)),
        const DateOnly(2026, 7, 12),
      );
    });

    test('every 3 days', () {
      final rule = RecurrenceRule.daily(interval: 3);
      expect(
        engine.nextOccurrence(rule, const DateOnly(2026, 7, 30)),
        const DateOnly(2026, 8, 2),
      );
    });
  });

  group('weekly recurrence', () {
    test('plain weekly keeps weekday', () {
      final rule = RecurrenceRule.weekly();
      // 2026-07-13 is a Monday.
      expect(
        engine.nextOccurrence(rule, const DateOnly(2026, 7, 13)),
        const DateOnly(2026, 7, 20),
      );
    });

    test('selected weekdays move within the week first', () {
      final rule = RecurrenceRule.weekly(
        weekdays: {DateTime.monday, DateTime.thursday},
      );
      expect(
        engine.nextOccurrence(rule, const DateOnly(2026, 7, 13)),
        const DateOnly(2026, 7, 16),
      ); // Mon -> Thu same week
      expect(
        engine.nextOccurrence(rule, const DateOnly(2026, 7, 16)),
        const DateOnly(2026, 7, 20),
      ); // Thu -> next Mon
    });

    test('every weekday skips weekends', () {
      final rule = RecurrenceRule.everyWeekday();
      // 2026-07-17 is a Friday.
      expect(
        engine.nextOccurrence(rule, const DateOnly(2026, 7, 17)),
        const DateOnly(2026, 7, 20),
      );
    });

    test('biweekly with weekday set jumps interval weeks', () {
      final rule = RecurrenceRule.weekly(
        interval: 2,
        weekdays: {DateTime.friday},
      );
      expect(
        engine.nextOccurrence(rule, const DateOnly(2026, 7, 17)),
        const DateOnly(2026, 7, 31),
      );
    });
  });

  group('monthly recurrence', () {
    test('day pinned; short months use last valid day', () {
      final rule = RecurrenceRule.monthly(dayOfMonth: 31);
      expect(
        engine.nextOccurrence(rule, const DateOnly(2026, 1, 31)),
        const DateOnly(2026, 2, 28),
      );
      // The intent (31st) is preserved for later months.
      expect(
        engine.nextOccurrence(rule, const DateOnly(2026, 2, 28)),
        const DateOnly(2026, 3, 31),
      );
    });

    test('leap-year February keeps the 29th', () {
      final rule = RecurrenceRule.monthly(dayOfMonth: 31);
      expect(
        engine.nextOccurrence(rule, const DateOnly(2024, 1, 31)),
        const DateOnly(2024, 2, 29),
      );
    });

    test('last day of month mode', () {
      const rule = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        monthlyMode: MonthlyMode.lastDay,
      );
      expect(
        engine.nextOccurrence(rule, const DateOnly(2026, 1, 31)),
        const DateOnly(2026, 2, 28),
      );
      expect(
        engine.nextOccurrence(rule, const DateOnly(2026, 2, 28)),
        const DateOnly(2026, 3, 31),
      );
    });

    test('every 2 months', () {
      final rule = RecurrenceRule.monthly(interval: 2, dayOfMonth: 15);
      expect(
        engine.nextOccurrence(rule, const DateOnly(2026, 11, 15)),
        const DateOnly(2027, 1, 15),
      );
    });
  });

  group('yearly recurrence', () {
    test('regular anniversary', () {
      final rule = RecurrenceRule.yearly();
      expect(
        engine.nextOccurrence(rule, const DateOnly(2026, 7, 11)),
        const DateOnly(2027, 7, 11),
      );
    });

    test('Feb 29 falls back to Feb 28 in non-leap years', () {
      final rule = RecurrenceRule.yearly();
      expect(
        engine.nextOccurrence(rule, const DateOnly(2024, 2, 29)),
        const DateOnly(2025, 2, 28),
      );
    });
  });

  group('repeat after completion', () {
    test('daily counts from completion date', () {
      const rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        interval: 3,
        behavior: RecurrenceBehavior.afterCompletion,
      );
      expect(
        engine.nextOccurrence(
          rule,
          const DateOnly(2026, 7, 1),
          completedOn: const DateOnly(2026, 7, 10),
        ),
        const DateOnly(2026, 7, 13),
      );
    });

    test('fixed schedule ignores completion date', () {
      final rule = RecurrenceRule.daily(interval: 3);
      expect(
        engine.nextOccurrence(
          rule,
          const DateOnly(2026, 7, 1),
          completedOn: const DateOnly(2026, 7, 10),
        ),
        const DateOnly(2026, 7, 4),
      );
    });
  });

  group('series ends', () {
    test('end date stops the series', () {
      final rule = RecurrenceRule.daily().copyWith(
        endDate: const DateOnly(2026, 7, 12),
      );
      expect(
        engine.nextOccurrence(rule, const DateOnly(2026, 7, 11)),
        const DateOnly(2026, 7, 12),
      );
      expect(engine.nextOccurrence(rule, const DateOnly(2026, 7, 12)), isNull);
    });

    test('occurrence count stops the series', () {
      final rule = RecurrenceRule.daily().copyWith(maxOccurrences: 3);
      expect(
        engine.nextOccurrence(rule, const DateOnly(2026, 7, 11), nextIndex: 3),
        const DateOnly(2026, 7, 12),
      );
      expect(
        engine.nextOccurrence(rule, const DateOnly(2026, 7, 12), nextIndex: 4),
        isNull,
      );
    });
  });

  group('projection', () {
    test('projects within range only', () {
      final rule = RecurrenceRule.daily();
      final dates = engine.projectOccurrences(
        rule,
        const DateOnly(2026, 7, 1),
        from: const DateOnly(2026, 7, 10),
        to: const DateOnly(2026, 7, 12),
      );
      expect(dates, [
        const DateOnly(2026, 7, 10),
        const DateOnly(2026, 7, 11),
        const DateOnly(2026, 7, 12),
      ]);
    });

    test('honors max occurrences', () {
      final rule = RecurrenceRule.daily().copyWith(maxOccurrences: 2);
      final dates = engine.projectOccurrences(
        rule,
        const DateOnly(2026, 7, 1),
        from: const DateOnly(2026, 7, 1),
        to: const DateOnly(2026, 7, 30),
      );
      expect(dates, [const DateOnly(2026, 7, 1), const DateOnly(2026, 7, 2)]);
    });

    test('after-completion rules do not project', () {
      const rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        behavior: RecurrenceBehavior.afterCompletion,
      );
      expect(
        engine.projectOccurrences(
          rule,
          const DateOnly(2026, 7, 1),
          from: const DateOnly(2026, 7, 1),
          to: const DateOnly(2026, 7, 30),
        ),
        isEmpty,
      );
    });
  });
}
