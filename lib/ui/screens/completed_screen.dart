import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/formats.dart';
import '../../domain/models/date_only.dart';
import '../../domain/models/task.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'task_editor_screen.dart';

class CompletedScreen extends StatelessWidget {
  const CompletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final completed = state.completedTasks;

    // Group by completion date, newest first.
    final groups = <DateOnly, List<Task>>{};
    for (final task in completed) {
      final date = DateOnly.fromDateTime(task.completedAt ?? task.updatedAt);
      groups.putIfAbsent(date, () => []).add(task);
    }
    final dates = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    final hasClearable = completed.any(
      (t) => t.kind == TaskKind.single && t.seriesId == null,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed'),
        actions: [
          if (hasClearable)
            TextButton(
              onPressed: () async {
                final confirmed = await confirmDialog(
                  context,
                  title: 'Clear completed tasks?',
                  message:
                      'All completed non-recurring tasks will be permanently '
                      'deleted. Recurring history is kept.',
                  confirmLabel: 'Clear',
                );
                if (confirmed) await state.clearCompletedNonRecurring();
              },
              child: const Text('Clear'),
            ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: completed.isEmpty
            ? Center(
                child: Text(
                  'Completed tasks will appear here.',
                  style: TextStyle(
                    fontSize: 15.5,
                    color: context.colors.textSecondary,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                children: [
                  for (final date in dates) ...[
                    SectionHeader(
                      Formats.completionGroup(date),
                      trailing: '${groups[date]!.length}',
                    ),
                    for (final task in groups[date]!)
                      _CompletedRow(task: task, state: state),
                  ],
                ],
              ),
      ),
    );
  }
}

class _CompletedRow extends StatelessWidget {
  final Task task;
  final AppState state;

  const _CompletedRow({required this.task, required this.state});

  @override
  Widget build(BuildContext context) {
    final completedAt = task.completedAt;
    final meta = <String>[
      if (completedAt != null) 'Done ${Formats.timeOf(completedAt)}',
      if (task.dueDate != null)
        'was due ${Formats.deadline(task.dueDate!, task.dueMinutes)}',
      if (task.subtasks.isNotEmpty)
        '${task.completedSubtaskCount} of ${task.subtasks.length} subtasks',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: context.colors.elevated,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => TaskEditorScreen.open(context, task: task),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 20, color: context.colors.done),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              task.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                color: context.colors.textSecondary,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: context.colors.textMuted,
                              ),
                            ),
                          ),
                          if (task.isRecurring)
                            Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(
                                Icons.repeat,
                                size: 14,
                                color: context.colors.textMuted,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        meta.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Restore task',
                  icon: Icon(
                    Icons.undo,
                    size: 19,
                    color: context.colors.textSecondary,
                  ),
                  onPressed: () => state.restoreTask(task),
                ),
                IconButton(
                  tooltip: 'Delete permanently',
                  icon: Icon(
                    Icons.delete_outline,
                    size: 19,
                    color: context.colors.textMuted,
                  ),
                  onPressed: () async {
                    final confirmed = await confirmDialog(
                      context,
                      title: 'Delete permanently?',
                      message:
                          '"${task.title}" will be removed from your '
                          'completed history.',
                    );
                    if (confirmed) await state.deleteCompletedTask(task);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
