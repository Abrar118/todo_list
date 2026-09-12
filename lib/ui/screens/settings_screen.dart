import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_colors.dart';
import '../../core/formats.dart';
import '../../data/app_settings.dart';
import '../../data/ics_codec.dart';
import '../../domain/models/priority.dart';
import '../../domain/models/recurrence.dart';
import '../../services/home_widget_service.dart';
import '../../services/notification_service.dart';
import '../../state/app_state.dart';
import '../../state/habit_controller.dart';
import '../../state/settings_controller.dart';
import '../widgets/common.dart';
import '../widgets/task_flows.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final state = context.watch<AppState>();
    final settings = controller.settings;

    Future<void> save(AppSettings updated) => controller.update(updated);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            const SectionHeader('Notifications'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      controller.notificationsUsable
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_off_outlined,
                      color: controller.notificationsUsable
                          ? context.colors.done
                          : context.colors.medium,
                    ),
                    title: const Text('Notification permission'),
                    subtitle: Text(
                      switch (controller.permission) {
                        NotificationPermission.granted => 'Allowed',
                        NotificationPermission.denied =>
                          'Disabled — reminders show only inside the app',
                        NotificationPermission.notRequested =>
                          'Not requested yet',
                      },
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.colors.textMuted,
                      ),
                    ),
                    onTap: () => ensureNotificationPermission(context),
                  ),
                  if (controller.notificationsUsable &&
                      !controller.exactDeliveryAvailable)
                    ListTile(
                      leading: Icon(
                        Icons.info_outline,
                        color: context.colors.medium,
                      ),
                      title: Text('Exact delivery unavailable'),
                      subtitle: Text(
                        'Device power-management settings may delay reminders '
                        'slightly.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: context.colors.textMuted,
                        ),
                      ),
                    ),
                  ListTile(
                    leading: const Icon(Icons.open_in_new),
                    title: const Text('Open system notification settings'),
                    onTap: state.notificationsServiceOpenSettings,
                  ),
                  ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: const Text('Default reminder timing'),
                    subtitle: Text(
                      _offsetLabel(settings.defaultReminderOffsetMinutes),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.colors.textMuted,
                      ),
                    ),
                    onTap: () async {
                      final value = await _pickOffset(
                        context,
                        settings.defaultReminderOffsetMinutes,
                      );
                      if (value != null) {
                        await save(
                          settings.copyWith(
                            defaultReminderOffsetMinutes: value,
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.wb_sunny_outlined),
                    title: const Text('Reminder time for date-only tasks'),
                    subtitle: Text(
                      Formats.time(settings.dateOnlyReminderMinutes),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.colors.textMuted,
                      ),
                    ),
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: settings.dateOnlyReminderMinutes ~/ 60,
                          minute: settings.dateOnlyReminderMinutes % 60,
                        ),
                      );
                      if (t != null) {
                        await save(
                          settings.copyWith(
                            dateOnlyReminderMinutes: t.hour * 60 + t.minute,
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications_active_outlined),
                    title: const Text('Default alarm cadence'),
                    subtitle: Text(
                      _cadenceLabel(settings.defaultAlarmCadenceMinutes),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.colors.textMuted,
                      ),
                    ),
                    onTap: () async {
                      final value = await _pickCadence(
                        context,
                        settings.defaultAlarmCadenceMinutes,
                      );
                      if (value != null) {
                        await save(
                          settings.copyWith(defaultAlarmCadenceMinutes: value),
                        );
                      }
                    },
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.bedtime_outlined),
                    title: const Text('Quiet hours'),
                    subtitle: Text(
                      settings.quietHours.enabled
                          ? '${Formats.time(settings.quietHours.startMinutes)} – '
                                '${Formats.time(settings.quietHours.endMinutes)}'
                          : 'Off',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.colors.textMuted,
                      ),
                    ),
                    value: settings.quietHours.enabled,
                    onChanged: (v) => save(
                      settings.copyWith(
                        quietHours: settings.quietHours.copyWith(enabled: v),
                      ),
                    ),
                  ),
                  if (settings.quietHours.enabled) ...[
                    ListTile(
                      leading: const SizedBox(width: 24),
                      title: const Text('Starts'),
                      trailing: Text(
                        Formats.time(settings.quietHours.startMinutes),
                        style: TextStyle(color: context.colors.textSecondary),
                      ),
                      onTap: () async {
                        final t = await _pickTimeOfDay(
                          context,
                          settings.quietHours.startMinutes,
                        );
                        if (t != null) {
                          await save(
                            settings.copyWith(
                              quietHours: settings.quietHours.copyWith(
                                startMinutes: t,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    ListTile(
                      leading: const SizedBox(width: 24),
                      title: const Text('Ends'),
                      trailing: Text(
                        Formats.time(settings.quietHours.endMinutes),
                        style: TextStyle(color: context.colors.textSecondary),
                      ),
                      onTap: () async {
                        final t = await _pickTimeOfDay(
                          context,
                          settings.quietHours.endMinutes,
                        );
                        if (t != null) {
                          await save(
                            settings.copyWith(
                              quietHours: settings.quietHours.copyWith(
                                endMinutes: t,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                  SwitchListTile(
                    secondary: const Icon(Icons.volume_up_outlined),
                    title: const Text('Sound'),
                    value: settings.soundEnabled,
                    onChanged: (v) => save(settings.copyWith(soundEnabled: v)),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.vibration),
                    title: const Text('Vibration'),
                    value: settings.vibrationEnabled,
                    onChanged: (v) =>
                        save(settings.copyWith(vibrationEnabled: v)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.send_outlined),
                    title: const Text('Send test notification'),
                    onTap: () async {
                      final usable = await ensureNotificationPermission(
                        context,
                      );
                      if (usable) {
                        await state.showTestNotification();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SectionHeader('Focus timer'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: const Text('Focus session length'),
                    trailing: Text(
                      '${settings.pomodoroWorkMinutes} min',
                      style: TextStyle(color: context.colors.textSecondary),
                    ),
                    onTap: () async {
                      final v = await _pickFromList<int>(
                        context,
                        title: 'Focus session length',
                        values: const [15, 25, 45, 50, 90],
                        selected: settings.pomodoroWorkMinutes,
                        label: (m) => '$m minutes',
                      );
                      if (v != null) {
                        await save(settings.copyWith(pomodoroWorkMinutes: v));
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.free_breakfast_outlined),
                    title: const Text('Break length'),
                    trailing: Text(
                      '${settings.pomodoroBreakMinutes} min',
                      style: TextStyle(color: context.colors.textSecondary),
                    ),
                    onTap: () async {
                      final v = await _pickFromList<int>(
                        context,
                        title: 'Break length',
                        values: const [5, 10, 15, 20],
                        selected: settings.pomodoroBreakMinutes,
                        label: (m) => '$m minutes',
                      );
                      if (v != null) {
                        await save(settings.copyWith(pomodoroBreakMinutes: v));
                      }
                    },
                  ),
                ],
              ),
            ),
            const SectionHeader('Appearance'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(switch (settings.themeMode) {
                      AppThemeMode.system => Icons.brightness_auto_outlined,
                      AppThemeMode.dark => Icons.dark_mode_outlined,
                      AppThemeMode.light => Icons.light_mode_outlined,
                    }),
                    title: const Text('Theme'),
                    trailing: Text(
                      settings.themeMode.label,
                      style: TextStyle(color: context.colors.textSecondary),
                    ),
                    onTap: () async {
                      final mode = await _pickFromList<AppThemeMode>(
                        context,
                        title: 'Theme',
                        values: AppThemeMode.values,
                        selected: settings.themeMode,
                        label: (m) => m.label,
                      );
                      if (mode != null) {
                        await save(settings.copyWith(themeMode: mode));
                      }
                    },
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.animation),
                    title: const Text('Reduce motion'),
                    value: settings.reduceMotion,
                    onChanged: (v) => save(settings.copyWith(reduceMotion: v)),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.density_small),
                    title: const Text('Compact task rows'),
                    value: settings.compactRows,
                    onChanged: (v) => save(settings.copyWith(compactRows: v)),
                  ),
                  if (Platform.isAndroid)
                    ListTile(
                      leading: const Icon(Icons.widgets_outlined),
                      title: const Text('Add widget to Home screen'),
                      subtitle: Text(
                        'Up next or task list',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: context.colors.textMuted,
                        ),
                      ),
                      onTap: () => _pinWidget(context),
                    ),
                ],
              ),
            ),
            const SectionHeader('Task defaults'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.flag_outlined),
                    title: const Text('Default priority'),
                    trailing: Text(
                      settings.defaultPriority.label,
                      style: TextStyle(color: context.colors.textSecondary),
                    ),
                    onTap: () async {
                      final p = await _pickFromList<TaskPriority>(
                        context,
                        title: 'Default priority',
                        values: TaskPriority.values,
                        selected: settings.defaultPriority,
                        label: (p) => p.label,
                      );
                      if (p != null) {
                        await save(settings.copyWith(defaultPriority: p));
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.repeat),
                    title: const Text('Default recurrence behavior'),
                    subtitle: Text(
                      settings.defaultRecurrenceBehavior ==
                              RecurrenceBehavior.fixedSchedule
                          ? 'Fixed schedule'
                          : 'Repeat after completion',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.colors.textMuted,
                      ),
                    ),
                    onTap: () async {
                      final b = await _pickFromList<RecurrenceBehavior>(
                        context,
                        title: 'Recurrence behavior',
                        values: RecurrenceBehavior.values,
                        selected: settings.defaultRecurrenceBehavior,
                        label: (b) => b == RecurrenceBehavior.fixedSchedule
                            ? 'Fixed schedule'
                            : 'Repeat after completion',
                      );
                      if (b != null) {
                        await save(
                          settings.copyWith(defaultRecurrenceBehavior: b),
                        );
                      }
                    },
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.notification_add_outlined),
                    title: const Text('Reminder on by default'),
                    subtitle: Text(
                      'Pre-selects Reminder in quick add',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.colors.textMuted,
                      ),
                    ),
                    value: settings.defaultReminderEnabled,
                    onChanged: (v) =>
                        save(settings.copyWith(defaultReminderEnabled: v)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.view_week_outlined),
                    title: const Text('Start of week'),
                    trailing: Text(
                      settings.startOfWeek == DateTime.sunday
                          ? 'Sunday'
                          : settings.startOfWeek == DateTime.saturday
                          ? 'Saturday'
                          : 'Monday',
                      style: TextStyle(color: context.colors.textSecondary),
                    ),
                    onTap: () async {
                      final v = await _pickFromList<int>(
                        context,
                        title: 'Start of week',
                        values: const [
                          DateTime.monday,
                          DateTime.saturday,
                          DateTime.sunday,
                        ],
                        selected: settings.startOfWeek,
                        label: (d) => switch (d) {
                          DateTime.sunday => 'Sunday',
                          DateTime.saturday => 'Saturday',
                          _ => 'Monday',
                        },
                      );
                      if (v != null) {
                        await save(settings.copyWith(startOfWeek: v));
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Keep completed tasks'),
                    trailing: Text(
                      settings.completedRetention.label,
                      style: TextStyle(color: context.colors.textSecondary),
                    ),
                    onTap: () async {
                      final v = await _pickFromList<CompletedRetention>(
                        context,
                        title: 'Keep completed tasks',
                        values: CompletedRetention.values,
                        selected: settings.completedRetention,
                        label: (r) => r.label,
                      );
                      if (v != null) {
                        await save(settings.copyWith(completedRetention: v));
                      }
                    },
                  ),
                ],
              ),
            ),
            const SectionHeader('Data'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.upload_outlined),
                    title: const Text('Export tasks as JSON'),
                    onTap: () => _export(context, state),
                  ),
                  ListTile(
                    leading: const Icon(Icons.download_outlined),
                    title: const Text('Import tasks from JSON'),
                    onTap: () => _import(context, state),
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: const Text('Export calendar (.ics)'),
                    subtitle: Text(
                      'Open tasks with deadlines, for any calendar app',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.colors.textMuted,
                      ),
                    ),
                    onTap: () => _exportIcs(context, state),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.delete_forever,
                      color: context.colors.overdue,
                    ),
                    title: Text(
                      'Delete all local data',
                      style: TextStyle(color: context.colors.overdue),
                    ),
                    onTap: () => _deleteAll(
                      context,
                      state,
                      context.read<HabitController>(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _offsetLabel(int minutes) => minutes == 0
      ? 'At deadline'
      : minutes % 1440 == 0
      ? '${minutes ~/ 1440} day${minutes == 1440 ? '' : 's'} before'
      : minutes % 60 == 0
      ? '${minutes ~/ 60} hour${minutes == 60 ? '' : 's'} before'
      : '$minutes minutes before';

  static String _cadenceLabel(int minutes) => minutes % 60 == 0
      ? (minutes == 60 ? 'Every hour' : 'Every ${minutes ~/ 60} hours')
      : 'Every $minutes minutes';

  static Future<int?> _pickOffset(BuildContext context, int current) =>
      _pickFromList<int>(
        context,
        title: 'Default reminder timing',
        values: const [0, 5, 15, 30, 60, 180, 1440],
        selected: current,
        label: _offsetLabel,
      );

  static Future<int?> _pickCadence(BuildContext context, int current) =>
      _pickFromList<int>(
        context,
        title: 'Default alarm cadence',
        values: const [15, 30, 60, 180],
        selected: current,
        label: _cadenceLabel,
      );

  static Future<int?> _pickTimeOfDay(BuildContext context, int current) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    return t == null ? null : t.hour * 60 + t.minute;
  }

  static Future<T?> _pickFromList<T>(
    BuildContext context, {
    required String title,
    required List<T> values,
    required T selected,
    required String Function(T) label,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final v in values)
              ListTile(
                leading: Icon(
                  v == selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: v == selected
                      ? context.colors.accent
                      : context.colors.textMuted,
                ),
                title: Text(label(v)),
                onTap: () => Navigator.pop(context, v),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pinWidget(BuildContext context) async {
    final widgets = context.read<HomeWidgetService>();
    if (!await widgets.pinSupported()) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Your launcher does not support adding widgets from here. '
          'Long-press your home screen and choose Widgets instead.',
        );
      }
      return;
    }
    if (!context.mounted) return;
    final upNext = await showModalBottomSheet<bool>(
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
                  'Add widget',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.crop_16_9),
              title: const Text('Up next'),
              subtitle: Text(
                'Your single most important task',
                style: TextStyle(
                  fontSize: 12.5,
                  color: context.colors.textMuted,
                ),
              ),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.view_agenda_outlined),
              title: const Text('Task list'),
              subtitle: Text(
                'Overdue and today, like the Focus screen',
                style: TextStyle(
                  fontSize: 12.5,
                  color: context.colors.textMuted,
                ),
              ),
              onTap: () => Navigator.pop(context, false),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (upNext == null) return;
    await widgets.requestPin(upNext: upNext);
  }

  Future<void> _export(BuildContext context, AppState state) async {
    try {
      final json = state.exportJson();
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().toIso8601String().split('T').first;
      final file = File('${dir.path}/nudge-backup-$stamp.json');
      await file.writeAsString(json);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: 'Nudge backup',
        ),
      );
    } catch (_) {
      if (context.mounted) {
        showAppSnackBar(context, 'Could not export your tasks. Try again.');
      }
    }
  }

  Future<void> _exportIcs(BuildContext context, AppState state) async {
    try {
      final ics = const IcsCodec().encode(state.allTasks, now: DateTime.now());
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().toIso8601String().split('T').first;
      final file = File('${dir.path}/nudge-tasks-$stamp.ics');
      await file.writeAsString(ics);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/calendar')],
          subject: 'Nudge tasks',
        ),
      );
    } catch (_) {
      if (context.mounted) {
        showAppSnackBar(context, 'Could not export the calendar. Try again.');
      }
    }
  }

  Future<void> _import(BuildContext context, AppState state) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Import data?',
      message:
          'Importing replaces all current tasks with the contents of '
          'the backup file.',
      confirmLabel: 'Choose file',
      destructive: false,
    );
    if (!confirmed || !context.mounted) return;
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      final file = files.firstOrNull;
      if (file == null) return;
      final data = await file.readAsBytes();
      final count = await state.importJson(utf8.decode(data));
      if (context.mounted) {
        showAppSnackBar(context, 'Imported $count tasks.');
      }
    } on FormatException catch (e) {
      if (context.mounted) showAppSnackBar(context, e.message);
    } catch (_) {
      if (context.mounted) {
        showAppSnackBar(context, 'Could not read that file.');
      }
    }
  }

  Future<void> _deleteAll(
    BuildContext context,
    AppState state,
    HabitController habits,
  ) async {
    final first = await confirmDialog(
      context,
      title: 'Delete all data?',
      message:
          'Every task, subtask, habit and setting will be permanently removed '
          'and all reminders cancelled.',
      confirmLabel: 'Continue',
    );
    if (!first || !context.mounted) return;
    final second = await confirmDialog(
      context,
      title: 'Are you absolutely sure?',
      message: 'This cannot be undone.',
      confirmLabel: 'Delete everything',
    );
    if (!second || !context.mounted) return;
    await state.deleteAllData();
    await habits.deleteAll();
    if (context.mounted) {
      showAppSnackBar(context, 'All local data deleted.');
    }
  }
}
