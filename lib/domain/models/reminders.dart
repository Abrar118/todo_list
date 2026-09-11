/// A single reminder time attached to a task. A task may have several.
class ReminderEntry {
  /// Minutes before the deadline. 0 = at deadline. Null when [customTime] is
  /// set instead.
  final int? offsetMinutes;

  /// An absolute reminder time, independent of the deadline.
  final DateTime? customTime;

  const ReminderEntry.atDeadline() : offsetMinutes = 0, customTime = null;

  const ReminderEntry.before(int minutes)
    : offsetMinutes = minutes,
      customTime = null;

  const ReminderEntry.custom(DateTime this.customTime) : offsetMinutes = null;

  bool get isCustom => customTime != null;
  bool get isAtDeadline => offsetMinutes == 0;

  Map<String, dynamic> toJson() => {
    if (offsetMinutes != null) 'offsetMinutes': offsetMinutes,
    if (customTime != null) 'customTime': customTime!.toUtc().toIso8601String(),
  };

  factory ReminderEntry.fromJson(Map<String, dynamic> json) {
    final custom = DateTime.tryParse(json['customTime'] as String? ?? '');
    if (custom != null) return ReminderEntry.custom(custom.toLocal());
    return ReminderEntry.before((json['offsetMinutes'] as num?)?.toInt() ?? 0);
  }

  String describe() {
    if (isCustom) return 'Custom time';
    final m = offsetMinutes!;
    if (m == 0) return 'At deadline';
    if (m % 1440 == 0) {
      final d = m ~/ 1440;
      return d == 1 ? '1 day before' : '$d days before';
    }
    if (m % 60 == 0) {
      final h = m ~/ 60;
      return h == 1 ? '1 hour before' : '$h hours before';
    }
    return '$m minutes before';
  }

  @override
  bool operator ==(Object other) =>
      other is ReminderEntry &&
      other.offsetMinutes == offsetMinutes &&
      other.customTime == customTime;

  @override
  int get hashCode => Object.hash(offsetMinutes, customTime);
}

/// Opt-in persistent alarm: keeps re-notifying at [cadenceMinutes] intervals
/// from the task's deadline until the task is completed, snoozed, disabled or
/// the optional stop time is reached.
class AlarmConfig {
  final bool enabled;
  final int cadenceMinutes;

  /// Optional daily window (minutes of day). When set, alarm notifications
  /// fire only between start and stop.
  final int? startMinutesOfDay;
  final int? stopMinutesOfDay;

  /// When true this alarm keeps firing during quiet hours.
  final bool allowInQuietHours;
  final bool soundEnabled;
  final bool vibrationEnabled;

  const AlarmConfig({
    this.enabled = false,
    this.cadenceMinutes = 60,
    this.startMinutesOfDay,
    this.stopMinutesOfDay,
    this.allowInQuietHours = false,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  AlarmConfig copyWith({
    bool? enabled,
    int? cadenceMinutes,
    int? startMinutesOfDay,
    bool clearStart = false,
    int? stopMinutesOfDay,
    bool clearStop = false,
    bool? allowInQuietHours,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) => AlarmConfig(
    enabled: enabled ?? this.enabled,
    cadenceMinutes: cadenceMinutes ?? this.cadenceMinutes,
    startMinutesOfDay: clearStart
        ? null
        : (startMinutesOfDay ?? this.startMinutesOfDay),
    stopMinutesOfDay: clearStop
        ? null
        : (stopMinutesOfDay ?? this.stopMinutesOfDay),
    allowInQuietHours: allowInQuietHours ?? this.allowInQuietHours,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'cadenceMinutes': cadenceMinutes,
    if (startMinutesOfDay != null) 'startMinutesOfDay': startMinutesOfDay,
    if (stopMinutesOfDay != null) 'stopMinutesOfDay': stopMinutesOfDay,
    'allowInQuietHours': allowInQuietHours,
    'soundEnabled': soundEnabled,
    'vibrationEnabled': vibrationEnabled,
  };

  factory AlarmConfig.fromJson(Map<String, dynamic> json) => AlarmConfig(
    enabled: json['enabled'] as bool? ?? false,
    cadenceMinutes: ((json['cadenceMinutes'] as num?)?.toInt() ?? 60).clamp(
      5,
      1440,
    ),
    startMinutesOfDay: (json['startMinutesOfDay'] as num?)?.toInt(),
    stopMinutesOfDay: (json['stopMinutesOfDay'] as num?)?.toInt(),
    allowInQuietHours: json['allowInQuietHours'] as bool? ?? false,
    soundEnabled: json['soundEnabled'] as bool? ?? true,
    vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
  );

  String describeCadence() {
    final m = cadenceMinutes;
    if (m % 60 == 0) {
      final h = m ~/ 60;
      return h == 1 ? 'Every hour' : 'Every $h hours';
    }
    return 'Every $m minutes';
  }
}
