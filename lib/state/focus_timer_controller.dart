import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/notification_service.dart';
import 'app_state.dart';
import 'settings_controller.dart';

enum TimerPhase { idle, work, brk }

/// Pomodoro-style focus timer for one task at a time.
///
/// Time is derived from a wall-clock [_endsAt], not tick counting, so the
/// remaining time stays correct while the app is backgrounded (the UI tick
/// only repaints). A session-end notification is scheduled with the OS on a
/// reserved id, so the alert fires even if the app is not open; it is
/// cancelled on pause/stop. Completed work sessions are credited to the task
/// via [AppState.addTimeSpent] — abandoned (stopped) sessions credit the
/// elapsed part too.
class FocusTimerController extends ChangeNotifier {
  final AppState _appState;
  final SettingsController _settings;
  final NotificationService _notifications;

  FocusTimerController(this._appState, this._settings, this._notifications);

  TimerPhase _phase = TimerPhase.idle;
  String? _taskId;
  String _taskTitle = '';
  DateTime? _endsAt;
  Duration? _pausedRemaining;
  Duration _phaseLength = Duration.zero;
  DateTime? _workStartedAt;
  int _completedSessions = 0;
  Timer? _ticker;

  TimerPhase get phase => _phase;
  bool get isActive => _phase != TimerPhase.idle;
  bool get isPaused => isActive && _pausedRemaining != null;
  String? get taskId => _taskId;
  String get taskTitle => _taskTitle;
  int get completedSessions => _completedSessions;
  Duration get phaseLength => _phaseLength;

  Duration get remaining {
    final paused = _pausedRemaining;
    if (paused != null) return paused;
    final ends = _endsAt;
    if (ends == null) return Duration.zero;
    final left = ends.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  /// 0.0 (fresh) to 1.0 (phase finished).
  double get progress => _phaseLength.inSeconds == 0
      ? 0
      : 1 - remaining.inSeconds / _phaseLength.inSeconds;

  void startWork({required String taskId, required String taskTitle}) {
    if (_taskId != taskId) _completedSessions = 0;
    _taskId = taskId;
    _taskTitle = taskTitle;
    _beginPhase(
      TimerPhase.work,
      Duration(minutes: _settings.settings.pomodoroWorkMinutes),
    );
    _workStartedAt = DateTime.now();
  }

  void pause() {
    if (!isActive || isPaused) return;
    _pausedRemaining = remaining;
    _endsAt = null;
    _notifications.cancelTimerAlert();
    _stopTicker();
    notifyListeners();
  }

  void resume() {
    final paused = _pausedRemaining;
    if (paused == null) return;
    _pausedRemaining = null;
    _endsAt = DateTime.now().add(paused);
    _scheduleAlert();
    _startTicker();
    notifyListeners();
  }

  /// Stops the session. Work time elapsed so far is still credited.
  Future<void> stop() async {
    final credit = _pendingWorkCredit();
    _reset();
    notifyListeners();
    if (credit != null) await credit();
  }

  void skipBreak() {
    if (_phase != TimerPhase.brk) return;
    _reset();
    notifyListeners();
  }

  /// Forces the current phase to be over, as if its end time had passed
  /// while the app was backgrounded. Test-only.
  @visibleForTesting
  void debugExpirePhase() {
    if (!isActive) return;
    _pausedRemaining = null;
    _endsAt = DateTime.now().subtract(const Duration(seconds: 1));
  }

  /// Called by the UI tick (and on app resume) to process phase ends that
  /// happened while nobody was watching.
  Future<void> checkPhaseEnd() async {
    if (!isActive || isPaused) return;
    if (remaining > Duration.zero) return;
    if (_phase == TimerPhase.work) {
      final credit = _pendingWorkCredit(full: true);
      _completedSessions++;
      _beginPhase(
        TimerPhase.brk,
        Duration(minutes: _settings.settings.pomodoroBreakMinutes),
      );
      if (credit != null) await credit();
    } else {
      _reset();
      notifyListeners();
    }
  }

  /// Credits work time to the task; returns the async write to run after
  /// state has been updated. [full] credits the whole phase length.
  Future<void> Function()? _pendingWorkCredit({bool full = false}) {
    if (_phase != TimerPhase.work) return null;
    final taskId = _taskId;
    final startedAt = _workStartedAt;
    if (taskId == null || startedAt == null) return null;
    final elapsed = full ? _phaseLength : _phaseLength - remaining;
    _workStartedAt = null;
    if (elapsed < const Duration(seconds: 30)) return null;
    return () => _appState.addTimeSpent(taskId, elapsed);
  }

  void _beginPhase(TimerPhase phase, Duration length) {
    _phase = phase;
    _phaseLength = length;
    _pausedRemaining = null;
    _endsAt = DateTime.now().add(length);
    _scheduleAlert();
    _startTicker();
    notifyListeners();
  }

  void _scheduleAlert() {
    final ends = _endsAt;
    if (ends == null || !_settings.notificationsUsable) return;
    final work = _phase == TimerPhase.work;
    _notifications.scheduleTimerAlert(
      at: ends,
      title: work ? 'Focus session complete' : 'Break over',
      body: work
          ? 'Nice work on "$_taskTitle". Time for a break.'
          : 'Ready for another round on "$_taskTitle"?',
    );
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      checkPhaseEnd();
      notifyListeners();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _reset() {
    _stopTicker();
    _notifications.cancelTimerAlert();
    _phase = TimerPhase.idle;
    _endsAt = null;
    _pausedRemaining = null;
    _phaseLength = Duration.zero;
    _workStartedAt = null;
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}
