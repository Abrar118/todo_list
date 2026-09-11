/// A calendar date without a time component.
///
/// Deadlines are stored as calendar dates (plus an optional minutes-of-day
/// value) instead of instants so that recurrence math is immune to daylight
/// saving and time-zone changes: "every Monday" stays on Monday even when the
/// UTC offset shifts. Conversion to an instant happens only at the edge
/// (notification scheduling, overdue checks) using the device's current local
/// time zone.
class DateOnly implements Comparable<DateOnly> {
  final int year;
  final int month;
  final int day;

  const DateOnly(this.year, this.month, this.day);

  factory DateOnly.fromDateTime(DateTime dt) =>
      DateOnly(dt.year, dt.month, dt.day);

  factory DateOnly.today() => DateOnly.fromDateTime(DateTime.now());

  /// Parses `yyyy-MM-dd`.
  factory DateOnly.parse(String value) {
    final parts = value.split('-');
    if (parts.length != 3) {
      throw FormatException('Invalid date: $value');
    }
    return DateOnly(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static DateOnly? tryParse(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateOnly.parse(value);
    } on FormatException {
      return null;
    }
  }

  /// Local midnight at the start of this date.
  DateTime toDateTime() => DateTime(year, month, day);

  /// Local instant at [minutesOfDay] past midnight on this date.
  DateTime atMinutes(int minutesOfDay) =>
      DateTime(year, month, day, minutesOfDay ~/ 60, minutesOfDay % 60);

  int get weekday => toDateTime().weekday;

  static int daysInMonth(int year, int month) {
    const days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month == 2 && isLeapYear(year)) return 29;
    return days[month - 1];
  }

  static bool isLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

  DateOnly addDays(int count) {
    // DateTime day arithmetic at noon avoids DST edge cases entirely.
    final dt = DateTime(year, month, day, 12).add(Duration(days: count));
    return DateOnly(dt.year, dt.month, dt.day);
  }

  /// Adds [count] months, clamping the day to the last valid day of the
  /// resulting month (Jan 31 + 1 month -> Feb 28/29).
  DateOnly addMonthsClamped(int count, {int? preferredDay}) {
    final totalMonths = (year * 12 + (month - 1)) + count;
    final newYear = totalMonths ~/ 12;
    final newMonth = totalMonths % 12 + 1;
    final targetDay = preferredDay ?? day;
    final clamped = targetDay.clamp(1, daysInMonth(newYear, newMonth));
    return DateOnly(newYear, newMonth, clamped);
  }

  DateOnly addYearsClamped(int count, {int? preferredDay}) {
    final newYear = year + count;
    final targetDay = preferredDay ?? day;
    final clamped = targetDay.clamp(1, daysInMonth(newYear, month));
    return DateOnly(newYear, month, clamped);
  }

  DateOnly lastDayOfMonth() => DateOnly(year, month, daysInMonth(year, month));

  int differenceInDays(DateOnly other) => DateTime(
    year,
    month,
    day,
    12,
  ).difference(DateTime(other.year, other.month, other.day, 12)).inDays;

  bool isBefore(DateOnly other) => compareTo(other) < 0;
  bool isAfter(DateOnly other) => compareTo(other) > 0;

  @override
  int compareTo(DateOnly other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is DateOnly &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}
