import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_tokens.dart';
import '../../domain/models/date_only.dart';
import '../../domain/models/goal.dart';
import '../../domain/models/swatch.dart';
import '../../state/goal_controller.dart';
import '../widgets/common.dart';
import '../widgets/frosted_bottom_navigation_bar.dart';

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
      // The shell's MeshBackdrop paints the background for all tabs.
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          rootAppBar(
            title: const Text('Goals'),
            actions: [
              IconButton(
                tooltip: 'Add goal',
                onPressed: () => GoalEditorSheet.open(context),
                icon: const Icon(Icons.add_rounded),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),
          if (!controller.isLoaded)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: context.colors.accent),
              ),
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
                FrostedBottomNavigationBar.heightOf(context) + AppSpacing.sm,
              ),
              sliver: SliverList.list(
                children: [
                  _GoalsSummary(
                    active: goals.where((goal) => !goal.isCompleted).length,
                    completed: goals.where((goal) => goal.isCompleted).length,
                    average: average,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'YOUR GOALS',
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: AppTypography.caption,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
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
    final color = swatchColor(context.colors, goal.color);
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
    final color = swatchColor(context.colors, goal.color);
    final percent = (goal.progress * 100).round();
    final days = goal.targetDate.differenceInDays(DateOnly.today());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heroStart = Color.alphaBlend(
      color.withValues(alpha: isDark ? .3 : .22),
      isDark ? const Color(0xFF17160F) : const Color(0xFFFFF1BE),
    );
    final heroEnd = isDark ? const Color(0xFF10110D) : const Color(0xFFFFFBEB);
    final status = goal.isCompleted
        ? 'Complete'
        : days < 0
        ? 'Needs attention'
        : 'On track';
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              key: const ValueKey('goal-detail-background'),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 42),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [heroStart, heroEnd],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _RoundAction(
                        tooltip: 'Back',
                        icon: Icons.arrow_back_rounded,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Text(
                        'GOAL  /  ${days < 0 ? 'OVERDUE' : '$days DAYS'}',
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const Spacer(),
                      _RoundAction(
                        tooltip: 'Edit goal',
                        icon: Icons.tune_rounded,
                        onPressed: () =>
                            GoalEditorSheet.open(context, goal: goal),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'More options',
                        icon: const Icon(Icons.more_horiz_rounded),
                        onSelected: (value) =>
                            _handleMenu(context, goal, value),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete goal'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  Semantics(
                    label: '$percent percent complete',
                    child: Text(
                      '$percent',
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 118,
                        height: .82,
                        fontWeight: FontWeight.w200,
                        letterSpacing: -8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '%',
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 22,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'complete',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w300,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .24),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.trending_up_rounded,
                          color: color,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 38),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _TargetMetric(
                        value: goal.checkpoints.isEmpty
                            ? '$percent%'
                            : '${goal.completedCheckpointCount}/${goal.checkpoints.length}',
                        label: goal.checkpoints.isEmpty
                            ? 'Progress'
                            : 'Checkpoints',
                      ),
                      _TargetMetric(
                        value: days < 0
                            ? '${-days}'
                            : days == 0
                            ? 'Today'
                            : '$days',
                        label: days < 0 ? 'Days overdue' : 'Days remaining',
                        alignEnd: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 28),
                decoration: BoxDecoration(
                  color: context.colors.background,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(34),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Your Goal',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -.7,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Text('·  $status', style: TextStyle(color: color)),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      goal.title,
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.8,
                      ),
                    ),
                    if (goal.description.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        goal.description,
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      'Target  ${MaterialLocalizations.of(context).formatMediumDate(goal.targetDate.toDateTime())}',
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Semantics(
                      label:
                          'Progress chart. Current progress is $percent percent.',
                      child: SizedBox(
                        key: const ValueKey('goal-progress-chart'),
                        height: 150,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _GoalProgressPainter(
                            progress: goal.progress,
                            color: color,
                            gridColor: context.colors.borderStrong,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ChartLabel('START'),
                        _ChartLabel('NOW'),
                        _ChartLabel('TARGET'),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tracking progress',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                goal.checkpoints.isEmpty
                                    ? 'Update the percentage as you move'
                                    : '${goal.completedCheckpointCount} of ${goal.checkpoints.length} checkpoints complete',
                                style: TextStyle(
                                  color: context.colors.textSecondary,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filled(
                          tooltip: 'Add checkpoint',
                          style: IconButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: context.colors.onAccent,
                          ),
                          onPressed: () => _addCheckpoint(context, goal.id),
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (goal.checkpoints.isEmpty)
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .09),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
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
                              onChanged: (value) => controller.updateProgress(
                                goal.id,
                                value.round(),
                              ),
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
              ),
            ),
          ],
        ),
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

class _RoundAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _RoundAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      backgroundColor: context.colors.elevated.withValues(alpha: .62),
      minimumSize: const Size(48, 48),
    ),
    icon: Icon(icon),
  );
}

class _TargetMetric extends StatelessWidget {
  final String value;
  final String label;
  final bool alignEnd;

  const _TargetMetric({
    required this.value,
    required this.label,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -.5,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        label,
        style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
      ),
    ],
  );
}

class _ChartLabel extends StatelessWidget {
  final String label;

  const _ChartLabel(this.label);

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      color: context.colors.textMuted,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: .8,
    ),
  );
}

class _GoalProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color gridColor;

  const _GoalProgressPainter({
    required this.progress,
    required this.color,
    required this.gridColor,
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
    canvas.drawCircle(
      Offset(x, y),
      3.5,
      Paint()..color = const Color(0xFF171A14),
    );
  }

  @override
  bool shouldRepaint(_GoalProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.gridColor != gridColor;
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
              'COLOR',
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
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
