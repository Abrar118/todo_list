import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_tokens.dart';
import '../../core/chunky_border.dart';
import '../../domain/logic/escalation.dart';
import '../../domain/logic/ticket_age.dart';
import '../../domain/models/date_only.dart';
import '../../domain/models/priority.dart';
import '../../domain/models/recurrence.dart';
import '../../domain/models/task.dart';
import '../../state/app_state.dart';
import '../../state/focus_timer_controller.dart';
import '../../state/habit_controller.dart';
import '../../state/settings_controller.dart';
import '../widgets/common.dart';
import '../widgets/meadow.dart';
import '../widgets/task_flows.dart';
import '../widgets/task_row.dart';
import '../widgets/ticket.dart';
import 'completed_screen.dart';
import 'focus_timer_screen.dart';
import 'quick_add_sheet.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'task_editor_screen.dart';

/// Focus opens on the meadow: a greeting, three stat tiles (habit streak,
/// done today, still waiting), then the task that has waited longest on the
/// dark-forest hero card, stamped with how late it is. Everything else sits
/// below as chunky cards in sentence-case sections, each ending in its own
/// stamp. Put a task off and it comes back hotter.
class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  String? _tagFilter;

  /// Tasks being spiked: struck through and sliding off before the
  /// completion lands and the list closes over them.
  final _spiking = <String>{};

  /// Strike, slide off, close the gap: the whole exit, after which the
  /// completion actually lands.
  static const _spikeDuration = Duration(milliseconds: 560);

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
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: ShapeDecoration(
          color: colors.tintSun,
          shape: AppRadii.mediumShape,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.update, size: 20, color: colors.textPrimary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Later',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      child: child,
    );

    Widget row(Task task) => deferSwipe(
      task,
      TaskCard(
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
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _HeroTask(
                task: lead,
                rule: state.ruleOf(lead),
                spiking: _spiking.contains(lead.id),
                onOpen: () => TaskEditorScreen.open(context, task: lead),
                onDone: () => _complete(state, lead),
                onLater: () => deferFlow(context, state, lead),
              ),
            ),
          ),
        ),
    ];
    void section(String title, List<Task> tasks, {String? trailing}) {
      if (tasks.isEmpty) return;
      final first = entries.isEmpty;
      entries.add(() => SectionHeader(title, trailing: trailing, tight: first));
      for (final task in tasks) {
        entries.add(() => row(task));
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

    final now = DateTime.now();
    final today = DateOnly.fromDateTime(now);
    final waiting = {
      for (final t in [
        ...sections.spotlight,
        ...sections.overdue,
        ...sections.today,
      ])
        t.id: t,
    }.values;
    final late = waiting.where((t) => t.isOverdue(now)).length;
    final doneToday = state.allTasks
        .where(
          (t) =>
              t.isCompleted &&
              t.completedAt != null &&
              DateOnly.fromDateTime(t.completedAt!) == today,
        )
        .length;
    final streak = context
        .watch<HabitController>()
        .habits
        .map((h) => h.currentStreak(today))
        .fold(0, (a, b) => a > b ? a : b);

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
            title: _greeting(now),
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
          SliverToBoxAdapter(
            child: MeadowHeader(
              child: _FocusSummary(
                waiting: waiting.length,
                late: late,
                doneToday: doneToday,
                streak: streak,
              ),
            ),
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

  static String _greeting(DateTime now) => switch (now.hour) {
    < 12 => 'Good morning',
    < 17 => 'Good afternoon',
    _ => 'Good evening',
  };

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

/// The line under the greeting and the three stat tiles, on the grass.
class _FocusSummary extends StatelessWidget {
  final int waiting;
  final int late;
  final int doneToday;
  final int streak;

  const _FocusSummary({
    required this.waiting,
    required this.late,
    required this.doneToday,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final line = switch ((waiting, late)) {
      (0, _) => 'Nothing waiting. Enjoy it.',
      (final w, 0) =>
        w == 1 ? 'One thing waiting on you.' : '$w things waiting on you.',
      (final w, final l) => '$w waiting, $l of them late.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The mascot stands on the grass beside the day's line, and cheers
        // when nothing is waiting.
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  line,
                  style: TextStyle(
                    fontSize: AppTypography.callout,
                    fontWeight: FontWeight.w800,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
            Mascot(
              mood: waiting == 0 ? MascotMood.cheer : MascotMood.idle,
              size: 84,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StatTile(
                art: Art.fire,
                value: '$streak',
                label: 'day streak',
                tint: colors.tintSun,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: StatTile(
                art: Art.checkMark,
                value: '$doneToday',
                label: 'done today',
                tint: colors.tintLeaf,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: StatTile(
                art: late > 0 ? Art.alarmClock : Art.hourglass,
                value: '$waiting',
                label: 'waiting',
                tint: colors.tintSky,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The hero card: the one task that has waited longest, on dark forest,
/// printed large with its stamp, and the two things you can do about it
/// right there. Later is a button here, not only a swipe, because putting
/// something off on purpose is half of what Nudge is for.
class _HeroTask extends StatelessWidget {
  final Task task;
  final RecurrenceRule? rule;
  final bool spiking;
  final VoidCallback onOpen;
  final VoidCallback onDone;
  final VoidCallback onLater;

  const _HeroTask({
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
    final heat = heroHeatColor(colors, age.heat);
    final putOff = switch (task.deferralCount) {
      0 => Escalation.describe(task, now),
      1 => 'Put off once',
      _ => Escalation.describe(task, now),
    };

    final meta = <Widget>[
      if (task.priority != TaskPriority.none)
        MetaChip(
          icon: priorityIcon(task.priority),
          label: '${task.priority.label} priority',
          color: colors.onHeroMuted,
        ),
      if (task.subtasks.isNotEmpty)
        MetaChip(
          icon: Icons.checklist_outlined,
          label: '${task.completedSubtaskCount} of ${task.subtasks.length}',
          color: colors.onHeroMuted,
        ),
      if (task.isRecurring)
        MetaChip(
          icon: Icons.repeat,
          label: rule?.describe() ?? 'Repeats',
          color: colors.onHeroMuted,
        ),
    ];

    final art = switch (age.heat) {
      >= 2 => Art.alarmClock,
      1 => Art.hourglass,
      _ => Art.bullseye,
    };

    return Semantics(
      container: true,
      label: [
        'Up next: ${task.title}',
        if (stamp != null) '${stamp.caption} ${stamp.value}'.trim(),
        ?putOff,
      ].join(', '),
      child: Material(
        color: colors.hero,
        shape: ChunkyBorder(
          radius: AppRadii.lg,
          depth: 5,
          edge: Color.alphaBlend(const Color(0x59000000), colors.hero),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg + 4,
              AppSpacing.lg + 4,
              AppSpacing.lg + 4,
              AppSpacing.lg + 9,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: AppTypography.trackingFor(
                                      AppTypography.title3,
                                    ),
                                    color: spiking
                                        ? colors.onHeroMuted
                                        : colors.onHero,
                                    decoration: spiking
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: colors.onHeroMuted,
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
                          const SizedBox(width: AppSpacing.md),
                          Illustration(art, size: 56),
                        ],
                      ),
                      if (stamp != null || task.deferralCount > 0) ...[
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            if (stamp != null) ...[
                              Text(
                                stamp.value,
                                style: TextStyle(
                                  fontSize: AppTypography.display,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: AppTypography.trackingFor(
                                    AppTypography.display,
                                  ),
                                  color: age.heat > 0 ? heat : colors.onHero,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              if (stamp.caption.isNotEmpty) ...[
                                const SizedBox(width: AppSpacing.xs + 2),
                                Text(
                                  stamp.caption,
                                  style: TextStyle(
                                    fontSize: AppTypography.callout,
                                    fontWeight: FontWeight.w800,
                                    color: heat,
                                  ),
                                ),
                              ],
                            ],
                            const Spacer(),
                            if (task.deferralCount > 0)
                              PunchMarks(
                                count: task.deferralCount,
                                color: heat,
                                ground: colors.hero,
                              ),
                          ],
                        ),
                      ],
                      if (putOff != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          putOff,
                          style: TextStyle(
                            fontSize: AppTypography.footnote,
                            fontWeight: FontWeight.w800,
                            color: heat,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: FilledButton.icon(
                        onPressed: spiking ? null : onDone,
                        style: _done(colors),
                        icon: const Icon(Icons.check_rounded, size: 22),
                        label: const Text('Done'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: spiking ? null : onLater,
                        style: _onHero(colors),
                        icon: const Icon(Icons.update_rounded, size: 22),
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

  /// Done on the hero: the palette's hero action (its fill, unless that
  /// would vanish on this hero), with its own lip.
  static ButtonStyle _done(AppColors colors) =>
      FilledButton.styleFrom(
        backgroundColor: colors.heroAction,
        foregroundColor: colors.onHeroAction,
      ).copyWith(
        shape: WidgetStateProperty.resolveWith(
          (states) => ChunkyBorder(
            radius: AppRadii.md,
            edge: Color.alphaBlend(const Color(0x33000000), colors.heroAction),
            depth: states.contains(WidgetState.pressed) ? 1 : 4,
          ),
        ),
      );

  /// The quiet chunky button, re-mixed for the forest: a translucent face
  /// and a darker lip, so it never competes with Done.
  static ButtonStyle _onHero(AppColors colors) =>
      OutlinedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.12),
        foregroundColor: colors.onHero,
      ).copyWith(
        side: const WidgetStatePropertyAll(BorderSide.none),
        shape: WidgetStateProperty.resolveWith(
          (states) => ChunkyBorder(
            radius: AppRadii.md,
            edge: const Color(0x40000000),
            depth: states.contains(WidgetState.pressed) ? 1 : 4,
          ),
        ),
      );
}

/// The signature exit. A completed ticket holds its strike-through for a
/// beat, slides fully off the rail, then the rail closes over the gap it
/// left. Skipped entirely under Reduce Motion, because [FocusScreen] then
/// completes immediately.
class _Spike extends StatefulWidget {
  final bool spiking;
  final Widget child;

  const _Spike({required this.spiking, required this.child});

  @override
  State<_Spike> createState() => _SpikeState();
}

class _SpikeState extends State<_Spike> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: _FocusScreenState._spikeDuration,
  );
  late final _slide = Tween(begin: Offset.zero, end: const Offset(1.05, 0))
      .animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.2, 0.65, curve: AppMotion.exitCurve),
        ),
      );
  late final _height = Tween(begin: 1.0, end: 0.0).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1, curve: AppMotion.curve),
    ),
  );

  @override
  void initState() {
    super.initState();
    if (widget.spiking) _controller.value = 1;
  }

  @override
  void didUpdateWidget(_Spike oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spiking && !oldWidget.spiking) {
      _controller.forward(from: 0);
    } else if (!widget.spiking && oldWidget.spiking) {
      // Completion was cancelled (say, at the subtasks prompt): put the
      // ticket back on the rail.
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizeTransition(
    sizeFactor: _height,
    alignment: Alignment.topCenter,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}

class _EmptyFocus extends StatelessWidget {
  const _EmptyFocus();

  @override
  Widget build(BuildContext context) => EmptyState(
    title: 'Nothing is waiting on you',
    message:
        'Tasks you add land here, oldest first. Put one off and it comes '
        'back a little louder each time, until it is done.',
    actionLabel: 'Add a task',
    onAction: () => QuickAddSheet.open(context),
  );
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
