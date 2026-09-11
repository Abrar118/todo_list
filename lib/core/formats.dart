import 'package:intl/intl.dart';

import '../domain/models/date_only.dart';

/// Date/time display helpers. Everything renders in the device's current
/// local time zone.
abstract final class Formats {
  static String time(int minutesOfDay) {
    final dt = DateTime(2000, 1, 1, minutesOfDay ~/ 60, minutesOfDay % 60);
    return DateFormat.jm().format(dt);
  }

  static String timeOf(DateTime dt) => DateFormat.jm().format(dt);

  /// "Today", "Tomorrow", "Yesterday", or "Mon, Jul 14" (with year when not
  /// this year).
  static String relativeDate(DateOnly date, {DateOnly? from}) {
    final today = from ?? DateOnly.today();
    final diff = date.differenceInDays(today);
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    final dt = date.toDateTime();
    return date.year == today.year
        ? DateFormat('EEE, MMM d').format(dt)
        : DateFormat('EEE, MMM d, y').format(dt);
  }

  /// "Today at 5:30 PM" / "Mon, Jul 14".
  static String deadline(DateOnly date, int? minutesOfDay, {DateOnly? from}) {
    final base = relativeDate(date, from: from);
    return minutesOfDay == null ? base : '$base at ${time(minutesOfDay)}';
  }

  static String monthTitle(int year, int month) =>
      DateFormat.yMMMM().format(DateTime(year, month));

  static String completionGroup(DateOnly date) {
    final today = DateOnly.today();
    final diff = today.differenceInDays(date);
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    final dt = date.toDateTime();
    return date.year == today.year
        ? DateFormat('EEEE, MMM d').format(dt)
        : DateFormat('MMM d, y').format(dt);
  }

  static String fullTimestamp(DateTime dt) =>
      DateFormat('MMM d, y').add_jm().format(dt);
}
