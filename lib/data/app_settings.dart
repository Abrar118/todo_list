import '../domain/logic/quiet_hours.dart';
import '../domain/models/priority.dart';
import '../domain/models/recurrence.dart';

/// App theme choice. Default stays dark — the brand look — so existing
/// installs don't change appearance on update.
enum AppThemeMode {
  system('System'),
  dark('Dark'),
  light('Light');

  final String label;
  const AppThemeMode(this.label);
}

/// Completed-task retention window.
enum CompletedRetention {
  sevenDays(7, '7 days'),
  thirtyDays(30, '30 days'),
  ninetyDays(90, '90 days'),
  forever(null, 'Forever');

  final int? days;
  final String label;
  const CompletedRetention(this.days, this.label);
}

class AppSettings {
  // Notifications
  final int defaultReminderOffsetMinutes;
  final int dateOnlyReminderMinutes;
  final int defaultAlarmCadenceMinutes;
  final QuietHours quietHours;
  final bool soundEnabled;
  final bool vibrationEnabled;

  // Focus timer
  final int pomodoroWorkMinutes;
  final int pomodoroBreakMinutes;

  // Appearance
  final AppThemeMode themeMode;
  final bool reduceMotion;
  final bool compactRows;

  // Task defaults
  final TaskPriority defaultPriority;
  final RecurrenceBehavior defaultRecurrenceBehavior;
  final bool defaultReminderEnabled;
  final int startOfWeek; // DateTime.monday..DateTime.sunday
  final CompletedRetention completedRetention;

  const AppSettings({
    this.defaultReminderOffsetMinutes = 0,
    this.dateOnlyReminderMinutes = 9 * 60,
    this.defaultAlarmCadenceMinutes = 60,
    this.quietHours = const QuietHours(),
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.pomodoroWorkMinutes = 25,
    this.pomodoroBreakMinutes = 5,
    this.themeMode = AppThemeMode.system,
    this.reduceMotion = false,
    this.compactRows = false,
    this.defaultPriority = TaskPriority.none,
    this.defaultRecurrenceBehavior = RecurrenceBehavior.fixedSchedule,
    this.defaultReminderEnabled = false,
    this.startOfWeek = DateTime.monday,
    this.completedRetention = CompletedRetention.forever,
  });

  AppSettings copyWith({
    int? defaultReminderOffsetMinutes,
    int? dateOnlyReminderMinutes,
    int? defaultAlarmCadenceMinutes,
    QuietHours? quietHours,
    bool? soundEnabled,
    bool? vibrationEnabled,
    int? pomodoroWorkMinutes,
    int? pomodoroBreakMinutes,
    AppThemeMode? themeMode,
    bool? reduceMotion,
    bool? compactRows,
    TaskPriority? defaultPriority,
    RecurrenceBehavior? defaultRecurrenceBehavior,
    bool? defaultReminderEnabled,
    int? startOfWeek,
    CompletedRetention? completedRetention,
  }) => AppSettings(
    defaultReminderOffsetMinutes:
        defaultReminderOffsetMinutes ?? this.defaultReminderOffsetMinutes,
    dateOnlyReminderMinutes:
        dateOnlyReminderMinutes ?? this.dateOnlyReminderMinutes,
    defaultAlarmCadenceMinutes:
        defaultAlarmCadenceMinutes ?? this.defaultAlarmCadenceMinutes,
    quietHours: quietHours ?? this.quietHours,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    pomodoroWorkMinutes: pomodoroWorkMinutes ?? this.pomodoroWorkMinutes,
    pomodoroBreakMinutes: pomodoroBreakMinutes ?? this.pomodoroBreakMinutes,
    themeMode: themeMode ?? this.themeMode,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    compactRows: compactRows ?? this.compactRows,
    defaultPriority: defaultPriority ?? this.defaultPriority,
    defaultRecurrenceBehavior:
        defaultRecurrenceBehavior ?? this.defaultRecurrenceBehavior,
    defaultReminderEnabled:
        defaultReminderEnabled ?? this.defaultReminderEnabled,
    startOfWeek: startOfWeek ?? this.startOfWeek,
    completedRetention: completedRetention ?? this.completedRetention,
  );

  Map<String, dynamic> toJson() => {
    'defaultReminderOffsetMinutes': defaultReminderOffsetMinutes,
    'dateOnlyReminderMinutes': dateOnlyReminderMinutes,
    'defaultAlarmCadenceMinutes': defaultAlarmCadenceMinutes,
    'quietHours': quietHours.toJson(),
    'soundEnabled': soundEnabled,
    'vibrationEnabled': vibrationEnabled,
    'pomodoroWorkMinutes': pomodoroWorkMinutes,
    'pomodoroBreakMinutes': pomodoroBreakMinutes,
    'themeMode': themeMode.name,
    'reduceMotion': reduceMotion,
    'compactRows': compactRows,
    'defaultPriority': defaultPriority.name,
    'defaultRecurrenceBehavior': defaultRecurrenceBehavior.name,
    'defaultReminderEnabled': defaultReminderEnabled,
    'startOfWeek': startOfWeek,
    'completedRetention': completedRetention.name,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    defaultReminderOffsetMinutes:
        (json['defaultReminderOffsetMinutes'] as num?)?.toInt() ?? 0,
    dateOnlyReminderMinutes:
        (json['dateOnlyReminderMinutes'] as num?)?.toInt() ?? 9 * 60,
    defaultAlarmCadenceMinutes:
        (json['defaultAlarmCadenceMinutes'] as num?)?.toInt() ?? 60,
    quietHours: json['quietHours'] is Map<String, dynamic>
        ? QuietHours.fromJson(json['quietHours'] as Map<String, dynamic>)
        : const QuietHours(),
    soundEnabled: json['soundEnabled'] as bool? ?? true,
    vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
    pomodoroWorkMinutes: ((json['pomodoroWorkMinutes'] as num?)?.toInt() ?? 25)
        .clamp(5, 120),
    pomodoroBreakMinutes: ((json['pomodoroBreakMinutes'] as num?)?.toInt() ?? 5)
        .clamp(1, 60),
    themeMode: AppThemeMode.values.firstWhere(
      (m) => m.name == json['themeMode'],
      orElse: () => AppThemeMode.system,
    ),
    reduceMotion: json['reduceMotion'] as bool? ?? false,
    compactRows: json['compactRows'] as bool? ?? false,
    defaultPriority: TaskPriority.fromName(json['defaultPriority'] as String?),
    defaultRecurrenceBehavior: RecurrenceBehavior.values.firstWhere(
      (b) => b.name == json['defaultRecurrenceBehavior'],
      orElse: () => RecurrenceBehavior.fixedSchedule,
    ),
    defaultReminderEnabled: json['defaultReminderEnabled'] as bool? ?? false,
    startOfWeek: ((json['startOfWeek'] as num?)?.toInt() ?? DateTime.monday)
        .clamp(DateTime.monday, DateTime.sunday),
    completedRetention: CompletedRetention.values.firstWhere(
      (r) => r.name == json['completedRetention'],
      orElse: () => CompletedRetention.forever,
    ),
  );
}
