import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../domain/models/date_only.dart';
import '../../domain/models/habit.dart';
import '../../state/habit_controller.dart';
import '../widgets/task_flows.dart';
import 'habit_detail_screen.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HabitController>();
    final today = DateOnly.today();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
        actions: [
          IconButton.filled(
            tooltip: 'Add habit',
            onPressed: () => HabitEditorSheet.open(context),
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: !controller.isLoaded
            ? Center(
                child: CircularProgressIndicator(color: context.colors.accent),
              )
            : controller.habits.isEmpty
            ? _EmptyHabits(onAdd: () => HabitEditorSheet.open(context))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                children: [
                  _TodaySummary(controller: controller, today: today),
                  if (controller.hasStorageError ||
                      controller.hasNotificationError) ...[
                    const SizedBox(height: 12),
                    _StatusWarning(controller: controller),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        'YOUR ROUTINES',
                        style: TextStyle(
                          color: context.colors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${controller.habits.length} active',
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final habit in controller.habits) ...[
                    _HabitCard(habit: habit, today: today),
                    const SizedBox(height: 11),
                  ],
                ],
              ),
      ),
    );
  }
}

class HabitEditorSheet extends StatefulWidget {
  final Habit? habit;

  const HabitEditorSheet({super.key, this.habit});

  static Future<void> open(BuildContext context, {Habit? habit}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => HabitEditorSheet(habit: habit),
      );

  @override
  State<HabitEditorSheet> createState() => _HabitEditorSheetState();
}

class _HabitEditorSheetState extends State<HabitEditorSheet> {
  late final TextEditingController _title;
  late HabitColor _color;
  late HabitType _type;
  late int? _scheduledMinutes;
  late double _targetMinutes;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    _title = TextEditingController(text: habit?.title);
    _color = habit?.color ?? HabitColor.green;
    _type = habit?.type ?? HabitType.checkIn;
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
      helpText: 'Daily reminder',
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
        scheduledMinutes: _scheduledMinutes,
        timerTargetMinutes: _targetMinutes.round(),
      );
    } else {
      await controller.updateHabit(
        habit.id,
        title: _title.text,
        color: _color,
        type: _type,
        scheduledMinutes: _scheduledMinutes,
        timerTargetMinutes: _targetMinutes.round(),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = habitColorOf(colors, _color);
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
              widget.habit == null ? 'Create a daily habit' : 'Customize habit',
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
            _SectionLabel('HABIT TYPE'),
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
                  const _SectionLabel('DAILY TARGET'),
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
              Slider(
                value: _targetMinutes,
                min: 5,
                max: 120,
                divisions: 23,
                activeColor: accent,
                onChanged: (value) => setState(() => _targetMinutes = value),
              ),
            ],
            const SizedBox(height: 14),
            _SectionLabel('DAILY REMINDER'),
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
            _SectionLabel('COLOR'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final color in HabitColor.values)
                  _ColorChip(
                    color: color,
                    selected: color == _color,
                    onTap: () => setState(() => _color = color),
                  ),
              ],
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
  final HabitController controller;
  final DateOnly today;

  const _TodaySummary({required this.controller, required this.today});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final completed = controller.completedCountOn(today);
    final total = controller.habits.length;
    final progress = total == 0 ? 0.0 : completed / total;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            height: 82,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 9,
                  strokeCap: StrokeCap.round,
                  backgroundColor: colors.pressed,
                  color: colors.accent,
                ),
                Center(
                  child: Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today', style: TextStyle(color: colors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  '$completed of $total complete today',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  completed == total
                      ? 'Perfect rhythm. Keep it going.'
                      : 'Small steps add up.',
                  style: TextStyle(color: colors.textMuted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          Icon(Icons.bolt_rounded, color: colors.accent, size: 28),
        ],
      ),
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
    final color = habitColorOf(colors, habit.color);
    final days = List.generate(7, (index) => today.addDays(index - 6));
    final isTimer = habit.type == HabitType.timer;
    final seconds = context.watch<HabitController>().timerSecondsFor(
      habit.id,
      today,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Material(
          color: colors.card.withValues(alpha: 0.88),
          child: Column(
            children: [
              InkWell(
                onTap: () => HabitDetailScreen.open(context, habit.id),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          isTimer ? Icons.timer_rounded : Icons.loop_rounded,
                          color: color,
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
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              habitMeta(context, habit, seconds),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 12,
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
                          onTap: () =>
                              HabitDetailScreen.open(context, habit.id),
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
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Open',
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 12,
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
        ),
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
                    fontSize: 10,
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
                            fontSize: 11,
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
                        fontSize: 11,
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

class _ColorChip extends StatelessWidget {
  final HabitColor color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorChip({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final value = habitColorOf(context.colors, color);
    return ChoiceChip(
      label: Text(habitColorName(color)),
      selected: selected,
      showCheckmark: false,
      avatar: Icon(
        selected ? Icons.check_circle_rounded : Icons.circle,
        size: 17,
        color: value,
      ),
      backgroundColor: value.withValues(alpha: .08),
      selectedColor: value.withValues(alpha: .18),
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: selected ? value : context.colors.textSecondary,
      ),
      onSelected: (_) => onTap(),
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
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
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
      color: context.colors.textMuted,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1,
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
  const _EmptyHabits({required this.onAdd});

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
          const Text(
            'No habits yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a repeatable routine, add checkpoints, or track time.',
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

Color habitColorOf(AppColors colors, HabitColor color) => switch (color) {
  HabitColor.violet => colors.accent,
  HabitColor.blue => colors.low,
  HabitColor.green => colors.done,
  HabitColor.amber => colors.medium,
  HabitColor.rose => colors.overdue,
};

String habitColorName(HabitColor color) => switch (color) {
  HabitColor.violet => 'Lime',
  HabitColor.blue => 'Cyan',
  HabitColor.green => 'Green',
  HabitColor.amber => 'Sand',
  HabitColor.rose => 'Coral',
};

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
