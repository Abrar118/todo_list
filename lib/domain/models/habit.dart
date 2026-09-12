import 'date_only.dart';

enum HabitColor { violet, blue, green, amber, rose }

enum HabitType { checkIn, timer }

enum HabitCadence { daily, monthly }

const _unset = Object();

class HabitCheckpoint {
  final String id;
  final String title;
  final int? scheduledMinutes;
  final Set<DateOnly> completedDates;

  const HabitCheckpoint({
    required this.id,
    required this.title,
    this.scheduledMinutes,
    this.completedDates = const {},
  });

  bool isCompletedOn(DateOnly date) => completedDates.contains(date);

  HabitCheckpoint toggle(DateOnly date) {
    final next = Set<DateOnly>.of(completedDates);
    if (!next.add(date)) next.remove(date);
    return copyWith(completedDates: next);
  }

  HabitCheckpoint copyWith({
    String? title,
    Object? scheduledMinutes = _unset,
    Set<DateOnly>? completedDates,
  }) => HabitCheckpoint(
    id: id,
    title: title ?? this.title,
    scheduledMinutes: identical(scheduledMinutes, _unset)
        ? this.scheduledMinutes
        : scheduledMinutes as int?,
    completedDates: Set.unmodifiable(completedDates ?? this.completedDates),
  );

  Map<String, Object?> toJson() {
    final dates = completedDates.toList()..sort();
    return {
      'id': id,
      'title': title,
      'scheduledMinutes': scheduledMinutes,
      'completedDates': dates.map((date) => date.toString()).toList(),
    };
  }

  factory HabitCheckpoint.fromJson(Map<String, dynamic> json) {
    final completed = (json['completedDates'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .map(DateOnly.parse)
        .toSet();
    return HabitCheckpoint(
      id: json['id'] as String,
      title: json['title'] as String,
      scheduledMinutes: json['scheduledMinutes'] as int?,
      completedDates: Set.unmodifiable(completed),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HabitCheckpoint &&
      other.id == id &&
      other.title == title &&
      other.scheduledMinutes == scheduledMinutes &&
      other.completedDates.length == completedDates.length &&
      other.completedDates.containsAll(completedDates);

  @override
  int get hashCode => Object.hash(
    id,
    title,
    scheduledMinutes,
    Object.hashAll(completedDates.toList()..sort()),
  );
}

class Habit {
  final String id;
  final String title;
  final HabitColor color;
  final DateOnly createdOn;
  final Set<DateOnly> completedDates;
  final HabitType type;
  final HabitCadence cadence;
  final int monthlyDay;
  final int? scheduledMinutes;
  final int timerTargetMinutes;
  final List<HabitCheckpoint> checkpoints;
  final Map<DateOnly, int> trackedSecondsByDate;
  final DateTime? timerStartedAt;
  final bool isCollapsed;

  const Habit({
    required this.id,
    required this.title,
    required this.color,
    required this.createdOn,
    this.completedDates = const {},
    this.type = HabitType.checkIn,
    this.cadence = HabitCadence.daily,
    this.monthlyDay = 1,
    this.scheduledMinutes,
    this.timerTargetMinutes = 30,
    this.checkpoints = const [],
    this.trackedSecondsByDate = const {},
    this.timerStartedAt,
    this.isCollapsed = false,
  });

  bool isCompletedOn(DateOnly date) => completedDates.contains(date);

  int trackedSecondsOn(DateOnly date) => trackedSecondsByDate[date] ?? 0;

  Habit toggle(DateOnly date) {
    final next = Set<DateOnly>.of(completedDates);
    if (!next.add(date)) next.remove(date);
    return copyWith(completedDates: next);
  }

  Habit toggleCheckpoint(String checkpointId, DateOnly date) {
    final nextCheckpoints = checkpoints
        .map(
          (checkpoint) => checkpoint.id == checkpointId
              ? checkpoint.toggle(date)
              : checkpoint,
        )
        .toList(growable: false);
    final nextCompleted = Set<DateOnly>.of(completedDates);
    final allDone =
        nextCheckpoints.isNotEmpty &&
        nextCheckpoints.every((checkpoint) => checkpoint.isCompletedOn(date));
    if (allDone) {
      nextCompleted.add(date);
    } else {
      nextCompleted.remove(date);
    }
    return copyWith(
      checkpoints: nextCheckpoints,
      completedDates: nextCompleted,
    );
  }

  int currentStreak(DateOnly today) {
    var cursor = isCompletedOn(today) ? today : today.addDays(-1);
    var count = 0;
    while (isCompletedOn(cursor)) {
      count++;
      cursor = cursor.addDays(-1);
    }
    return count;
  }

  Habit copyWith({
    String? title,
    HabitColor? color,
    Set<DateOnly>? completedDates,
    HabitType? type,
    HabitCadence? cadence,
    int? monthlyDay,
    Object? scheduledMinutes = _unset,
    int? timerTargetMinutes,
    List<HabitCheckpoint>? checkpoints,
    Map<DateOnly, int>? trackedSecondsByDate,
    Object? timerStartedAt = _unset,
    bool? isCollapsed,
  }) => Habit(
    id: id,
    title: title ?? this.title,
    color: color ?? this.color,
    createdOn: createdOn,
    completedDates: Set.unmodifiable(completedDates ?? this.completedDates),
    type: type ?? this.type,
    cadence: cadence ?? this.cadence,
    monthlyDay: monthlyDay ?? this.monthlyDay,
    scheduledMinutes: identical(scheduledMinutes, _unset)
        ? this.scheduledMinutes
        : scheduledMinutes as int?,
    timerTargetMinutes: timerTargetMinutes ?? this.timerTargetMinutes,
    checkpoints: List.unmodifiable(checkpoints ?? this.checkpoints),
    trackedSecondsByDate: Map.unmodifiable(
      trackedSecondsByDate ?? this.trackedSecondsByDate,
    ),
    timerStartedAt: identical(timerStartedAt, _unset)
        ? this.timerStartedAt
        : timerStartedAt as DateTime?,
    isCollapsed: isCollapsed ?? this.isCollapsed,
  );

  Map<String, Object?> toJson() {
    final dates = completedDates.toList()..sort();
    final tracked = trackedSecondsByDate.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return {
      'id': id,
      'title': title,
      'color': color.name,
      'createdOn': createdOn.toString(),
      'completedDates': dates.map((date) => date.toString()).toList(),
      'type': type.name,
      'cadence': cadence.name,
      'monthlyDay': monthlyDay,
      'scheduledMinutes': scheduledMinutes,
      'timerTargetMinutes': timerTargetMinutes,
      'checkpoints': checkpoints
          .map((checkpoint) => checkpoint.toJson())
          .toList(),
      'trackedSecondsByDate': {
        for (final entry in tracked) entry.key.toString(): entry.value,
      },
      'timerStartedAt': timerStartedAt?.toIso8601String(),
      'isCollapsed': isCollapsed,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    final completed = (json['completedDates'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .map(DateOnly.parse)
        .toSet();
    final tracked = <DateOnly, int>{};
    final trackedJson = json['trackedSecondsByDate'];
    if (trackedJson is Map) {
      for (final entry in trackedJson.entries) {
        if (entry.key is String && entry.value is num) {
          tracked[DateOnly.parse(entry.key as String)] = (entry.value as num)
              .toInt();
        }
      }
    }
    final checkpointJson = json['checkpoints'] as List<dynamic>? ?? const [];
    return Habit(
      id: json['id'] as String,
      title: json['title'] as String,
      color: HabitColor.values.firstWhere(
        (color) => color.name == json['color'],
        orElse: () => HabitColor.violet,
      ),
      createdOn: DateOnly.parse(json['createdOn'] as String),
      completedDates: Set.unmodifiable(completed),
      type: HabitType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => HabitType.checkIn,
      ),
      cadence: HabitCadence.values.firstWhere(
        (cadence) => cadence.name == json['cadence'],
        orElse: () => HabitCadence.daily,
      ),
      monthlyDay: (json['monthlyDay'] as num?)?.toInt().clamp(1, 31) ?? 1,
      scheduledMinutes: json['scheduledMinutes'] as int?,
      timerTargetMinutes: (json['timerTargetMinutes'] as num?)?.toInt() ?? 30,
      checkpoints: List.unmodifiable(
        checkpointJson.whereType<Map>().map(
          (value) => HabitCheckpoint.fromJson(Map<String, dynamic>.from(value)),
        ),
      ),
      trackedSecondsByDate: Map.unmodifiable(tracked),
      timerStartedAt: json['timerStartedAt'] is String
          ? DateTime.tryParse(json['timerStartedAt'] as String)
          : null,
      isCollapsed: json['isCollapsed'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Habit &&
      other.id == id &&
      other.title == title &&
      other.color == color &&
      other.createdOn == createdOn &&
      other.type == type &&
      other.cadence == cadence &&
      other.monthlyDay == monthlyDay &&
      other.scheduledMinutes == scheduledMinutes &&
      other.timerTargetMinutes == timerTargetMinutes &&
      other.timerStartedAt == timerStartedAt &&
      other.isCollapsed == isCollapsed &&
      other.completedDates.length == completedDates.length &&
      other.completedDates.containsAll(completedDates) &&
      _listEquals(other.checkpoints, checkpoints) &&
      _mapEquals(other.trackedSecondsByDate, trackedSecondsByDate);

  @override
  int get hashCode => Object.hash(
    id,
    title,
    color,
    createdOn,
    type,
    cadence,
    monthlyDay,
    scheduledMinutes,
    timerTargetMinutes,
    timerStartedAt,
    isCollapsed,
    Object.hashAll(completedDates.toList()..sort()),
    Object.hashAll(checkpoints),
    Object.hashAll(
      (trackedSecondsByDate.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key)))
          .map((entry) => Object.hash(entry.key, entry.value)),
    ),
  );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}
