import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_tokens.dart';
import '../../domain/logic/focus_arranger.dart';
import '../../domain/models/task.dart';
import '../../state/app_state.dart';
import '../../state/focus_timer_controller.dart';
import '../../state/settings_controller.dart';
import '../widgets/common.dart';
import '../widgets/frosted_bottom_navigation_bar.dart';
import '../widgets/task_row.dart';
import '../widgets/task_flows.dart';
import 'focus_timer_screen.dart';
import 'completed_screen.dart';
import 'quick_add_sheet.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'task_editor_screen.dart';

enum _FocusMenuAction { completed, settings }

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  String? _tagFilter;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final settings = context.watch<SettingsController>().settings;
    final colors = context.colors;
    final tags = state.allTags;
    if (_tagFilter != null &&
        !tags.any((t) => t.toLowerCase() == _tagFilter!.toLowerCase())) {
      // The last task with this tag was completed or deleted.
      _tagFilter = null;
    }
    final sections = state.focusSections(tag: _tagFilter);
    final compact = settings.compactRows;

    if (!state.isLoaded) {
      return Center(child: CircularProgressIndicator(color: colors.accent));
    }

    Widget row(Task task, {bool spotlight = false, bool overdue = false}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Dismissible(
            key: ValueKey('defer-${task.id}'),
            direction: DismissDirection.endToStart,
            // The sheet handles the action; the row itself never dismisses.
            confirmDismiss: (_) async {
              await deferFlow(context, state, task);
              return false;
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppSpacing.xl),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.14),
                borderRadius: AppRadii.mediumRadius,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.update, size: 20, color: colors.accent),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Later',
                    style: TextStyle(
                      color: colors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            child: TaskRow(
              task: task,
              rule: state.ruleOf(task),
              spotlight: spotlight,
              compact: compact && !spotlight,
              showOverdue: overdue || spotlight,
              showTaskBackground: true,
              onTap: () => TaskEditorScreen.open(context, task: task),
              onToggle: () => completeTaskFlow(context, state, task),
              onSnooze: task.hasAlarm || task.hasReminders
                  ? () => snoozeFlow(context, state, task)
                  : null,
            ),
          ),
        );

    final timer = context.watch<FocusTimerController>();
    final entries = _entriesFor(sections, colors, row);

    return Scaffold(
      // The shell's MeshBackdrop paints the background for all tabs.
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          rootAppBar(
            title: const Text('Focus'),
            actions: [
              if (timer.isActive)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: ActionChip(
                    avatar: Icon(
                      timer.phase == TimerPhase.work
                          ? Icons.timer
                          : Icons.free_breakfast_outlined,
                      size: 16,
                      color: colors.accent,
                    ),
                    label: Text(FocusTimerScreen.format(timer.remaining)),
                    tooltip: 'Open focus timer',
                    onPressed: () => FocusTimerScreen.open(context),
                  ),
                ),
              IconButton(
                tooltip: 'Search tasks',
                icon: const Icon(Icons.search),
                onPressed: () => SearchScreen.open(context),
              ),
              // Search is the only true action here; Completed and Settings
              // are destinations, so one menu holds both.
              PopupMenuButton<_FocusMenuAction>(
                tooltip: 'More',
                icon: const Icon(Icons.more_horiz),
                onSelected: (action) => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => switch (action) {
                      _FocusMenuAction.completed => const CompletedScreen(),
                      _FocusMenuAction.settings => const SettingsScreen(),
                    },
                  ),
                ),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _FocusMenuAction.completed,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.task_alt_rounded),
                      title: Text('Completed'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _FocusMenuAction.settings,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.settings_outlined),
                      title: Text('Settings'),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),
          if (tags.isNotEmpty) SliverToBoxAdapter(child: _tagBar(tags, colors)),
          if (state.hasStorageError)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
                child: _StorageErrorBanner(),
              ),
            ),
          if (entries.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _tagFilter == null
                  ? const _EmptyFocus()
                  : Center(
                      child: Text(
                        'Nothing open with #$_tagFilter.',
                        style: TextStyle(
                          fontSize: AppTypography.body,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                FrostedBottomNavigationBar.heightOf(context) + AppSpacing.sm,
              ),
              sliver: SliverList.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) => entries[index](),
              ),
            ),
        ],
      ),
    );
  }

  /// Headers and rows flattened into one lazy list, so only what is on
  /// screen is built. Each entry is a thunk: nothing is constructed until
  /// the sliver asks for that index.
  List<Widget Function()> _entriesFor(
    FocusSections sections,
    AppColors colors,
    Widget Function(Task task, {bool spotlight, bool overdue}) row,
  ) {
    final entries = <Widget Function()>[];
    void section(
      String title,
      List<Task> tasks, {
      String? trailing,
      Color? color,
      bool spotlight = false,
      bool overdue = false,
    }) {
      if (tasks.isEmpty) return;
      final first = entries.isEmpty;
      entries.add(
        () => SectionHeader(
          title,
          trailing: trailing,
          color: color,
          tight: first,
        ),
      );
      for (final task in tasks) {
        entries.add(() => row(task, spotlight: spotlight, overdue: overdue));
      }
    }

    section(
      'Up next',
      sections.spotlight,
      color: colors.accent,
      spotlight: true,
    );
    section(
      'Overdue',
      sections.overdue,
      color: colors.overdue,
      trailing: '${sections.overdue.length}',
      overdue: true,
    );
    section('Today', sections.today, trailing: '${sections.today.length}');
    section('Upcoming', sections.upcoming);
    return entries;
  }

  Widget _tagBar(List<String> tags, AppColors colors) => SizedBox(
    height: 44,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: tags.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              avatar: Icon(
                Icons.all_inclusive_rounded,
                size: 17,
                color: colors.accent,
              ),
              label: const Text('All'),
              selected: _tagFilter == null,
              showCheckmark: false,
              side: BorderSide.none,
              backgroundColor: colors.accent.withValues(alpha: 0.08),
              selectedColor: colors.accent.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: _tagFilter == null
                    ? colors.accent
                    : colors.textSecondary,
                fontWeight: _tagFilter == null
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
              onSelected: (_) => setState(() => _tagFilter = null),
            ),
          );
        }
        final tag = tags[index - 1];
        final selected = _tagFilter?.toLowerCase() == tag.toLowerCase();
        final tagColor = colors.decorativeFor(tag);
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: ChoiceChip(
            avatar: Icon(Icons.tag_rounded, size: 16, color: tagColor),
            label: Text('#$tag'),
            selected: selected,
            showCheckmark: false,
            side: BorderSide.none,
            backgroundColor: tagColor.withValues(alpha: 0.08),
            selectedColor: tagColor.withValues(alpha: 0.2),
            labelStyle: TextStyle(
              color: selected ? tagColor : colors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
            onSelected: (v) => setState(() => _tagFilter = v ? tag : null),
          ),
        );
      },
    ),
  );
}

class _EmptyFocus extends StatelessWidget {
  const _EmptyFocus();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 40, color: colors.textMuted),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'You are clear for now.',
            style: TextStyle(
              fontSize: AppTypography.callout,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // An empty screen is an invitation to act, not just a status.
          FilledButton(
            onPressed: () => QuickAddSheet.open(context),
            child: const Text('Add a task'),
          ),
        ],
      ),
    );
  }
}

class _StorageErrorBanner extends StatelessWidget {
  const _StorageErrorBanner();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.overdue.withValues(alpha: 0.12),
        borderRadius: AppRadii.mediumRadius,
        border: Border.all(color: colors.overdue.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.overdue, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Some changes could not be saved to device storage. Recent '
              'edits may be lost when the app closes.',
              style: TextStyle(fontSize: AppTypography.footnote),
            ),
          ),
        ],
      ),
    );
  }
}
