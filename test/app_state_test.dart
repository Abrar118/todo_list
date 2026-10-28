import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/domain/models/swatch.dart';
import 'package:todo_list/data/app_settings.dart';
import 'package:todo_list/domain/logic/notification_planner.dart';
import 'package:todo_list/domain/logic/quiet_hours.dart';
import 'package:todo_list/domain/models/date_only.dart';
import 'package:todo_list/domain/models/priority.dart';
import 'package:todo_list/domain/models/recurrence.dart';
import 'package:todo_list/domain/models/reminders.dart';
import 'package:todo_list/domain/models/task.dart';
import 'package:todo_list/services/notification_service.dart';
import 'package:todo_list/state/app_state.dart';
import 'package:todo_list/state/settings_controller.dart';

import 'helpers/fakes.dart';

void main() {
  late InMemoryTaskRepository repo;
  late FakeNotificationService notifications;
  late InMemorySettingsRepository settingsRepo;
  late SettingsController settings;
  late AppState state;

  setUp(() async {
    repo = InMemoryTaskRepository();
    notifications = FakeNotificationService();
    settingsRepo = InMemorySettingsRepository();
    settings = SettingsController(settingsRepo, notifications);
    settingsRepo.permissionRequested = true;
    await settings.load();
    state = AppState(repo, notifications, settings);
    await state.init();
  });

  final today = DateOnly.today();

  group('task creation', () {
    test('creates and persists a task', () async {
      final task = await state.createTask(
        title: 'Buy milk',
        dueDate: today,
        priority: TaskPriority.medium,
      );
      expect(state.allTasks.single.id, task.id);
      expect(repo.store[task.id]!.title, 'Buy milk');
      expect(repo.store[task.id]!.priority, TaskPriority.medium);
    });

    test('uses the default priority from settings', () async {
      await settings.update(
        settings.settings.copyWith(defaultPriority: TaskPriority.high),
      );
      final task = await state.createTask(title: 'x');
      expect(task.priority, TaskPriority.high);
    });

    test('creating with recurrence builds template plus occurrence', () async {
      final occurrence = await state.createTask(
        title: 'Water plants',
        dueDate: today,
        recurrence: RecurrenceRule.daily(),
      );
      expect(occurrence.kind, TaskKind.occurrence);
      final template = state.templateOf(occurrence);
      expect(template, isNotNull);
      expect(template!.recurrence!.frequency, RecurrenceFrequency.daily);
      expect(repo.store.length, 2);
    });
  });

  group('editing', () {
    test('updateTask persists edits', () async {
      final task = await state.createTask(title: 'Old');
      await state.updateTask(task.copyWith(title: 'New'));
      expect(repo.store[task.id]!.title, 'New');
    });

    test('editing one occurrence only leaves the series untouched', () async {
      final occ = await state.createTask(
        title: 'Series',
        dueDate: today,
        recurrence: RecurrenceRule.daily(),
      );
      await state.applySeriesEdit(
        occ.copyWith(title: 'Edited once'),
        SeriesEditScope.thisOccurrence,
      );
      expect(state.taskById(occ.id)!.title, 'Edited once');
      expect(state.templateOf(occ)!.title, 'Series');
    });

    test('editing this-and-future updates the template', () async {
      final occ = await state.createTask(
        title: 'Series',
        dueDate: today,
        recurrence: RecurrenceRule.daily(),
      );
      await state.applySeriesEdit(
        occ.copyWith(
          title: 'New name',
          priority: TaskPriority.high,
          background: Swatch.mist,
        ),
        SeriesEditScope.thisAndFuture,
      );
      final template = state.templateOf(occ)!;
      expect(template.title, 'New name');
      expect(template.priority, TaskPriority.high);
      expect(template.background, Swatch.mist);
      // Next occurrence inherits the edit.
      await state.completeTask(state.taskById(occ.id)!);
      final next = state.allTasks.firstWhere(
        (t) => t.kind == TaskKind.occurrence && !t.isCompleted,
      );
      expect(next.title, 'New name');
      expect(next.background, Swatch.mist);
    });

    test('entire-series edit rewrites completed history titles', () async {
      final occ = await state.createTask(
        title: 'Series',
        dueDate: today,
        recurrence: RecurrenceRule.daily(),
      );
      await state.completeTask(state.taskById(occ.id)!);
      final active = state.allTasks.firstWhere(
        (t) => t.kind == TaskKind.occurrence && !t.isCompleted,
      );
      await state.applySeriesEdit(
        active.copyWith(title: 'Renamed'),
        SeriesEditScope.entireSeries,
      );
      final history = state.taskById(occ.id)!;
      expect(history.isCompleted, isTrue);
      expect(history.title, 'Renamed');
    });

    test('updateSeriesRule converts a plain task into a series', () async {
      final task = await state.createTask(title: 'Plain', dueDate: today);
      final occurrence = await state.updateSeriesRule(
        task,
        RecurrenceRule.weekly(),
      );
      expect(occurrence.kind, TaskKind.occurrence);
      // The plain row becomes the series template; a fresh occurrence row
      // carries the visible task.
      expect(state.taskById(task.id)!.kind, TaskKind.seriesTemplate);
      expect(
        state.templateOf(occurrence)!.recurrence!.frequency,
        RecurrenceFrequency.weekly,
      );
    });

    test('updateSeriesRule with null detaches the occurrence', () async {
      final occ = await state.createTask(
        title: 'Series',
        dueDate: today,
        recurrence: RecurrenceRule.daily(),
      );
      final standalone = await state.updateSeriesRule(occ, null);
      expect(standalone.kind, TaskKind.single);
      expect(standalone.seriesId, isNull);
      expect(
        state.allTasks.any((t) => t.kind == TaskKind.seriesTemplate),
        isFalse,
      );
    });
  });

  group('completion', () {
    test(
      'completing cancels reminders and schedules the next occurrence',
      () async {
        final occ = await state.createTask(
          title: 'Daily',
          dueDate: today,
          dueMinutes: 23 * 60 + 59,
          reminders: const [ReminderEntry.atDeadline()],
          recurrence: RecurrenceRule.daily(),
        );
        await state.completeTask(occ);
        final completed = state.taskById(occ.id)!;
        expect(completed.isCompleted, isTrue);
        final next = state.allTasks.firstWhere(
          (t) => t.kind == TaskKind.occurrence && !t.isCompleted,
        );
        expect(next.dueDate, today.addDays(1));
        // Plan no longer contains the completed occurrence.
        expect(notifications.lastPlan.every((p) => p.taskId != occ.id), isTrue);
        expect(notifications.lastPlan.any((p) => p.taskId == next.id), isTrue);
      },
    );

    test(
      'undo restores the task and removes the generated occurrence',
      () async {
        final occ = await state.createTask(
          title: 'Daily',
          dueDate: today,
          recurrence: RecurrenceRule.daily(),
        );
        await state.completeTask(occ);
        expect(state.allTasks.whereType<Task>().length, 3);
        await state.undoLastCompletion();
        expect(state.taskById(occ.id)!.isCompleted, isFalse);
        final occurrences = state.allTasks.where(
          (t) => t.kind == TaskKind.occurrence,
        );
        expect(occurrences.length, 1);
        expect(repo.store.length, 2);
      },
    );

    test(
      'restoring a completed occurrence never duplicates the series',
      () async {
        final occ = await state.createTask(
          title: 'Daily',
          dueDate: today,
          recurrence: RecurrenceRule.daily(),
        );
        await state.completeTask(occ);
        await state.restoreTask(state.taskById(occ.id)!);
        // Restored + the already-generated next one; no new template, no third.
        expect(
          state.allTasks.where((t) => t.kind == TaskKind.occurrence).length,
          2,
        );
        expect(
          state.allTasks.where((t) => t.kind == TaskKind.seriesTemplate).length,
          1,
        );
      },
    );

    test('snooze updates the plan', () async {
      final task = await state.createTask(
        title: 'Soon',
        dueDate: today,
        dueMinutes: 23 * 60 + 59,
        reminders: const [ReminderEntry.atDeadline()],
      );
      await state.snoozeTask(task, const Duration(minutes: 15));
      final snoozed = state.taskById(task.id)!;
      expect(snoozed.snoozedUntil, isNotNull);
      expect(
        notifications.lastPlan.any((p) => p.kind == PlannedKind.snooze),
        isTrue,
      );
    });
  });

  group('deletion', () {
    test('deleting one occurrence materializes the next', () async {
      final occ = await state.createTask(
        title: 'Daily',
        dueDate: today,
        recurrence: RecurrenceRule.daily(),
      );
      await state.deleteOccurrence(occ, SeriesEditScope.thisOccurrence);
      expect(state.taskById(occ.id), isNull);
      final next = state.allTasks.firstWhere(
        (t) => t.kind == TaskKind.occurrence && !t.isCompleted,
      );
      expect(next.dueDate, today.addDays(1));
    });

    test(
      'deleting this-and-future ends the series but keeps history',
      () async {
        final occ = await state.createTask(
          title: 'Daily',
          dueDate: today,
          recurrence: RecurrenceRule.daily(),
        );
        await state.completeTask(occ); // history row + next active
        final active = state.allTasks.firstWhere(
          (t) => t.kind == TaskKind.occurrence && !t.isCompleted,
        );
        await state.deleteOccurrence(active, SeriesEditScope.thisAndFuture);
        expect(state.taskById(active.id), isNull);
        expect(state.taskById(occ.id)!.isCompleted, isTrue); // history kept
        final template = state.allTasks.firstWhere(
          (t) => t.kind == TaskKind.seriesTemplate,
        );
        expect(template.recurrence!.endDate, isNotNull);
      },
    );

    test(
      'deleting the entire series removes template and occurrences',
      () async {
        final occ = await state.createTask(
          title: 'Daily',
          dueDate: today,
          recurrence: RecurrenceRule.daily(),
        );
        await state.completeTask(occ);
        final active = state.allTasks.firstWhere(
          (t) => t.kind == TaskKind.occurrence && !t.isCompleted,
        );
        await state.deleteOccurrence(active, SeriesEditScope.entireSeries);
        expect(state.allTasks, isEmpty);
        expect(repo.store, isEmpty);
      },
    );

    test('endSeries stops future occurrences, keeps history', () async {
      final occ = await state.createTask(
        title: 'Daily',
        dueDate: today,
        recurrence: RecurrenceRule.daily(),
      );
      await state.completeTask(occ);
      await state.endSeries(state.taskById(occ.id)!);
      expect(
        state.allTasks.where(
          (t) => !t.isCompleted && t.kind == TaskKind.occurrence,
        ),
        isEmpty,
      );
      expect(state.taskById(occ.id)!.isCompleted, isTrue);
    });

    test('deleteAllData wipes tasks and cancels notifications', () async {
      await state.createTask(title: 'a', dueDate: today);
      await state.deleteAllData();
      expect(state.allTasks, isEmpty);
      expect(repo.store, isEmpty);
      expect(notifications.cancelAllCount, greaterThan(0));
    });
  });

  group('calendar', () {
    test('agenda groups stored tasks by date', () async {
      await state.createTask(title: 'today', dueDate: today);
      await state.createTask(title: 'tomorrow', dueDate: today.addDays(1));
      expect(state.agendaFor(today).map((i) => i.task.title), ['today']);
      expect(state.agendaFor(today.addDays(1)).map((i) => i.task.title), [
        'tomorrow',
      ]);
    });

    test('future recurring occurrences appear as projections', () async {
      await state.createTask(
        title: 'Daily',
        dueDate: today,
        recurrence: RecurrenceRule.daily(),
      );
      final agenda = state.agendaFor(today.addDays(3));
      expect(agenda.single.isProjection, isTrue);
      expect(agenda.single.task.title, 'Daily');
    });

    test(
      'month markers aggregate priority/recurring/completed flags',
      () async {
        await state.createTask(
          title: 'High',
          dueDate: today,
          priority: TaskPriority.high,
        );
        final done = await state.createTask(title: 'Done', dueDate: today);
        await state.completeTask(done);
        final markers = state.monthMarkers(today.year, today.month);
        final m = markers[today]!;
        expect(m.taskCount, 2);
        expect(m.hasHighPriority, isTrue);
        expect(m.hasCompleted, isTrue);
        expect(m.allCompleted, isFalse);
      },
    );
  });

  group('import/export', () {
    test(
      'round-trips through JSON and regenerates active occurrences',
      () async {
        await state.createTask(
          title: 'Daily',
          dueDate: today,
          recurrence: RecurrenceRule.daily(),
        );
        await state.createTask(title: 'Plain', dueDate: today);
        final exported = state.exportJson();

        await state.deleteAllData();
        expect(state.allTasks, isEmpty);

        final count = await state.importJson(exported);
        expect(count, 2);
        expect(state.allTasks.length, 3); // template + occurrence + plain
      },
    );

    test('rejects invalid imports without clearing existing data', () async {
      await state.createTask(title: 'Keep me');
      await expectLater(state.importJson('garbage'), throwsFormatException);
      expect(state.allTasks.single.title, 'Keep me');
    });
  });

  group('notifications', () {
    test('sync skips when permission is missing', () async {
      notifications.permission = NotificationPermission.denied;
      await settings.refreshPermissionState();
      final before = notifications.syncCount;
      await state.createTask(
        title: 'x',
        dueDate: today,
        reminders: const [ReminderEntry.atDeadline()],
      );
      expect(notifications.syncCount, before);
    });

    test('quiet-hours settings change triggers a replan', () async {
      await state.createTask(
        title: 'Late task',
        dueDate: today.addDays(1),
        dueMinutes: 23 * 60 + 30,
        reminders: const [ReminderEntry.atDeadline()],
      );
      final unshifted = notifications.lastPlan.single.fireAt;
      expect(unshifted.hour, 23);

      await settings.update(
        settings.settings.copyWith(quietHours: const QuietHours(enabled: true)),
      );
      await pumpEventQueue();
      final shifted = notifications.lastPlan.single.fireAt;
      expect(shifted.hour, 7);
    });

    test('complete action from a notification', () async {
      final task = await state.createTask(title: 'Do it', dueDate: today);
      await state.handleNotificationAction(
        NotificationAction(NotificationActionKind.complete, task.id),
      );
      expect(state.taskById(task.id)!.isCompleted, isTrue);
    });

    test('action referencing a deleted task is ignored', () async {
      await state.handleNotificationAction(
        const NotificationAction(NotificationActionKind.complete, 'ghost'),
      );
      expect(state.allTasks, isEmpty);
    });

    test('open action publishes the task id for navigation', () async {
      final task = await state.createTask(title: 'Open me');
      await state.handleNotificationAction(
        NotificationAction(NotificationActionKind.open, task.id),
      );
      expect(state.openTaskRequest.value, task.id);
    });
  });

  group('storage failures', () {
    test('write failure surfaces the storage error flag', () async {
      repo.failWrites = true;
      await state.createTask(title: 'x');
      expect(state.hasStorageError, isTrue);
      repo.failWrites = false;
      await state.createTask(title: 'y');
      expect(state.hasStorageError, isFalse);
    });
  });

  group('sample content', () {
    test('adds the three sample tasks once', () async {
      await state.addSampleTasks();
      final titles = state.allTasks
          .where((t) => t.kind != TaskKind.seriesTemplate)
          .map((t) => t.title)
          .toSet();
      expect(titles, {
        'Submit project proposal',
        'Book dentist appointment',
        'Review monthly expenses',
      });
      final proposal = state.allTasks.firstWhere(
        (t) => t.title == 'Submit project proposal',
      );
      expect(proposal.priority, TaskPriority.high);
      expect(proposal.subtasks.length, 2);
      final expenses = state.allTasks.firstWhere(
        (t) =>
            t.title == 'Review monthly expenses' &&
            t.kind == TaskKind.occurrence,
      );
      expect(
        state.templateOf(expenses)!.recurrence!.frequency,
        RecurrenceFrequency.monthly,
      );
      expect(expenses.subtasks.length, 3);
    });
  });

  group('retention', () {
    test('old completed tasks are pruned on maintenance', () async {
      final task = await state.createTask(title: 'Old done');
      await state.completeTask(task);
      // Backdate the completion far beyond the retention window.
      final aged = state
          .taskById(task.id)!
          .copyWith(
            completedAt: DateTime.now().subtract(const Duration(days: 40)),
          );
      await repo.upsert(aged);
      await settings.update(
        settings.settings.copyWith(
          completedRetention: CompletedRetention.thirtyDays,
        ),
      );

      final fresh = AppState(repo, notifications, settings);
      await fresh.init();
      expect(fresh.taskById(task.id), isNull);
      fresh.dispose();
    });
  });

  tearDown(() => state.dispose());
}
