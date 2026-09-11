import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'headless_actions.dart';

/// Entry point for notification action buttons pressed while the app process
/// is not in the foreground. Runs in a background isolate; the shared
/// [applyHeadlessAction] bootstraps database access and applies the same
/// mutations the app uses.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  handleBackgroundAction(response);
}

Future<void> handleBackgroundAction(NotificationResponse response) async {
  final actionId = response.actionId;
  if (actionId != 'complete' && actionId != 'snooze') return;

  String? taskId;
  try {
    final decoded = jsonDecode(response.payload ?? '');
    if (decoded is Map<String, dynamic>) taskId = decoded['taskId'] as String?;
  } on FormatException {
    return;
  }
  if (taskId == null) return;

  try {
    await applyHeadlessAction(taskId, complete: actionId == 'complete');
  } catch (_) {
    // Best effort: the app fully re-syncs state and schedules on next launch.
  }
}
