import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/formats.dart';
import '../../domain/models/date_only.dart';
import '../../domain/models/task.dart';
import '../../services/notification_service.dart';
import '../../state/app_state.dart';
import '../../state/settings_controller.dart';
import 'common.dart';

/// Shared interaction flows used by Focus, Calendar and the editor so
/// completion, snoozing, deletion and the permission prompt behave
/// identically everywhere.

Future<void> completeTaskFlow(
  BuildContext context,
  AppState state,
  Task task,
) async {
  if (task.isCompleted) {
    await state.restoreTask(task);
    return;
  }

  var completeSubtasks = false;
  final incomplete = task.subtasks.where((s) => !s.isCompleted).length;
  if (incomplete > 0) {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Incomplete subtasks'),
        content: const Text(
          'This task still has incomplete subtasks. Complete everything?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'parent'),
            child: Text(
              'Only this task',
              style: TextStyle(color: context.colors.textPrimary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'all'),
            child: const Text('Complete everything'),
          ),
        ],
      ),
    );
    if (choice == null) return;
    completeSubtasks = choice == 'all';
  }

  await state.completeTask(task, completeSubtasks: completeSubtasks);
  if (context.mounted) {
    showAppSnackBar(
      context,
      'Completed "${task.title}"',
      actionLabel: 'Undo',
      onAction: state.undoLastCompletion,
    );
  }
}

Future<void> snoozeFlow(BuildContext context, AppState state, Task task) async {
  final duration = await showModalBottomSheet<Duration>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Snooze reminders',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          for (final (label, minutes) in [
            ('5 minutes', 5),
            ('15 minutes', 15),
            ('30 minutes', 30),
            ('1 hour', 60),
          ])
            ListTile(
              leading: const Icon(Icons.snooze),
              title: Text(label),
              onTap: () => Navigator.pop(context, Duration(minutes: minutes)),
            ),
          ListTile(
            leading: const Icon(Icons.more_time),
            title: const Text('Custom…'),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(
                  DateTime.now().add(const Duration(hours: 1)),
                ),
                helpText: 'Snooze until',
              );
              if (time != null && context.mounted) {
                final now = DateTime.now();
                var target = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  time.hour,
                  time.minute,
                );
                if (!target.isAfter(now)) {
                  target = target.add(const Duration(days: 1));
                }
                Navigator.pop(context, target.difference(now));
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (duration == null) return;
  await state.snoozeTask(task, duration);
  if (context.mounted) {
    final until = DateTime.now().add(duration);
    showAppSnackBar(context, 'Snoozed until ${Formats.timeOf(until)}');
  }
}

/// "Not today": moves the deadline instead of letting the task rot in the
/// overdue section (or forcing a dishonest completion). Counts as a deferral
/// so a repeatedly pushed task escalates.
Future<void> deferFlow(BuildContext context, AppState state, Task task) async {
  final today = DateOnly.today();
  final tomorrow = today.addDays(1);
  final nextWeek = today.addDays(7);

  final picked = await showModalBottomSheet<DateOnly>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Move deadline',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.wb_sunny_outlined),
            title: const Text('Tomorrow'),
            onTap: () => Navigator.pop(context, tomorrow),
          ),
          ListTile(
            leading: const Icon(Icons.next_week_outlined),
            title: Text('Next week (${Formats.relativeDate(nextWeek)})'),
            onTap: () => Navigator.pop(context, nextWeek),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('Pick a date…'),
            onTap: () async {
              final now = DateTime.now();
              final date = await showDatePicker(
                context: context,
                initialDate: tomorrow.toDateTime(),
                firstDate: now,
                lastDate: now.add(const Duration(days: 365 * 5)),
              );
              if (context.mounted) {
                Navigator.pop(
                  context,
                  date == null ? null : DateOnly.fromDateTime(date),
                );
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (picked == null) return;
  await state.deferTask(task, picked);
  if (context.mounted) {
    showAppSnackBar(context, 'Moved to ${Formats.relativeDate(picked)}');
  }
}

/// The opt-in permission flow: explains why before showing the OS dialog,
/// and explains what to do when the OS permission is denied. Returns true
/// when notifications are usable.
Future<bool> ensureNotificationPermission(BuildContext context) async {
  final settings = context.read<SettingsController>();
  final appState = context.read<AppState>();
  await settings.refreshPermissionState();
  if (settings.permission == NotificationPermission.granted) return true;
  if (!context.mounted) return false;

  if (settings.permission == NotificationPermission.notRequested) {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable reminders'),
        content: const Text(
          'Allow Nudge to remind you about tasks and habits, even when the '
          'app is not open.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Not now',
              style: TextStyle(color: context.colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (proceed != true) return false;
    final result = await settings.requestPermission();
    if (result == NotificationPermission.granted) return true;
  }

  if (context.mounted) {
    showAppSnackBar(
      context,
      'Device notifications are disabled. Your reminder is saved and will '
      'show inside the app; enable notifications in system settings to get '
      'alerts.',
      actionLabel: 'Settings',
      onAction: appState.notificationsServiceOpenSettings,
    );
  }
  return false;
}

Future<void> deleteTaskFlow(
  BuildContext context,
  AppState state,
  Task task,
) async {
  if (task.kind == TaskKind.occurrence && state.templateOf(task) != null) {
    final scope = await showSeriesScopeSheet(
      context,
      title: 'Delete recurring task',
      thisLabel: 'Delete this occurrence',
      futureLabel: 'Delete this and future occurrences',
      allLabel: 'Delete entire series',
    );
    if (scope == null) return;
    await state.deleteOccurrence(task, scope);
    if (context.mounted) showAppSnackBar(context, 'Deleted "${task.title}"');
    return;
  }
  final confirmed = await confirmDialog(
    context,
    title: 'Delete task?',
    message: '"${task.title}" will be permanently deleted.',
  );
  if (!confirmed) return;
  await state.deleteTask(task);
  if (context.mounted) showAppSnackBar(context, 'Deleted "${task.title}"');
}

Future<SeriesEditScope?> showSeriesScopeSheet(
  BuildContext context, {
  required String title,
  String thisLabel = 'This occurrence only',
  String futureLabel = 'This and future occurrences',
  String allLabel = 'Entire series',
  bool allowThisOnly = true,
}) {
  return showModalBottomSheet<SeriesEditScope>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (allowThisOnly)
            ListTile(
              leading: const Icon(Icons.looks_one_outlined),
              title: Text(thisLabel),
              onTap: () =>
                  Navigator.pop(context, SeriesEditScope.thisOccurrence),
            ),
          ListTile(
            leading: const Icon(Icons.fast_forward_outlined),
            title: Text(futureLabel),
            onTap: () => Navigator.pop(context, SeriesEditScope.thisAndFuture),
          ),
          ListTile(
            leading: const Icon(Icons.all_inclusive),
            title: Text(allLabel),
            onTap: () => Navigator.pop(context, SeriesEditScope.entireSeries),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
