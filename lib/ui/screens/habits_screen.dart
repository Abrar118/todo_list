import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_tokens.dart';
import '../../domain/models/date_only.dart';
import '../../domain/models/habit.dart';
import '../../domain/models/swatch.dart';
import '../../state/habit_controller.dart';
import '../widgets/common.dart';
import '../widgets/task_flows.dart';
import 'habit_detail_screen.dart';

enum _HabitRange { daily, monthly }

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  _HabitRange _range = _HabitRange.daily;
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HabitController>();
    final today = DateOnly.today();
    void addHabit() => HabitEditorSheet.open(
      context,
      initialCadence: _range == _HabitRange.daily
          ? HabitCadence.daily
          : HabitCadence.monthly,
    );
    void select(_HabitRange? range) {
      if (range != null) setState(() => _range = range);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: rootAddFab(
        context,
        onPressed: addHabit,
        tooltip: 'Add habit',
      ),
      body: CustomScrollView(
        slivers: [
          rootAppBar(
            context,
            title: 'Habits',
            onAdd: addHabit,
            addTooltip: 'Add habit',
          ),
          if (!controller.isLoaded)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator.adaptive()),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                // The platform's own segmented control on each OS.
                child: isCupertino(context)
                    ? CupertinoSlidingSegmentedControl<_HabitRange>(
                        groupValue: _range,
                        onValueChanged: select,
                        children: const {
                          _HabitRange.daily: Text('Daily'),
                          _HabitRange.monthly: Text('Monthly'),
                        },
                      )
                    : SegmentedButton<_HabitRange>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: _HabitRange.daily,
                            label: Text('Daily'),
                          ),
                          ButtonSegment(
                            value: _HabitRange.monthly,
                            label: Text('Monthly'),
                          ),
                        ],
                        selected: {_range},
                        onSelectionChanged: (value) => select(value.single),
                      ),
              ),
            ),
            switch (_range) {
              _HabitRange.daily => _DailyHabitView(
                controller: controller,
                today: today,
              ),
              _HabitRange.monthly => _MonthlyRoutineView(
                controller: controller,
                today: today,
              ),
            },
          ],
        ],
      ),
    );
  }
}

class _DailyHabitView extends StatelessWidget {
  final HabitController controller;
  final DateOnly today;

  const _DailyHabitView({required this.controller, required this.today});

  @override
  Widget build(BuildContext context) {
    final habits = controller.habits
        .where((habit) => habit.cadence == HabitCadence.daily)
        .toList(growable: false);
    if (habits.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyHabits(
          onAdd: () => HabitEditorSheet.open(
            context,
            initialCadence: HabitCadence.daily,
          ),
        ),
      );
    }
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        listBottomInset(context),
      ),
      sliver: SliverList.list(
        children: [
          _TodaySummary(habits: habits, today: today),
          if (controller.hasStorageError ||
              controller.hasNotificationError) ...[
            const SizedBox(height: AppSpacing.md),
            _StatusWarning(controller: controller),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              const _SectionLabel('Your routines'),
              const Spacer(),
              Text(
                '${habits.length} active',
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: AppTypography.footnote,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final habit in habits) ...[
            _HabitCard(habit: habit, today: today),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _MonthlyRoutineView extends StatelessWidget {
  final HabitController controller;
  final DateOnly today;

  const _MonthlyRoutineView({required this.controller, required this.today});

  @override
  Widget build(BuildContext context) {
    final habits = controller.habits
        .where((habit) => habit.cadence == HabitCadence.monthly)
        .toList(growable: false);
    if (habits.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyHabits(
          title: 'No monthly habits yet',
          message: 'Add something you want to complete once every month.',
          onAdd: () => HabitEditorSheet.open(
            context,
            initialCadence: HabitCadence.monthly,
          ),
        ),
      );
    }
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        listBottomInset(context),
      ),
      sliver: SliverList.list(
        children: [
          Row(
            children: [
              const _SectionLabel('Monthly routines'),
              const Spacer(),
              Text(
                '${habits.length} active',
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: AppTypography.footnote,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final habit in habits) ...[
            _MonthlyRoutineCard(habit: habit, today: today),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _MonthlyRoutineCard extends StatelessWidget {
  final Habit habit;
  final DateOnly today;

  const _MonthlyRoutineCard({required this.habit, required this.today});

  @override
  Widget build(BuildContext context) {
    final color = swatchColor(context.colors, habit.color);
    final dueDay = habit.monthlyDay.clamp(
      1,
      DateOnly.daysInMonth(today.year, today.month),
    );
    final dueDate = DateOnly(today.year, today.month, dueDay);
    final done = habit.isCompletedOn(dueDate);
    return Material(
      color: context.colors.card,
      shape: AppRadii.mediumShape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => HabitDetailScreen.open(context, habit.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: const TextStyle(
                        fontSize: AppTypography.body,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Every month on day ${habit.monthlyDay}'
                      '${habit.scheduledMinutes == null ? '' : '  •  ${formatHabitTime(context, habit.scheduledMinutes!)}'}',
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: AppTypography.footnote,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: done
                    ? 'Mark this month incomplete'
                    : 'Complete this month',
                onPressed: () => context.read<HabitController>().toggleDate(
                  habit.id,
                  dueDate,
                ),
                icon: Icon(
                  done ? Icons.check_rounded : Icons.circle_outlined,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HabitEditorSheet extends StatefulWidget {
  final Habit? habit;
  final HabitCadence initialCadence;

  const HabitEditorSheet({
    super.key,
    this.habit,
    this.initialCadence = HabitCadence.daily,
  });

  static Future<void> open(
    BuildContext context, {
    Habit? habit,
    HabitCadence initialCadence = HabitCadence.daily,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        HabitEditorSheet(habit: habit, initialCadence: initialCadence),
  );

  @override
  State<HabitEditorSheet> createState() => _HabitEditorSheetState();
}

class _HabitEditorSheetState extends State<HabitEditorSheet> {
  late final TextEditingController _title;
  late Swatch _color;
  late HabitType _type;
  late HabitCadence _cadence;
  late double _monthlyDay;
  late int? _scheduledMinutes;
  late double _targetMinutes;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    _title = TextEditingController(text: habit?.title);
    _color = habit?.color ?? Swatch.moss;
    _type = habit?.type ?? HabitType.checkIn;
    _cadence = habit?.cadence ?? widget.initialCadence;
    _monthlyDay = (habit?.monthlyDay ?? DateTime.now().day).toDouble();
    _scheduledMinutes = habit?.scheduledMinutes;
    _targetMinutes = (habit?.timerTargetMinutes ?? 30).toDouble();
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final current = _scheduledMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: current == null
          ? TimeOfDay.now()
          : TimeOfDay(hour: current ~/ 60, minute: current % 60),
      helpText: _cadence == HabitCadence.daily
          ? 'Daily reminder'
          : 'Monthly reminder',
    );
    if (picked != null) {
      setState(() => _scheduledMinutes = picked.hour * 60 + picked.minute);
    }
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;
    if (_scheduledMinutes != null) await ensureNotificationPermission(context);
    if (!mounted) return;
    final controller = context.read<HabitController>();
    final habit = widget.habit;
    if (habit == null) {
      await controller.addHabit(
        title: _title.text,
        color: _color,
        type: _type,
        cadence: _cadence,
        monthlyDay: _monthlyDay.round(),
        scheduledMinutes: _scheduledMinutes,
        timerTargetMinutes: _targetMinutes.round(),
      );
    } else {
      await controller.updateHabit(
        habit.id,
        title: _title.text,
        color: _color,
        type: _type,
        cadence: _cadence,
        monthlyDay: _monthlyDay.round(),
        scheduledMinutes: _scheduledMinutes,
        timerTargetMinutes: _targetMinutes.round(),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = swatchColor(colors, _color);
    return AnimatedPadding(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.habit == null
                  ? 'Create a ${_cadence.name} habit'
                  : 'Customize habit',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Build a routine that fits your day.',
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: 18),
            TextField(
              key: const ValueKey('habit-name-field'),
              controller: _title,
              autofocus: widget.habit == null,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Habit name',
                hintText: 'Daily workout',
                prefixIcon: Icon(Icons.auto_awesome_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 4),
            _SectionLabel('Frequency'),
            const SizedBox(height: 8),
            SegmentedButton<HabitCadence>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: HabitCadence.daily,
                  label: Text('Daily'),
                  icon: Icon(Icons.today_rounded),
                ),
                ButtonSegment(
                  value: HabitCadence.monthly,
                  label: Text('Monthly'),
                  icon: Icon(Icons.event_repeat_rounded),
                ),
              ],
              selected: {_cadence},
              onSelectionChanged: (value) =>
                  setState(() => _cadence = value.single),
            ),
            if (_cadence == HabitCadence.monthly) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const _SectionLabel('Day of month'),
                  const Spacer(),
                  Text(
                    '${_monthlyDay.round()}',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Slider.adaptive(
                value: _monthlyDay,
                min: 1,
                max: 31,
                divisions: 30,
                activeColor: accent,
                label: '${_monthlyDay.round()}',
                onChanged: (value) => setState(() => _monthlyDay = value),
              ),
            ],
            const SizedBox(height: 16),
            _SectionLabel('Habit type'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TypeCard(
                    selected: _type == HabitType.checkIn,
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Check-in',
                    caption: 'Mark it done',
                    onTap: () => setState(() => _type = HabitType.checkIn),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TypeCard(
                    selected: _type == HabitType.timer,
                    icon: Icons.timer_outlined,
                    title: 'Timer',
                    caption: 'Track duration',
                    onTap: () => setState(() => _type = HabitType.timer),
                  ),
                ),
              ],
            ),
            if (_type == HabitType.timer) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  const _SectionLabel('Daily target'),
                  const Spacer(),
                  Text(
                    '${_targetMinutes.round()} min',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Slider.adaptive(
                value: _targetMinutes,
                min: 5,
                max: 120,
                divisions: 23,
                activeColor: accent,
                onChanged: (value) => setState(() => _targetMinutes = value),
              ),
            ],
            const SizedBox(height: 14),
            _SectionLabel('Daily reminder'),
            const SizedBox(height: 8),
            Material(
              color: colors.card,
              borderRadius: BorderRadius.circular(14),
              child: ListTile(
                leading: Icon(
                  Icons.notifications_active_outlined,
                  color: accent,
                ),
                title: Text(
                  _scheduledMinutes == null
                      ? 'No reminder'
                      : formatHabitTime(context, _scheduledMinutes!),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  _scheduledMinutes == null
                      ? 'Choose a time to get a daily nudge'
                      : 'Repeats every day',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_scheduledMinutes != null)
                      IconButton(
                        tooltip: 'Remove reminder',
                        onPressed: () =>
                            setState(() => _scheduledMinutes = null),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
                onTap: _pickTime,
              ),
            ),
            const SizedBox(height: 18),
            _SectionLabel('Color'),
            const SizedBox(height: 8),
            SwatchPicker(
              selected: _color,
              onPick: (color) => setState(() => _color = color!),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _title.text.trim().isEmpty ? null : _save,
              icon: Icon(
                widget.habit == null
                    ? Icons.add_task_rounded
                    : Icons.check_rounded,
              ),
              label: Text(
                widget.habit == null ? 'Create habit' : 'Save changes',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodaySummary extends StatelessWidget {
  final List<Habit> habits;
  final DateOnly today;

  const _TodaySummary({required this.habits, required this.today});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final completed = habits
        .where((habit) => habit.isCompletedOn(today))
        .length;
    final total = habits.length;
    // A status line, not a scoreboard: day one should not open on a large
    // zero, so the count is plain text over a thin ink rule.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          completed < total
              ? '$completed of $total done today'
              : total == 1
              ? 'Done today'
              : 'All $total done today',
          style: TextStyle(
            fontSize: AppTypography.body,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : completed / total,
            minHeight: 4,
            color: colors.textPrimary,
            backgroundColor: colors.pressed,
          ),
        ),
      ],
    );
  }
}

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final DateOnly today;

  const _HabitCard({required this.habit, required this.today});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = swatchColor(colors, habit.color);
    final days = List.generate(7, (index) => today.addDays(index - 6));
    final isTimer = habit.type == HabitType.timer;
    final seconds = context.watch<HabitController>().timerSecondsFor(
      habit.id,
      today,
    );
    // A sheet of ticket paper like the Focus rail; the habit's colour is
    // its identity dot, not a tinted icon tile.
    return Material(
      color: colors.card,
      shape: AppRadii.mediumShape,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => HabitDetailScreen.open(context, habit.id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: AppTypography.body,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          habitMeta(context, habit, seconds),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: AppTypography.footnote,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (habit.currentStreak(today) > 0)
                    _Pill(
                      label:
                          '${habit.currentStreak(today)} day${habit.currentStreak(today) == 1 ? '' : 's'} streak',
                      color: color,
                    ),
                  IconButton(
                    tooltip: habit.isCollapsed
                        ? 'Expand habit'
                        : 'Collapse habit',
                    onPressed: () => context
                        .read<HabitController>()
                        .toggleCollapsed(habit.id),
                    icon: AnimatedRotation(
                      turns: habit.isCollapsed ? 0 : .5,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            crossFadeState: habit.isCollapsed
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      for (final date in days)
                        Expanded(
                          child: _HabitDay(
                            habit: habit,
                            date: date,
                            today: today,
                            color: color,
                          ),
                        ),
                    ],
                  ),
                  if (isTimer || habit.checkpoints.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    InkWell(
                      borderRadius: BorderRadius.circular(13),
                      onTap: () => HabitDetailScreen.open(context, habit.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isTimer
                                  ? Icons.play_circle_outline_rounded
                                  : Icons.route_rounded,
                              size: 19,
                              color: color,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isTimer
                                    ? '${formatDuration(seconds)} of ${habit.timerTargetMinutes} min today'
                                    : '${habit.checkpoints.where((c) => c.isCompletedOn(today)).length} of ${habit.checkpoints.length} checkpoints',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: AppTypography.footnote,
                                ),
                              ),
                            ),
                            Text(
                              'Open',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: AppTypography.footnote,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: colors.textSecondary,
                              size: 19,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitDay extends StatelessWidget {
  final Habit habit;
  final DateOnly date;
  final DateOnly today;
  final Color color;

  const _HabitDay({
    required this.habit,
    required this.date,
    required this.today,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final done = habit.isCompletedOn(date);
    final isToday = date == today;
    final relativeDate = date == today ? 'today' : date.toString();
    final action = done
        ? 'Mark $relativeDate incomplete'
        : 'Mark $relativeDate complete';
    return Semantics(
      button: true,
      toggled: done,
      label: '$action for ${habit.title} on ${date.toString()}',
      child: Tooltip(
        message: action,
        child: InkWell(
          onTap: () =>
              context.read<HabitController>().toggleDate(habit.id, date),
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 58, minWidth: 44),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  weekdays[date.weekday - 1],
                  style: TextStyle(
                    color: isToday ? color : context.colors.textMuted,
                    fontSize: AppTypography.caption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: done ? color : context.colors.pressed,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: done
                      ? Icon(
                          Icons.check_rounded,
                          color: context.colors.onAccent,
                          size: 18,
                        )
                      : Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isToday
                                ? color
                                : context.colors.textSecondary,
                            fontSize: AppTypography.caption,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback onTap;

  const _TypeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.caption,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? context.colors.accent
        : context.colors.textSecondary;
    return Material(
      color: selected
          ? context.colors.accent.withValues(alpha: .12)
          : context.colors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      caption,
                      style: TextStyle(
                        color: context.colors.textMuted,
                        fontSize: AppTypography.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: AppTypography.caption,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: context.colors.textPrimary,
      fontSize: AppTypography.footnote,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _StatusWarning extends StatelessWidget {
  final HabitController controller;
  const _StatusWarning({required this.controller});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: context.colors.overdue.withValues(alpha: .11),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline_rounded, color: context.colors.overdue),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            controller.hasStorageError
                ? 'A habit change could not be saved. Please try again.'
                : 'Some habit reminders could not be scheduled.',
            style: TextStyle(color: context.colors.textSecondary),
          ),
        ),
      ],
    ),
  );
}

class _EmptyHabits extends StatelessWidget {
  final VoidCallback onAdd;
  final String title;
  final String message;
  const _EmptyHabits({
    required this.onAdd,
    this.title = 'No habits yet',
    this.message =
        'Create a repeatable routine, add checkpoints, or track time.',
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: context.colors.accent.withValues(alpha: .13),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bolt_rounded,
              size: 40,
              color: context.colors.accent,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: AppTypography.title3,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add habit'),
          ),
        ],
      ),
    ),
  );
}

String formatHabitTime(BuildContext context, int minutes) =>
    TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60).format(context);

String formatDuration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remaining = seconds % 60;
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}';
}

String habitMeta(BuildContext context, Habit habit, int seconds) {
  final parts = <String>[];
  if (habit.scheduledMinutes != null) {
    parts.add(formatHabitTime(context, habit.scheduledMinutes!));
  }
  if (habit.type == HabitType.timer) {
    parts.add('${habit.timerTargetMinutes} min target');
  } else if (habit.checkpoints.isNotEmpty) {
    parts.add('${habit.checkpoints.length} checkpoints');
  } else {
    parts.add('Daily check-in');
  }
  return parts.join('  •  ');
}
