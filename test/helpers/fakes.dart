import 'package:todo_list/data/app_settings.dart';
import 'package:todo_list/data/habit_repository.dart';
import 'package:todo_list/data/settings_repository.dart';
import 'package:todo_list/data/task_repository.dart';
import 'package:todo_list/domain/logic/notification_planner.dart';
import 'package:todo_list/domain/models/habit.dart';
import 'package:todo_list/domain/models/task.dart';
import 'package:todo_list/services/notification_service.dart';

class InMemoryTaskRepository implements TaskRepository {
  final Map<String, Task> store = {};
  bool failWrites = false;

  @override
  Future<List<Task>> loadAll() async => store.values.toList();

  @override
  Future<void> upsert(Task task) async {
    if (failWrites) throw Exception('write failed');
    store[task.id] = task;
  }

  @override
  Future<void> upsertAll(List<Task> tasks) async {
    for (final t in tasks) {
      await upsert(t);
    }
  }

  @override
  Future<void> delete(String id) async {
    if (failWrites) throw Exception('write failed');
    store.remove(id);
  }

  @override
  Future<void> deleteMany(Iterable<String> ids) async {
    for (final id in ids) {
      await delete(id);
    }
  }

  @override
  Future<void> deleteAll() async {
    if (failWrites) throw Exception('write failed');
    store.clear();
  }
}

class InMemoryHabitRepository implements HabitRepository {
  List<Habit> store = [];

  @override
  Future<List<Habit>> loadAll() async => List.of(store);

  @override
  Future<void> saveAll(List<Habit> habits) async => store = List.of(habits);

  @override
  Future<void> deleteAll() async => store.clear();
}

class FakeNotificationService implements NotificationService {
  NotificationPermission permission = NotificationPermission.granted;
  List<PlannedNotification> lastPlan = [];
  Set<String> lastKeepDisplayed = {};
  int syncCount = 0;
  int cancelAllCount = 0;
  void Function(NotificationAction action)? listener;

  @override
  Future<void> init() async {}

  @override
  Future<NotificationPermission> permissionState() async => permission;

  @override
  Future<NotificationPermission> requestPermission() async => permission;

  @override
  Future<bool> exactDeliveryAvailable() async => true;

  @override
  Future<ScheduleResult> syncPlan(
    List<PlannedNotification> plan, {
    Set<String> keepDisplayedForTaskIds = const {},
  }) async {
    lastPlan = plan;
    lastKeepDisplayed = keepDisplayedForTaskIds;
    syncCount++;
    return ScheduleResult(
      scheduled: plan.length,
      failed: 0,
      exactDeliveryAvailable: true,
    );
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCount++;
    lastPlan = [];
  }

  @override
  Future<void> showTestNotification() async {}

  DateTime? timerAlertAt;
  String? timerAlertTitle;

  @override
  Future<void> scheduleTimerAlert({
    required DateTime at,
    required String title,
    required String body,
  }) async {
    timerAlertAt = at;
    timerAlertTitle = title;
  }

  @override
  Future<void> cancelTimerAlert() async {
    timerAlertAt = null;
    timerAlertTitle = null;
  }

  @override
  void setActionListener(void Function(NotificationAction action) l) {
    listener = l;
  }

  @override
  Future<NotificationAction?> takeLaunchAction() async => null;

  @override
  Future<void> openSystemNotificationSettings() async {}
}

class InMemorySettingsRepository implements SettingsRepository {
  AppSettings settings = const AppSettings();
  bool firstLaunch = true;
  bool permissionRequested = false;

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<void> save(AppSettings s) async => settings = s;

  @override
  Future<bool> isFirstLaunch() async => firstLaunch;

  @override
  Future<void> markFirstLaunchDone() async => firstLaunch = false;

  @override
  Future<bool> wasPermissionRequested() async => permissionRequested;

  @override
  Future<void> markPermissionRequested() async => permissionRequested = true;

  @override
  Future<void> clearAll() async {
    settings = const AppSettings();
    permissionRequested = false;
  }
}
