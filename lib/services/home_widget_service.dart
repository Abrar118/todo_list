import 'dart:async';
import 'dart:io';

import 'package:home_widget/home_widget.dart';

import '../domain/logic/widget_deep_link.dart';
import '../state/app_state.dart';
import '../domain/models/task.dart';
import 'widget_action_handler.dart';
import 'widget_snapshot.dart';

/// Mirrors task state into the home-screen widgets and relays widget taps
/// back into the app.
///
/// Listens to [AppState] so every mutation (create, complete, snooze, edit,
/// import, …) refreshes the widgets; a short debounce coalesces bursts.
class HomeWidgetService {
  static const _androidUpNextProvider = 'UpNextWidgetProvider';
  static const _androidFocusProvider = 'FocusListWidgetProvider';
  static const _iosUpNextKind = 'NudgeUpNextWidget';
  static const _iosFocusKind = 'NudgeFocusWidget';

  /// iOS app group shared with the widget extension. Must match the App
  /// Group configured on the Runner and widget-extension targets in Xcode.
  static const iosAppGroup = 'group.com.abrar118.nudge';

  static bool get _supported => Platform.isAndroid || Platform.isIOS;

  AppState? _appState;
  Timer? _debounce;
  StreamSubscription<Uri?>? _clicks;

  Future<void> attach(AppState appState) async {
    if (!_supported) return;
    _appState = appState;
    if (Platform.isIOS) {
      await HomeWidget.setAppGroupId(iosAppGroup);
    }
    // The complete button on the widgets runs Dart in a background isolate.
    await HomeWidget.registerInteractivityCallback(widgetActionBackground);
    appState.addListener(_scheduleSync);
    await _sync();
  }

  void _scheduleSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _sync);
  }

  Future<void> _sync() async {
    final appState = _appState;
    if (appState == null) return;
    try {
      await pushSnapshot(appState.allTasks);
    } catch (_) {
      // Widget refresh is best-effort; the app itself is unaffected.
    }
  }

  /// Writes the widget data snapshot and asks both widgets to redraw. Also
  /// used by the headless action handlers, which have no service instance.
  static Future<void> pushSnapshot(List<Task> tasks) async {
    if (!_supported) return;
    if (Platform.isIOS) {
      await HomeWidget.setAppGroupId(iosAppGroup);
    }
    final snapshot = WidgetSnapshot.build(tasks, DateTime.now());
    await HomeWidget.saveWidgetData(
      WidgetSnapshot.upNextKey,
      snapshot.upNextJson,
    );
    await HomeWidget.saveWidgetData(
      WidgetSnapshot.focusKey,
      snapshot.focusJson,
    );
    await HomeWidget.updateWidget(
      androidName: _androidUpNextProvider,
      iOSName: _iosUpNextKind,
    );
    await HomeWidget.updateWidget(
      androidName: _androidFocusProvider,
      iOSName: _iosFocusKind,
    );
  }

  /// Routes widget taps, per [WidgetDeepLink]: `nudge://task/<id>` opens the
  /// task, `nudge://quickadd` opens quick add, `nudge://focus` (the iOS
  /// focus-list widget's background tap) shows the Focus screen. Handles both
  /// a cold start from a tap and taps while the app is alive.
  Future<void> handleClicks({
    required void Function(String taskId) onOpenTask,
    required void Function() onQuickAdd,
    required void Function() onShowFocus,
  }) async {
    if (!_supported) return;
    void route(Uri? uri) {
      final link = WidgetDeepLink.parse(uri);
      switch (link?.kind) {
        case WidgetDeepLinkKind.openTask:
          onOpenTask(link!.taskId!);
        case WidgetDeepLinkKind.quickAdd:
          onQuickAdd();
        case WidgetDeepLinkKind.focus:
          onShowFocus();
        case null:
          break;
      }
    }

    try {
      route(await HomeWidget.initiallyLaunchedFromHomeWidget());
      _clicks = HomeWidget.widgetClicked.listen(route);
    } catch (_) {
      // Plugin unavailable (e.g. tests): widget taps simply do nothing.
    }
  }

  /// Android launcher pin dialog. No-op elsewhere.
  Future<void> requestPin({required bool upNext}) async {
    if (!Platform.isAndroid) return;
    await HomeWidget.requestPinWidget(
      androidName: upNext ? _androidUpNextProvider : _androidFocusProvider,
    );
  }

  Future<bool> pinSupported() async {
    if (!Platform.isAndroid) return false;
    try {
      return await HomeWidget.isRequestPinWidgetSupported() ?? false;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _debounce?.cancel();
    _clicks?.cancel();
    _appState?.removeListener(_scheduleSync);
  }
}
