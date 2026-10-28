import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/goal_repository.dart';
import '../domain/models/swatch.dart';
import '../domain/models/date_only.dart';
import '../domain/models/goal.dart';

class GoalController extends ChangeNotifier {
  final GoalRepository _repository;
  final Uuid uuid;
  final List<Goal> _goals = [];
  bool _isLoaded = false;
  bool _hasStorageError = false;

  GoalController(this._repository, {this.uuid = const Uuid()});

  UnmodifiableListView<Goal> get goals => UnmodifiableListView(_goals);
  bool get isLoaded => _isLoaded;
  bool get hasStorageError => _hasStorageError;

  Goal? goalById(String id) {
    final index = _goals.indexWhere((goal) => goal.id == id);
    return index == -1 ? null : _goals[index];
  }

  Future<void> init() async {
    try {
      _goals
        ..clear()
        ..addAll(await _repository.loadAll());
      _hasStorageError = false;
    } catch (_) {
      _hasStorageError = true;
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> addGoal({
    required String title,
    String description = '',
    required DateOnly targetDate,
    required Swatch color,
    DateOnly? createdOn,
  }) async {
    final cleaned = title.trim();
    if (cleaned.isEmpty) return;
    _goals.add(
      Goal(
        id: uuid.v4(),
        title: cleaned,
        description: description.trim(),
        targetDate: targetDate,
        createdOn: createdOn ?? DateOnly.today(),
        color: color,
      ),
    );
    await _changed();
  }

  Future<void> updateGoal(
    String id, {
    required String title,
    required String description,
    required DateOnly targetDate,
    required Swatch color,
  }) async {
    final index = _indexOf(id);
    final cleaned = title.trim();
    if (index == -1 || cleaned.isEmpty) return;
    _goals[index] = _goals[index].copyWith(
      title: cleaned,
      description: description.trim(),
      targetDate: targetDate,
      color: color,
    );
    await _changed();
  }

  Future<void> updateProgress(String id, int percent) async {
    final index = _indexOf(id);
    if (index == -1) return;
    _goals[index] = _goals[index].copyWith(manualProgress: percent);
    await _changed();
  }

  Future<void> addCheckpoint(String goalId, {required String title}) async {
    final index = _indexOf(goalId);
    final cleaned = title.trim();
    if (index == -1 || cleaned.isEmpty) return;
    final checkpoints = List<GoalCheckpoint>.of(_goals[index].checkpoints)
      ..add(GoalCheckpoint(id: uuid.v4(), title: cleaned));
    _goals[index] = _goals[index].copyWith(checkpoints: checkpoints);
    await _changed();
  }

  Future<void> toggleCheckpoint(String goalId, String checkpointId) async {
    final index = _indexOf(goalId);
    if (index == -1) return;
    final checkpoints = _goals[index].checkpoints
        .map(
          (checkpoint) => checkpoint.id == checkpointId
              ? checkpoint.copyWith(isCompleted: !checkpoint.isCompleted)
              : checkpoint,
        )
        .toList(growable: false);
    _goals[index] = _goals[index].copyWith(checkpoints: checkpoints);
    await _changed();
  }

  Future<void> deleteCheckpoint(String goalId, String checkpointId) async {
    final index = _indexOf(goalId);
    if (index == -1) return;
    _goals[index] = _goals[index].copyWith(
      checkpoints: _goals[index].checkpoints
          .where((checkpoint) => checkpoint.id != checkpointId)
          .toList(growable: false),
    );
    await _changed();
  }

  Future<void> deleteGoal(String id) async {
    _goals.removeWhere((goal) => goal.id == id);
    await _changed();
  }

  Future<void> deleteAll() async {
    _goals.clear();
    try {
      await _repository.deleteAll();
      _hasStorageError = false;
    } catch (_) {
      _hasStorageError = true;
    }
    notifyListeners();
  }

  int _indexOf(String id) => _goals.indexWhere((goal) => goal.id == id);

  Future<void> _changed() async {
    notifyListeners();
    try {
      await _repository.saveAll(_goals);
      _hasStorageError = false;
    } catch (_) {
      _hasStorageError = true;
      notifyListeners();
    }
  }
}
