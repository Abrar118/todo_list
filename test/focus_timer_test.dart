import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/domain/models/date_only.dart';
import 'package:todo_list/state/app_state.dart';
import 'package:todo_list/state/focus_timer_controller.dart';
import 'package:todo_list/state/settings_controller.dart';

import 'helpers/fakes.dart';

void main() {
  late InMemoryTaskRepository repo;
  late FakeNotificationService notifications;
  late SettingsController settings;
  late AppState state;
  late FocusTimerController timer;

  setUp(() async {
    repo = InMemoryTaskRepository();
    notifications = FakeNotificationService();
    final settingsRepo = InMemorySettingsRepository()
      ..permissionRequested = true;
    settings = SettingsController(settingsRepo, notifications);
    await settings.load();
    state = AppState(repo, notifications, settings);
    await state.init();
    timer = FocusTimerController(state, settings, notifications);
  });

  tearDown(() => timer.dispose());

  test('startWork enters the work phase and schedules the OS alert', () async {
    final task = await state.createTask(
      title: 'Deep work',
      dueDate: DateOnly.today(),
    );
    timer.startWork(taskId: task.id, taskTitle: task.title);

    expect(timer.phase, TimerPhase.work);
    expect(timer.isActive, isTrue);
    expect(timer.remaining.inMinutes, greaterThanOrEqualTo(24));
    expect(timer.phaseLength, const Duration(minutes: 25));
    expect(notifications.timerAlertAt, isNotNull);
    expect(notifications.timerAlertTitle, 'Focus session complete');
  });

  test('pause cancels the alert; resume reschedules it', () async {
    final task = await state.createTask(title: 'Deep work');
    timer.startWork(taskId: task.id, taskTitle: task.title);

    timer.pause();
    expect(timer.isPaused, isTrue);
    expect(notifications.timerAlertAt, isNull);
    final frozen = timer.remaining;

    timer.resume();
    expect(timer.isPaused, isFalse);
    expect(notifications.timerAlertAt, isNotNull);
    expect(
      (timer.remaining - frozen).abs(),
      lessThan(const Duration(seconds: 2)),
    );
  });

  test('stop cancels the alert and goes idle without crediting a short '
      'session', () async {
    final task = await state.createTask(title: 'Deep work');
    timer.startWork(taskId: task.id, taskTitle: task.title);
    await timer.stop();

    expect(timer.phase, TimerPhase.idle);
    expect(notifications.timerAlertAt, isNull);
    expect(state.taskById(task.id)!.timeSpentSeconds, 0);
  });

  test('a finished work phase credits the task and starts the break', () async {
    final task = await state.createTask(title: 'Deep work');
    timer.startWork(taskId: task.id, taskTitle: task.title);
    // Simulate the phase having ended (endsAt in the past) by pausing with
    // zero remaining, then resuming into an immediately-expired phase.
    timer.pause();
    timer.debugExpirePhase();
    await timer.checkPhaseEnd();

    expect(timer.phase, TimerPhase.brk);
    expect(timer.completedSessions, 1);
    expect(
      state.taskById(task.id)!.timeSpentSeconds,
      const Duration(minutes: 25).inSeconds,
    );
    expect(notifications.timerAlertTitle, 'Break over');
  });

  test('skipBreak ends the session', () async {
    final task = await state.createTask(title: 'Deep work');
    timer.startWork(taskId: task.id, taskTitle: task.title);
    timer.pause();
    timer.debugExpirePhase();
    await timer.checkPhaseEnd();
    expect(timer.phase, TimerPhase.brk);

    timer.skipBreak();
    expect(timer.phase, TimerPhase.idle);
    expect(notifications.timerAlertAt, isNull);
  });
}
