import 'dart:convert';

import '../domain/models/task.dart';

/// Backup format for "Export all task data as JSON" / import.
class TaskJsonCodec {
  static const formatVersion = 1;

  const TaskJsonCodec();

  String encode(List<Task> tasks) =>
      const JsonEncoder.withIndent('  ').convert({
        'app': 'nudge',
        'version': formatVersion,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
      });

  /// Throws [FormatException] with a user-safe message on invalid input.
  List<Task> decode(String raw) {
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
    final tasks = <Task>[];
    for (final item in decoded['tasks'] as List) {
      if (item is! Map<String, dynamic> || item['id'] is! String) {
        throw const FormatException('The backup contains invalid task data.');
      }
      tasks.add(Task.fromJson(item));
    }
    return tasks;
  }
}
