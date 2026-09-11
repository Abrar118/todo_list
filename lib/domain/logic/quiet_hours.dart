/// Global quiet-hours window, stored as minutes of the day. Supports ranges
/// that cross midnight (23:00 -> 07:00).
class QuietHours {
  final bool enabled;
  final int startMinutes;
  final int endMinutes;

  const QuietHours({
    this.enabled = false,
    this.startMinutes = 23 * 60,
    this.endMinutes = 7 * 60,
  });

  QuietHours copyWith({bool? enabled, int? startMinutes, int? endMinutes}) =>
      QuietHours(
        enabled: enabled ?? this.enabled,
        startMinutes: startMinutes ?? this.startMinutes,
        endMinutes: endMinutes ?? this.endMinutes,
      );

  bool contains(DateTime time) {
    if (!enabled || startMinutes == endMinutes) return false;
    final m = time.hour * 60 + time.minute;
    if (startMinutes < endMinutes) {
      return m >= startMinutes && m < endMinutes;
    }
    // Crosses midnight.
    return m >= startMinutes || m < endMinutes;
  }

  /// Returns [time] unchanged when outside quiet hours, otherwise the moment
  /// quiet hours end (same or next day).
  DateTime adjust(DateTime time) {
    if (!contains(time)) return time;
    final m = time.hour * 60 + time.minute;
    var end = DateTime(
      time.year,
      time.month,
      time.day,
      endMinutes ~/ 60,
      endMinutes % 60,
    );
    // In a midnight-crossing window, times after the start belong to the
    // window that ends tomorrow morning.
    if (startMinutes > endMinutes && m >= startMinutes) {
      end = end.add(const Duration(days: 1));
    }
    return end;
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'startMinutes': startMinutes,
    'endMinutes': endMinutes,
  };

  factory QuietHours.fromJson(Map<String, dynamic> json) => QuietHours(
    enabled: json['enabled'] as bool? ?? false,
    startMinutes: (json['startMinutes'] as num?)?.toInt() ?? 23 * 60,
    endMinutes: (json['endMinutes'] as num?)?.toInt() ?? 7 * 60,
  );
}
