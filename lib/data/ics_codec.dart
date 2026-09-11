import '../domain/logic/task_search.dart';
import '../domain/models/task.dart';

/// Encodes tasks as an RFC 5545 iCalendar file for one-way export into any
/// calendar app. Pure Dart.
///
/// Every incomplete, non-template task with a deadline becomes a VEVENT:
/// date-only deadlines as all-day events, timed ones as 30-minute events at
/// the deadline. Recurring tasks export only their materialized occurrence —
/// the app owns the recurrence rule; exporting RRULEs would fork the series.
class IcsCodec {
  const IcsCodec();

  String encode(List<Task> tasks, {required DateTime now}) {
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Nudge//Task export//EN',
      'CALSCALE:GREGORIAN',
    ];
    final stamp = _utcStamp(now.toUtc());
    for (final task in tasks) {
      if (task.isCompleted ||
          task.kind == TaskKind.seriesTemplate ||
          task.dueDate == null) {
        continue;
      }
      final due = task.dueDate!;
      lines.add('BEGIN:VEVENT');
      lines.add('UID:${task.id}@nudge');
      lines.add('DTSTAMP:$stamp');
      if (task.dueMinutes == null) {
        final end = due.addDays(1);
        lines.add('DTSTART;VALUE=DATE:${_date(due.year, due.month, due.day)}');
        lines.add('DTEND;VALUE=DATE:${_date(end.year, end.month, end.day)}');
      } else {
        final start = due.atMinutes(task.dueMinutes!);
        final end = start.add(const Duration(minutes: 30));
        // Floating local times: the deadline means wall-clock time wherever
        // the user is, matching the app's calendar-date semantics.
        lines.add('DTSTART:${_local(start)}');
        lines.add('DTEND:${_local(end)}');
      }
      lines.add('SUMMARY:${_escape(task.title)}');
      final description = TaskSearch.detailsPlainText(task.detailsJson).trim();
      if (description.isNotEmpty) {
        lines.add('DESCRIPTION:${_escape(description)}');
      }
      if (task.tags.isNotEmpty) {
        lines.add('CATEGORIES:${task.tags.map(_escape).join(',')}');
      }
      for (final reminder in task.reminders) {
        if (reminder.isCustom) continue; // absolute triggers rarely import
        lines.add('BEGIN:VALARM');
        lines.add('ACTION:DISPLAY');
        lines.add('DESCRIPTION:${_escape(task.title)}');
        lines.add('TRIGGER:-PT${reminder.offsetMinutes}M');
        lines.add('END:VALARM');
      }
      lines.add('END:VEVENT');
    }
    lines.add('END:VCALENDAR');
    return lines.map(_fold).join('\r\n');
  }

  static String _date(int year, int month, int day) =>
      '${year.toString().padLeft(4, '0')}'
      '${month.toString().padLeft(2, '0')}'
      '${day.toString().padLeft(2, '0')}';

  static String _local(DateTime t) =>
      '${_date(t.year, t.month, t.day)}T'
      '${t.hour.toString().padLeft(2, '0')}'
      '${t.minute.toString().padLeft(2, '0')}00';

  static String _utcStamp(DateTime utc) => '${_local(utc)}Z';

  /// RFC 5545 text escaping: backslash, semicolon, comma, newline.
  static String _escape(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll(';', '\\;')
      .replaceAll(',', '\\,')
      .replaceAll('\n', '\\n');

  /// Content lines longer than 75 octets are folded with CRLF + space.
  static String _fold(String line) {
    if (line.length <= 75) return line;
    final buffer = StringBuffer(line.substring(0, 75));
    var rest = line.substring(75);
    while (rest.length > 74) {
      buffer.write('\r\n ${rest.substring(0, 74)}');
      rest = rest.substring(74);
    }
    if (rest.isNotEmpty) buffer.write('\r\n $rest');
    return buffer.toString();
  }
}
