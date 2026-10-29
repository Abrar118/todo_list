import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_tokens.dart';
import '../../domain/models/date_only.dart';
import '../../domain/models/goal.dart';
import '../../domain/models/swatch.dart';
import '../../state/goal_controller.dart';
import '../widgets/common.dart';
import '../widgets/meadow.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalController>();
    final goals = controller.goals;

    void addGoal() => GoalEditorSheet.open(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: rootAddFab(
        context,
        onPressed: addGoal,
        tooltip: 'Add goal',
      ),
      body: CustomScrollView(
        slivers: [
          rootAppBar(
            context,
            title: 'Goals',
            onAdd: addGoal,
            addTooltip: 'Add goal',
          ),
          SliverToBoxAdapter(
            child: MeadowHeader(
              child: goals.isEmpty
                  ? null
                  : _GoalsSummary(
                      active: goals.where((goal) => !goal.isCompleted).length,
                      completed: goals.where((goal) => goal.isCompleted).length,
                    ),
            ),
          ),
          if (!controller.isLoaded)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator.adaptive()),
            )
          else if (goals.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyGoals(onAdd: () => GoalEditorSheet.open(context)),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                listBottomInset(context),
              ),
              sliver: SliverList.list(
                children: [
                  Text(
                    'Your goals',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: AppTypography.callout,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final goal in goals) ...[
                    _GoalCard(goal: goal),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Two tiles on the grass: goals still in progress, and goals reached.
class _GoalsSummary extends StatelessWidget {
  final int active;
  final int completed;

  const _GoalsSummary({required this.active, required this.completed});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: StatTile(
            art: Art.bullseye,
            value: '$active',
            label: 'in progress',
            tint: colors.tintSky,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StatTile(
            art: Art.trophy,
            value: '$completed',
            label: 'reached',
            tint: colors.tintSun,
          ),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = swatchColor(colors, goal.color);
    final percent = (goal.progress * 100).round();
    final days = goal.targetDate.differenceInDays(DateOnly.today());
    final dateLabel = MaterialLocalizations.of(
      context,
    ).formatMediumDate(goal.targetDate.toDateTime());
    return Semantics(
      button: true,
      label: '${goal.title}, $percent percent complete',
      child: Material(
        color: colors.card,
        shape: chunkyCard(colors),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => GoalDetailScreen.open(context, goal.id),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg + 3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: AppTypography.callout,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            days < 0
                                ? '${-days} days past target'
                                : days == 0
                                ? 'Target is today'
                                : '$dateLabel, $days days left',
                            style: TextStyle(
                              color: days < 0
                                  ? colors.overdue
                                  : colors.textSecondary,
                              fontSize: AppTypography.footnote,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: AppTypography.title3,
                        fontWeight: FontWeight.w900,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: AppRadii.pillRadius,
                  child: LinearProgressIndicator(
                    value: goal.progress,
                    minHeight: 12,
                    color: colors.accentFill,
                    backgroundColor: colors.pressed,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  goal.checkpoints.isEmpty
                      ? 'Manual progress'
                      : '${goal.completedCheckpointCount} of ${goal.checkpoints.length} checkpoints',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: AppTypography.footnote,
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

class _EmptyGoals extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyGoals({required this.onAdd});

  @override
  Widget build(BuildContext context) => EmptyState(
    art: Art.trophy,
    title: 'No goals yet',
    message:
        'A goal has a target date and a few checkpoints on the way. Tick '
        'them off as you go.',
    actionLabel: 'Add a goal',
    onAction: onAdd,
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
    final colors = context.colors;
    final color = swatchColor(colors, goal.color);
    final percent = (goal.progress * 100).round();
    final days = goal.targetDate.differenceInDays(DateOnly.today());
    final targetLabel = MaterialLocalizations.of(
      context,
    ).formatMediumDate(goal.targetDate.toDateTime());
    final when = goal.isCompleted
        ? 'Complete'
        : days < 0
        ? '${-days} days past the target of $targetLabel'
        : days == 0
        ? 'Target is today'
        : 'Target $targetLabel, $days days left';
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Edit goal',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => GoalEditorSheet.open(context, goal: goal),
          ),
          PopupMenuButton<String>(
            tooltip: 'More options',
            onSelected: (value) => _handleMenu(context, goal, value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'delete', child: Text('Delete goal')),
            ],
          ),
        ],
      ),
      body: ListView(
        key: const ValueKey('goal-detail-background'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  goal.title,
                  style: TextStyle(
                    fontSize: AppTypography.title1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: AppTypography.trackingFor(
                      AppTypography.title1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (goal.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              goal.description,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: AppTypography.body,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            when,
            style: TextStyle(
              color: days < 0 && !goal.isCompleted
                  ? colors.overdue
                  : colors.textSecondary,
              fontSize: AppTypography.footnote,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Semantics(
            label: '$percent percent complete',
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: AppTypography.title1,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    goal.checkpoints.isEmpty
                        ? 'complete'
                        : 'complete, ${goal.completedCheckpointCount} of '
                              '${goal.checkpoints.length} checkpoints',
                    style: TextStyle(
                      fontSize: AppTypography.footnote,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            label: 'Progress chart. Current progress is $percent percent.',
            child: SizedBox(
              key: const ValueKey('goal-progress-chart'),
              height: 150,
              width: double.infinity,
              child: CustomPaint(
                painter: _GoalProgressPainter(
                  progress: goal.progress,
                  color: color,
                  gridColor: colors.borderStrong,
                  holeColor: colors.background,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ChartLabel('Start'),
              _ChartLabel('Now'),
              _ChartLabel('Target'),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tracking progress',
                  style: TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Add checkpoint',
                onPressed: () => _addCheckpoint(context, goal.id),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (goal.checkpoints.isEmpty)
            Material(
              color: colors.card,
              shape: AppRadii.mediumShape,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('Manual progress'),
                        const Spacer(),
                        Text(
                          '$percent%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    Slider.adaptive(
                      value: goal.manualProgress.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: '$percent%',
                      onChanged: (value) =>
                          controller.updateProgress(goal.id, value.round()),
                    ),
                  ],
                ),
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

  Future<void> _handleMenu(
    BuildContext context,
    Goal goal,
    String value,
  ) async {
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

class _ChartLabel extends StatelessWidget {
  final String label;

  const _ChartLabel(this.label);

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      color: context.colors.textSecondary,
      fontSize: AppTypography.caption,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _GoalProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color gridColor;

  /// The centre of the progress marker, punched through to the page.
  final Color holeColor;

  const _GoalProgressPainter({
    required this.progress,
    required this.color,
    required this.gridColor,
    required this.holeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final top = size.height * .16;
    final bottom = size.height * .86;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = top + ((bottom - top) / 2 * i);
      const dash = 6.0;
      for (var x = 0.0; x < size.width; x += dash * 2) {
        canvas.drawLine(
          Offset(x, y),
          Offset((x + dash).clamp(0, size.width), y),
          gridPaint,
        );
      }
    }

    final forecast = Path()
      ..moveTo(0, bottom)
      ..cubicTo(
        size.width * .34,
        bottom - 4,
        size.width * .7,
        size.height * .54,
        size.width,
        top,
      )
      ..lineTo(size.width, bottom)
      ..close();
    canvas.drawPath(forecast, Paint()..color = color.withValues(alpha: .1));

    final clamped = progress.clamp(0.0, 1.0);
    final x = size.width * clamped;
    final y = bottom - (bottom - top) * (.2 * clamped + .8 * clamped * clamped);
    final completed = Path()
      ..moveTo(0, bottom)
      ..cubicTo(x * .28, bottom, x * .66, y + 10, x, y)
      ..lineTo(x, bottom)
      ..close();
    canvas.drawPath(completed, Paint()..color = color.withValues(alpha: .26));
    final line = Path()
      ..moveTo(0, bottom)
      ..cubicTo(x * .28, bottom, x * .66, y + 10, x, y);
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(x, y),
      Offset(x, bottom),
      Paint()
        ..color = color.withValues(alpha: .58)
        ..strokeWidth = 1,
    );
    canvas.drawCircle(Offset(x, y), 9, Paint()..color = color);
    canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = holeColor);
  }

  @override
  bool shouldRepaint(_GoalProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.holeColor != holeColor;
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
                      fontSize: AppTypography.body,
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
  late Swatch _color;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.goal?.title);
    _description = TextEditingController(text: widget.goal?.description);
    _targetDate =
        widget.goal?.targetDate ?? DateOnly.today().addMonthsClamped(1);
    _color = widget.goal?.color ?? Swatch.sage;
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
              style: const TextStyle(
                fontSize: AppTypography.title3,
                fontWeight: FontWeight.w700,
              ),
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
                color: swatchColor(context.colors, _color),
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
              'Color',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: AppTypography.footnote,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            SwatchPicker(
              selected: _color,
              onPick: (choice) => setState(() => _color = choice!),
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
