import 'package:uuid/uuid.dart';

import '../data/app_database.dart';
import '../data/settings_repository.dart';
import '../data/task_repository.dart';
import '../domain/logic/notification_planner.dart';
import '../domain/logic/recurrence_engine.dart';
import '../domain/logic/task_mutations.dart';
import '../domain/models/task.dart';
import 'home_widget_service.dart';
import 'local_notification_service.dart';

/// Completes or snoozes a task while the app UI is not running — shared by
/// the notification-action isolate and the widget-button isolate. Bootstraps
/// its own database access, applies the same [TaskMutations] the app uses,
/// then re-syncs the notification plan and refreshes the home-screen widgets.
Future<void> applyHeadlessAction(
  String taskId, {
  required bool complete,
  Duration snoozeDuration = const Duration(minutes: 15),
}) async {
  final db = await AppDatabase.open();
  final repo = SqfliteTaskRepository(db);
  final all = await repo.loadAll();
  final task = all.where((t) => t.id == taskId).firstOrNull;
  // Action referencing a deleted or already-completed task: nothing to do.
  if (task == null || task.isCompleted) return;

  const uuid = Uuid();
  final mutations = TaskMutations(
    engine: const RecurrenceEngine(),
    newId: uuid.v4,
  );
  final now = DateTime.now();
  final result = complete
      ? mutations.complete(task, all: all, now: now, completeSubtasks: true)
      : mutations.snooze(task, snoozeDuration, now);
  await repo.upsertAll(result.upserts);

  // Re-sync schedules so stale reminders for the handled task disappear.
  final updated = await repo.loadAll();
  final settings = await PrefsSettingsRepository().load();
  final planner = NotificationPlanner(
    quietHours: settings.quietHours,
    dateOnlyReminderMinutes: settings.dateOnlyReminderMinutes,
  );
  final service = LocalNotificationService();
  await service.init();
  final stillWaiting = {
    for (final t in updated)
      if (!t.isCompleted &&
          t.kind != TaskKind.seriesTemplate &&
          !(t.snoozedUntil?.isAfter(now) ?? false))
        t.id,
  };
  await service.syncPlan(
    planner.plan(updated, now),
    keepDisplayedForTaskIds: stillWaiting,
  );

  try {
    await HomeWidgetService.pushSnapshot(updated);
  } catch (_) {
    // Widget refresh is best-effort.
  }
}
