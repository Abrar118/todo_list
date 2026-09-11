import 'dart:convert';

import '../models/task.dart';

/// Case-insensitive task search over titles, rich-text details and subtask
/// titles. Series templates are excluded — their occurrences carry the same
/// content — so search doubles as history ("when did I last do this?") via
/// completed occurrences.
abstract final class TaskSearch {
  static List<Task> search(List<Task> tasks, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    // Lower rank sorts first: title match beats details/subtask-only match,
    // active beats completed; recency breaks ties.
    (int, Task)? rank(Task task) {
      if (task.kind == TaskKind.seriesTemplate) return null;
      var score = task.title.toLowerCase().contains(q) ? 0 : 2;
      if (score != 0) {
        // "#work" and "work" both hit the tag.
        final tagQuery = q.startsWith('#') ? q.substring(1) : q;
        final inTags = task.tags.any((t) => t.toLowerCase().contains(tagQuery));
        final inSubtasks = task.subtasks.any(
          (s) => s.title.toLowerCase().contains(q),
        );
        if (!inTags &&
            !inSubtasks &&
            !detailsPlainText(task.detailsJson).toLowerCase().contains(q)) {
          return null;
        }
      }
      if (task.isCompleted) score += 1;
      return (score, task);
    }

    final ranked = tasks.map(rank).whereType<(int, Task)>().toList()
      ..sort((a, b) {
        if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
        return b.$2.updatedAt.compareTo(a.$2.updatedAt);
      });
    return [for (final r in ranked) r.$2];
  }

  /// Extracts the plain text of a Quill Delta document.
  static String detailsPlainText(String? detailsJson) {
    if (detailsJson == null || detailsJson.isEmpty) return '';
    try {
      final ops = jsonDecode(detailsJson);
      if (ops is! List) return '';
      final buffer = StringBuffer();
      for (final op in ops) {
        if (op is Map && op['insert'] is String) {
          buffer.write(op['insert'] as String);
        }
      }
      return buffer.toString();
    } on FormatException {
      return '';
    }
  }
}
