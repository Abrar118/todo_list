import 'headless_actions.dart';

/// Entry point for interactive widget buttons (the complete circle). Runs in
/// a background isolate started by the home_widget plugin, so the app opens
/// nothing and the widget updates in place.
@pragma('vm:entry-point')
Future<void> widgetActionBackground(Uri? uri) async {
  if (uri == null || uri.host != 'complete') return;
  final taskId = uri.pathSegments.firstOrNull;
  if (taskId == null || taskId.isEmpty) return;
  try {
    await applyHeadlessAction(taskId, complete: true);
  } catch (_) {
    // Best effort: the app fully re-syncs state and schedules on next launch.
  }
}
