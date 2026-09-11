import '../domain/logic/notification_planner.dart';

enum NotificationPermission { notRequested, granted, denied }

enum NotificationActionKind { open, complete, snooze }

/// A user interaction with a delivered notification.
class NotificationAction {
  final NotificationActionKind kind;
  final String taskId;

  const NotificationAction(this.kind, this.taskId);
}

/// Result of a sync so callers never assume scheduling succeeded when it
/// didn't.
class ScheduleResult {
  final int scheduled;
  final int failed;
  final bool exactDeliveryAvailable;

  const ScheduleResult({
    required this.scheduled,
    required this.failed,
    required this.exactDeliveryAvailable,
  });

  bool get allScheduled => failed == 0;
}

/// Platform boundary for local notifications. Controllers depend on this
/// interface only, keeping scheduling testable and swappable.
abstract class NotificationService {
  Future<void> init();

  Future<NotificationPermission> permissionState();

  /// Shows the OS permission dialog. Returns the resulting state.
  Future<NotificationPermission> requestPermission();

  /// Whether Android exact-alarm delivery is available. Always true on iOS
  /// (delivery precision there is managed by the system).
  Future<bool> exactDeliveryAvailable();

  /// Replaces all scheduled notifications with [plan]. Idempotent.
  ///
  /// Already-delivered notifications stay visible while their task still
  /// needs attention ([keepDisplayedForTaskIds]); displayed notifications
  /// for completed, deleted or snoozed tasks are dismissed.
  Future<ScheduleResult> syncPlan(
    List<PlannedNotification> plan, {
    Set<String> keepDisplayedForTaskIds = const {},
  });

  Future<void> cancelAll();

  Future<void> showTestNotification();

  /// Schedules the single focus-timer session-end alert. Uses a reserved id
  /// outside the task plan, so [syncPlan] never cancels it. Replaces any
  /// previous timer alert.
  Future<void> scheduleTimerAlert({
    required DateTime at,
    required String title,
    required String body,
  });

  Future<void> cancelTimerAlert();

  /// Fired when the user taps a notification or one of its action buttons
  /// while the app is running (or to deliver the launch action on startup).
  void setActionListener(void Function(NotificationAction action) listener);

  /// The action that launched the app, if any (cold start from a
  /// notification tap).
  Future<NotificationAction?> takeLaunchAction();

  Future<void> openSystemNotificationSettings();
}
