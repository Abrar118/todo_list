import 'dart:convert';

import '../domain/logic/focus_arranger.dart';
import '../domain/models/date_only.dart';
import '../domain/models/priority.dart';
import '../domain/models/task.dart';

/// Pure builder for the JSON snapshots the home-screen widgets render.
///
/// Selection and ordering reuse [FocusArranger] (the widgets mirror the Focus
/// screen); deadline labels are computed natively at render time so a widget
/// stays correct when the date rolls over while the app is closed. Only raw
/// fields are exported here.
class WidgetSnapshot {
  static const maxListItems = 12;

  /// Key for the single-task "Up next" widget.
  static const upNextKey = 'widget_up_next';

  /// Key for the task-list "Focus" widget.
  static const focusKey = 'widget_focus';

  final String upNextJson;
  final String focusJson;

  const WidgetSnapshot({required this.upNextJson, required this.focusJson});

  static WidgetSnapshot build(List<Task> tasks, DateTime now) {
    final sections = const FocusArranger().arrange(tasks, now);
    final ordered = <Task>[
      ...sections.spotlight,
      ...sections.overdue,
      ...sections.today,
      ...sections.upcoming,
    ];
    final seen = <String>{};
    final allItems = [
      for (final t in ordered)
        if (seen.add(t.id)) t,
    ];
    final items = allItems.take(maxListItems).toList();
    final today = DateOnly.fromDateTime(now);

    final upNext = items.firstOrNull;
    return WidgetSnapshot(
      upNextJson: jsonEncode(
        upNext == null ? {'empty': true} : _taskJson(upNext),
      ),
      focusJson: jsonEncode({
        'items': [for (final t in items) _taskJson(t)],
        'total': allItems.length,
        'overdue': allItems.where((task) => task.isOverdue(now)).length,
        'today': allItems
            .where((task) => task.dueDate == today && !task.isOverdue(now))
            .length,
      }),
    );
  }

  static Map<String, dynamic> _taskJson(Task task) => {
    'id': task.id,
    'title': task.title,
    if (task.dueDate != null) 'due': task.dueDate.toString(),
    if (task.dueMinutes != null) 'dueMinutes': task.dueMinutes,
    if (task.priority != TaskPriority.none) 'priority': task.priority.name,
    if (task.subtasks.isNotEmpty)
      'subtasks': '${task.completedSubtaskCount} of ${task.subtasks.length}',
    if (task.progress != null) 'progress': (task.progress! * 100).round(),
    if (task.tags.isNotEmpty) 'tags': task.tags,
    if (task.isRecurring) 'recurring': true,
    if (task.hasReminders) 'reminders': true,
    if (task.hasAlarm) 'alarm': true,
    if (task.timeSpentSeconds >= 60)
      'focusedMinutes': task.timeSpentSeconds ~/ 60,
  };
}
