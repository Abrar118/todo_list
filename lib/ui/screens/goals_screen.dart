import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../domain/models/date_only.dart';
import '../../domain/models/goal.dart';
import '../../state/goal_controller.dart';
import '../widgets/common.dart';

Color goalColorOf(AppColors colors, GoalColor color) => switch (color) {
  GoalColor.lime => colors.accent,
  GoalColor.cyan => colors.low,
  GoalColor.amber => colors.medium,
  GoalColor.coral => colors.overdue,
  GoalColor.violet => const Color(0xFFA991F4),
};

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalController>();
    final goals = controller.goals;
    final average = goals.isEmpty
        ? 0
        : (goals.fold<double>(0, (sum, goal) => sum + goal.progress) /
                  goals.length *
                  100)
              .round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          IconButton(
            tooltip: 'Add goal',
            onPressed: () => GoalEditorSheet.open(context),
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: !controller.isLoaded
          ? Center(
              child: CircularProgressIndicator(color: context.colors.accent),
            )
          : goals.isEmpty
          ? _EmptyGoals(onAdd: () => GoalEditorSheet.open(context))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 124),
              children: [
                _GoalsSummary(
                  active: goals.where((goal) => !goal.isCompleted).length,
                  completed: goals.where((goal) => goal.isCompleted).length,
                  average: average,
                ),
                const SizedBox(height: 24),
                Text(
                  'YOUR GOALS',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                for (final goal in goals) ...[
                  _GoalCard(goal: goal),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _GoalsSummary extends StatelessWidget {
  final int active;
  final int completed;
  final int average;

  const _GoalsSummary({
    required this.active,
    required this.completed,
    required this.average,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.accent.withValues(alpha: .22),
            colors.low.withValues(alpha: .08),
            colors.card,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$average%',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 58,
                    height: .95,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Overall progress',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          _Metric(value: '$active', label: 'active'),
          const SizedBox(width: 20),
          _Metric(value: '$completed', label: 'done'),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;

  const _Metric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      ),
      Text(
        label,
        style: TextStyle(color: context.colors.textMuted, fontSize: 12),
      ),
    ],
  );
}

class _GoalCard extends StatelessWidget {
  final Goal goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final color = goalColorOf(context.colors, goal.color);
    final percent = (goal.progress * 100).round();
    final days = goal.targetDate.differenceInDays(DateOnly.today());
    final dateLabel = MaterialLocalizations.of(
      context,
    ).formatMediumDate(goal.targetDate.toDateTime());
    return Semantics(
      button: true,
      label: '${goal.title}, $percent percent complete',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => GoalDetailScreen.open(context, goal.id),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: .19),
                context.colors.card.withValues(alpha: .97),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -14,
                top: -20,
                child: Icon(
                  Icons.flag_rounded,
                  size: 104,
                  color: color.withValues(alpha: .065),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.flag_rounded, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                days < 0
                                    ? '${-days} days overdue'
                                    : days == 0
                                    ? 'Target is today'
                                    : '$dateLabel · $days days left',
                                style: TextStyle(
                                  color: days < 0
                                      ? context.colors.overdue
                                      : context.colors.textSecondary,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '$percent%',
                          style: TextStyle(
                            color: color,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: goal.progress,
                        minHeight: 7,
                        color: color,
                        backgroundColor: color.withValues(alpha: .12),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      goal.checkpoints.isEmpty
                          ? 'Manual progress'
                          : '${goal.completedCheckpointCount} of ${goal.checkpoints.length} checkpoints',
                      style: TextStyle(
                        color: context.colors.textMuted,
                        fontSize: 12,
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

class _EmptyGoals extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyGoals({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flag_circle_rounded,
            size: 68,
            color: context.colors.accent,
          ),
          const SizedBox(height: 18),
          const Text(
            'Set your next direction.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a goal, choose a target date, and move forward one checkpoint at a time.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create a goal'),
          ),
        ],
      ),
    ),
  );
}

class GoalDetailScreen extends StatelessWidget {
  final String goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  static Future<void> open(BuildContext context, String goalId) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GoalDetailScreen(goalId: goalId),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalController>();
    final goal = controller.goalById(goalId);
    if (goal == null) {
      return const Scaffold(body: Center(child: Text('Goal no longer exists')));
    }
    final color = goalColorOf(context.colors, goal.color);
    final percent = (goal.progress * 100).round();
    final days = goal.targetDate.differenceInDays(DateOnly.today());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal'),
        actions: [
          IconButton(
            tooltip: 'Edit goal',
            onPressed: () => GoalEditorSheet.open(context, goal: goal),
            icon: const Icon(Icons.tune_rounded),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value != 'delete') return;
              final confirmed = await confirmDialog(
                context,
                title: 'Delete ${goal.title}?',
                message: 'Its checkpoints and progress will be removed.',
                confirmLabel: 'Delete goal',
              );
              if (confirmed && context.mounted) {
                await context.read<GoalController>().deleteGoal(goal.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'delete', child: Text('Delete goal')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        children: [
          Container(
            key: const ValueKey('goal-detail-background'),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: .3),
                  context.colors.card.withValues(alpha: .97),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  top: -35,
                  child: Icon(
                    Icons.track_changes_rounded,
                    size: 170,
                    color: color.withValues(alpha: .07),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        fontSize: 68,
                        height: .95,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      goal.title,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (goal.description.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        goal.description,
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: goal.progress,
                        minHeight: 9,
                        color: color,
                        backgroundColor: color.withValues(alpha: .14),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(Icons.event_rounded, size: 17, color: color),
                        const SizedBox(width: 7),
                        Text(
                          MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(goal.targetDate.toDateTime()),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          days < 0
                              ? '${-days} days overdue'
                              : days == 0
                              ? 'Today'
                              : '$days days left',
                          style: TextStyle(
                            color: days < 0
                                ? context.colors.overdue
                                : context.colors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
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
                    goal.checkpoints.isEmpty
                        ? 'Add milestones or track progress manually'
                        : '${goal.completedCheckpointCount} of ${goal.checkpoints.length} complete',
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
                onPressed: () => _addCheckpoint(context, goal.id),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (goal.checkpoints.isEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Manual progress'),
                      const Spacer(),
                      Text(
                        '$percent%',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: goal.manualProgress.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor: color,
                    label: '$percent%',
                    onChanged: (value) =>
                        controller.updateProgress(goal.id, value.round()),
                  ),
                ],
              ),
            )
          else
            for (var i = 0; i < goal.checkpoints.length; i++)
              _CheckpointRow(
                goalId: goal.id,
                checkpoint: goal.checkpoints[i],
                color: color,
                isLast: i == goal.checkpoints.length - 1,
              ),
        ],
      ),
    );
  }

  Future<void> _addCheckpoint(BuildContext context, String goalId) async {
    var checkpointTitle = '';
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New checkpoint'),
        content: TextField(
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'What marks progress?'),
          onChanged: (value) => checkpointTitle = value,
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, checkpointTitle),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (title != null && context.mounted) {
      await context.read<GoalController>().addCheckpoint(goalId, title: title);
    }
  }
}

class _CheckpointRow extends StatelessWidget {
  final String goalId;
  final GoalCheckpoint checkpoint;
  final Color color;
  final bool isLast;

  const _CheckpointRow({
    required this.goalId,
    required this.checkpoint,
    required this.color,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 34,
          child: Column(
            children: [
              InkResponse(
                onTap: () => context.read<GoalController>().toggleCheckpoint(
                  goalId,
                  checkpoint.id,
                ),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: checkpoint.isCompleted
                        ? color
                        : color.withValues(alpha: .11),
                  ),
                  child: checkpoint.isCompleted
                      ? Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: context.colors.onAccent,
                        )
                      : Icon(Icons.circle_outlined, size: 17, color: color),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: color.withValues(alpha: .2),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    checkpoint.title,
                    style: TextStyle(
                      fontSize: 15.5,
                      decoration: checkpoint.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: checkpoint.isCompleted
                          ? context.colors.textMuted
                          : context.colors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Delete checkpoint',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => context
                      .read<GoalController>()
                      .deleteCheckpoint(goalId, checkpoint.id),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class GoalEditorSheet extends StatefulWidget {
  final Goal? goal;

  const GoalEditorSheet({super.key, this.goal});

  static Future<void> open(BuildContext context, {Goal? goal}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => GoalEditorSheet(goal: goal),
      );

  @override
  State<GoalEditorSheet> createState() => _GoalEditorSheetState();
}

class _GoalEditorSheetState extends State<GoalEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late DateOnly _targetDate;
  late GoalColor _color;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.goal?.title);
    _description = TextEditingController(text: widget.goal?.description);
    _targetDate =
        widget.goal?.targetDate ?? DateOnly.today().addMonthsClamped(1);
    _color = widget.goal?.color ?? GoalColor.lime;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.borderStrong,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.goal == null ? 'Create a goal' : 'Edit goal',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            TextField(
              key: const ValueKey('goal-title-field'),
              controller: _title,
              autofocus: widget.goal == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Goal',
                hintText: 'Finish a book',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Why this matters',
                hintText: 'Optional details',
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.event_rounded,
                color: goalColorOf(context.colors, _color),
              ),
              title: const Text('Target date'),
              subtitle: Text(
                MaterialLocalizations.of(
                  context,
                ).formatMediumDate(_targetDate.toDateTime()),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            Text(
              'COLOR',
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              children: [
                for (final choice in GoalColor.values)
                  Semantics(
                    label: '${choice.name} goal color',
                    selected: _color == choice,
                    child: InkResponse(
                      onTap: () => setState(() => _color = choice),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: goalColorOf(context.colors, choice),
                        ),
                        child: _color == choice
                            ? Icon(
                                Icons.check_rounded,
                                color: context.colors.onAccent,
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: Text(widget.goal == null ? 'Create goal' : 'Save goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate.toDateTime(),
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 36500)),
    );
    if (picked != null) {
      setState(() => _targetDate = DateOnly.fromDateTime(picked));
    }
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      showAppSnackBar(context, 'Give this goal a name.');
      return;
    }
    final controller = context.read<GoalController>();
    if (widget.goal == null) {
      await controller.addGoal(
        title: _title.text,
        description: _description.text,
        targetDate: _targetDate,
        color: _color,
      );
    } else {
      await controller.updateGoal(
        widget.goal!.id,
        title: _title.text,
        description: _description.text,
        targetDate: _targetDate,
        color: _color,
      );
    }
    if (mounted) Navigator.pop(context);
  }
}
