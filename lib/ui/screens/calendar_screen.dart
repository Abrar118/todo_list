import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_tokens.dart';
import '../../core/formats.dart';
import '../../domain/models/date_only.dart';
import '../../state/app_state.dart';
import '../../state/settings_controller.dart';
import '../widgets/common.dart';
import '../widgets/task_row.dart';
import '../widgets/task_flows.dart';
import '../widgets/ticket.dart';
import 'quick_add_sheet.dart';
import 'task_editor_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateOnly _selected;
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _selected = DateOnly.today();
    _year = _selected.year;
    _month = _selected.month;
  }

  void _shiftMonth(int delta) {
    setState(() {
      final total = _year * 12 + (_month - 1) + delta;
      _year = total ~/ 12;
      _month = total % 12 + 1;
    });
  }

  void _goToday() {
    setState(() {
      _selected = DateOnly.today();
      _year = _selected.year;
      _month = _selected.month;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final settings = context.watch<SettingsController>().settings;
    final markers = state.monthMarkers(_year, _month);
    final agenda = state.agendaFor(_selected);
    final today = DateOnly.today();
    final showingToday = _year == today.year && _month == today.month;

    final allDay = agenda.where(
      (i) => !i.task.isCompleted && i.task.dueMinutes == null,
    );
    final timed = agenda.where(
      (i) => !i.task.isCompleted && i.task.dueMinutes != null,
    );
    final done = agenda.where((i) => i.task.isCompleted);

    final entries = <Widget Function()>[];
    void group(String title, Iterable<AgendaItem> items) {
      if (items.isEmpty) return;
      final first = entries.isEmpty;
      entries.add(() => SectionHeader(title, tight: first));
      final list = items.toList();
      for (final (i, item) in list.indexed) {
        entries.add(
          () => RailTile(
            first: i == 0,
            last: i == list.length - 1,
            child: _agendaRow(state, item),
          ),
        );
      }
    }

    group('All-day', allDay);
    group('Scheduled', timed);
    group('Completed', done);

    // The add action always adds to the selected day.
    void addForDay() => QuickAddSheet.open(context, initialDate: _selected);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: rootAddFab(
        context,
        onPressed: addForDay,
        tooltip: 'Add task',
      ),
      body: CustomScrollView(
        slivers: [
          rootAppBar(
            context,
            title: Formats.monthTitle(_year, _month),
            onAdd: addForDay,
            addTooltip: 'Add task',
            actions: [
              if (!showingToday || _selected != today)
                TextButton(onPressed: _goToday, child: const Text('Today')),
              IconButton(
                tooltip: 'Previous month',
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _shiftMonth(-1),
              ),
              IconButton(
                tooltip: 'Next month',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _shiftMonth(1),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: _MonthGrid(
              year: _year,
              month: _month,
              selected: _selected,
              startOfWeek: settings.startOfWeek,
              markers: markers,
              onSelect: (d) => setState(() => _selected = d),
            ),
          ),
          const SliverToBoxAdapter(child: Divider()),
          if (entries.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Nothing on ${Formats.relativeDate(_selected)}',
                      style: TextStyle(color: context.colors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _addForDayButton(),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
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

  Widget _addForDayButton() => TextButton.icon(
    onPressed: () => QuickAddSheet.open(context, initialDate: _selected),
    icon: const Icon(Icons.add, size: 18),
    label: const Text('Add task for this day'),
  );

  Widget _agendaRow(AppState state, AgendaItem item) {
    final task = item.task;
    return TaskRow(
      task: task,
      rule: state.ruleOf(task),
      isProjection: item.isProjection,
      onTap: item.isProjection
          ? () {
              // Future occurrences aren't materialized yet; edit the
              // series' current occurrence instead.
              final template = state.templateOf(task);
              final active = state.allTasks
                  .where((t) => t.seriesId == template?.id && !t.isCompleted)
                  .toList();
              if (active.isNotEmpty) {
                TaskEditorScreen.open(context, task: active.first);
              }
            }
          : () => TaskEditorScreen.open(context, task: task),
      onToggle: item.isProjection
          ? null
          : () => completeTaskFlow(context, state, task),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final int year;
  final int month;
  final DateOnly selected;
  final int startOfWeek;
  final Map<DateOnly, DayMarkers> markers;
  final ValueChanged<DateOnly> onSelect;

  const _MonthGrid({
    required this.year,
    required this.month,
    required this.selected,
    required this.startOfWeek,
    required this.markers,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateOnly.today();
    final first = DateOnly(year, month, 1);
    final daysInMonth = DateOnly.daysInMonth(year, month);
    final leading = (first.weekday - startOfWeek + 7) % 7;
    final totalCells = ((leading + daysInMonth) / 7).ceil() * 7;
    const dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      dayLetters[(startOfWeek - 1 + i) % 7],
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var row = 0; row < totalCells / 7; row++)
            Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: _cell(
                      context,
                      row * 7 + col - leading + 1,
                      daysInMonth,
                      today,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, int day, int daysInMonth, DateOnly today) {
    if (day < 1 || day > daysInMonth) return const SizedBox(height: 46);
    final date = DateOnly(year, month, day);
    final isSelected = date == selected;
    final isToday = date == today;
    final m = markers[date];
    final colors = context.colors;

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${Formats.relativeDate(date)}'
          '${m != null ? ', ${m.taskCount} task${m.taskCount == 1 ? '' : 's'}' : ''}'
          '${m?.hasHighPriority == true ? ', has high priority' : ''}',
      child: InkWell(
        onTap: () => onSelect(date),
        borderRadius: AppRadii.smallRadius,
        child: AnimatedContainer(
          duration: AppMotion.quick,
          height: 46,
          decoration: BoxDecoration(
            // The selected day is punched in ink; today is ringed.
            color: isSelected ? colors.textPrimary : Colors.transparent,
            borderRadius: AppRadii.smallRadius,
            border: Border.all(
              color: isToday && !isSelected
                  ? colors.textPrimary
                  : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: AppTypography.body,
                  fontWeight: isToday || isSelected
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: isSelected
                      ? colors.background
                      : isToday
                      ? colors.textPrimary
                      : colors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 6,
                child: m == null
                    ? null
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (m.hasHighPriority)
                            _dot(colors.overdue)
                          else if (!m.allCompleted)
                            _dot(
                              isSelected
                                  ? colors.background
                                  : colors.textPrimary,
                            ),
                          if (m.hasRecurring) _dot(colors.textMuted),
                          if (m.hasCompleted && m.allCompleted)
                            _dot(colors.done),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: 5,
    height: 5,
    margin: const EdgeInsets.symmetric(horizontal: 1.5),
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
