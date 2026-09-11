import 'package:flutter/foundation.dart';

import '../data/app_settings.dart';
import '../data/settings_repository.dart';
import '../services/notification_service.dart';

class SettingsController extends ChangeNotifier {
  final SettingsRepository _repository;
  final NotificationService _notifications;

  AppSettings _settings = const AppSettings();
  NotificationPermission _permission = NotificationPermission.notRequested;
  bool _permissionRequested = false;
  bool _exactDelivery = true;

  SettingsController(this._repository, this._notifications);

  AppSettings get settings => _settings;
  NotificationPermission get permission => _permission;
  bool get permissionRequested => _permissionRequested;
  bool get exactDeliveryAvailable => _exactDelivery;
  bool get notificationsUsable => _permission == NotificationPermission.granted;

  Future<void> load() async {
    _settings = await _repository.load();
    _permissionRequested = await _repository.wasPermissionRequested();
    await refreshPermissionState();
  }

  Future<void> refreshPermissionState() async {
    final state = await _notifications.permissionState();
    // Before the explanatory prompt has ever been shown, report
    // "not requested" rather than the platform's default "denied".
    _permission =
        !_permissionRequested && state == NotificationPermission.denied
        ? NotificationPermission.notRequested
        : state;
    _exactDelivery = await _notifications.exactDeliveryAvailable();
    notifyListeners();
  }

  /// Shows the OS permission dialog (once per explicit user request).
  Future<NotificationPermission> requestPermission() async {
    _permissionRequested = true;
    await _repository.markPermissionRequested();
    _permission = await _notifications.requestPermission();
    _exactDelivery = await _notifications.exactDeliveryAvailable();
    notifyListeners();
    return _permission;
  }

  Future<void> update(AppSettings settings) async {
    _settings = settings;
    notifyListeners();
    await _repository.save(settings);
  }

  Future<void> resetForDataWipe() async {
    await _repository.clearAll();
    _settings = const AppSettings();
    notifyListeners();
  }
}
