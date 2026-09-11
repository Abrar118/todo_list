import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/data/habit_repository.dart';
import 'package:todo_list/domain/models/date_only.dart';
import 'package:todo_list/domain/models/habit.dart';
import 'package:todo_list/domain/logic/habit_reminder_planner.dart';
import 'package:todo_list/services/habit_reminder_service.dart';
import 'package:todo_list/state/habit_controller.dart';

class _MemoryHabitRepository implements HabitRepository {
  List<Habit> stored = [];
  int saveCount = 0;

  @override
  Future<List<Habit>> loadAll() async => List.of(stored);

  @override
  Future<void> saveAll(List<Habit> habits) async {
    stored = List.of(habits);
    saveCount++;
  }

  @override
  Future<void> deleteAll() async => stored.clear();
}

class _MemoryHabitReminderService implements HabitReminderService {
  List<PlannedHabitReminder> lastPlan = [];
  int syncCount = 0;

  @override
  Future<void> syncHabitReminders(List<PlannedHabitReminder> plan) async {
    lastPlan = List.of(plan);
    syncCount++;
  }
}

void main() {
  const today = DateOnly(2026, 9, 7);

  test('habit toggles a completion date on and off', () {
    const habit = Habit(
      id: 'habit-1',
      title: 'Drink water',
      color: HabitColor.blue,
      createdOn: today,
    );

    final completed = habit.toggle(today);
    expect(completed.isCompletedOn(today), isTrue);

    final reopened = completed.toggle(today);
    expect(reopened.isCompletedOn(today), isFalse);
  });

  test('current streak allows today to remain unfinished', () {
    final habit =
        const Habit(
              id: 'habit-1',
              title: 'Read',
              color: HabitColor.violet,
              createdOn: DateOnly(2026, 9, 1),
            )
            .toggle(today.addDays(-3))
            .toggle(today.addDays(-2))
            .toggle(today.addDays(-1));

    expect(habit.currentStreak(today), 3);
    expect(habit.toggle(today).currentStreak(today), 4);
  });

  test('habit JSON round-trip preserves completed days', () {
    final habit = const Habit(
      id: 'habit-1',
      title: 'Stretch',
      color: HabitColor.green,
      createdOn: DateOnly(2026, 9, 1),
    ).toggle(today).toggle(today.addDays(-1));

    expect(Habit.fromJson(habit.toJson()), habit);
  });

  test('habit JSON round-trip preserves customization and timer state', () {
    final habit = Habit(
      id: 'habit-rich',
      title: 'Daily workout',
      color: HabitColor.green,
      createdOn: const DateOnly(2026, 9, 1),
      type: HabitType.timer,
      scheduledMinutes: 7 * 60,
      timerTargetMinutes: 45,
      checkpoints: [
        HabitCheckpoint(
          id: 'warmup',
          title: 'Warm up',
          scheduledMinutes: 7 * 60 + 5,
          completedDates: {today},
        ),
      ],
      trackedSecondsByDate: {today: 125},
      timerStartedAt: DateTime.utc(2026, 9, 7, 6, 30),
      isCollapsed: true,
    );

    expect(Habit.fromJson(habit.toJson()), habit);
  });

  test('completing every checkpoint completes the habit for that day', () {
    final habit = Habit(
      id: 'routine',
      title: 'Morning routine',
      color: HabitColor.amber,
      createdOn: today,
      checkpoints: const [
        HabitCheckpoint(id: 'one', title: 'First'),
        HabitCheckpoint(id: 'two', title: 'Second'),
      ],
    );

    final first = habit.toggleCheckpoint('one', today);
    expect(first.isCompletedOn(today), isFalse);
    final all = first.toggleCheckpoint('two', today);
    expect(all.isCompletedOn(today), isTrue);
    expect(all.toggleCheckpoint('one', today).isCompletedOn(today), isFalse);
  });

  test('habit reminder plan includes habit and checkpoint timestamps', () {
    final habit = Habit(
      id: 'routine',
      title: 'Morning routine',
      color: HabitColor.blue,
      createdOn: today,
      scheduledMinutes: 7 * 60,
      checkpoints: const [
        HabitCheckpoint(
          id: 'water',
          title: 'Drink water',
          scheduledMinutes: 7 * 60 + 15,
        ),
        HabitCheckpoint(
          id: 'stretch',
          title: 'Stretch',
          scheduledMinutes: 7 * 60 + 30,
        ),
        HabitCheckpoint(id: 'journal', title: 'Journal'),
      ],
    );

    final plan = const HabitReminderPlanner().plan([habit]);
    expect(plan.map((item) => item.minutesOfDay), [420, 435, 450]);
    expect(plan.map((item) => item.id).toSet().length, 3);
    expect(plan[1].body, 'Drink water');
    expect(plan[1].checkpointId, 'water');
  });

  test('controller loads, mutates, and persists habits', () async {
    final repository = _MemoryHabitRepository();
    final controller = HabitController(repository);
    await controller.init();

    await controller.addHabit(
      title: 'Morning walk',
      color: HabitColor.amber,
      createdOn: today,
    );
    final id = controller.habits.single.id;
    await controller.toggleDate(id, today);

    expect(controller.habits.single.isCompletedOn(today), isTrue);
    expect(repository.stored.single.isCompletedOn(today), isTrue);
    expect(repository.saveCount, 2);
  });

  test('controller syncs reminders after scheduled habit changes', () async {
    final repository = _MemoryHabitRepository();
    final reminders = _MemoryHabitReminderService();
    final controller = HabitController(repository, reminders: reminders);
    await controller.init();

    await controller.addHabit(
      title: 'Take vitamins',
      color: HabitColor.green,
      scheduledMinutes: 8 * 60,
      createdOn: today,
    );

    expect(reminders.lastPlan.single.minutesOfDay, 8 * 60);
    expect(reminders.syncCount, 2); // initial load, then mutation
  });

  test('timer habit persists elapsed time and completes its target', () async {
    final repository = _MemoryHabitRepository();
    final controller = HabitController(repository);
    await controller.init();
    await controller.addHabit(
      title: 'Workout',
      color: HabitColor.green,
      type: HabitType.timer,
      timerTargetMinutes: 1,
      createdOn: today,
    );
    final id = controller.habits.single.id;

    await controller.startTimer(id, at: DateTime(2026, 9, 7, 10));
    await controller.pauseTimer(id, at: DateTime(2026, 9, 7, 10, 1, 5));

    final habit = controller.habits.single;
    expect(habit.trackedSecondsOn(today), 65);
    expect(habit.timerStartedAt, isNull);
    expect(habit.isCompletedOn(today), isTrue);
    expect(repository.stored.single.trackedSecondsOn(today), 65);
  });
}
