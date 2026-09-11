import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
  Future<bool> isFirstLaunch();
  Future<void> markFirstLaunchDone();
  Future<bool> wasPermissionRequested();
  Future<void> markPermissionRequested();
  Future<void> clearAll();
}

class PrefsSettingsRepository implements SettingsRepository {
  static const _settingsKey = 'nudge.settings';
  static const _firstLaunchKey = 'nudge.firstLaunchDone';
  static const _permissionKey = 'nudge.permissionRequested';

  @override
  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return const AppSettings();
    }
  }

  @override
  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  @override
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_firstLaunchKey) ?? false);
  }

  @override
  Future<void> markFirstLaunchDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, true);
  }

  @override
  Future<bool> wasPermissionRequested() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionKey) ?? false;
  }

  @override
  Future<void> markPermissionRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionKey, true);
  }

  @override
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
    await prefs.remove(_permissionKey);
    // First-launch stays done: deleted sample tasks must never come back.
  }
}
