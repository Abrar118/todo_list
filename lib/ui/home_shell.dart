import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../services/home_widget_service.dart';
import '../state/app_state.dart';
import 'screens/calendar_screen.dart';
import 'screens/focus_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/habits_screen.dart';
import 'screens/quick_add_sheet.dart';
import 'screens/task_editor_screen.dart';
import 'widgets/frosted_bottom_navigation_bar.dart';
import 'widgets/mesh_backdrop.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;
  late final AppState _appState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appState = context.read<AppState>();
    _appState.openTaskRequest.addListener(_onOpenTaskRequest);
    context.read<HomeWidgetService>().handleClicks(
      onOpenTask: (taskId) => _appState.openTaskRequest.value = taskId,
      onQuickAdd: () {
        if (mounted) QuickAddSheet.open(context);
      },
      onShowFocus: () {
        if (mounted) setState(() => _index = 0);
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appState.openTaskRequest.removeListener(_onOpenTaskRequest);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      context.read<AppState>().onAppResumed();
    }
  }

  /// A notification tap asked us to open a specific task.
  void _onOpenTaskRequest() {
    final state = context.read<AppState>();
    final taskId = state.openTaskRequest.value;
    if (taskId == null) return;
    state.openTaskRequest.value = null;
    final task = state.taskById(taskId);
    if (task != null && mounted) {
      setState(() => _index = 0);
      TaskEditorScreen.open(context, task: task);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      // The backdrop paints the background for all four tabs, so each tab's
      // own Scaffold is transparent (see their `backgroundColor`).
      body: MeshBackdrop(
        child: IndexedStack(
          index: _index,
          children: const [
            FocusScreen(),
            CalendarScreen(),
            HabitsScreen(),
            GoalsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: FrostedBottomNavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        onAdd: () => QuickAddSheet.open(context),
        items: [
          FrostedNavigationItem(
            icon: Icons.center_focus_strong_outlined,
            selectedIcon: Icons.center_focus_strong,
            label: 'Focus',
            color: context.colors.accent,
          ),
          FrostedNavigationItem(
            icon: Icons.calendar_month_outlined,
            selectedIcon: Icons.calendar_month,
            label: 'Calendar',
            color: context.colors.low,
          ),
          FrostedNavigationItem(
            icon: Icons.loop_outlined,
            selectedIcon: Icons.loop_rounded,
            label: 'Habits',
            color: context.colors.medium,
          ),
          FrostedNavigationItem(
            icon: Icons.flag_outlined,
            selectedIcon: Icons.flag_rounded,
            label: 'Goals',
            color: context.colors.overdue,
          ),
        ],
      ),
    );
  }
}
