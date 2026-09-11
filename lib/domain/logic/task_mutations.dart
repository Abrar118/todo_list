import '../models/date_only.dart';
import '../models/task.dart';
import 'recurrence_engine.dart';

/// The storage changes produced by a mutation.
class MutationResult {
  final List<Task> upserts;
  final List<String> deletes;

  const MutationResult({this.upserts = const [], this.deletes = const []});
}

/// Completion and snooze transitions, shared by the in-app controller and the
/// background notification-action handler so recurring behavior can never
/// diverge between the two paths.
class TaskMutations {
  final RecurrenceEngine engine;
  final String Function() newId;

  const TaskMutations({required this.engine, required this.newId});

  /// Completes [task]. For a recurring occurrence this also materializes the
  /// next occurrence from its series template (when the series has not
  /// ended). Completing one occurrence never touches the rest of the series.
  MutationResult complete(
    Task task, {
    required List<Task> all,
    required DateTime now,
    bool completeSubtasks = false,
  }) {
    var subtasks = task.subtasks;
    if (completeSubtasks) {
      subtasks = [
        for (final s in subtasks)
          s.isCompleted ? s : s.copyWith(isCompleted: true, completedAt: now),
      ];
    }
    final completed = task.copyWith(
      isCompleted: true,
      completedAt: now,
      clearSnooze: true,
      subtasks: subtasks,
      updatedAt: now,
    );
    final upserts = <Task>[completed];

    if (task.kind == TaskKind.occurrence && task.seriesId != null) {
      final next = _materializeNext(task, all: all, now: now);
      if (next != null) upserts.add(next);
    }
    return MutationResult(upserts: upserts);
  }

  /// Restores a completed task to active. Never regenerates series state or
  /// duplicates future occurrences — it only flips this row back.
  MutationResult restore(Task task, DateTime now) => MutationResult(
    upserts: [
      task.copyWith(isCompleted: false, clearCompletedAt: true, updatedAt: now),
    ],
  );

  MutationResult snooze(Task task, Duration duration, DateTime now) =>
      MutationResult(
        upserts: [
          task.copyWith(
            snoozedUntil: now.add(duration),
            deferralCount: task.deferralCount + 1,
            updatedAt: now,
          ),
        ],
      );

  /// Moves the deadline to [date] ("not today"), keeping the time-of-day.
  /// Counts as a deferral so escalation can react to repeated postponing.
  /// For a recurring occurrence only the deadline moves; [Task.occurrenceDate]
  /// stays as the schedule anchor, so the series keeps its rhythm.
  MutationResult defer(Task task, DateOnly date, DateTime now) =>
      MutationResult(
        upserts: [
          task.copyWith(
            dueDate: date,
            clearSnooze: true,
            deferralCount: task.deferralCount + 1,
            updatedAt: now,
          ),
        ],
      );

  /// Builds the next occurrence of the series [task] belongs to, or null when
  /// the series has ended or an incomplete occurrence already exists (guards
  /// against double-generation from repeated notification actions).
  Task? _materializeNext(
    Task task, {
    required List<Task> all,
    required DateTime now,
  }) {
    final template = all
        .where(
          (t) => t.id == task.seriesId && t.kind == TaskKind.seriesTemplate,
        )
        .firstOrNull;
    final rule = template?.recurrence;
    if (template == null || rule == null) return null;

    final hasActiveSibling = all.any(
      (t) =>
          t.seriesId == task.seriesId &&
          t.kind == TaskKind.occurrence &&
          t.id != task.id &&
          !t.isCompleted,
    );
    if (hasActiveSibling) return null;

    final current = task.occurrenceDate ?? task.dueDate;
    if (current == null) return null;
    final nextDate = engine.nextOccurrence(
      rule,
      current,
      completedOn: DateOnly.fromDateTime(now),
      nextIndex: task.occurrenceIndex + 1,
    );
    if (nextDate == null) return null;

    return materializeOccurrence(
      template,
      nextDate,
      index: task.occurrenceIndex + 1,
      now: now,
    );
  }

  /// Copies the series template into a concrete occurrence on [date]:
  /// title, details, priority, reminder and alarm configuration carry over;
  /// subtasks are copied and reset to incomplete.
  Task materializeOccurrence(
    Task template,
    DateOnly date, {
    required int index,
    required DateTime now,
  }) => Task(
    id: newId(),
    kind: TaskKind.occurrence,
    title: template.title,
    detailsJson: template.detailsJson,
    priority: template.priority,
    dueDate: date,
    dueMinutes: template.dueMinutes,
    reminders: List.of(template.reminders),
    alarm: template.alarm,
    tags: List.of(template.tags),
    seriesId: template.id,
    occurrenceDate: date,
    occurrenceIndex: index,
    subtasks: [
      for (final s in template.subtasks) s.resetForNewOccurrence(newId(), now),
    ],
    createdAt: now,
    updatedAt: now,
    sortIndex: template.sortIndex,
  );
}
