import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/goal.dart';

abstract interface class GoalRepository {
  Future<List<Goal>> loadAll();
  Future<void> saveAll(List<Goal> goals);
  Future<void> deleteAll();
}

class PrefsGoalRepository implements GoalRepository {
  static const _storageKey = 'nudge.goals.v1';

  @override
  Future<List<Goal>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final source = prefs.getString(_storageKey);
    if (source == null || source.isEmpty) return [];
    return (jsonDecode(source) as List<dynamic>)
        .map((value) => Goal.fromJson(value as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<void> saveAll(List<Goal> goals) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      _storageKey,
      jsonEncode(goals.map((goal) => goal.toJson()).toList()),
    );
    if (!saved) throw StateError('Could not save goals');
  }

  @override
  Future<void> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();
    final removed = await prefs.remove(_storageKey);
    if (!removed && prefs.containsKey(_storageKey)) {
      throw StateError('Could not delete goals');
    }
  }
}
