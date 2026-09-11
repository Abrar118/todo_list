import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/task_json_codec.dart';
import '../data/task_repository.dart';
import '../domain/logic/focus_arranger.dart';
import '../domain/logic/notification_planner.dart';
import '../domain/logic/recurrence_engine.dart';
import '../domain/logic/task_mutations.dart';
import '../domain/models/date_only.dart';
import '../domain/models/priority.dart';
import '../domain/models/recurrence.dart';
import '../domain/models/reminders.dart';
import '../domain/models/subtask.dart';
import '../domain/models/task.dart';
import '../services/notification_service.dart';
import 'settings_controller.dart';

/// Scope choices when editing or deleting one occurrence of a series.
enum SeriesEditScope { thisOccurrence, thisAndFuture, entireSeries }

/// A task shown on the calendar agenda: either a real stored task or a
/// projected future occurrence of a recurring series (not yet materialized).
class AgendaItem {
  final Task task;
  final bool isProjection;

  const AgendaItem(this.task, {this.isProjection = false});
}

/// Per-date calendar indicators.
class DayMarkers {
  final int taskCount;
  final bool hasHighPriority;
  final bool hasCompleted;
  final bool hasRecurring;
  final bool allCompleted;

  const DayMarkers({
    this.taskCount = 0,
    this.hasHighPriority = false,
    this.hasCompleted = false,
    this.hasRecurring = false,
    this.allCompleted = false,
  });
}

class _UndoRecord {
  final List<Task> before;
  final List<String> createdIds;

  const _UndoRecord(this.before, this.createdIds);
}

/// Central task store and coordinator: persistence, recurrence, notification
/// sync and derived views all flow through here.
class AppState extends ChangeNotifier {
  final TaskRepository _repository;
  final NotificationService _notifications;
  final SettingsController _settingsController;

  static const _uuid = Uuid();
  final RecurrenceEngine engine = const RecurrenceEngine();
  late final TaskMutations _mutations = TaskMutations(
    engine: engine,
    newId: _uuid.v4,
  );
  final FocusArranger _arranger = const FocusArranger();

  List<Task> _tasks = [];
  bool _loaded = false;
  bool _storageError = false;
  ScheduleResult? _lastScheduleResult;
  _UndoRecord? _lastCompletion;

  /// Set when a notification asks the app to open a task; the shell listens
  /// and navigates.
  final ValueNotifier<String?> openTaskRequest = ValueNotifier(null);

  AppState(this._repository, this._notifications, this._settingsController) {
    _settingsController.addListener(_onSettingsChanged);
  }

  bool get isLoaded => _loaded;
  bool get hasStorageError => _storageError;
  ScheduleResult? get lastScheduleResult => _lastScheduleResult;
  List<Task> get allTasks => List.unmodifiable(_tasks);

  Task? taskById(String id) => _tasks.where((t) => t.id == id).firstOrNull;

  Task? templateOf(Task task) => task.seriesId == null
      ? null
      : _tasks
            .where(
              (t) => t.id == task.seriesId && t.kind == TaskKind.seriesTemplate,
            )
            .firstOrNull;

  RecurrenceRule? ruleOf(Task task) => task.kind == TaskKind.seriesTemplate
      ? task.recurrence
      : templateOf(task)?.recurrence ?? task.recurrence;

  // ---------------------------------------------------------------------
  // Startup
  // ---------------------------------------------------------------------

  Future<void> init() async {
    try {
      _tasks = await _repository.loadAll();
      _storageError = false;
    } catch (_) {
      _tasks = [];
      _storageError = true;
    }
    _loaded = true;
    await _runStartupMaintenance();
    notifyListeners();
    _notifications.setActionListener(handleNotificationAction);
    await resyncNotifications();
  }

  /// Startup/resume housekeeping: prune old completed tasks per retention,
  /// make sure every live series has an active occurrence, refresh schedules.
  Future<void> _runStartupMaintenance() async {
    final now = DateTime.now();
    final retention = _settingsController.settings.completedRetention.days;
    if (retention != null) {
      final cutoff = now.subtract(Duration(days: retention));
      final stale = _tasks
          .where(
            (t) =>
                t.isCompleted &&
                t.kind != TaskKind.seriesTemplate &&
                (t.completedAt ?? t.updatedAt).isBefore(cutoff),
          )
          .map((t) => t.id)
          .toList();
      if (stale.isNotEmpty) {
        _tasks.removeWhere((t) => stale.contains(t.id));
        await _guard(() => _repository.deleteMany(stale));
      }
    }
    await _ensureActiveOccurrences(now);
  }

  /// After an import (or an interrupted completion) a series can exist with
  /// no active occurrence; regenerate the next one so the series continues.
  Future<void> _ensureActiveOccurrences(DateTime now) async {
    final created = <Task>[];
    for (final template
        in _tasks
            .where(
              (t) => t.kind == TaskKind.seriesTemplate && t.recurrence != null,
            )
            .toList()) {
      final occurrences = _tasks
          .where((t) => t.seriesId == template.id)
          .toList();
      if (occurrences.any((t) => !t.isCompleted)) continue;
      if (occurrences.isEmpty) {
        // Fresh series (import without occurrences): materialize the anchor.
        final anchor = template.dueDate;
        if (anchor != null) {
          created.add(
            _mutations.materializeOccurrence(
              template,
              anchor,
              index: 1,
              now: now,
            ),
          );
        }
        continue;
      }
      occurrences.sort(
        (a, b) => (a.occurrenceIndex).compareTo(b.occurrenceIndex),
      );
      final last = occurrences.last;
      final lastDate = last.occurrenceDate ?? last.dueDate;
      if (lastDate == null) continue;
      final next = engine.nextOccurrence(
        template.recurrence!,
        lastDate,
        completedOn: last.completedAt != null
            ? DateOnly.fromDateTime(last.completedAt!)
            : null,
        nextIndex: last.occurrenceIndex + 1,
      );
      if (next != null) {
        created.add(
          _mutations.materializeOccurrence(
            template,
            next,
            index: last.occurrenceIndex + 1,
            now: now,
          ),
        );
      }
    }
    if (created.isNotEmpty) {
      _tasks.addAll(created);
      await _guard(() => _repository.upsertAll(created));
    }
  }

  Future<void> onAppResumed() async {
    // A widget button or notification action may have mutated storage from a
    // background isolate while we were paused; reload rather than trusting
    // the in-memory copy.
    try {
      _tasks = await _repository.loadAll();
      _storageError = false;
    } catch (_) {
      // Keep the in-memory state; every mutation is persisted individually.
    }
    await _runStartupMaintenance();
    await _settingsController.refreshPermissionState();
    notifyListeners();
    await resyncNotifications();
  }

  void _onSettingsChanged() {
    // Quiet hours / default reminder time changes shift delivery times.
    resyncNotifications();
  }

  // ---------------------------------------------------------------------
  // Derived views
  // ---------------------------------------------------------------------

  /// [tag] filters every section (case-insensitive) before arranging.
  FocusSections focusSections({DateTime? now, String? tag}) {
    var tasks = _tasks;
    if (tag != null) {
      final q = tag.toLowerCase();
      tasks = [
        for (final t in tasks)
          if (t.tags.any((x) => x.toLowerCase() == q)) t,
      ];
    }
    return _arranger.arrange(tasks, now ?? DateTime.now());
  }

  /// Every tag in use, display-cased by first appearance, sorted
  /// alphabetically.
  List<String> get allTags {
    final byLower = <String, String>{};
    for (final t in _tasks) {
      if (t.isCompleted) continue;
      for (final tag in t.tags) {
        byLower.putIfAbsent(tag.toLowerCase(), () => tag);
      }
    }
    return byLower.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  List<Task> get completedTasks =>
      _tasks
          .where((t) => t.isCompleted && t.kind != TaskKind.seriesTemplate)
          .toList()
        ..sort(
          (a, b) => (b.completedAt ?? b.updatedAt).compareTo(
            a.completedAt ?? a.updatedAt,
          ),
        );

  /// Stored tasks plus projected recurring occurrences for [date].
  List<AgendaItem> agendaFor(DateOnly date) {
    final items = <AgendaItem>[
      for (final t in _tasks)
        if (t.kind != TaskKind.seriesTemplate && t.dueDate == date)
          AgendaItem(t),
    ];
    final materialized = items
        .map((i) => (i.task.seriesId, i.task.occurrenceDate))
        .toSet();
    for (final projection in _projectionsInRange(date, date)) {
      if (!materialized.contains((
        projection.task.seriesId,
        projection.task.occurrenceDate,
      ))) {
        items.add(projection);
      }
    }
    items.sort((a, b) {
      final ma = a.task.dueMinutes ?? -1;
      final mb = b.task.dueMinutes ?? -1;
      if (ma != mb) return ma.compareTo(mb);
      return a.task.createdAt.compareTo(b.task.createdAt);
    });
    return items;
  }

  Map<DateOnly, DayMarkers> monthMarkers(int year, int month) {
    final first = DateOnly(year, month, 1);
    final last = first.lastDayOfMonth();
    final byDate = <DateOnly, List<AgendaItem>>{};

    for (final t in _tasks) {
      if (t.kind == TaskKind.seriesTemplate) continue;
      final d = t.dueDate;
      if (d == null || d.isBefore(first) || d.isAfter(last)) continue;
      byDate.putIfAbsent(d, () => []).add(AgendaItem(t));
    }
    for (final projection in _projectionsInRange(first, last)) {
      final d = projection.task.dueDate!;
      final existing = byDate[d] ?? const <AgendaItem>[];
      final dup = existing.any(
        (i) =>
            i.task.seriesId == projection.task.seriesId &&
            i.task.occurrenceDate == projection.task.occurrenceDate,
      );
      if (!dup) byDate.putIfAbsent(d, () => []).add(projection);
    }

    return byDate.map((date, items) {
      final tasks = items.map((i) => i.task).toList();
      return MapEntry(
        date,
        DayMarkers(
          taskCount: tasks.length,
          hasHighPriority: tasks.any(
            (t) => t.priority == TaskPriority.high && !t.isCompleted,
          ),
          hasCompleted: tasks.any((t) => t.isCompleted),
          hasRecurring: tasks.any((t) => t.isRecurring),
          allCompleted: tasks.every((t) => t.isCompleted),
        ),
      );
    });
  }

  /// Projected (not materialized) future occurrences of every live series in
  /// [from]..[to].
  List<AgendaItem> _projectionsInRange(DateOnly from, DateOnly to) {
    final projections = <AgendaItem>[];
    for (final template in _tasks.where(
      (t) => t.kind == TaskKind.seriesTemplate && t.recurrence != null,
    )) {
      final active = _tasks
          .where((t) => t.seriesId == template.id && !t.isCompleted)
          .toList();
      if (active.isEmpty) continue; // ended series projects nothing
      final anchor = active.first;
      final anchorDate = anchor.occurrenceDate ?? anchor.dueDate;
      if (anchorDate == null) continue;
      final dates = engine.projectOccurrences(
        template.recurrence!,
        anchorDate,
        from: from,
        to: to,
        startIndex: anchor.occurrenceIndex,
      );
      for (final date in dates) {
        if (date == anchorDate) continue; // the real row covers this one
        projections.add(
          AgendaItem(
            Task(
              id: 'projection:${template.id}:$date',
              kind: TaskKind.occurrence,
              title: template.title,
              priority: template.priority,
              dueDate: date,
              dueMinutes: template.dueMinutes,
              seriesId: template.id,
              occurrenceDate: date,
              subtasks: template.subtasks,
              createdAt: template.createdAt,
              updatedAt: template.updatedAt,
            ),
            isProjection: true,
          ),
        );
      }
    }
    return projections;
  }

  // ---------------------------------------------------------------------
  // Creation and editing
  // ---------------------------------------------------------------------

  int _nextSortIndex() => _tasks.isEmpty
      ? 0
      : _tasks.map((t) => t.sortIndex).reduce((a, b) => a > b ? a : b) + 1;

  /// Quick-add path. Returns the created task (or the first occurrence when
  /// [recurrence] is set).
  Future<Task> createTask({
    required String title,
    DateOnly? dueDate,
    int? dueMinutes,
    TaskPriority? priority,
    List<ReminderEntry> reminders = const [],
    RecurrenceRule? recurrence,
    String? detailsJson,
    List<Subtask> subtasks = const [],
    AlarmConfig alarm = const AlarmConfig(),
    List<String> tags = const [],
  }) async {
    final now = DateTime.now();
    final task = Task(
      id: _uuid.v4(),
      title: title.trim(),
      detailsJson: detailsJson,
      priority: priority ?? _settingsController.settings.defaultPriority,
      dueDate: dueDate,
      dueMinutes: dueMinutes,
      reminders: reminders,
      alarm: alarm,
      tags: tags,
      subtasks: subtasks,
      createdAt: now,
      updatedAt: now,
      sortIndex: _nextSortIndex(),
    );
    if (recurrence != null && dueDate != null) {
      return _createSeries(task, recurrence);
    }
    _tasks.add(task);
    notifyListeners();
    await _guard(() => _repository.upsert(task));
    await resyncNotifications();
    return task;
  }

  /// Converts [draft] into a series template plus its first occurrence.
  Future<Task> _createSeries(Task draft, RecurrenceRule rule) async {
    final now = DateTime.now();
    final template = draft.copyWith(
      kind: TaskKind.seriesTemplate,
      recurrence: rule,
      updatedAt: now,
    );
    final occurrence = _mutations.materializeOccurrence(
      template,
      draft.dueDate!,
      index: 1,
      now: now,
    );
    _tasks.addAll([template, occurrence]);
    notifyListeners();
    await _guard(() => _repository.upsertAll([template, occurrence]));
    await resyncNotifications();
    return occurrence;
  }

  /// Plain update for non-recurring tasks and "this occurrence only" edits.
  Future<void> updateTask(Task updated) async {
    final task = updated.copyWith(updatedAt: DateTime.now());
    _replace(task);
    notifyListeners();
    await _guard(() => _repository.upsert(task));
    await resyncNotifications();
  }

  /// Changes a task's recurrence structure. Returns the surviving row the
  /// editor should continue editing.
  ///
  /// - plain task + rule: converts it into a series (template + occurrence)
  /// - occurrence + null: detaches it into a plain task and drops the series
  /// - occurrence + rule: updates the series template's rule
  Future<Task> updateSeriesRule(Task task, RecurrenceRule? rule) async {
    final now = DateTime.now();
    final template = templateOf(task);

    if (template == null) {
      if (rule == null || task.dueDate == null) {
        final updated = task.copyWith(clearRecurrence: true, updatedAt: now);
        await updateTask(updated);
        return updated;
      }
      await _deleteRows([task.id]);
      return _createSeries(task.copyWith(updatedAt: now), rule);
    }

    if (rule == null) {
      // Removing the rule ends the series: this occurrence becomes
      // standalone; completed history keeps its rows.
      final standalone = task.copyWith(
        kind: TaskKind.single,
        clearSeriesId: true,
        clearRecurrence: true,
        updatedAt: now,
      );
      _replace(standalone);
      _tasks.removeWhere((t) => t.id == template.id);
      notifyListeners();
      await _guard(() async {
        await _repository.upsert(standalone);
        await _repository.delete(template.id);
      });
      await resyncNotifications();
      return standalone;
    }

    final updatedTemplate = template.copyWith(recurrence: rule, updatedAt: now);
    _replace(updatedTemplate);
    notifyListeners();
    await _guard(() => _repository.upsert(updatedTemplate));
    await resyncNotifications();
    return task;
  }

  /// Propagates an edited occurrence's content to its series per [scope].
  /// The template's recurrence rule is managed by [updateSeriesRule].
  Future<void> applySeriesEdit(Task edited, SeriesEditScope scope) async {
    final now = DateTime.now();
    final template = templateOf(edited);

    if (template == null || scope == SeriesEditScope.thisOccurrence) {
      await updateTask(edited);
      return;
    }

    final updatedTemplate = template.copyWith(
      title: edited.title,
      detailsJson: edited.detailsJson,
      clearDetails: edited.detailsJson == null,
      priority: edited.priority,
      dueDate: edited.dueDate,
      dueMinutes: edited.dueMinutes,
      clearDueMinutes: edited.dueMinutes == null,
      reminders: edited.reminders,
      alarm: edited.alarm,
      tags: List.of(edited.tags),
      subtasks: [
        for (final s in edited.subtasks) s.resetForNewOccurrence(s.id, now),
      ],
      updatedAt: now,
    );
    final updatedOccurrence = edited.copyWith(
      occurrenceDate: edited.dueDate,
      updatedAt: now,
    );
    final upserts = <Task>[updatedTemplate, updatedOccurrence];

    if (scope == SeriesEditScope.entireSeries) {
      for (final t in _tasks) {
        if (t.seriesId == template.id && t.id != edited.id && t.isCompleted) {
          upserts.add(
            t.copyWith(
              title: edited.title,
              priority: edited.priority,
              updatedAt: now,
            ),
          );
        }
      }
    }
    for (final t in upserts) {
      _replace(t);
    }
    notifyListeners();
    await _guard(() => _repository.upsertAll(upserts));
    await resyncNotifications();
  }

  // ---------------------------------------------------------------------
  // Completion / restore / snooze
  // ---------------------------------------------------------------------

  Future<void> completeTask(Task task, {bool completeSubtasks = false}) async {
    final now = DateTime.now();
    final result = _mutations.complete(
      task,
      all: _tasks,
      now: now,
      completeSubtasks: completeSubtasks,
    );
    final beforeIds = _tasks.map((t) => t.id).toSet();
    _lastCompletion = _UndoRecord(
      [task],
      result.upserts
          .where((t) => !beforeIds.contains(t.id))
          .map((t) => t.id)
          .toList(),
    );
    for (final t in result.upserts) {
      _replace(t, addIfMissing: true);
    }
    notifyListeners();
    await _guard(() => _repository.upsertAll(result.upserts));
    await resyncNotifications();
  }

  /// Undoes the most recent completion: restores the task and removes any
  /// occurrence that completion generated.
  Future<void> undoLastCompletion() async {
    final record = _lastCompletion;
    if (record == null) return;
    _lastCompletion = null;
    _tasks.removeWhere((t) => record.createdIds.contains(t.id));
    for (final t in record.before) {
      _replace(t, addIfMissing: true);
    }
    notifyListeners();
    await _guard(() async {
      await _repository.deleteMany(record.createdIds);
      await _repository.upsertAll(record.before);
    });
    await resyncNotifications();
  }

  /// Restore from the Completed screen. Never regenerates series schedules.
  Future<void> restoreTask(Task task) async {
    final result = _mutations.restore(task, DateTime.now());
    for (final t in result.upserts) {
      _replace(t);
    }
    notifyListeners();
    await _guard(() => _repository.upsertAll(result.upserts));
    await resyncNotifications();
  }

  Future<void> snoozeTask(Task task, Duration duration) async {
    final result = _mutations.snooze(task, duration, DateTime.now());
    for (final t in result.upserts) {
      _replace(t);
    }
    notifyListeners();
    await _guard(() => _repository.upsertAll(result.upserts));
    await resyncNotifications();
  }

  /// Accumulates focus-timer time on a task. No notification resync needed —
  /// time spent affects no schedule.
  Future<void> addTimeSpent(String taskId, Duration duration) async {
    final task = taskById(taskId);
    if (task == null) return;
    final updated = task.copyWith(
      timeSpentSeconds: task.timeSpentSeconds + duration.inSeconds,
      updatedAt: DateTime.now(),
    );
    _replace(updated);
    notifyListeners();
    await _guard(() => _repository.upsert(updated));
  }

  /// "Not today": moves the deadline to [date] and counts the deferral for
  /// escalation.
  Future<void> deferTask(Task task, DateOnly date) async {
    final result = _mutations.defer(task, date, DateTime.now());
    for (final t in result.upserts) {
      _replace(t);
    }
    notifyListeners();
    await _guard(() => _repository.upsertAll(result.upserts));
    await resyncNotifications();
  }

  Future<void> toggleSubtask(Task task, Subtask subtask) async {
    final now = DateTime.now();
    final updated = task.copyWith(
      subtasks: [
        for (final s in task.subtasks)
          s.id == subtask.id
              ? s.copyWith(
                  isCompleted: !s.isCompleted,
                  completedAt: s.isCompleted ? null : now,
                  clearCompletedAt: s.isCompleted,
                )
              : s,
      ],
      updatedAt: now,
    );
    _replace(updated);
    notifyListeners();
    await _guard(() => _repository.upsert(updated));
  }

  // ---------------------------------------------------------------------
  // Deletion
  // ---------------------------------------------------------------------

  Future<void> deleteTask(Task task) async {
    if (task.kind == TaskKind.occurrence && task.seriesId != null) {
      await deleteOccurrence(task, SeriesEditScope.thisOccurrence);
      return;
    }
    await _deleteRows([task.id]);
  }

  Future<void> deleteOccurrence(Task task, SeriesEditScope scope) async {
    final template = templateOf(task);
    if (template == null || template.recurrence == null) {
      await _deleteRows([task.id]);
      return;
    }
    final now = DateTime.now();
    switch (scope) {
      case SeriesEditScope.thisOccurrence:
        // Skip this date but keep the series alive: materialize the next
        // occurrence (only when deleting the active one).
        final upserts = <Task>[];
        if (!task.isCompleted) {
          final current = task.occurrenceDate ?? task.dueDate;
          final next = current == null
              ? null
              : engine.nextOccurrence(
                  template.recurrence!,
                  current,
                  completedOn: DateOnly.fromDateTime(now),
                  nextIndex: task.occurrenceIndex + 1,
                );
          if (next != null) {
            upserts.add(
              _mutations.materializeOccurrence(
                template,
                next,
                index: task.occurrenceIndex + 1,
                now: now,
              ),
            );
          }
        }
        _tasks.removeWhere((t) => t.id == task.id);
        _tasks.addAll(upserts);
        notifyListeners();
        await _guard(() async {
          await _repository.delete(task.id);
          if (upserts.isNotEmpty) await _repository.upsertAll(upserts);
        });
        await resyncNotifications();

      case SeriesEditScope.thisAndFuture:
        // End the series just before this occurrence; history stays.
        final cutoff = (task.occurrenceDate ?? task.dueDate)?.addDays(-1);
        final endedTemplate = template.copyWith(
          recurrence: template.recurrence!.copyWith(endDate: cutoff),
          updatedAt: now,
        );
        _replace(endedTemplate);
        _tasks.removeWhere((t) => t.id == task.id);
        notifyListeners();
        await _guard(() async {
          await _repository.upsert(endedTemplate);
          await _repository.delete(task.id);
        });
        await resyncNotifications();

      case SeriesEditScope.entireSeries:
        final ids = _tasks
            .where((t) => t.id == template.id || t.seriesId == template.id)
            .map((t) => t.id)
            .toList();
        await _deleteRows(ids);
    }
  }

  /// Explicit "End recurring series": stops future occurrences, removes the
  /// current active one, preserves completed history.
  Future<void> endSeries(Task anyOfSeries) async {
    final template = anyOfSeries.kind == TaskKind.seriesTemplate
        ? anyOfSeries
        : templateOf(anyOfSeries);
    if (template == null || template.recurrence == null) return;
    final now = DateTime.now();
    final endedTemplate = template.copyWith(
      recurrence: template.recurrence!.copyWith(
        endDate: DateOnly.fromDateTime(now).addDays(-1),
      ),
      updatedAt: now,
    );
    final activeIds = _tasks
        .where((t) => t.seriesId == template.id && !t.isCompleted)
        .map((t) => t.id)
        .toList();
    _replace(endedTemplate);
    _tasks.removeWhere((t) => activeIds.contains(t.id));
    notifyListeners();
    await _guard(() async {
      await _repository.upsert(endedTemplate);
      await _repository.deleteMany(activeIds);
    });
    await resyncNotifications();
  }

  Future<void> deleteCompletedTask(Task task) => _deleteRows([task.id]);

  /// "Clear completed" for non-recurring tasks.
  Future<void> clearCompletedNonRecurring() async {
    final ids = _tasks
        .where(
          (t) =>
              t.isCompleted && t.kind == TaskKind.single && t.seriesId == null,
        )
        .map((t) => t.id)
        .toList();
    await _deleteRows(ids);
  }

  Future<void> deleteAllData() async {
    _tasks = [];
    _lastCompletion = null;
    notifyListeners();
    await _guard(() => _repository.deleteAll());
    await _notifications.cancelAll();
    await _settingsController.resetForDataWipe();
  }

  Future<void> _deleteRows(List<String> ids) async {
    if (ids.isEmpty) return;
    _tasks.removeWhere((t) => ids.contains(t.id));
    notifyListeners();
    await _guard(() => _repository.deleteMany(ids));
    await resyncNotifications();
  }

  // ---------------------------------------------------------------------
  // Import / export
  // ---------------------------------------------------------------------

  String exportJson() => const TaskJsonCodec().encode(_tasks);

  /// Replaces all current data with the backup contents. Throws
  /// [FormatException] with a user-safe message when the file is invalid.
  Future<int> importJson(String raw) async {
    final imported = const TaskJsonCodec().decode(raw);
    _tasks = imported;
    _lastCompletion = null;
    notifyListeners();
    await _guard(() async {
      await _repository.deleteAll();
      await _repository.upsertAll(imported);
    });
    await _ensureActiveOccurrences(DateTime.now());
    notifyListeners();
    await resyncNotifications();
    return imported.where((t) => t.kind != TaskKind.seriesTemplate).length;
  }

  // ---------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------

  Future<void> resyncNotifications() async {
    if (!_settingsController.notificationsUsable) return;
    final settings = _settingsController.settings;
    final planner = NotificationPlanner(
      quietHours: settings.quietHours,
      dateOnlyReminderMinutes: settings.dateOnlyReminderMinutes,
    );
    final plan = planner.plan(_tasks, DateTime.now());
    // Global sound/vibration preferences gate every notification.
    final gated = [
      for (final p in plan)
        PlannedNotification(
          id: p.id,
          taskId: p.taskId,
          fireAt: p.fireAt,
          kind: p.kind,
          title: p.title,
          body: p.body,
          sound: p.sound && settings.soundEnabled,
          vibration: p.vibration && settings.vibrationEnabled,
        ),
    ];
    // Displayed notifications stay in the shade while their task is still
    // waiting; completed, deleted or snoozed tasks get theirs dismissed.
    final stillWaiting = {
      for (final t in _tasks)
        if (!t.isCompleted && t.kind != TaskKind.seriesTemplate && !t.isSnoozed)
          t.id,
    };
    try {
      _lastScheduleResult = await _notifications.syncPlan(
        gated,
        keepDisplayedForTaskIds: stillWaiting,
      );
    } catch (_) {
      _lastScheduleResult = const ScheduleResult(
        scheduled: 0,
        failed: 1,
        exactDeliveryAvailable: false,
      );
    }
    notifyListeners();
  }

  Future<void> notificationsServiceOpenSettings() =>
      _notifications.openSystemNotificationSettings();

  Future<void> showTestNotification() => _notifications.showTestNotification();

  Future<void> handleNotificationAction(NotificationAction action) async {
    final task = taskById(action.taskId);
    switch (action.kind) {
      case NotificationActionKind.open:
        openTaskRequest.value = action.taskId;
      case NotificationActionKind.complete:
        if (task != null && !task.isCompleted) {
          await completeTask(task, completeSubtasks: true);
        }
      case NotificationActionKind.snooze:
        if (task != null && !task.isCompleted) {
          await snoozeTask(task, const Duration(minutes: 15));
        }
    }
  }

  // ---------------------------------------------------------------------
  // Sample content
  // ---------------------------------------------------------------------

  /// First launch only. Deleted samples never come back because the
  /// first-launch flag is permanent.
  Future<void> addSampleTasks() async {
    final now = DateTime.now();
    final today = DateOnly.fromDateTime(now);
    Subtask sub(String title, int index) =>
        Subtask(id: _uuid.v4(), title: title, sortIndex: index, createdAt: now);

    await createTask(
      title: 'Submit project proposal',
      priority: TaskPriority.high,
      dueDate: today,
      subtasks: [
        sub('Draft summary section', 0),
        sub('Attach budget estimate', 1),
      ],
    );
    await createTask(
      title: 'Book dentist appointment',
      priority: TaskPriority.medium,
      dueDate: today.addDays(1),
      reminders: const [ReminderEntry.atDeadline()],
    );
    await createTask(
      title: 'Review monthly expenses',
      dueDate: today,
      recurrence: RecurrenceRule.monthly(dayOfMonth: today.day),
      subtasks: [
        sub('Export card statement', 0),
        sub('Check subscriptions', 1),
        sub('Update budget sheet', 2),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  void _replace(Task task, {bool addIfMissing = true}) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      _tasks[index] = task;
    } else if (addIfMissing) {
      _tasks.add(task);
    }
  }

  Future<void> _guard(Future<void> Function() write) async {
    try {
      await write();
      _storageError = false;
    } catch (_) {
      _storageError = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _settingsController.removeListener(_onSettingsChanged);
    openTaskRequest.dispose();
    super.dispose();
  }
}
