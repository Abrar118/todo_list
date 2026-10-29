import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_tokens.dart';
import '../../domain/logic/escalation.dart';
import '../../domain/logic/ticket_age.dart';
import '../../domain/models/priority.dart';
import '../../domain/models/recurrence.dart';
import '../../domain/models/task.dart';
import '../../state/app_state.dart';
import '../../state/focus_timer_controller.dart';
import '../../state/settings_controller.dart';
import '../widgets/common.dart';
import '../widgets/task_flows.dart';
import '../widgets/task_row.dart';
import '../widgets/ticket.dart';
import 'completed_screen.dart';
import 'focus_timer_screen.dart';
import 'quick_add_sheet.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'task_editor_screen.dart';

/// Focus is the ticket rail. The task that has waited longest sits on the
/// pass at the top, stamped with how late it is; everything else hangs on
/// the rail below in sentence-case sections, each row ending in its own
/// stamp. Put a task off and it comes back hotter.
class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  String? _tagFilter;

  /// Tickets being spiked: struck through and sliding off before the
  /// completion lands and the list closes over them.
  final _spiking = <String>{};

  static const _spikeDuration = Duration(milliseconds: 320);

  Future<void> _complete(AppState state, Task task) async {
    if (!MediaQuery.disableAnimationsOf(context)) {
      setState(() => _spiking.add(task.id));
      await Future<void>.delayed(_spikeDuration);
      if (!mounted) return;
    }
    await completeTaskFlow(context, state, task);
    if (mounted) setState(() => _spiking.remove(task.id));
  }

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
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    // Swiping any ticket left puts it off, on the pass and on the rail alike.
    Widget deferSwipe(Task task, Widget child) => Dismissible(
      key: ValueKey('defer-${task.id}'),
      direction: DismissDirection.endToStart,
      // The sheet handles the action; the ticket itself never dismisses.
      confirmDismiss: (_) async {
        await deferFlow(context, state, task);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        color: colors.pressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.update, size: 20, color: colors.textPrimary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Later',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: child,
    );

    Widget row(Task task, {required bool first, required bool last}) =>
        deferSwipe(
          task,
          RailTile(
            first: first,
            last: last,
            child: _Spike(
              spiking: _spiking.contains(task.id),
              child: TaskRow(
                task: task,
                rule: state.ruleOf(task),
                compact: compact,
                showOverdue: true,
                showTaskBackground: true,
                stamp: true,
                striking: _spiking.contains(task.id),
                onTap: () => TaskEditorScreen.open(context, task: task),
                onToggle: () => _complete(state, task),
                onSnooze: task.hasAlarm || task.hasReminders
                    ? () => snoozeFlow(context, state, task)
                    : null,
              ),
            ),
          ),
        );

    final lead = sections.spotlight.isEmpty ? null : sections.spotlight.first;
    final entries = <Widget Function()>[
      if (lead != null)
        () => deferSwipe(
          lead,
          _Spike(
            spiking: _spiking.contains(lead.id),
            child: _PassTicket(
              task: lead,
              rule: state.ruleOf(lead),
              spiking: _spiking.contains(lead.id),
              onOpen: () => TaskEditorScreen.open(context, task: lead),
              onDone: () => _complete(state, lead),
              onLater: () => deferFlow(context, state, lead),
            ),
          ),
        ),
    ];
    void section(String title, List<Task> tasks, {String? trailing}) {
      if (tasks.isEmpty) return;
      final first = entries.isEmpty;
      entries.add(() => SectionHeader(title, trailing: trailing, tight: first));
      for (final (i, task) in tasks.indexed) {
        entries.add(
          () => row(task, first: i == 0, last: i == tasks.length - 1),
        );
      }
    }

    section('Up next', sections.spotlight.skip(1).toList());
    section(
      'Overdue',
      sections.overdue,
      trailing: '${sections.overdue.length}',
    );
    section('Today', sections.today, trailing: '${sections.today.length}');
    section('Coming up', sections.upcoming);
    if (entries.isNotEmpty) {
      entries.add(
        () => Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          child: Center(
            child: TextButton(
              onPressed: () => CompletedScreen.open(context),
              child: const Text('Show completed'),
            ),
          ),
        ),
      );
    }

    final timer = context.watch<FocusTimerController>();
    void addTask() => QuickAddSheet.open(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: rootAddFab(
        context,
        onPressed: addTask,
        tooltip: 'Add task',
      ),
      body: CustomScrollView(
        slivers: [
          rootAppBar(
            context,
            title: 'Focus',
            onAdd: addTask,
            addTooltip: 'Add task',
            actions: [
              if (timer.isActive)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: ActionChip(
                    avatar: Icon(
                      timer.phase == TimerPhase.work
                          ? Icons.timer_outlined
                          : Icons.free_breakfast_outlined,
                      size: 16,
                    ),
                    label: Text(
                      FocusTimerScreen.format(timer.remaining),
                      style: const TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    tooltip: 'Open focus timer',
                    onPressed: () => FocusTimerScreen.open(context),
                  ),
                ),
              IconButton(
                tooltip: 'Search tasks',
                icon: Icon(
                  isCupertino(context) ? CupertinoIcons.search : Icons.search,
                ),
                onPressed: () => SearchScreen.open(context),
              ),
              const _FocusMenu(),
            ],
          ),
          if (tags.isNotEmpty) SliverToBoxAdapter(child: _tagBar(tags)),
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
                AppSpacing.sm,
                AppSpacing.lg,
                listBottomInset(context),
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

  Widget _tagBar(List<String> tags) => SizedBox(
    height: 48,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: tags.length + 1,
      itemBuilder: (context, index) {
        final tag = index == 0 ? null : tags[index - 1];
        final selected = tag == null
            ? _tagFilter == null
            : _tagFilter?.toLowerCase() == tag.toLowerCase();
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: ChoiceChip(
            label: Text(tag == null ? 'All' : '#$tag'),
            selected: selected,
            showCheckmark: false,
            onSelected: (v) => setState(() => _tagFilter = v ? tag : null),
          ),
        );
      },
    ),
  );
}

/// Completed and Settings are destinations, not actions, so they share one
/// overflow: a pull-up action sheet on iOS, a Material menu on Android.
class _FocusMenu extends StatelessWidget {
  const _FocusMenu();

  void _open(BuildContext context, Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    if (isCupertino(context)) {
      return IconButton(
        tooltip: 'More',
        icon: const Icon(CupertinoIcons.ellipsis_circle),
        onPressed: () => showCupertinoModalPopup<void>(
          context: context,
          builder: (sheetContext) => CupertinoActionSheet(
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _open(context, const CompletedScreen());
                },
                child: const Text('Completed'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _open(context, const SettingsScreen());
                },
                child: const Text('Settings'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Cancel'),
            ),
          ),
        ),
      );
    }
    return PopupMenuButton<Widget>(
      tooltip: 'More',
      onSelected: (screen) => _open(context, screen),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: CompletedScreen(),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.task_alt_rounded),
            title: Text('Completed'),
          ),
        ),
        PopupMenuItem(
          value: SettingsScreen(),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.settings_outlined),
            title: Text('Settings'),
          ),
        ),
      ],
    );
  }
}

/// The ticket on the pass: the one task that has waited longest, printed
/// large with its stamp, and the two things you can do about it right there.
/// Later is a button here, not only a swipe, because deferring on purpose is
/// half of what Nudge is for.
class _PassTicket extends StatelessWidget {
  final Task task;
  final RecurrenceRule? rule;
  final bool spiking;
  final VoidCallback onOpen;
  final VoidCallback onDone;
  final VoidCallback onLater;

  const _PassTicket({
    required this.task,
    required this.rule,
    required this.spiking,
    required this.onOpen,
    required this.onDone,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();
    final age = TicketAge.of(task, now);
    final stamp = stampText(task, age);
    final putOff = switch (task.deferralCount) {
      0 => Escalation.describe(task, now),
      1 => 'Put off once',
      _ => Escalation.describe(task, now),
    };

    final meta = <Widget>[
      if (task.priority != TaskPriority.none)
        MetaChip(
          icon: Icons.flag_outlined,
          label: '${task.priority.label} priority',
          color: priorityColor(context, task.priority),
        ),
      if (task.subtasks.isNotEmpty)
        MetaChip(
          icon: Icons.checklist_outlined,
          label: '${task.completedSubtaskCount} of ${task.subtasks.length}',
        ),
      if (task.isRecurring)
        MetaChip(icon: Icons.repeat, label: rule?.describe() ?? 'Repeats'),
    ];

    return Semantics(
      container: true,
      label: [
        'Up next: ${task.title}',
        if (stamp != null) '${stamp.caption} ${stamp.value}',
        ?putOff,
      ].join(', '),
      child: Material(
        color: colors.card,
        shape: AppRadii.mediumShape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: AppTypography.title3,
                                height: 1.2,
                                fontWeight: FontWeight.w600,
                                letterSpacing: AppTypography.trackingFor(
                                  AppTypography.title3,
                                ),
                                color: spiking
                                    ? colors.textMuted
                                    : colors.textPrimary,
                                decoration: spiking
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: colors.textMuted,
                                decorationThickness: 2,
                              ),
                            ),
                            if (meta.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.md,
                                runSpacing: AppSpacing.xs,
                                children: meta,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      TicketStamp(task: task, age: age, large: true),
                    ],
                  ),
                ),
                if (putOff != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  ExcludeSemantics(
                    child: Text(
                      putOff,
                      style: TextStyle(
                        fontSize: AppTypography.footnote,
                        fontWeight: FontWeight.w600,
                        color: heatColor(colors, age.heat),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: spiking ? null : onDone,
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: const Text('Done'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: spiking ? null : onLater,
                        icon: const Icon(Icons.update_rounded, size: 20),
                        label: const Text('Later'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A completed ticket slides off the rail and fades, after its strike-through
/// has had a moment to land. Collapses to nothing under Reduce Motion,
/// because [FocusScreen] then completes immediately.
class _Spike extends StatelessWidget {
  final bool spiking;
  final Widget child;

  const _Spike({required this.spiking, required this.child});

  @override
  Widget build(BuildContext context) => AnimatedSlide(
    offset: spiking ? const Offset(0.08, 0) : Offset.zero,
    duration: AppMotion.slow,
    curve: AppMotion.exitCurve,
    child: AnimatedOpacity(
      opacity: spiking ? 0.0 : 1.0,
      duration: AppMotion.slow,
      curve: AppMotion.exitCurve,
      child: child,
    ),
  );
}

class _EmptyFocus extends StatelessWidget {
  const _EmptyFocus();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Nothing is waiting on you.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypography.title3,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tasks you add land here, oldest first. Put one off and it comes '
            'back a little louder each time, until it is done.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypography.body,
              height: 1.4,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
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
      decoration: ShapeDecoration(
        color: colors.card,
        shape: AppRadii.shape(
          AppRadii.md,
          side: BorderSide(color: colors.overdue),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.overdue, size: 20),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
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
