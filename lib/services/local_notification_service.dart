import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:app_settings/app_settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/app_colors.dart';
import '../domain/logic/notification_planner.dart';
import '../domain/logic/habit_reminder_planner.dart';
import '../domain/models/habit.dart';
import '../domain/models/notification_tone.dart';
import 'background_action_handler.dart';
import 'habit_reminder_service.dart';
import 'notification_service.dart';

/// flutter_local_notifications-backed implementation.
class LocalNotificationService
    implements NotificationService, HabitReminderService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  void Function(NotificationAction action)? _listener;
  NotificationAction? _pendingAction;
  List<PlannedHabitReminder> _lastHabitPlan = const [];

  static const _channelReminders = AndroidNotificationChannel(
    'nudge_reminders',
    'Reminders',
    description: 'Task deadline reminders',
    importance: Importance.high,
  );

  static const _channelAlarms = AndroidNotificationChannel(
    'nudge_alarms',
    'Priority alarms',
    description: 'Persistent reminders for priority tasks',
    importance: Importance.max,
  );

  static const _channelHabits = AndroidNotificationChannel(
    'nudge_habits',
    'Habit reminders',
    description: 'Daily habit and checkpoint reminders',
    importance: Importance.high,
  );

  static const darwinCategoryId = 'NUDGE_TASK';

  /// Reserved OS id for the focus-timer alert; [syncPlan] leaves it alone.
  static const timerAlertId = 0x7ffffff0;

  @override
  Future<void> init() async {
    await _configureTimeZone();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final darwinInit = DarwinInitializationSettings(
      // Permission is requested explicitly when the user enables their first
      // reminder, never at launch.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          darwinCategoryId,
          actions: [
            DarwinNotificationAction.plain('complete', 'Complete'),
            DarwinNotificationAction.plain('snooze', 'Snooze 15 min'),
          ],
        ),
      ],
    );

    await _plugin.initialize(
      settings: InitializationSettings(android: androidInit, iOS: darwinInit),
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_channelReminders);
    await android?.createNotificationChannel(_channelAlarms);
    await android?.createNotificationChannel(_channelHabits);

    final launch = await _plugin.getNotificationAppLaunchDetails();
    final response = launch?.notificationResponse;
    if ((launch?.didNotificationLaunchApp ?? false) && response != null) {
      _pendingAction = _toAction(response);
    }
  }

  Future<void> _configureTimeZone() async {
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Unknown zone id: fall back to the device's raw offset via tz.local
      // default (UTC). Scheduling still works; times were computed in local
      // wall-clock terms before conversion.
    }
  }

  void _onResponse(NotificationResponse response) {
    final action = _toAction(response);
    if (action == null) return;
    final listener = _listener;
    if (listener != null) {
      listener(action);
    } else {
      _pendingAction = action;
    }
  }

  String? _taskIdFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        final taskId = decoded['taskId'] as String?;
        return taskId == null || taskId.isEmpty ? null : taskId;
      }
    } on FormatException {
      // fall through
    }
    return null;
  }

  NotificationAction? _toAction(NotificationResponse response) {
    final taskId = _taskIdFromPayload(response.payload);
    if (taskId == null) return null;
    final kind = switch (response.actionId) {
      'complete' => NotificationActionKind.complete,
      'snooze' => NotificationActionKind.snooze,
      _ => NotificationActionKind.open,
    };
    return NotificationAction(kind, taskId);
  }

  @override
  void setActionListener(void Function(NotificationAction action) listener) {
    _listener = listener;
    final pending = _pendingAction;
    if (pending != null) {
      _pendingAction = null;
      listener(pending);
    }
  }

  @override
  Future<NotificationAction?> takeLaunchAction() async {
    final pending = _pendingAction;
    _pendingAction = null;
    return pending;
  }

  @override
  Future<NotificationPermission> permissionState() async {
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final enabled = await android?.areNotificationsEnabled();
      if (enabled == null) return NotificationPermission.notRequested;
      return enabled
          ? NotificationPermission.granted
          : NotificationPermission.denied;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final options = await ios?.checkPermissions();
    if (options == null) return NotificationPermission.notRequested;
    if (options.isEnabled || options.isProvisionalEnabled) {
      return NotificationPermission.granted;
    }
    return NotificationPermission.denied;
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    bool? granted;
    if (Platform.isAndroid) {
      granted = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else {
      granted = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
    return granted == true
        ? NotificationPermission.granted
        : NotificationPermission.denied;
  }

  @override
  Future<bool> exactDeliveryAvailable() async {
    if (!Platform.isAndroid) return true;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.canScheduleExactNotifications() ?? false;
  }

  @override
  Future<ScheduleResult> syncPlan(
    List<PlannedNotification> plan, {
    Set<String> keepDisplayedForTaskIds = const {},
  }) async {
    // Re-read the device time zone so a zone change while backgrounded is
    // reflected in the rescheduled delivery times.
    await _configureTimeZone();
    // Cancel-then-reschedule keeps the OS state an exact mirror of the plan:
    // no duplicates, no orphans from completed or edited tasks. Pending
    // (undelivered) schedules are all replaced; already-delivered
    // notifications stay in the shade while their task still needs
    // attention.
    try {
      for (final pending in await _plugin.pendingNotificationRequests()) {
        if (pending.id == timerAlertId ||
            HabitReminderPlanner.ownsId(pending.id)) {
          continue;
        }
        await _plugin.cancel(id: pending.id);
      }
      for (final active in await _plugin.getActiveNotifications()) {
        final id = active.id;
        if (id == null) continue;
        final taskId = _taskIdFromPayload(active.payload);
        // Unknown payloads (e.g. the test notification) are left alone.
        if (taskId != null && !keepDisplayedForTaskIds.contains(taskId)) {
          await _plugin.cancel(id: id);
        }
      }
    } catch (_) {
      // Querying pending/active notifications can fail on some platforms;
      // fall back to a full reset rather than risking duplicates.
      await _plugin.cancelAll();
      await _scheduleHabitPlan(_lastHabitPlan);
    }
    final exact = await exactDeliveryAvailable();
    final mode = exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    var scheduled = 0;
    var failed = 0;
    for (final item in plan) {
      try {
        await _plugin.zonedSchedule(
          id: item.id,
          title: item.title,
          body: item.body,
          scheduledDate: tz.TZDateTime.from(item.fireAt, tz.local),
          notificationDetails: _details(item),
          androidScheduleMode: mode,
          payload: jsonEncode({'taskId': item.taskId, 'kind': item.kind.name}),
        );
        scheduled++;
      } catch (_) {
        failed++;
      }
    }
    return ScheduleResult(
      scheduled: scheduled,
      failed: failed,
      exactDeliveryAvailable: exact,
    );
  }

  @override
  Future<void> syncHabitReminders(List<PlannedHabitReminder> plan) async {
    await _configureTimeZone();
    _lastHabitPlan = List.unmodifiable(plan);
    try {
      for (final pending in await _plugin.pendingNotificationRequests()) {
        if (HabitReminderPlanner.ownsId(pending.id)) {
          await _plugin.cancel(id: pending.id);
        }
      }
    } catch (_) {
      // Schedule with deterministic ids below; the OS replaces matching ids.
    }
    await _scheduleHabitPlan(plan);
  }

  Future<void> _scheduleHabitPlan(List<PlannedHabitReminder> plan) async {
    final exact = await exactDeliveryAvailable();
    final mode = exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    final now = tz.TZDateTime.now(tz.local);
    for (final item in plan) {
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        item.dayOfMonth?.clamp(1, DateTime(now.year, now.month + 1, 0).day) ??
            now.day,
        item.minutesOfDay ~/ 60,
        item.minutesOfDay % 60,
      );
      if (!scheduled.isAfter(now)) {
        scheduled = item.cadence == HabitCadence.monthly
            ? tz.TZDateTime(
                tz.local,
                now.year,
                now.month + 1,
                item.dayOfMonth!.clamp(
                  1,
                  DateTime(now.year, now.month + 2, 0).day,
                ),
                item.minutesOfDay ~/ 60,
                item.minutesOfDay % 60,
              )
            : scheduled.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        id: item.id,
        title: item.title,
        body: item.body,
        scheduledDate: scheduled,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelHabits.id,
            _channelHabits.name,
            channelDescription: _channelHabits.description,
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
            color: _notificationColor(item.tone),
            colorized: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: true,
            interruptionLevel: InterruptionLevel.active,
          ),
        ),
        androidScheduleMode: mode,
        matchDateTimeComponents: item.cadence == HabitCadence.monthly
            ? DateTimeComponents.dayOfMonthAndTime
            : DateTimeComponents.time,
        payload: jsonEncode({
          'habitId': item.habitId,
          if (item.checkpointId != null) 'checkpointId': item.checkpointId,
        }),
      );
    }
  }

  NotificationDetails _details(PlannedNotification item) {
    final isAlarm = item.kind == PlannedKind.alarm;
    final channel = isAlarm ? _channelAlarms : _channelReminders;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: isAlarm ? Priority.max : Priority.high,
        category: isAlarm
            ? AndroidNotificationCategory.alarm
            : AndroidNotificationCategory.reminder,
        color: _notificationColor(item.tone),
        colorized: true,
        playSound: item.sound,
        enableVibration: item.vibration,
        actions: const [
          AndroidNotificationAction(
            'complete',
            'Complete',
            showsUserInterface: false,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'snooze',
            'Snooze 15 min',
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: darwinCategoryId,
        presentAlert: true,
        presentBadge: false,
        presentSound: item.sound,
        interruptionLevel: isAlarm
            ? InterruptionLevel.timeSensitive
            : InterruptionLevel.active,
      ),
    );
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> showTestNotification() async {
    await _plugin.show(
      id: 0x7ffffffe,
      title: 'Nudge test notification',
      body: 'Notifications are working.',
      notificationDetails: _details(
        PlannedNotification(
          id: 0x7ffffffe,
          taskId: '',
          fireAt: DateTime.now(),
          kind: PlannedKind.reminder,
          title: '',
          body: '',
        ),
      ),
    );
  }

  @override
  Future<void> scheduleTimerAlert({
    required DateTime at,
    required String title,
    required String body,
  }) async {
    final exact = await exactDeliveryAvailable();
    // No Complete/Snooze actions: this alert is about the session, not a
    // task deadline.
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelReminders.id,
        _channelReminders.name,
        channelDescription: _channelReminders.description,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
    await _plugin.zonedSchedule(
      id: timerAlertId,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: details,
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancelTimerAlert() => _plugin.cancel(id: timerAlertId);

  Color _notificationColor(NotificationTone tone) => switch (tone) {
    NotificationTone.lime => AppColors.dark.accent,
    NotificationTone.cyan => AppColors.dark.low,
    NotificationTone.sand => AppColors.dark.medium,
    NotificationTone.coral => AppColors.dark.overdue,
  };

  @override
  Future<void> openSystemNotificationSettings() =>
      AppSettings.openAppSettings(type: AppSettingsType.notification);
}
