import 'date_only.dart';

enum RecurrenceFrequency { daily, weekly, monthly, yearly }

/// How the next occurrence's date is derived.
///
/// [fixedSchedule]: the series follows the calendar regardless of when an
/// occurrence is completed (every Monday stays on Mondays).
///
/// [afterCompletion]: the next occurrence is offset from the completion time
/// of the current one (repeat 3 days after completion).
enum RecurrenceBehavior { fixedSchedule, afterCompletion }

/// For monthly rules: pin to a specific day of the month (clamped to the last
/// valid day in shorter months) or always the last day of the month.
enum MonthlyMode { dayOfMonth, lastDay }

class RecurrenceRule {
  final RecurrenceFrequency frequency;

  /// Every N days/weeks/months/years. Always >= 1.
  final int interval;

  /// For weekly rules: the weekdays the task occurs on
  /// (DateTime.monday..DateTime.sunday). Empty means "same weekday as the
  /// anchor date".
  final Set<int> weekdays;

  final MonthlyMode monthlyMode;

  /// For [MonthlyMode.dayOfMonth]: the target day (1-31). When null the
  /// anchor date's day is used. Clamped to the last valid day of shorter
  /// months.
  final int? dayOfMonth;

  final RecurrenceBehavior behavior;

  /// Series produces no occurrences after this date (inclusive of the date
  /// itself).
  final DateOnly? endDate;

  /// Series ends after this many occurrences.
  final int? maxOccurrences;

  const RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.weekdays = const {},
    this.monthlyMode = MonthlyMode.dayOfMonth,
    this.dayOfMonth,
    this.behavior = RecurrenceBehavior.fixedSchedule,
    this.endDate,
    this.maxOccurrences,
  }) : assert(interval >= 1);

  factory RecurrenceRule.daily({int interval = 1}) =>
      RecurrenceRule(frequency: RecurrenceFrequency.daily, interval: interval);

  factory RecurrenceRule.everyWeekday() => const RecurrenceRule(
    frequency: RecurrenceFrequency.weekly,
    weekdays: {
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
    },
  );

  factory RecurrenceRule.weekly({
    int interval = 1,
    Set<int> weekdays = const {},
  }) => RecurrenceRule(
    frequency: RecurrenceFrequency.weekly,
    interval: interval,
    weekdays: weekdays,
  );

  factory RecurrenceRule.monthly({int interval = 1, int? dayOfMonth}) =>
      RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        interval: interval,
        dayOfMonth: dayOfMonth,
      );

  factory RecurrenceRule.yearly({int interval = 1}) =>
      RecurrenceRule(frequency: RecurrenceFrequency.yearly, interval: interval);

  RecurrenceRule copyWith({
    RecurrenceFrequency? frequency,
    int? interval,
    Set<int>? weekdays,
    MonthlyMode? monthlyMode,
    int? dayOfMonth,
    bool clearDayOfMonth = false,
    RecurrenceBehavior? behavior,
    DateOnly? endDate,
    bool clearEndDate = false,
    int? maxOccurrences,
    bool clearMaxOccurrences = false,
  }) => RecurrenceRule(
    frequency: frequency ?? this.frequency,
    interval: interval ?? this.interval,
    weekdays: weekdays ?? this.weekdays,
    monthlyMode: monthlyMode ?? this.monthlyMode,
    dayOfMonth: clearDayOfMonth ? null : (dayOfMonth ?? this.dayOfMonth),
    behavior: behavior ?? this.behavior,
    endDate: clearEndDate ? null : (endDate ?? this.endDate),
    maxOccurrences: clearMaxOccurrences
        ? null
        : (maxOccurrences ?? this.maxOccurrences),
  );

  Map<String, dynamic> toJson() => {
    'frequency': frequency.name,
    'interval': interval,
    if (weekdays.isNotEmpty) 'weekdays': weekdays.toList()..sort(),
    'monthlyMode': monthlyMode.name,
    if (dayOfMonth != null) 'dayOfMonth': dayOfMonth,
    'behavior': behavior.name,
    if (endDate != null) 'endDate': endDate.toString(),
    if (maxOccurrences != null) 'maxOccurrences': maxOccurrences,
  };

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) => RecurrenceRule(
    frequency: RecurrenceFrequency.values.firstWhere(
      (f) => f.name == json['frequency'],
      orElse: () => RecurrenceFrequency.daily,
    ),
    interval: ((json['interval'] as num?)?.toInt() ?? 1).clamp(1, 999),
    weekdays: ((json['weekdays'] as List?) ?? const [])
        .map((e) => (e as num).toInt())
        .where((d) => d >= DateTime.monday && d <= DateTime.sunday)
        .toSet(),
    monthlyMode: MonthlyMode.values.firstWhere(
      (m) => m.name == json['monthlyMode'],
      orElse: () => MonthlyMode.dayOfMonth,
    ),
    dayOfMonth: (json['dayOfMonth'] as num?)?.toInt(),
    behavior: RecurrenceBehavior.values.firstWhere(
      (b) => b.name == json['behavior'],
      orElse: () => RecurrenceBehavior.fixedSchedule,
    ),
    endDate: DateOnly.tryParse(json['endDate'] as String?),
    maxOccurrences: (json['maxOccurrences'] as num?)?.toInt(),
  );

  /// Human-readable summary, e.g. "Every 2 weeks on Mon, Wed".
  String describe() {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final unit = switch (frequency) {
      RecurrenceFrequency.daily => 'day',
      RecurrenceFrequency.weekly => 'week',
      RecurrenceFrequency.monthly => 'month',
      RecurrenceFrequency.yearly => 'year',
    };
    var base = interval == 1 ? 'Every $unit' : 'Every $interval ${unit}s';
    if (frequency == RecurrenceFrequency.weekly && weekdays.isNotEmpty) {
      final sorted = weekdays.toList()..sort();
      if (sorted.length == 5 &&
          !sorted.contains(DateTime.saturday) &&
          !sorted.contains(DateTime.sunday) &&
          interval == 1) {
        base = 'Every weekday';
      } else {
        base = '$base on ${sorted.map((d) => dayNames[d - 1]).join(', ')}';
      }
    }
    if (frequency == RecurrenceFrequency.monthly) {
      base = monthlyMode == MonthlyMode.lastDay
          ? '$base on the last day'
          : (dayOfMonth != null ? '$base on day $dayOfMonth' : base);
    }
    if (behavior == RecurrenceBehavior.afterCompletion) {
      base = '$base after completion';
    }
    if (endDate != null) base = '$base until $endDate';
    if (maxOccurrences != null) base = '$base, $maxOccurrences times';
    return base;
  }
}
