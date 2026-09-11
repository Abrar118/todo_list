import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/domain/logic/quick_add_parser.dart';
import 'package:todo_list/domain/models/date_only.dart';

void main() {
  // Saturday, July 11 2026, noon.
  final now = DateTime(2026, 7, 11, 12);
  const today = DateOnly(2026, 7, 11);

  test('plain titles pass through untouched', () {
    final p = QuickAddParser.parse('Buy milk and bread', now);
    expect(p.title, 'Buy milk and bread');
    expect(p.dueDate, isNull);
    expect(p.dueMinutes, isNull);
    expect(p.hasMatch, isFalse);
  });

  test('date and time are extracted and stripped', () {
    final p = QuickAddParser.parse('call mom tomorrow 5pm', now);
    expect(p.title, 'call mom');
    expect(p.dueDate, today.addDays(1));
    expect(p.dueMinutes, 17 * 60);
  });

  test('"at 5:30pm" and "17:30" forms', () {
    expect(
      QuickAddParser.parse('dentist today at 5:30pm', now).dueMinutes,
      17 * 60 + 30,
    );
    expect(
      QuickAddParser.parse('dentist today 17:30', now).dueMinutes,
      17 * 60 + 30,
    );
    expect(QuickAddParser.parse('lunch today noon', now).dueMinutes, 12 * 60);
    expect(QuickAddParser.parse('flight today 12:15am', now).dueMinutes, 15);
  });

  test('weekday names resolve to the next occurrence', () {
    // Now is a Saturday.
    final p = QuickAddParser.parse('water plants friday', now);
    expect(p.title, 'water plants');
    expect(p.dueDate, const DateOnly(2026, 7, 17));
    // The same weekday means next week, and "next" adds a week.
    expect(
      QuickAddParser.parse('x saturday', now).dueDate,
      const DateOnly(2026, 7, 18),
    );
    expect(
      QuickAddParser.parse('x next friday', now).dueDate,
      const DateOnly(2026, 7, 24),
    );
  });

  test('abbreviated weekdays work too', () {
    expect(
      QuickAddParser.parse('gym fri', now).dueDate,
      const DateOnly(2026, 7, 17),
    );
    expect(
      QuickAddParser.parse('brunch this sun', now).dueDate,
      const DateOnly(2026, 7, 12),
    );
    expect(
      QuickAddParser.parse('dentist next tues', now).dueDate,
      const DateOnly(2026, 7, 21),
    );
    expect(QuickAddParser.parse('gym fri', now).title, 'gym');
  });

  test('month dates, both orders, ordinals, and year rollover', () {
    expect(
      QuickAddParser.parse('flight july 20', now).dueDate,
      const DateOnly(2026, 7, 20),
    );
    expect(
      QuickAddParser.parse('flight 20 july', now).dueDate,
      const DateOnly(2026, 7, 20),
    );
    expect(
      QuickAddParser.parse('taxes apr 15th', now).dueDate,
      const DateOnly(2027, 4, 15), // April 15 already passed this year
    );
    expect(QuickAddParser.parse('flight july 20', now).title, 'flight');
    // Invalid day numbers never match.
    expect(QuickAddParser.parse('notes feb 31', now).dueDate, isNull);
  });

  test('more keywords: tmrw, day after tomorrow, next month, weekend', () {
    expect(QuickAddParser.parse('call tmrw', now).dueDate, today.addDays(1));
    expect(
      QuickAddParser.parse('pack day after tomorrow', now).dueDate,
      today.addDays(2),
    );
    expect(
      QuickAddParser.parse('rent next month', now).dueDate,
      const DateOnly(2026, 8, 11),
    );
    // Now is Saturday: "weekend" means today.
    expect(QuickAddParser.parse('hike this weekend', now).dueDate, today);
    // On a Wednesday it means the coming Saturday.
    expect(
      QuickAddParser.parse(
        'hike this weekend',
        DateTime(2026, 7, 8, 12),
      ).dueDate,
      const DateOnly(2026, 7, 11),
    );
  });

  test('day-part words attach to dates or "this"', () {
    final p = QuickAddParser.parse('pack tomorrow morning', now);
    expect(p.dueDate, today.addDays(1));
    expect(p.dueMinutes, 9 * 60);
    expect(p.title, 'pack');

    final evening = QuickAddParser.parse('laundry this evening', now);
    expect(evening.dueDate, today);
    expect(evening.dueMinutes, 19 * 60);

    // Bare day-part words never mangle titles.
    final walk = QuickAddParser.parse('Evening walk', now);
    expect(walk.hasMatch, isFalse);
    expect(walk.title, 'Evening walk');
  });

  test('"at 5" uses the working-hours heuristic', () {
    expect(QuickAddParser.parse('call today at 5', now).dueMinutes, 17 * 60);
    expect(QuickAddParser.parse('standup today at 9', now).dueMinutes, 9 * 60);
    expect(QuickAddParser.parse('lunch today at 12', now).dueMinutes, 12 * 60);
    expect(QuickAddParser.parse('call today at 17', now).dueMinutes, 17 * 60);
    // Bare numbers without "at" never match.
    expect(QuickAddParser.parse('buy 2 lamps', now).hasMatch, isFalse);
  });

  test('"in N hours/minutes" resolves relative to now', () {
    final p = QuickAddParser.parse('take out oven in 2 hours', now);
    expect(p.title, 'take out oven');
    expect(p.dueDate, today);
    expect(p.dueMinutes, 14 * 60);

    final soon = QuickAddParser.parse('meds in 30 minutes', now);
    expect(soon.dueMinutes, 12 * 60 + 30);

    final hour = QuickAddParser.parse('leave in an hour', now);
    expect(hour.dueMinutes, 13 * 60);

    // Crossing midnight lands on tomorrow.
    final late = QuickAddParser.parse(
      'shutdown in 2 hours',
      DateTime(2026, 7, 11, 23, 30),
    );
    expect(late.dueDate, today.addDays(1));
    expect(late.dueMinutes, 90);
  });

  test('"tonight", "next week" and "in N days/weeks"', () {
    final tonight = QuickAddParser.parse('take out trash tonight', now);
    expect(tonight.dueDate, today);
    expect(tonight.dueMinutes, 20 * 60);
    expect(
      QuickAddParser.parse('report next week', now).dueDate,
      today.addDays(7),
    );
    expect(
      QuickAddParser.parse('renew passport in 3 days', now).dueDate,
      today.addDays(3),
    );
    expect(
      QuickAddParser.parse('trip in 2 weeks', now).dueDate,
      today.addDays(14),
    );
  });

  test('a bare time already past today means tomorrow', () {
    expect(QuickAddParser.parse('standup 9am', now).dueDate, today.addDays(1));
    expect(QuickAddParser.parse('standup 5pm', now).dueDate, today);
  });

  test('never eats the whole title', () {
    final p = QuickAddParser.parse('tomorrow', now);
    expect(p.title, 'tomorrow');
  });

  test('does not match inside ordinary words', () {
    final p = QuickAddParser.parse('Sort by weekdays', now);
    expect(p.hasMatch, isFalse);
    expect(p.title, 'Sort by weekdays');
  });

  test('#tags are extracted, deduped and stripped from the title', () {
    final p = QuickAddParser.parse('file taxes #Finance #home #finance', now);
    expect(p.tags, ['Finance', 'home']);
    expect(p.title, 'file taxes');
  });

  test('a #tag shields its word from date parsing', () {
    final p = QuickAddParser.parse('gym plan #friday', now);
    expect(p.tags, ['friday']);
    expect(p.dueDate, isNull);
    expect(p.title, 'gym plan');
  });

  test('tags combine with dates and times', () {
    final p = QuickAddParser.parse('call mom tomorrow 5pm #family', now);
    expect(p.tags, ['family']);
    expect(p.dueDate, today.addDays(1));
    expect(p.dueMinutes, 17 * 60);
    expect(p.title, 'call mom');
  });
}
