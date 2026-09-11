import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../domain/logic/task_search.dart';
import '../../domain/models/task.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/task_flows.dart';
import '../widgets/task_row.dart';
import 'task_editor_screen.dart';

/// Full-text search over every task, including completed history.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const SearchScreen()));

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final results = TaskSearch.search(state.allTasks, _query);
    final active = [
      for (final t in results)
        if (!t.isCompleted) t,
    ];
    final completed = [
      for (final t in results)
        if (t.isCompleted) t,
    ];

    Widget row(Task task) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TaskRow(
        task: task,
        rule: state.ruleOf(task),
        onTap: () => TaskEditorScreen.open(context, task: task),
        onToggle: () => completeTaskFlow(context, state, task),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search tasks…',
              isDense: true,
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _query.trim().isEmpty
            ? const _SearchHint(
                icon: Icons.search,
                message:
                    'Search titles, details and subtasks —\n'
                    'completed history included.',
              )
            : results.isEmpty
            ? const _SearchHint(
                icon: Icons.search_off,
                message: 'No matching tasks.',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  for (final task in active) row(task),
                  if (completed.isNotEmpty) ...[
                    SectionHeader('Completed', trailing: '${completed.length}'),
                    for (final task in completed) row(task),
                  ],
                ],
              ),
      ),
    );
  }
}

class _SearchHint extends StatelessWidget {
  final IconData icon;
  final String message;

  const _SearchHint({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: colors.textMuted),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.5, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
