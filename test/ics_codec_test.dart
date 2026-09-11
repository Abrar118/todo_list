import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/data/ics_codec.dart';
import 'package:todo_list/domain/models/date_only.dart';
import 'package:todo_list/domain/models/reminders.dart';
import 'package:todo_list/domain/models/task.dart';

Task make(
  String id, {
  String title = 'Task',
  DateOnly? due,
  int? dueMinutes,
  bool completed = false,
  TaskKind kind = TaskKind.single,
  List<ReminderEntry> reminders = const [],
  List<String> tags = const [],
  String? details,
}) {
  final t = DateTime(2026, 7, 1);
  return Task(
    id: id,
    kind: kind,
    title: title,
    detailsJson: details,
    dueDate: due,
    dueMinutes: dueMinutes,
    isCompleted: completed,
    reminders: reminders,
    tags: tags,
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  const codec = IcsCodec();
  final now = DateTime.utc(2026, 7, 11, 12);

  test('produces a valid VCALENDAR envelope', () {
    final ics = codec.encode([], now: now);
    final lines = ics.split('\r\n');
    expect(lines.first, 'BEGIN:VCALENDAR');
    expect(lines.last, 'END:VCALENDAR');
    expect(ics, contains('VERSION:2.0'));
  });

  test('date-only task becomes an all-day event', () {
    final ics = codec.encode([
      make('a', title: 'Pay rent', due: const DateOnly(2026, 7, 15)),
    ], now: now);
    expect(ics, contains('BEGIN:VEVENT'));
    expect(ics, contains('UID:a@nudge'));
    expect(ics, contains('DTSTART;VALUE=DATE:20260715'));
    expect(ics, contains('DTEND;VALUE=DATE:20260716'));
    expect(ics, contains('SUMMARY:Pay rent'));
  });

  test('timed task becomes a 30-minute floating-time event', () {
    final ics = codec.encode([
      make('a', due: const DateOnly(2026, 7, 15), dueMinutes: 17 * 60 + 30),
    ], now: now);
    expect(ics, contains('DTSTART:20260715T173000'));
    expect(ics, contains('DTEND:20260715T180000'));
  });

  test('skips completed tasks, templates and tasks without deadlines', () {
    final ics = codec.encode([
      make('done', due: const DateOnly(2026, 7, 15), completed: true),
      make(
        'tmpl',
        due: const DateOnly(2026, 7, 15),
        kind: TaskKind.seriesTemplate,
      ),
      make('nodate'),
    ], now: now);
    expect(ics, isNot(contains('BEGIN:VEVENT')));
  });

  test('reminders become VALARMs, tags become CATEGORIES', () {
    final ics = codec.encode([
      make(
        'a',
        due: const DateOnly(2026, 7, 15),
        dueMinutes: 9 * 60,
        reminders: const [ReminderEntry.before(30)],
        tags: const ['work'],
      ),
    ], now: now);
    expect(ics, contains('BEGIN:VALARM'));
    expect(ics, contains('TRIGGER:-PT30M'));
    expect(ics, contains('CATEGORIES:work'));
  });

  test('escapes special characters and folds long lines', () {
    final ics = codec.encode([
      make(
        'a',
        title: 'Semi; colon, and ${'x' * 100}',
        due: const DateOnly(2026, 7, 15),
      ),
    ], now: now);
    expect(ics, contains(r'Semi\; colon\,'));
    for (final line in ics.split('\r\n')) {
      expect(line.length, lessThanOrEqualTo(75));
    }
  });
}
