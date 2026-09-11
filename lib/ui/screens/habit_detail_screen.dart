import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../domain/models/date_only.dart';
import '../../domain/models/habit.dart';
import '../../state/habit_controller.dart';
import '../widgets/common.dart';
import '../widgets/task_flows.dart';
import 'habits_screen.dart';

class HabitDetailScreen extends StatelessWidget {
  final String habitId;

  const HabitDetailScreen({super.key, required this.habitId});

  static Future<void> open(BuildContext context, String habitId) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => HabitDetailScreen(habitId: habitId),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HabitController>();
    final habit = controller.habitById(habitId);
    if (habit == null) {
      return const Scaffold(
        body: Center(child: Text('Habit no longer exists')),
      );
    }
    final today = DateOnly.today();
    final color = habitColorOf(context.colors, habit.color);
    final completedCheckpoints = habit.checkpoints
        .where((checkpoint) => checkpoint.isCompletedOn(today))
        .length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit'),
        actions: [
          IconButton(
            tooltip: 'Edit habit',
            onPressed: () => HabitEditorSheet.open(context, habit: habit),
            icon: const Icon(Icons.tune_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: 'More options',
            onSelected: (value) {
              if (value == 'delete') _delete(context, habit);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded),
                    SizedBox(width: 10),
                    Text('Delete habit'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        children: [
          _HabitHero(habit: habit, color: color, today: today),
          if (habit.type == HabitType.timer) ...[
            const SizedBox(height: 14),
            _TimerPanel(habit: habit, color: color, today: today),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CHECKPOINTS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    habit.checkpoints.isEmpty
                        ? 'Break this habit into small steps'
                        : '$completedCheckpoints of ${habit.checkpoints.length} complete today',
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton.filledTonal(
                tooltip: 'Add checkpoint',
                onPressed: () => CheckpointEditorSheet.open(context, habit.id),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (habit.checkpoints.isEmpty)
            _EmptyCheckpoints(
              color: color,
              onAdd: () => CheckpointEditorSheet.open(context, habit.id),
            )
          else
            _Timeline(habit: habit, color: color, today: today),
          const SizedBox(height: 22),
          _WeekHistory(habit: habit, color: color, today: today),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, Habit habit) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Delete ${habit.title}?',
      message:
          'Its timer, checkpoints, and completion history will be removed.',
      confirmLabel: 'Delete habit',
    );
    if (confirmed && context.mounted) {
      await context.read<HabitController>().deleteHabit(habit.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _HabitHero extends StatelessWidget {
  final Habit habit;
  final Color color;
  final DateOnly today;

  const _HabitHero({
    required this.habit,
    required this.color,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final done = habit.isCompletedOn(today);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: .20), context.colors.card],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  habit.type == HabitType.timer
                      ? Icons.timer_rounded
                      : Icons.auto_awesome_rounded,
                  color: color,
                  size: 26,
                ),
              ),
              const Spacer(),
              if (habit.scheduledMinutes != null)
                _InfoChip(
                  icon: Icons.notifications_active_outlined,
                  label: formatHabitTime(context, habit.scheduledMinutes!),
                  color: color,
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            habit.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            habit.type == HabitType.timer
                ? '${habit.timerTargetMinutes} minute daily target'
                : habit.checkpoints.isEmpty
                ? 'Daily check-in habit'
                : '${habit.checkpoints.length} step daily routine',
            style: TextStyle(color: context.colors.textSecondary),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _Metric(
                value: '${habit.currentStreak(today)}',
                label: 'day streak',
                color: color,
              ),
              const SizedBox(width: 10),
              _Metric(
                value: '${habit.completedDates.length}',
                label: 'total days',
                color: context.colors.low,
              ),
              const Spacer(),
              if (habit.type == HabitType.checkIn)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: done ? context.colors.pressed : color,
                    foregroundColor: done
                        ? context.colors.textPrimary
                        : context.colors.onAccent,
                  ),
                  onPressed: () => context.read<HabitController>().toggleDate(
                    habit.id,
                    today,
                  ),
                  icon: Icon(done ? Icons.undo_rounded : Icons.check_rounded),
                  label: Text(done ? 'Undo today' : 'Complete'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimerPanel extends StatelessWidget {
  final Habit habit;
  final Color color;
  final DateOnly today;

  const _TimerPanel({
    required this.habit,
    required this.color,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HabitController>();
    final seconds = controller.timerSecondsFor(habit.id, today);
    final targetSeconds = habit.timerTargetMinutes * 60;
    final progress = (seconds / targetSeconds).clamp(0.0, 1.0);
    final running = habit.timerStartedAt != null;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            height: 104,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  color: color,
                  backgroundColor: context.colors.pressed,
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatDuration(seconds),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'today',
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
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  running ? 'Timer running' : 'Ready when you are',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${(targetSeconds - seconds).clamp(0, targetSeconds) ~/ 60} min remaining',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: color),
                  onPressed: () => running
                      ? controller.pauseTimer(habit.id)
                      : controller.startTimer(habit.id),
                  icon: Icon(
                    running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                  label: Text(running ? 'Pause' : 'Start timer'),
                ),
                TextButton(
                  onPressed: seconds == 0
                      ? null
                      : () => controller.resetTimer(habit.id, date: today),
                  child: const Text('Reset today'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final Habit habit;
  final Color color;
  final DateOnly today;

  const _Timeline({
    required this.habit,
    required this.color,
    required this.today,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
    decoration: BoxDecoration(
      color: context.colors.card,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        for (var index = 0; index < habit.checkpoints.length; index++)
          _TimelineRow(
            habit: habit,
            checkpoint: habit.checkpoints[index],
            color: color,
            today: today,
            first: index == 0,
            last: index == habit.checkpoints.length - 1,
          ),
      ],
    ),
  );
}

class _TimelineRow extends StatelessWidget {
  final Habit habit;
  final HabitCheckpoint checkpoint;
  final Color color;
  final DateOnly today;
  final bool first;
  final bool last;

  const _TimelineRow({
    required this.habit,
    required this.checkpoint,
    required this.color,
    required this.today,
    required this.first,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    final done = checkpoint.isCompletedOn(today);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: first ? 30 : 0,
                  bottom: last ? 30 : 0,
                  width: 2,
                  child: ColoredBox(color: color.withValues(alpha: .24)),
                ),
                Center(
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => context
                        .read<HabitController>()
                        .toggleCheckpoint(habit.id, checkpoint.id, today),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: done ? color : context.colors.pressed,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        done ? Icons.check_rounded : Icons.circle_outlined,
                        size: 17,
                        color: done ? context.colors.onAccent : color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(13),
              onTap: () => CheckpointEditorSheet.open(
                context,
                habit.id,
                checkpoint: checkpoint,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            checkpoint.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: done
                                  ? context.colors.textMuted
                                  : context.colors.textPrimary,
                            ),
                          ),
                          if (checkpoint.scheduledMinutes != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.notifications_none_rounded,
                                  size: 14,
                                  color: color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  formatHabitTime(
                                    context,
                                    checkpoint.scheduledMinutes!,
                                  ),
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.colors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CheckpointEditorSheet extends StatefulWidget {
  final String habitId;
  final HabitCheckpoint? checkpoint;

  const CheckpointEditorSheet({
    super.key,
    required this.habitId,
    this.checkpoint,
  });

  static Future<void> open(
    BuildContext context,
    String habitId, {
    HabitCheckpoint? checkpoint,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        CheckpointEditorSheet(habitId: habitId, checkpoint: checkpoint),
  );

  @override
  State<CheckpointEditorSheet> createState() => _CheckpointEditorSheetState();
}

class _CheckpointEditorSheetState extends State<CheckpointEditorSheet> {
  late final TextEditingController _title;
  late int? _minutes;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.checkpoint?.title);
    _minutes = widget.checkpoint?.scheduledMinutes;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final current = _minutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: current == null
          ? TimeOfDay.now()
          : TimeOfDay(hour: current ~/ 60, minute: current % 60),
      helpText: 'Checkpoint reminder',
    );
    if (picked != null) {
      setState(() => _minutes = picked.hour * 60 + picked.minute);
    }
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;
    if (_minutes != null) await ensureNotificationPermission(context);
    if (!mounted) return;
    final controller = context.read<HabitController>();
    final checkpoint = widget.checkpoint;
    if (checkpoint == null) {
      await controller.addCheckpoint(
        widget.habitId,
        title: _title.text,
        scheduledMinutes: _minutes,
      );
    } else {
      await controller.updateCheckpoint(
        widget.habitId,
        checkpoint.id,
        title: _title.text,
        scheduledMinutes: _minutes,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AnimatedPadding(
    duration: const Duration(milliseconds: 180),
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.checkpoint == null ? 'Add checkpoint' : 'Edit checkpoint',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Give this step its own optional reminder.',
            style: TextStyle(color: context.colors.textSecondary),
          ),
          const SizedBox(height: 18),
          TextField(
            key: const ValueKey('checkpoint-name-field'),
            controller: _title,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 60,
            decoration: const InputDecoration(
              labelText: 'Checkpoint',
              hintText: 'Warm up',
              prefixIcon: Icon(Icons.route_rounded),
            ),
            onChanged: (_) => setState(() {}),
          ),
          Material(
            color: context.colors.card,
            borderRadius: BorderRadius.circular(14),
            child: ListTile(
              leading: Icon(Icons.schedule_rounded, color: context.colors.low),
              title: Text(
                _minutes == null
                    ? 'No reminder'
                    : formatHabitTime(context, _minutes!),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_minutes != null)
                    IconButton(
                      tooltip: 'Remove reminder',
                      onPressed: () => setState(() => _minutes = null),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              onTap: _pickTime,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _title.text.trim().isEmpty ? null : _save,
            icon: const Icon(Icons.check_rounded),
            label: Text(
              widget.checkpoint == null ? 'Add checkpoint' : 'Save checkpoint',
            ),
          ),
          if (widget.checkpoint != null) ...[
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: () async {
                await context.read<HabitController>().deleteCheckpoint(
                  widget.habitId,
                  widget.checkpoint!.id,
                );
                if (context.mounted) Navigator.pop(context);
              },
              icon: Icon(
                Icons.delete_outline_rounded,
                color: context.colors.overdue,
              ),
              label: Text(
                'Delete checkpoint',
                style: TextStyle(color: context.colors.overdue),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _WeekHistory extends StatelessWidget {
  final Habit habit;
  final Color color;
  final DateOnly today;

  const _WeekHistory({
    required this.habit,
    required this.color,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (index) => today.addDays(index - 6));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LAST 7 DAYS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.colors.card,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              for (final date in days)
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        ['M', 'T', 'W', 'T', 'F', 'S', 'S'][date.weekday - 1],
                        style: TextStyle(
                          color: context.colors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: habit.isCompletedOn(date)
                              ? color
                              : context.colors.pressed,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: habit.isCompletedOn(date)
                            ? Icon(
                                Icons.check_rounded,
                                color: context.colors.onAccent,
                                size: 18,
                              )
                            : Text(
                                '${date.day}',
                                style: TextStyle(
                                  color: context.colors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyCheckpoints extends StatelessWidget {
  final Color color;
  final VoidCallback onAdd;

  const _EmptyCheckpoints({required this.color, required this.onAdd});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: context.colors.card,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        Icon(Icons.route_rounded, color: color, size: 30),
        const SizedBox(height: 10),
        const Text(
          'No checkpoints yet',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          'Add a sequence of steps and give each one its own time.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.textSecondary, fontSize: 12.5),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add first checkpoint'),
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _Metric({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .11),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: context.colors.textMuted, fontSize: 10.5),
        ),
      ],
    ),
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}
