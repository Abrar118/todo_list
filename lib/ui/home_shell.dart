import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_tokens.dart';
import '../services/home_widget_service.dart';
import '../state/app_state.dart';
import 'screens/calendar_screen.dart';
import 'screens/focus_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/habits_screen.dart';
import 'screens/quick_add_sheet.dart';
import 'screens/task_editor_screen.dart';
import 'widgets/common.dart';
import 'widgets/meadow.dart';

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

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final body = IndexedStack(
      index: _index,
      children: const [
        FocusScreen(),
        CalendarScreen(),
        HabitsScreen(),
        GoalsScreen(),
      ],
    );

    // Tabs are sections, never actions: each tab owns its add action (the
    // nav-bar + on iOS, a FAB on Android), so the bar only navigates. Both
    // platforms keep their own bar, floated as a chunky white block on the
    // page. The body stops above it (the gutters around the block are the
    // same page colour), so each tab's FAB floats clear of it.
    final Widget bar = isCupertino(context)
        ? CupertinoTabBar(
            currentIndex: _index,
            onTap: _select,
            activeColor: colors.accent,
            inactiveColor: colors.textMuted,
            backgroundColor: Colors.transparent,
            border: null,
            height: 58,
            iconSize: 26,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.scope),
                label: 'Focus',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.calendar),
                label: 'Calendar',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.arrow_2_circlepath),
                label: 'Habits',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.flag),
                activeIcon: Icon(CupertinoIcons.flag_fill),
                label: 'Goals',
              ),
            ],
          )
        : NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _select,
            backgroundColor: Colors.transparent,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.center_focus_strong_outlined),
                selectedIcon: Icon(Icons.center_focus_strong),
                label: 'Focus',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: 'Calendar',
              ),
              NavigationDestination(
                icon: Icon(Icons.loop_outlined),
                selectedIcon: Icon(Icons.loop_rounded),
                label: 'Habits',
              ),
              NavigationDestination(
                icon: Icon(Icons.flag_outlined),
                selectedIcon: Icon(Icons.flag_rounded),
                label: 'Goals',
              ),
            ],
          );

    final inset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: body,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          inset > 0 ? inset : AppSpacing.md,
        ),
        child: Material(
          color: colors.card,
          shape: chunkyCard(colors, radius: AppRadii.lg, depth: 4),
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          shadowColor: const Color(0x33000000),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            // The bar sits above the home indicator already, so it must not
            // pad for it a second time.
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: bar,
            ),
          ),
        ),
      ),
    );
  }
}
