import '../models/date_only.dart';
import '../models/recurrence.dart';

/// Pure date math for recurring series. No storage or widget dependencies so
/// every rule can be unit tested.
///
/// All calculations work on calendar dates ([DateOnly]) rather than instants,
/// which makes them immune to daylight-saving shifts and time-zone changes:
/// the wall-clock deadline time is re-applied when an occurrence is
/// materialized.
class RecurrenceEngine {
  const RecurrenceEngine();

  /// The date of the occurrence after [current].
  ///
  /// For [RecurrenceBehavior.afterCompletion] rules pass [completedOn]; the
  /// step is taken from the completion date instead of the scheduled date.
  ///
  /// Returns null when the series has ended ([RecurrenceRule.endDate] or
  /// [RecurrenceRule.maxOccurrences], checked against [nextIndex], the
  /// 1-based index the next occurrence would have).
  DateOnly? nextOccurrence(
    RecurrenceRule rule,
    DateOnly current, {
    DateOnly? completedOn,
    int? nextIndex,
  }) {
    final base = rule.behavior == RecurrenceBehavior.afterCompletion
        ? (completedOn ?? current)
        : current;
    final next = _step(rule, base);
    if (next == null) return null;
    if (rule.endDate != null && next.isAfter(rule.endDate!)) return null;
    if (rule.maxOccurrences != null &&
        nextIndex != null &&
        nextIndex > rule.maxOccurrences!) {
      return null;
    }
    return next;
  }

  DateOnly? _step(RecurrenceRule rule, DateOnly base) {
    switch (rule.frequency) {
      case RecurrenceFrequency.daily:
        return base.addDays(rule.interval);
      case RecurrenceFrequency.weekly:
        return _stepWeekly(rule, base);
      case RecurrenceFrequency.monthly:
        return _stepMonthly(rule, base);
      case RecurrenceFrequency.yearly:
        return base.addYearsClamped(rule.interval);
    }
  }

  DateOnly _stepWeekly(RecurrenceRule rule, DateOnly base) {
    if (rule.weekdays.isEmpty) return base.addDays(7 * rule.interval);
    // Weeks are aligned to Monday for interval counting. Later weekday in the
    // same week first; otherwise jump ahead `interval` weeks and take the
    // earliest selected weekday.
    final sorted = rule.weekdays.toList()..sort();
    for (final wd in sorted) {
      if (wd > base.weekday) return base.addDays(wd - base.weekday);
    }
    final mondayOfBase = base.addDays(1 - base.weekday);
    final nextWeekMonday = mondayOfBase.addDays(7 * rule.interval);
    return nextWeekMonday.addDays(sorted.first - DateTime.monday);
  }

  DateOnly _stepMonthly(RecurrenceRule rule, DateOnly base) {
    if (rule.monthlyMode == MonthlyMode.lastDay) {
      return base
          .addMonthsClamped(rule.interval, preferredDay: 1)
          .lastDayOfMonth();
    }
    // Clamp to the last valid day of shorter months (a task on the 31st runs
    // on Feb 28/29) while remembering the intended day for later months.
    final targetDay = rule.dayOfMonth ?? base.day;
    return base.addMonthsClamped(rule.interval, preferredDay: targetDay);
  }

  /// Projects the series' occurrence dates within [from]..[to] (inclusive),
  /// starting from [anchor] (the date of the first/current occurrence).
  ///
  /// Used to draw future occurrences on the calendar without materializing
  /// database rows. [startIndex] is the 1-based index of the anchor
  /// occurrence, needed to honor "end after N occurrences".
  /// Fixed-schedule rules only; repeat-after-completion series have no
  /// projectable future until the current occurrence completes.
  List<DateOnly> projectOccurrences(
    RecurrenceRule rule,
    DateOnly anchor, {
    required DateOnly from,
    required DateOnly to,
    int startIndex = 1,
    int maxResults = 100,
  }) {
    if (rule.behavior == RecurrenceBehavior.afterCompletion) return const [];
    final results = <DateOnly>[];
    var current = anchor;
    var index = startIndex;
    // Guard against pathological rules; 1000 steps covers ~3 years of a
    // daily rule, far beyond any visible calendar range.
    for (var i = 0; i < 1000; i++) {
      if (current.isAfter(to)) break;
      if (rule.endDate != null && current.isAfter(rule.endDate!)) break;
      if (rule.maxOccurrences != null && index > rule.maxOccurrences!) break;
      if (!current.isBefore(from)) {
        results.add(current);
        if (results.length >= maxResults) break;
      }
      final next = nextOccurrence(rule, current, nextIndex: index + 1);
      if (next == null) break;
      current = next;
      index++;
    }
    return results;
  }

  /// Whether the series still produces occurrences after the one at
  /// [current] with 1-based index [currentIndex].
  bool hasNext(
    RecurrenceRule rule,
    DateOnly current, {
    DateOnly? completedOn,
    int currentIndex = 1,
  }) =>
      nextOccurrence(
        rule,
        current,
        completedOn: completedOn,
        nextIndex: currentIndex + 1,
      ) !=
      null;
}
