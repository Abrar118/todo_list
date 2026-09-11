import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/habit.dart';

abstract interface class HabitRepository {
  Future<List<Habit>> loadAll();
  Future<void> saveAll(List<Habit> habits);
  Future<void> deleteAll();
}

class PrefsHabitRepository implements HabitRepository {
  static const _storageKey = 'nudge.habits.v1';

  @override
  Future<List<Habit>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final source = prefs.getString(_storageKey);
    if (source == null || source.isEmpty) return [];

    final decoded = jsonDecode(source) as List<dynamic>;
    return decoded
        .map((value) => Habit.fromJson(value as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<void> saveAll(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(habits.map((habit) => habit.toJson()).toList());
    final saved = await prefs.setString(_storageKey, encoded);
    if (!saved) throw StateError('Could not save habits');
  }

  @override
  Future<void> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();
    final removed = await prefs.remove(_storageKey);
    if (!removed && prefs.containsKey(_storageKey)) {
      throw StateError('Could not delete habits');
    }
  }
}
