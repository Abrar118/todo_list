import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:uuid/uuid.dart';

import '../../core/app_colors.dart';
import '../../core/app_tokens.dart';
import '../../core/formats.dart';
import '../../domain/models/date_only.dart';
import '../../domain/models/priority.dart';
import '../../domain/models/recurrence.dart';
import '../../domain/models/subtask.dart';
import '../../domain/models/swatch.dart' as domain;
import '../../domain/models/task.dart' as domain;
import '../../services/calendar_export.dart';
import '../../state/app_state.dart';
import '../../state/focus_timer_controller.dart';
import '../../state/settings_controller.dart';
import '../widgets/common.dart';
import '../widgets/task_flows.dart';
import 'focus_timer_screen.dart';
import 'recurrence_sheet.dart';
import 'reminder_alarm_sheets.dart';

enum _SaveStatus { idle, saving, saved, error }

/// Full task editor: a dedicated screen with grouped sections and local
/// autosave. Edits persist continuously; Done additionally offers series
/// scopes for recurring occurrences.
class TaskEditorScreen extends StatefulWidget {
  final domain.Task? task;
  final String? draftTitle;
  final DateOnly? draftDate;
  final TaskPriority? draftPriority;

  const TaskEditorScreen({
    super.key,
    this.task,
    this.draftTitle,
    this.draftDate,
    this.draftPriority,
  });

  static Future<void> open(
    BuildContext context, {
    domain.Task? task,
    String? draftTitle,
    DateOnly? draftDate,
    TaskPriority? draftPriority,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskEditorScreen(
          task: task,
          draftTitle: draftTitle,
          draftDate: draftDate,
          draftPriority: draftPriority,
        ),
      ),
    );
  }

  @override
  State<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends State<TaskEditorScreen> {
  static const _uuid = Uuid();

  late domain.Task _draft;
  bool _persisted = false;
  RecurrenceRule? _rule;
  bool _seriesContentChanged = false;
  bool _showCompletedSubtasks = false;
  _SaveStatus _status = _SaveStatus.idle;
  Timer? _debounce;

  late final TextEditingController _title;
  final TextEditingController _newSubtask = TextEditingController();
  final TextEditingController _newTag = TextEditingController();
  late final QuillController _details;
  final FocusNode _detailsFocusNode = FocusNode(debugLabel: 'Task details');

  AppState get _state => context.read<AppState>();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (widget.task != null) {
      _draft = widget.task!;
      _persisted = true;
      _rule = context.read<AppState>().ruleOf(widget.task!);
    } else {
      final settings = context.read<SettingsController>().settings;
      _draft = domain.Task(
        id: _uuid.v4(),
        title: widget.draftTitle ?? '',
        priority: widget.draftPriority ?? settings.defaultPriority,
        dueDate: widget.draftDate,
        createdAt: now,
        updatedAt: now,
      );
    }
    _title = TextEditingController(text: _draft.title);
    _title.addListener(() {
      if (_title.text != _draft.title) {
        _update(_draft.copyWith(title: _title.text));
      }
    });
    _details = QuillController(
      document: _decodeDetails(_draft.detailsJson),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _details.document.changes.listen((_) => _onDetailsChanged());
  }

  Document _decodeDetails(String? json) {
    if (json == null || json.isEmpty) return Document();
    try {
      return Document.fromJson(jsonDecode(json) as List);
    } catch (_) {
      return Document()..insert(0, '');
    }
  }

  void _onDetailsChanged() {
    final delta = _details.document.toDelta().toJson();
    final encoded = _details.document.isEmpty() ? null : jsonEncode(delta);
    if (encoded != _draft.detailsJson) {
      _update(
        _draft.copyWith(detailsJson: encoded, clearDetails: encoded == null),
      );
    }
  }

  /// Every edit funnels through here: updates the draft, marks the
  /// series-content flag, schedules the debounced autosave.
  void _update(domain.Task updated, {bool touchesSeries = true}) {
    setState(() {
      _draft = updated;
      if (touchesSeries && _draft.kind == domain.TaskKind.occurrence) {
        _seriesContentChanged = true;
      }
      _status = _SaveStatus.saving;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _persistNow);
  }

  Future<void> _persistNow() async {
    _debounce?.cancel();
    if (_draft.title.trim().isEmpty && !_persisted) {
      setState(() => _status = _SaveStatus.idle);
      return;
    }
    try {
      if (!_persisted) {
        final created = await _state.createTask(
          title: _draft.title,
          dueDate: _draft.dueDate,
          dueMinutes: _draft.dueMinutes,
          priority: _draft.priority,
          reminders: _draft.reminders,
          recurrence: _rule,
          detailsJson: _draft.detailsJson,
          subtasks: _draft.subtasks,
          alarm: _draft.alarm,
          background: _draft.background,
        );
        _draft = created.copyWith(
          title: _draft.title,
          detailsJson: _draft.detailsJson,
          clearDetails: _draft.detailsJson == null,
        );
        _persisted = true;
        _seriesContentChanged = false;
      } else {
        await _state.updateTask(_draft);
        final saved = _state.taskById(_draft.id);
        if (saved != null) _draft = saved;
      }
      if (mounted) {
        setState(
          () => _status = _state.hasStorageError
              ? _SaveStatus.error
              : _SaveStatus.saved,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _status = _SaveStatus.error);
    }
  }

  Future<void> _finish() async {
    await _persistNow();
    if (!mounted) return;
    if (_persisted &&
        _draft.kind == domain.TaskKind.occurrence &&
        _seriesContentChanged &&
        _state.templateOf(_draft) != null) {
      final scope = await showSeriesScopeSheet(
        context,
        title: 'Apply changes to',
      );
      if (scope != null && scope != SeriesEditScope.thisOccurrence) {
        await _state.applySeriesEdit(_draft, scope);
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _title.dispose();
    _newSubtask.dispose();
    _newTag.dispose();
    _detailsFocusNode.dispose();
    _details.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------
  // Section actions
  // -------------------------------------------------------------------

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.dueDate?.toDateTime() ?? now,
      firstDate: now.subtract(const Duration(days: 365 * 2)),
      lastDate: now.add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      _update(_draft.copyWith(dueDate: DateOnly.fromDateTime(picked)));
    }
  }

  Future<void> _pickTime() async {
    final minutes = _draft.dueMinutes ?? 9 * 60;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked != null) {
      _update(_draft.copyWith(dueMinutes: picked.hour * 60 + picked.minute));
    }
  }

  Future<void> _editRecurrence() async {
    final anchor = _draft.dueDate ?? DateOnly.today();
    final settings = context.read<SettingsController>().settings;
    final result = await showRecurrenceSheet(
      context,
      current: _rule,
      anchorDate: anchor,
      defaultBehavior: settings.defaultRecurrenceBehavior,
    );
    if (result == null) return;
    if (_draft.dueDate == null && result.rule != null) {
      _update(_draft.copyWith(dueDate: DateOnly.today()));
    }
    setState(() => _rule = result.rule);
    if (_persisted) {
      // Rule changes always affect the series structure; apply immediately.
      await _persistNow();
      final survivor = await _state.updateSeriesRule(_draft, result.rule);
      setState(() {
        _draft = survivor;
        _seriesContentChanged = false;
      });
    } else {
      _update(_draft, touchesSeries: false);
    }
  }

  Future<void> _addReminder() async {
    final entry = await showReminderPicker(context);
    if (entry == null || !mounted) return;
    final usable = await ensureNotificationPermission(context);
    if (!mounted) return;

    // Quiet hours: surface the adjusted delivery time before committing.
    final settings = context.read<SettingsController>().settings;
    final due = _draft.dueInstant(
      dateOnlyMinutes: settings.dateOnlyReminderMinutes,
    );
    if (due != null && settings.quietHours.enabled) {
      final at = entry.isCustom
          ? entry.customTime!
          : due.subtract(Duration(minutes: entry.offsetMinutes!));
      final adjusted = settings.quietHours.adjust(at);
      if (adjusted != at) {
        final proceed = await confirmDialog(
          context,
          title: 'Quiet hours',
          message:
              'That time falls inside quiet hours. The reminder will be '
              'delivered at ${Formats.timeOf(adjusted)} instead.',
          confirmLabel: 'Add reminder',
          destructive: false,
        );
        if (!proceed) return;
      }
    }
    _update(_draft.copyWith(reminders: [..._draft.reminders, entry]));
    if (!usable && mounted) {
      // Message already shown by the permission flow; config is kept.
    }
  }

  Future<void> _editAlarm() async {
    final settings = context.read<SettingsController>().settings;
    final result = await showAlarmSheet(
      context,
      current: _draft.alarm,
      defaultCadenceMinutes: settings.defaultAlarmCadenceMinutes,
    );
    if (result == null || !mounted) return;
    if (result.enabled && !_draft.alarm.enabled) {
      await ensureNotificationPermission(context);
      if (!mounted) return;
    }
    _update(_draft.copyWith(alarm: result));
  }

  // Subtasks ------------------------------------------------------------

  void _addSubtask() {
    final text = _newSubtask.text.trim();
    if (text.isEmpty) return;
    _newSubtask.clear();
    final now = DateTime.now();
    final maxSort = _draft.subtasks.isEmpty
        ? -1
        : _draft.subtasks
              .map((s) => s.sortIndex)
              .reduce((a, b) => a > b ? a : b);
    _update(
      _draft.copyWith(
        subtasks: [
          ..._draft.subtasks,
          Subtask(
            id: _uuid.v4(),
            title: text,
            sortIndex: maxSort + 1,
            createdAt: now,
          ),
        ],
      ),
    );
  }

  void _toggleSubtask(Subtask subtask) {
    final now = DateTime.now();
    _update(
      _draft.copyWith(
        subtasks: [
          for (final s in _draft.subtasks)
            s.id == subtask.id
                ? s.copyWith(
                    isCompleted: !s.isCompleted,
                    completedAt: s.isCompleted ? null : now,
                    clearCompletedAt: s.isCompleted,
                  )
                : s,
        ],
      ),
    );
  }

  Future<void> _renameSubtask(Subtask subtask) async {
    final controller = TextEditingController(text: subtask.title);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit subtask'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result.isNotEmpty) {
      _update(
        _draft.copyWith(
          subtasks: [
            for (final s in _draft.subtasks)
              s.id == subtask.id ? s.copyWith(title: result) : s,
          ],
        ),
      );
    }
  }

  void _deleteSubtask(Subtask subtask) {
    _update(
      _draft.copyWith(
        subtasks: _draft.subtasks.where((s) => s.id != subtask.id).toList(),
      ),
    );
  }

  void _reorderSubtasks(int oldIndex, int newIndex, List<Subtask> visible) {
    final ordered = List<Subtask>.of(visible);
    final moved = ordered.removeAt(oldIndex);
    ordered.insert(newIndex, moved);
    final completed = _draft.subtasks.where((s) => s.isCompleted).toList();
    final all = [...ordered, ...completed];
    _update(
      _draft.copyWith(
        subtasks: [
          for (var i = 0; i < all.length; i++) all[i].copyWith(sortIndex: i),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pending = (_draft.subtasks.where((s) => !s.isCompleted).toList()
      ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex)));
    final completed = (_draft.subtasks.where((s) => s.isCompleted).toList()
      ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex)));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: _finish,
          ),
          title: Text(_persisted ? 'Edit task' : 'New task'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(child: _saveIndicator()),
            ),
            TextButton(onPressed: _finish, child: const Text('Done')),
          ],
        ),
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors.background,
                Color.lerp(colors.background, colors.accent, 0.045)!,
                colors.background,
              ],
              stops: const [0, 0.48, 1],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
              children: [
                _titleSection(),
                SectionHeader('Background', color: colors.accent),
                _backgroundSection(),
                SectionHeader('Schedule', color: colors.low),
                _card([
                  _dateTile(),
                  if (_draft.dueDate != null) _timeTile(),
                  _recurrenceTile(),
                  if (_draft.dueDate != null) _calendarTile(),
                ], tint: colors.low),
                SectionHeader('Reminders', color: colors.medium),
                _card([..._reminderTiles(), _alarmTile()], tint: colors.medium),
                SectionHeader('Subtasks', color: colors.done),
                _card([
                  if (pending.isEmpty && completed.isEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
                      child: Text(
                        'Break this task into steps.',
                        style: TextStyle(
                          color: context.colors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  if (_draft.subtasks.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${completed.length} of ${_draft.subtasks.length} completed',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: context.colors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: completed.length / _draft.subtasks.length,
                              minHeight: 5,
                              color: context.colors.done,
                              backgroundColor: context.colors.pressed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    onReorderItem: (a, b) => _reorderSubtasks(a, b, pending),
                    children: [
                      for (var i = 0; i < pending.length; i++)
                        _subtaskRow(
                          pending[i],
                          index: i,
                          key: ValueKey(pending[i].id),
                        ),
                    ],
                  ),
                  if (completed.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => setState(
                        () => _showCompletedSubtasks = !_showCompletedSubtasks,
                      ),
                      icon: Icon(
                        _showCompletedSubtasks
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 18,
                      ),
                      label: Text(
                        '${_showCompletedSubtasks ? 'Hide' : 'Show'} completed (${completed.length})',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  if (_showCompletedSubtasks)
                    for (final s in completed)
                      _subtaskRow(s, key: ValueKey(s.id)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: TextField(
                      controller: _newSubtask,
                      onSubmitted: (_) => _addSubtask(),
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: 'Add subtask',
                        isDense: true,
                        prefixIcon: const Icon(Icons.add, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check, size: 20),
                          tooltip: 'Add subtask',
                          onPressed: _addSubtask,
                        ),
                      ),
                    ),
                  ),
                ], tint: colors.done),
                SectionHeader('Details', color: colors.low),
                _detailsSection(),
                SectionHeader('Priority', color: colors.medium),
                _prioritySection(),
                SectionHeader('Tags', color: colors.accent),
                _tagsSection(),
                if (_draft.subtasks.isEmpty) ...[
                  SectionHeader('Progress', color: colors.done),
                  _progressSection(),
                ],
                if (_persisted && !_draft.isCompleted) ...[
                  SectionHeader('Focus timer', color: colors.accent),
                  _timerSection(),
                ],
                if (_persisted) ...[
                  const SizedBox(height: 24),
                  _footerActions(),
                  const SizedBox(height: 12),
                  _metadata(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _saveIndicator() {
    final (label, color) = switch (_status) {
      _SaveStatus.idle => ('', context.colors.textMuted),
      _SaveStatus.saving => ('Saving…', context.colors.textMuted),
      _SaveStatus.saved => ('Saved', context.colors.done),
      _SaveStatus.error => ('Unable to save', context.colors.overdue),
    };
    return AnimatedOpacity(
      opacity: label.isEmpty ? 0 : 1,
      duration: const Duration(milliseconds: 200),
      child: Text(label, style: TextStyle(fontSize: 12.5, color: color)),
    );
  }

  Widget _frostedPanel({
    required Widget child,
    Color? tint,
    EdgeInsetsGeometry? padding,
  }) {
    final colors = context.colors;
    final panelTint = tint ?? colors.accent;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.mediumRadius,
        boxShadow: [
          BoxShadow(
            color: panelTint.withValues(alpha: 0.08),
            blurRadius: 22,
            spreadRadius: -6,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      // Not glass: the editor's panels sit on the flat scaffold background,
      // so the blur returned that same colour at the cost of a saveLayer.
      child: ClipRSuperellipse(
        borderRadius: AppRadii.mediumRadius,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(colors.card, panelTint, isDark ? 0.12 : 0.08)!,
                colors.elevated,
              ],
            ),
          ),
          foregroundDecoration: ShapeDecoration(
            shape: RoundedSuperellipseBorder(
              borderRadius: AppRadii.mediumRadius,
              side: BorderSide(color: colors.borderStrong),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children, {Color? tint}) => _frostedPanel(
    tint: tint,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );

  Widget _titleSection() {
    return _frostedPanel(
      tint:
          _backgroundColor(_draft.background) ??
          priorityColor(context, _draft.priority),
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_persisted)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Checkbox(
                  value: _draft.isCompleted,
                  onChanged: (_) async {
                    await _persistNow();
                    final current = _state.taskById(_draft.id) ?? _draft;
                    if (!mounted) return;
                    await completeTaskFlow(context, _state, current);
                    final after = _state.taskById(_draft.id);
                    if (after != null && mounted) {
                      setState(() => _draft = after);
                    }
                  },
                ),
              ),
            ),
          Expanded(
            child: TextField(
              controller: _title,
              maxLines: null,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: 'Task title',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backgroundSection() {
    final selectedColor = _backgroundColor(_draft.background);
    return _frostedPanel(
      tint: selectedColor ?? context.colors.accent,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Give this task a distinct card treatment on Focus.',
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 10),
          SwatchPicker(
            selected: _draft.background,
            allowAutomatic: true,
            onPick: (swatch) => _update(
              _draft.copyWith(
                background: swatch,
                clearBackground: swatch == null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color? _backgroundColor(domain.Swatch? background) =>
      background == null ? null : swatchColor(context.colors, background);

  Widget _dateTile() {
    return ListTile(
      leading: const Icon(Icons.event_outlined),
      title: Text(
        _draft.dueDate != null
            ? Formats.relativeDate(_draft.dueDate!)
            : 'Add deadline',
      ),
      trailing: _draft.dueDate != null
          ? IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Remove deadline',
              onPressed: () => _update(_draft.copyWith(clearDueDate: true)),
            )
          : null,
      onTap: _pickDate,
    );
  }

  Widget _timeTile() {
    return ListTile(
      leading: const Icon(Icons.access_time),
      title: Text(
        _draft.dueMinutes != null
            ? Formats.time(_draft.dueMinutes!)
            : 'Add time',
      ),
      subtitle: _draft.dueMinutes == null
          ? Text(
              'All-day',
              style: TextStyle(fontSize: 12.5, color: context.colors.textMuted),
            )
          : null,
      trailing: _draft.dueMinutes != null
          ? IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Remove time',
              onPressed: () => _update(_draft.copyWith(clearDueMinutes: true)),
            )
          : null,
      onTap: _pickTime,
    );
  }

  Widget _recurrenceTile() {
    return ListTile(
      leading: const Icon(Icons.repeat),
      title: Text(_rule?.describe() ?? 'Does not repeat'),
      onTap: _editRecurrence,
    );
  }

  List<Widget> _reminderTiles() {
    final settings = context.watch<SettingsController>();
    return [
      for (final entry in _draft.reminders)
        ListTile(
          leading: const Icon(Icons.notifications_none),
          title: Text(
            entry.isCustom
                ? Formats.fullTimestamp(entry.customTime!)
                : entry.describe(),
          ),
          subtitle: !settings.notificationsUsable
              ? Text(
                  'Device notifications are off',
                  style: TextStyle(fontSize: 12, color: context.colors.medium),
                )
              : null,
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Remove reminder',
            onPressed: () => _update(
              _draft.copyWith(
                reminders: _draft.reminders.where((r) => r != entry).toList(),
              ),
            ),
          ),
        ),
      ListTile(
        leading: const Icon(Icons.add_alert_outlined),
        title: const Text('Add reminder'),
        enabled: _draft.dueDate != null,
        subtitle: _draft.dueDate == null
            ? Text(
                'Set a deadline first',
                style: TextStyle(fontSize: 12, color: context.colors.textMuted),
              )
            : null,
        onTap: _draft.dueDate == null ? null : _addReminder,
      ),
    ];
  }

  Widget _alarmTile() {
    final alarm = _draft.alarm;
    return ListTile(
      leading: Icon(
        alarm.enabled
            ? Icons.notifications_active
            : Icons.notifications_paused_outlined,
        color: alarm.enabled ? context.colors.accent : null,
      ),
      title: const Text('Persistent alarm'),
      subtitle: Text(
        alarm.enabled
            ? '${alarm.describeCadence()} until handled'
            : 'Keep reminding until handled',
        style: TextStyle(
          fontSize: 12.5,
          color: alarm.enabled
              ? context.colors.accent
              : context.colors.textMuted,
        ),
      ),
      trailing: Switch(
        value: alarm.enabled,
        onChanged: _draft.dueDate == null
            ? null
            : (v) async {
                if (v) {
                  await _editAlarm();
                } else {
                  _update(
                    _draft.copyWith(alarm: alarm.copyWith(enabled: false)),
                  );
                }
              },
      ),
      enabled: _draft.dueDate != null,
      onTap: _draft.dueDate == null ? null : _editAlarm,
    );
  }

  Widget _subtaskRow(Subtask subtask, {int? index, required Key key}) {
    return Row(
      key: key,
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: Checkbox(
            value: subtask.isCompleted,
            onChanged: (_) => _toggleSubtask(subtask),
            semanticLabel: 'Complete ${subtask.title}',
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: () => _renameSubtask(subtask),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                subtask.title,
                style: TextStyle(
                  fontSize: 14.5,
                  color: subtask.isCompleted
                      ? context.colors.textMuted
                      : context.colors.textPrimary,
                  decoration: subtask.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  decorationColor: context.colors.textMuted,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, size: 17, color: context.colors.textMuted),
          tooltip: 'Delete subtask',
          onPressed: () => _deleteSubtask(subtask),
        ),
        if (index != null)
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(
                Icons.drag_indicator,
                size: 20,
                color: context.colors.textMuted,
              ),
            ),
          ),
      ],
    );
  }

  Widget _detailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _frostedPanel(
          tint: context.colors.low,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: QuillEditor.basic(
            controller: _details,
            focusNode: _detailsFocusNode,
            config: QuillEditorConfig(
              placeholder: 'Add details…',
              minHeight: 100,
              scrollable: false,
              onLaunchUrl: (url) => launchUrlString(url),
              customStyles: DefaultStyles(
                placeHolder: DefaultTextBlockStyle(
                  TextStyle(color: context.colors.textMuted, fontSize: 14.5),
                  HorizontalSpacing.zero,
                  VerticalSpacing.zero,
                  VerticalSpacing.zero,
                  null,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _frostedPanel(
          tint: context.colors.accent,
          child: QuillSimpleToolbar(
            controller: _details,
            config: const QuillSimpleToolbarConfig(
              multiRowsDisplay: false,
              showBoldButton: true,
              showItalicButton: true,
              showListBullets: true,
              showListNumbers: true,
              showListCheck: true,
              showLink: true,
              showUndo: true,
              showRedo: true,
              // Everything else off: this is a task note, not a document.
              showFontFamily: false,
              showFontSize: false,
              showUnderLineButton: false,
              showStrikeThrough: false,
              showInlineCode: false,
              showColorButton: false,
              showBackgroundColorButton: false,
              showClearFormat: false,
              showAlignmentButtons: false,
              showHeaderStyle: false,
              showCodeBlock: false,
              showQuote: false,
              showIndent: false,
              showSearchButton: false,
              showSubscript: false,
              showSuperscript: false,
              showSmallButton: false,
              showLineHeightButton: false,
              showDividers: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _prioritySection() {
    return Wrap(
      spacing: 8,
      children: [
        for (final p in TaskPriority.values)
          ChoiceChip(
            avatar: p == TaskPriority.none
                ? null
                : Icon(Icons.flag, size: 15, color: priorityColor(context, p)),
            label: Text(p.label),
            selected: _draft.priority == p,
            onSelected: (_) => _update(_draft.copyWith(priority: p)),
          ),
      ],
    );
  }

  void _addTag([String? value]) {
    var tag = (value ?? _newTag.text).trim();
    if (tag.startsWith('#')) tag = tag.substring(1);
    _newTag.clear();
    if (tag.isEmpty) return;
    if (_draft.tags.any((t) => t.toLowerCase() == tag.toLowerCase())) return;
    _update(_draft.copyWith(tags: [..._draft.tags, tag]));
  }

  Widget _tagsSection() {
    final suggestions = _state.allTags
        .where(
          (t) => !_draft.tags.any((x) => x.toLowerCase() == t.toLowerCase()),
        )
        .toList();
    return _card([
      if (_draft.tags.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in _draft.tags)
                InputChip(
                  label: Text('#$tag'),
                  deleteButtonTooltipMessage: 'Remove #$tag',
                  onDeleted: () => _update(
                    _draft.copyWith(tags: [..._draft.tags]..remove(tag)),
                  ),
                ),
            ],
          ),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: TextField(
          controller: _newTag,
          onSubmitted: _addTag,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'Add tag',
            isDense: true,
            prefixIcon: const Icon(Icons.tag, size: 20),
            suffixIcon: IconButton(
              icon: const Icon(Icons.check, size: 20),
              tooltip: 'Add tag',
              onPressed: _addTag,
            ),
          ),
        ),
      ),
      if (suggestions.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in suggestions.take(8))
                ActionChip(label: Text('#$tag'), onPressed: () => _addTag(tag)),
            ],
          ),
        )
      else
        const SizedBox(height: 8),
    ], tint: context.colors.accent);
  }

  Widget _progressSection() {
    final percent = _draft.progressPercent;
    return _card([
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: Row(
          children: [
            Expanded(
              child: Slider(
                value: (percent ?? 0) / 100,
                divisions: 20,
                label: '${percent ?? 0}%',
                onChanged: (v) => _update(
                  _draft.copyWith(progressPercent: (v * 100).round()),
                  touchesSeries: false,
                ),
              ),
            ),
            SizedBox(
              width: 48,
              child: Text(
                percent == null ? '—' : '$percent%',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 13.5,
                  color: percent == null
                      ? context.colors.textMuted
                      : context.colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
      if (percent != null)
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 4),
            child: TextButton(
              onPressed: () => _update(
                _draft.copyWith(clearProgress: true),
                touchesSeries: false,
              ),
              child: const Text(
                'Clear progress',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
        )
      else
        const SizedBox(height: 6),
    ], tint: context.colors.done);
  }

  static String _formatSpent(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    return '<1m';
  }

  Widget _timerSection() {
    final timer = context.watch<FocusTimerController>();
    final settings = context.read<SettingsController>().settings;
    final runningHere = timer.isActive && timer.taskId == _draft.id;
    return _card([
      ListTile(
        leading: Icon(
          runningHere ? Icons.timer : Icons.timer_outlined,
          color: runningHere ? context.colors.accent : null,
        ),
        title: Text(
          runningHere
              ? (timer.phase == TimerPhase.work
                    ? 'Focusing — ${FocusTimerScreen.format(timer.remaining)}'
                    : 'On a break — '
                          '${FocusTimerScreen.format(timer.remaining)}')
              : 'Start focus session',
        ),
        subtitle: runningHere
            ? null
            : Text(
                '${settings.pomodoroWorkMinutes} min focus, '
                '${settings.pomodoroBreakMinutes} min break',
                style: TextStyle(
                  fontSize: 12.5,
                  color: context.colors.textMuted,
                ),
              ),
        trailing: runningHere ? const Icon(Icons.chevron_right) : null,
        onTap: () async {
          final controller = context.read<FocusTimerController>();
          if (!runningHere) {
            if (controller.isActive) {
              final confirmed = await confirmDialog(
                context,
                title: 'Switch focus session?',
                message:
                    'A session is running on "${controller.taskTitle}". '
                    'Stop it and focus on this task instead?',
                confirmLabel: 'Switch',
                destructive: false,
              );
              if (!confirmed) return;
              await controller.stop();
            }
            controller.startWork(taskId: _draft.id, taskTitle: _draft.title);
          }
          if (mounted) await FocusTimerScreen.open(context);
        },
      ),
      if (_draft.timeSpentSeconds > 0)
        ListTile(
          leading: const Icon(Icons.hourglass_bottom_outlined),
          title: Text('Time spent: ${_formatSpent(_draft.timeSpentSeconds)}'),
        ),
    ], tint: context.colors.accent);
  }

  Widget _calendarTile() {
    return ListTile(
      leading: Icon(
        Icons.event_available_outlined,
        color: context.colors.accent,
      ),
      title: const Text('Add to device calendar'),
      subtitle: Text(
        'Review and save it in your calendar app',
        style: TextStyle(fontSize: 12.5, color: context.colors.textMuted),
      ),
      onTap: () async {
        final minutes = context
            .read<SettingsController>()
            .settings
            .dateOnlyReminderMinutes;
        final ok = await addTaskToDeviceCalendar(
          _draft,
          dateOnlyMinutes: minutes,
        );
        if (!ok && mounted) {
          showAppSnackBar(context, 'Calendar event was not added.');
        }
      },
    );
  }

  Widget _footerActions() {
    final isOccurrence =
        _draft.kind == domain.TaskKind.occurrence &&
        _state.templateOf(_draft) != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isOccurrence)
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: context.colors.textPrimary,
              backgroundColor: context.colors.pressed.withValues(alpha: 0.72),
            ),
            icon: const Icon(Icons.stop_circle_outlined, size: 18),
            label: const Text('End recurring series'),
            onPressed: () async {
              final confirmed = await confirmDialog(
                context,
                title: 'End recurring series?',
                message:
                    'No future occurrences will be created. Completed '
                    'occurrences stay in your history.',
                confirmLabel: 'End series',
              );
              if (confirmed && mounted) {
                await _state.endSeries(_draft);
                if (mounted) Navigator.of(context).pop();
              }
            },
          ),
        const SizedBox(height: 8),
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: context.colors.overdue,
            backgroundColor: context.colors.overdue.withValues(alpha: 0.10),
          ),
          icon: Icon(
            Icons.delete_outline,
            size: 18,
            color: context.colors.overdue,
          ),
          label: Text(
            'Delete task',
            style: TextStyle(color: context.colors.overdue),
          ),
          onPressed: () async {
            final navigator = Navigator.of(context);
            await deleteTaskFlow(context, _state, _draft);
            if (mounted && _state.taskById(_draft.id) == null) {
              navigator.pop();
            }
          },
        ),
      ],
    );
  }

  Widget _metadata() {
    final style = TextStyle(fontSize: 12, color: context.colors.textMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Created ${Formats.fullTimestamp(_draft.createdAt)}',
          style: style,
        ),
        Text(
          'Updated ${Formats.fullTimestamp(_draft.updatedAt)}',
          style: style,
        ),
        if (_draft.completedAt != null)
          Text(
            'Completed ${Formats.fullTimestamp(_draft.completedAt!)}',
            style: style,
          ),
      ],
    );
  }
}
