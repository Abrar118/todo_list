import 'dart:convert';

import '../domain/models/goal.dart';
import '../domain/models/habit.dart';
import '../domain/models/task.dart';

/// The decoded contents of a backup file.
class NudgeBackup {
  final List<Task> tasks;

  /// Null when the backup predates habit and goal export (version 1), so an
  /// import leaves the current habits and goals alone instead of wiping them.
  final List<Habit>? habits;
  final List<Goal>? goals;

  const NudgeBackup({required this.tasks, this.habits, this.goals});
}

/// Backup format for "Export data as JSON" / import: tasks, habits and goals.
class TaskJsonCodec {
  /// 1: tasks only. 2: adds habits and goals.
  static const formatVersion = 2;

  const TaskJsonCodec();

  String encode(
    List<Task> tasks, {
    List<Habit> habits = const [],
    List<Goal> goals = const [],
  }) => const JsonEncoder.withIndent('  ').convert({
    'app': 'nudge',
    'version': formatVersion,
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'tasks': tasks.map((t) => t.toJson()).toList(),
    'habits': habits.map((h) => h.toJson()).toList(),
    'goals': goals.map((g) => g.toJson()).toList(),
  });

  /// Throws [FormatException] with a user-safe message on invalid input.
  NudgeBackup decode(String raw) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const FormatException('The file is not valid JSON.');
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['app'] != 'nudge' ||
        decoded['tasks'] is! List) {
      throw const FormatException('The file is not a Nudge backup.');
    }
    final version = (decoded['version'] as num?)?.toInt() ?? 0;
    if (version > formatVersion) {
      throw const FormatException(
        'This backup was created by a newer version of Nudge.',
      );
    }
    return NudgeBackup(
      tasks: _list(decoded['tasks'], 'task', Task.fromJson)!,
      habits: _list(decoded['habits'], 'habit', Habit.fromJson),
      goals: _list(decoded['goals'], 'goal', Goal.fromJson),
    );
  }

  static List<T>? _list<T>(
    Object? items,
    String noun,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (items == null) return null;
    final invalid = FormatException('The backup contains invalid $noun data.');
    if (items is! List) throw invalid;
    return [
      for (final item in items)
        if (item is Map<String, dynamic> && item['id'] is String)
          fromJson(item)
        else
          throw invalid,
    ];
  }
}
