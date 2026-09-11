import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../domain/logic/focus_arranger.dart';
import '../../domain/models/task.dart';
import '../../state/app_state.dart';
import '../../state/focus_timer_controller.dart';
import '../../state/settings_controller.dart';
import '../widgets/common.dart';
import '../widgets/task_row.dart';
import '../widgets/task_flows.dart';
import 'focus_timer_screen.dart';
import 'search_screen.dart';
import 'task_editor_screen.dart';

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
          padding: const EdgeInsets.only(bottom: 8),
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
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(spotlight ? 16 : 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.update, size: 20, color: colors.accent),
                  const SizedBox(width: 6),
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
              onTap: () => TaskEditorScreen.open(context, task: task),
              onToggle: () => completeTaskFlow(context, state, task),
              onSnooze: task.hasAlarm || task.hasReminders
                  ? () => snoozeFlow(context, state, task)
                  : null,
            ),
          ),
        );

    final timer = context.watch<FocusTimerController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus'),
        actions: [
          if (timer.isActive)
            Padding(
              padding: const EdgeInsets.only(right: 4),
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
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (tags.isNotEmpty)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
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
                    ),
                    for (final tag in tags)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(
                            Icons.tag_rounded,
                            size: 16,
                            color: _tagColor(colors, tag),
                          ),
                          label: Text('#$tag'),
                          selected:
                              _tagFilter?.toLowerCase() == tag.toLowerCase(),
                          showCheckmark: false,
                          side: BorderSide.none,
                          backgroundColor: _tagColor(
                            colors,
                            tag,
                          ).withValues(alpha: 0.08),
                          selectedColor: _tagColor(
                            colors,
                            tag,
                          ).withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color:
                                _tagFilter?.toLowerCase() == tag.toLowerCase()
                                ? _tagColor(colors, tag)
                                : colors.textSecondary,
                            fontWeight:
                                _tagFilter?.toLowerCase() == tag.toLowerCase()
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          onSelected: (v) =>
                              setState(() => _tagFilter = v ? tag : null),
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(child: _body(state, sections, colors, row)),
          ],
        ),
      ),
    );
  }

  Widget _body(
    AppState state,
    FocusSections sections,
    AppColors colors,
    Widget Function(Task task, {bool spotlight, bool overdue}) row,
  ) {
    if (sections.isEmpty) {
      return _tagFilter == null
          ? const _EmptyFocus()
          : Center(
              child: Text(
                'Nothing open with #$_tagFilter.',
                style: TextStyle(fontSize: 15, color: colors.textSecondary),
              ),
            );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      children: [
        if (state.hasStorageError) const _StorageErrorBanner(),
        if (sections.spotlight.isNotEmpty) ...[
          SectionHeader('Up next', color: colors.accent),
          for (final task in sections.spotlight) row(task, spotlight: true),
        ],
        if (sections.overdue.isNotEmpty) ...[
          SectionHeader(
            'Overdue',
            color: colors.overdue,
            trailing: '${sections.overdue.length}',
          ),
          for (final task in sections.overdue) row(task, overdue: true),
        ],
        if (sections.today.isNotEmpty) ...[
          SectionHeader('Today', trailing: '${sections.today.length}'),
          for (final task in sections.today) row(task),
        ],
        if (sections.upcoming.isNotEmpty) ...[
          const SectionHeader('Upcoming'),
          for (final task in sections.upcoming) row(task),
        ],
      ],
    );
  }
}

Color _tagColor(AppColors colors, String tag) {
  final palette = [
    colors.accent,
    colors.low,
    colors.done,
    colors.medium,
    colors.overdue,
  ];
  final seed = tag.toLowerCase().codeUnits.fold<int>(
    0,
    (sum, unit) => sum + unit,
  );
  return palette[seed % palette.length];
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
          const SizedBox(height: 14),
          Text(
            'You are clear for now.',
            style: TextStyle(
              fontSize: 17,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
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
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.overdue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.overdue.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.overdue, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Some changes could not be saved to device storage. Recent '
              'edits may be lost when the app closes.',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
