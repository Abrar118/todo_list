import 'date_only.dart';
import 'priority.dart';
import 'recurrence.dart';
import 'reminders.dart';
import 'subtask.dart';

/// Distinguishes the three shapes a row in storage can take.
///
/// [single]: an ordinary non-recurring task.
///
/// [seriesTemplate]: the definition of a recurring series. Never shown as a
/// task itself; it holds the recurrence rule plus the title/details/subtask
/// definitions copied into each occurrence.
///
/// [occurrence]: one materialized occurrence of a series. Only the current
/// (earliest incomplete) occurrence plus completed history exist in storage;
/// future occurrences are projected on demand for the calendar, which keeps a
/// neglected daily task from piling up hundreds of duplicate rows.
enum TaskKind { single, seriesTemplate, occurrence }

class Task {
  final String id;
  final TaskKind kind;
  final String title;

  /// Rich-text details, stored as Quill Delta JSON. Null/empty = no details.
  final String? detailsJson;

  final TaskPriority priority;
  final bool isCompleted;

  /// Calendar-date part of the deadline.
  final DateOnly? dueDate;

  /// Minutes past midnight for the deadline time. Null = date-only deadline.
  final int? dueMinutes;

  final List<ReminderEntry> reminders;
  final AlarmConfig alarm;
  final DateTime? snoozedUntil;

  /// How many times the user explicitly put this task off (snooze or
  /// deadline defer). Feeds escalation; never decremented.
  final int deferralCount;

  /// Free-form labels ("work", "errands"). Display case is kept; matching is
  /// case-insensitive.
  final List<String> tags;

  /// Manual completion percentage (0-100) for tasks without subtasks. Tasks
  /// with subtasks derive progress from them instead; see [progress].
  final int? progressPercent;

  /// Total focus-timer time accumulated on this task.
  final int timeSpentSeconds;

  /// Only set on [TaskKind.seriesTemplate] rows (and used transiently when a
  /// single task is converted into a series).
  final RecurrenceRule? recurrence;

  /// For occurrences: the id of their series template.
  final String? seriesId;

  /// For occurrences: the scheduled date of this occurrence.
  final DateOnly? occurrenceDate;

  /// For occurrences: 1-based position in the series, used to honor
  /// "end after N occurrences".
  final int occurrenceIndex;

  final List<Subtask> subtasks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final int sortIndex;

  const Task({
    required this.id,
    this.kind = TaskKind.single,
    required this.title,
    this.detailsJson,
    this.priority = TaskPriority.none,
    this.isCompleted = false,
    this.dueDate,
    this.dueMinutes,
    this.reminders = const [],
    this.alarm = const AlarmConfig(),
    this.snoozedUntil,
    this.deferralCount = 0,
    this.tags = const [],
    this.progressPercent,
    this.timeSpentSeconds = 0,
    this.recurrence,
    this.seriesId,
    this.occurrenceDate,
    this.occurrenceIndex = 1,
    this.subtasks = const [],
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.sortIndex = 0,
  });

  bool get isRecurring => kind == TaskKind.occurrence || recurrence != null;
  bool get hasDeadlineTime => dueMinutes != null;
  bool get hasAlarm => alarm.enabled;
  bool get hasReminders => reminders.isNotEmpty;

  int get completedSubtaskCount => subtasks.where((s) => s.isCompleted).length;

  /// 0.0–1.0 progress, or null when the task tracks none: derived from
  /// subtasks when present, otherwise the manual [progressPercent].
  double? get progress {
    if (subtasks.isNotEmpty) return completedSubtaskCount / subtasks.length;
    final percent = progressPercent;
    return percent == null ? null : percent / 100;
  }

  /// The deadline as a local instant. Date-only deadlines resolve to
  /// [dateOnlyMinutes] (the user's default reminder time-of-day).
  DateTime? dueInstant({int dateOnlyMinutes = 9 * 60}) =>
      dueDate?.atMinutes(dueMinutes ?? dateOnlyMinutes);

  /// A task with a time is overdue once that instant passes; a date-only task
  /// becomes overdue the day after its due date.
  bool isOverdue(DateTime now) {
    if (isCompleted || dueDate == null) return false;
    if (dueMinutes != null) {
      return dueDate!.atMinutes(dueMinutes!).isBefore(now);
    }
    return dueDate!.isBefore(DateOnly.fromDateTime(now));
  }

  bool isDueOn(DateOnly date) => dueDate == date;

  bool get isSnoozed =>
      snoozedUntil != null && snoozedUntil!.isAfter(DateTime.now());

  Task copyWith({
    TaskKind? kind,
    String? title,
    String? detailsJson,
    bool clearDetails = false,
    TaskPriority? priority,
    bool? isCompleted,
    DateOnly? dueDate,
    bool clearDueDate = false,
    int? dueMinutes,
    bool clearDueMinutes = false,
    List<ReminderEntry>? reminders,
    AlarmConfig? alarm,
    DateTime? snoozedUntil,
    bool clearSnooze = false,
    int? deferralCount,
    List<String>? tags,
    int? progressPercent,
    bool clearProgress = false,
    int? timeSpentSeconds,
    RecurrenceRule? recurrence,
    bool clearRecurrence = false,
    String? seriesId,
    bool clearSeriesId = false,
    DateOnly? occurrenceDate,
    int? occurrenceIndex,
    List<Subtask>? subtasks,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    int? sortIndex,
  }) => Task(
    id: id,
    kind: kind ?? this.kind,
    title: title ?? this.title,
    detailsJson: clearDetails ? null : (detailsJson ?? this.detailsJson),
    priority: priority ?? this.priority,
    isCompleted: isCompleted ?? this.isCompleted,
    dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
    dueMinutes: clearDueDate || clearDueMinutes
        ? null
        : (dueMinutes ?? this.dueMinutes),
    reminders: reminders ?? this.reminders,
    alarm: alarm ?? this.alarm,
    snoozedUntil: clearSnooze ? null : (snoozedUntil ?? this.snoozedUntil),
    deferralCount: deferralCount ?? this.deferralCount,
    tags: tags ?? this.tags,
    progressPercent: clearProgress
        ? null
        : (progressPercent ?? this.progressPercent),
    timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
    recurrence: clearRecurrence ? null : (recurrence ?? this.recurrence),
    seriesId: clearSeriesId ? null : (seriesId ?? this.seriesId),
    occurrenceDate: occurrenceDate ?? this.occurrenceDate,
    occurrenceIndex: occurrenceIndex ?? this.occurrenceIndex,
    subtasks: subtasks ?? this.subtasks,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    sortIndex: sortIndex ?? this.sortIndex,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    if (detailsJson != null) 'details': detailsJson,
    'priority': priority.name,
    'completed': isCompleted,
    if (dueDate != null) 'dueDate': dueDate.toString(),
    if (dueMinutes != null) 'dueMinutes': dueMinutes,
    if (reminders.isNotEmpty)
      'reminders': reminders.map((r) => r.toJson()).toList(),
    'alarm': alarm.toJson(),
    if (snoozedUntil != null)
      'snoozedUntil': snoozedUntil!.toUtc().toIso8601String(),
    if (deferralCount != 0) 'deferralCount': deferralCount,
    if (tags.isNotEmpty) 'tags': tags,
    if (progressPercent != null) 'progressPercent': progressPercent,
    if (timeSpentSeconds != 0) 'timeSpentSeconds': timeSpentSeconds,
    if (recurrence != null) 'recurrence': recurrence!.toJson(),
    if (seriesId != null) 'seriesId': seriesId,
    if (occurrenceDate != null) 'occurrenceDate': occurrenceDate.toString(),
    'occurrenceIndex': occurrenceIndex,
    if (subtasks.isNotEmpty)
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    if (completedAt != null)
      'completedAt': completedAt!.toUtc().toIso8601String(),
    'sortIndex': sortIndex,
  };

  factory Task.fromJson(Map<String, dynamic> json) {
    DateTime? parseTime(String? v) =>
        v == null ? null : DateTime.tryParse(v)?.toLocal();
    return Task(
      id: json['id'] as String,
      kind: TaskKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => TaskKind.single,
      ),
      title: json['title'] as String? ?? '',
      detailsJson: json['details'] as String?,
      priority: TaskPriority.fromName(json['priority'] as String?),
      isCompleted: json['completed'] as bool? ?? false,
      dueDate: DateOnly.tryParse(json['dueDate'] as String?),
      dueMinutes: (json['dueMinutes'] as num?)?.toInt(),
      reminders: ((json['reminders'] as List?) ?? const [])
          .map((e) => ReminderEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      alarm: json['alarm'] is Map<String, dynamic>
          ? AlarmConfig.fromJson(json['alarm'] as Map<String, dynamic>)
          : const AlarmConfig(),
      snoozedUntil: parseTime(json['snoozedUntil'] as String?),
      deferralCount: (json['deferralCount'] as num?)?.toInt() ?? 0,
      tags: [
        for (final t in (json['tags'] as List?) ?? const [])
          if (t is String && t.trim().isNotEmpty) t.trim(),
      ],
      progressPercent: (json['progressPercent'] as num?)?.toInt().clamp(0, 100),
      timeSpentSeconds: (json['timeSpentSeconds'] as num?)?.toInt() ?? 0,
      recurrence: json['recurrence'] is Map<String, dynamic>
          ? RecurrenceRule.fromJson(json['recurrence'] as Map<String, dynamic>)
          : null,
      seriesId: json['seriesId'] as String?,
      occurrenceDate: DateOnly.tryParse(json['occurrenceDate'] as String?),
      occurrenceIndex: (json['occurrenceIndex'] as num?)?.toInt() ?? 1,
      subtasks: ((json['subtasks'] as List?) ?? const [])
          .map((e) => Subtask.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: parseTime(json['createdAt'] as String?) ?? DateTime.now(),
      updatedAt: parseTime(json['updatedAt'] as String?) ?? DateTime.now(),
      completedAt: parseTime(json['completedAt'] as String?),
      sortIndex: (json['sortIndex'] as num?)?.toInt() ?? 0,
    );
  }
}
