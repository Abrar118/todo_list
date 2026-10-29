import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'data/app_database.dart';
import 'data/app_settings.dart';
import 'data/habit_repository.dart';
import 'data/goal_repository.dart';
import 'data/settings_repository.dart';
import 'data/task_repository.dart';
import 'services/app_icon_service.dart';
import 'services/home_widget_service.dart';
import 'services/local_notification_service.dart';
import 'state/app_state.dart';
import 'state/focus_timer_controller.dart';
import 'state/habit_controller.dart';
import 'state/goal_controller.dart';
import 'state/settings_controller.dart';
import 'ui/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notifications = LocalNotificationService();
  await notifications.init();

  final settingsRepository = PrefsSettingsRepository();
  final settingsController = SettingsController(
    settingsRepository,
    notifications,
  );
  await settingsController.load();

  final db = await AppDatabase.open();
  final taskRepository = SqfliteTaskRepository(db);
  final appState = AppState(taskRepository, notifications, settingsController);
  await appState.init();

  final habitController = HabitController(
    PrefsHabitRepository(),
    reminders: notifications,
  );
  await habitController.init();

  final goalController = GoalController(PrefsGoalRepository());
  await goalController.init();

  if (await settingsRepository.isFirstLaunch()) {
    // Mark first before seeding: deleted samples must never be recreated,
    // even if seeding is interrupted.
    await settingsRepository.markFirstLaunchDone();
    await appState.addSampleTasks();
  }

  final homeWidgets = HomeWidgetService();
  await homeWidgets.attach(appState);

  // The home-screen icon and widgets follow the palette chosen in Settings.
  final appIcon = AppIconService();
  var palette = settingsController.settings.palette;
  unawaited(homeWidgets.pushTheme(palette));
  unawaited(appIcon.apply(palette));
  settingsController.addListener(() {
    final next = settingsController.settings.palette;
    if (next == palette) return;
    palette = next;
    unawaited(homeWidgets.pushTheme(next));
    unawaited(appIcon.apply(next));
  });

  final focusTimer = FocusTimerController(
    appState,
    settingsController,
    notifications,
  );

  runApp(
    NudgeApp(
      appState: appState,
      settingsController: settingsController,
      homeWidgets: homeWidgets,
      focusTimer: focusTimer,
      habitController: habitController,
      goalController: goalController,
    ),
  );
}

class NudgeApp extends StatelessWidget {
  final AppState appState;
  final SettingsController settingsController;
  final HomeWidgetService homeWidgets;
  final FocusTimerController focusTimer;
  final HabitController habitController;
  final GoalController goalController;

  const NudgeApp({
    super.key,
    required this.appState,
    required this.settingsController,
    required this.homeWidgets,
    required this.focusTimer,
    required this.habitController,
    required this.goalController,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsController),
        ChangeNotifierProvider.value(value: appState),
        Provider<HomeWidgetService>.value(value: homeWidgets),
        ChangeNotifierProvider<FocusTimerController>.value(value: focusTimer),
        ChangeNotifierProvider<HabitController>.value(value: habitController),
        ChangeNotifierProvider<GoalController>.value(value: goalController),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) => MaterialApp(
          title: 'Nudge',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(settings.settings.palette),
          darkTheme: AppTheme.dark(settings.settings.palette),
          themeMode: switch (settings.settings.themeMode) {
            AppThemeMode.system => ThemeMode.system,
            AppThemeMode.dark => ThemeMode.dark,
            AppThemeMode.light => ThemeMode.light,
          },
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          builder: (context, child) {
            if (!settings.settings.reduceMotion) return child!;
            // App-level Reduce Motion preference: report the platform
            // disable-animations flag so transitions and implicit
            // animations collapse to their end states.
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            );
          },
          home: const HomeShell(),
        ),
      ),
    );
  }
}
