import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/habit_repository.dart';
import '../domain/logic/habit_reminder_planner.dart';
import '../domain/models/date_only.dart';
import '../domain/models/habit.dart';
import '../services/habit_reminder_service.dart';

class HabitController extends ChangeNotifier {
  final HabitRepository _repository;
  final HabitReminderService? reminders;
  final HabitReminderPlanner reminderPlanner;
  final Uuid uuid;
  final List<Habit> _habits = [];
  Timer? _ticker;

  bool _isLoaded = false;
  bool _hasStorageError = false;
  bool _hasNotificationError = false;

  HabitController(
    this._repository, {
    this.reminders,
    this.reminderPlanner = const HabitReminderPlanner(),
    this.uuid = const Uuid(),
  });

  UnmodifiableListView<Habit> get habits => UnmodifiableListView(_habits);
  bool get isLoaded => _isLoaded;
  bool get hasStorageError => _hasStorageError;
  bool get hasNotificationError => _hasNotificationError;

  Habit? habitById(String id) {
    final index = _habits.indexWhere((habit) => habit.id == id);
    return index == -1 ? null : _habits[index];
  }

  int completedCountOn(DateOnly date) =>
      _habits.where((habit) => habit.isCompletedOn(date)).length;

  Future<void> init() async {
    try {
      _habits
        ..clear()
        ..addAll(await _repository.loadAll());
      _hasStorageError = false;
      _updateTicker();
      await _syncReminders();
    } catch (_) {
      _hasStorageError = true;
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> addHabit({
    required String title,
    required HabitColor color,
    DateOnly? createdOn,
    HabitType type = HabitType.checkIn,
    int? scheduledMinutes,
    int timerTargetMinutes = 30,
  }) async {
    final cleaned = title.trim();
    if (cleaned.isEmpty) return;
    _habits.add(
      Habit(
        id: uuid.v4(),
        title: cleaned,
        color: color,
        createdOn: createdOn ?? DateOnly.today(),
        type: type,
        scheduledMinutes: scheduledMinutes,
        timerTargetMinutes: timerTargetMinutes,
      ),
    );
    await _changed();
  }

  Future<void> updateHabit(
    String id, {
    required String title,
    required HabitColor color,
    required HabitType type,
    required int? scheduledMinutes,
    required int timerTargetMinutes,
  }) async {
    final index = _indexOf(id);
    final cleaned = title.trim();
    if (index == -1 || cleaned.isEmpty) return;
    _habits[index] = _habits[index].copyWith(
      title: cleaned,
      color: color,
      type: type,
      scheduledMinutes: scheduledMinutes,
      timerTargetMinutes: timerTargetMinutes,
    );
    await _changed();
  }

  Future<void> toggleDate(String id, DateOnly date) async {
    final index = _indexOf(id);
    if (index == -1) return;
    _habits[index] = _habits[index].toggle(date);
    await _changed(syncReminders: false);
  }

  Future<void> toggleCollapsed(String id) async {
    final index = _indexOf(id);
    if (index == -1) return;
    _habits[index] = _habits[index].copyWith(
      isCollapsed: !_habits[index].isCollapsed,
    );
    await _changed(syncReminders: false);
  }

  Future<void> addCheckpoint(
    String habitId, {
    required String title,
    int? scheduledMinutes,
  }) async {
    final index = _indexOf(habitId);
    final cleaned = title.trim();
    if (index == -1 || cleaned.isEmpty) return;
    final checkpoints = List<HabitCheckpoint>.of(_habits[index].checkpoints)
      ..add(
        HabitCheckpoint(
          id: uuid.v4(),
          title: cleaned,
          scheduledMinutes: scheduledMinutes,
        ),
      );
    _habits[index] = _habits[index].copyWith(checkpoints: checkpoints);
    await _changed();
  }

  Future<void> updateCheckpoint(
    String habitId,
    String checkpointId, {
    required String title,
    required int? scheduledMinutes,
  }) async {
    final index = _indexOf(habitId);
    final cleaned = title.trim();
    if (index == -1 || cleaned.isEmpty) return;
    final checkpoints = _habits[index].checkpoints
        .map((checkpoint) {
          if (checkpoint.id != checkpointId) return checkpoint;
          return checkpoint.copyWith(
            title: cleaned,
            scheduledMinutes: scheduledMinutes,
          );
        })
        .toList(growable: false);
    _habits[index] = _habits[index].copyWith(checkpoints: checkpoints);
    await _changed();
  }

  Future<void> deleteCheckpoint(String habitId, String checkpointId) async {
    final index = _indexOf(habitId);
    if (index == -1) return;
    final checkpoints = _habits[index].checkpoints
        .where((checkpoint) => checkpoint.id != checkpointId)
        .toList(growable: false);
    _habits[index] = _habits[index].copyWith(checkpoints: checkpoints);
    await _changed();
  }

  Future<void> toggleCheckpoint(
    String habitId,
    String checkpointId,
    DateOnly date,
  ) async {
    final index = _indexOf(habitId);
    if (index == -1) return;
    _habits[index] = _habits[index].toggleCheckpoint(checkpointId, date);
    await _changed(syncReminders: false);
  }

  int timerSecondsFor(String id, DateOnly date, {DateTime? now}) {
    final habit = habitById(id);
    if (habit == null) return 0;
    var seconds = habit.trackedSecondsOn(date);
    final started = habit.timerStartedAt;
    final current = now ?? DateTime.now();
    if (started != null && DateOnly.fromDateTime(started) == date) {
      seconds += current.difference(started).inSeconds.clamp(0, 1 << 31);
    }
    return seconds;
  }

  Future<void> startTimer(String id, {DateTime? at}) async {
    final index = _indexOf(id);
    if (index == -1 || _habits[index].type != HabitType.timer) return;
    final startedAt = at ?? DateTime.now();
    for (var i = 0; i < _habits.length; i++) {
      if (i != index && _habits[i].timerStartedAt != null) {
        _pauseAt(i, startedAt);
      }
    }
    if (_habits[index].timerStartedAt == null) {
      _habits[index] = _habits[index].copyWith(timerStartedAt: startedAt);
    }
    _updateTicker();
    await _changed(syncReminders: false);
  }

  Future<void> pauseTimer(String id, {DateTime? at}) async {
    final index = _indexOf(id);
    if (index == -1 || _habits[index].timerStartedAt == null) return;
    _pauseAt(index, at ?? DateTime.now());
    _updateTicker();
    await _changed(syncReminders: false);
  }

  Future<void> resetTimer(String id, {DateOnly? date}) async {
    final index = _indexOf(id);
    if (index == -1) return;
    final targetDate = date ?? DateOnly.today();
    final tracked = Map<DateOnly, int>.of(_habits[index].trackedSecondsByDate)
      ..remove(targetDate);
    final completed = Set<DateOnly>.of(_habits[index].completedDates)
      ..remove(targetDate);
    _habits[index] = _habits[index].copyWith(
      trackedSecondsByDate: tracked,
      completedDates: completed,
      timerStartedAt: null,
    );
    _updateTicker();
    await _changed(syncReminders: false);
  }

  void _pauseAt(int index, DateTime at) {
    final habit = _habits[index];
    final started = habit.timerStartedAt;
    if (started == null) return;
    final date = DateOnly.fromDateTime(started);
    final elapsed = at.difference(started).inSeconds.clamp(0, 1 << 31);
    final tracked = Map<DateOnly, int>.of(habit.trackedSecondsByDate);
    tracked[date] = (tracked[date] ?? 0) + elapsed;
    final completed = Set<DateOnly>.of(habit.completedDates);
    if (tracked[date]! >= habit.timerTargetMinutes * 60) completed.add(date);
    _habits[index] = habit.copyWith(
      trackedSecondsByDate: tracked,
      completedDates: completed,
      timerStartedAt: null,
    );
  }

  Future<void> deleteHabit(String id) async {
    _habits.removeWhere((habit) => habit.id == id);
    _updateTicker();
    await _changed();
  }

  Future<void> deleteAll() async {
    _habits.clear();
    _updateTicker();
    notifyListeners();
    try {
      await _repository.deleteAll();
      _hasStorageError = false;
    } catch (_) {
      _hasStorageError = true;
    }
    await _syncReminders();
    notifyListeners();
  }

  int _indexOf(String id) => _habits.indexWhere((habit) => habit.id == id);

  Future<void> _changed({bool syncReminders = true}) async {
    notifyListeners();
    await _persist();
    if (syncReminders) await _syncReminders();
  }

  Future<void> _persist() async {
    try {
      await _repository.saveAll(_habits);
      _hasStorageError = false;
    } catch (_) {
      _hasStorageError = true;
    }
    notifyListeners();
  }

  Future<void> _syncReminders() async {
    final service = reminders;
    if (service == null) return;
    try {
      await service.syncHabitReminders(reminderPlanner.plan(_habits));
      _hasNotificationError = false;
    } catch (_) {
      _hasNotificationError = true;
    }
  }

  void _updateTicker() {
    final running = _habits.any((habit) => habit.timerStartedAt != null);
    if (running && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        notifyListeners();
      });
    } else if (!running) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
