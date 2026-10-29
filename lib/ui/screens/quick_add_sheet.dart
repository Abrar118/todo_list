import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_tokens.dart';
import '../../core/app_colors.dart';
import '../../core/formats.dart';
import '../../domain/logic/quick_add_parser.dart';
import '../../domain/models/date_only.dart';
import '../../domain/models/priority.dart';
import '../../domain/models/reminders.dart';
import '../../state/app_state.dart';
import '../../state/settings_controller.dart';
import '../widgets/common.dart';
import '../widgets/task_flows.dart';
import 'task_editor_screen.dart';

/// The fastest creation path: a title, an optional deadline, done.
/// Everything else lives one tap away in the full editor.
class QuickAddSheet extends StatefulWidget {
  final DateOnly? initialDate;

  const QuickAddSheet({super.key, this.initialDate});

  static Future<void> open(BuildContext context, {DateOnly? initialDate}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: QuickAddSheet(initialDate: initialDate),
      ),
    );
  }

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final _controller = TextEditingController();
  DateOnly? _dueDate;
  TaskPriority _priority = TaskPriority.none;
  bool _reminder = false;
  bool _saving = false;

  /// Date/time detected in the typed text ("call mom tomorrow 5pm").
  ParsedQuickAdd? _parsed;

  /// Set when the user dismissed the detected date; the text is then used
  /// verbatim.
  bool _ignoreParsed = false;

  @override
  void initState() {
    super.initState();
    _dueDate = widget.initialDate;
    final settings = context.read<SettingsController>().settings;
    _priority = settings.defaultPriority;
    _reminder = settings.defaultReminderEnabled;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ParsedQuickAdd? get _activeParse =>
      _ignoreParsed || _parsed?.hasMatch != true ? null : _parsed;

  /// Manual choice wins over the parsed date.
  DateOnly? get _effectiveDate => _dueDate ?? _activeParse?.dueDate;

  void _onTextChanged(String text) {
    setState(() {
      _ignoreParsed = false;
      _parsed = text.trim().isEmpty
          ? null
          : QuickAddParser.parse(text, DateTime.now());
    });
  }

  Future<void> _submit() async {
    final parse = _activeParse;
    final title = (parse?.title ?? _controller.text).trim();
    final dueDate = _effectiveDate;
    if (title.isEmpty || _saving) return;
    setState(() => _saving = true);
    final state = context.read<AppState>();
    final settings = context.read<SettingsController>().settings;

    var reminders = const <ReminderEntry>[];
    if (_reminder && dueDate != null) {
      final usable = await ensureNotificationPermission(context);
      reminders = [ReminderEntry.before(settings.defaultReminderOffsetMinutes)];
      // Keep the configuration even when permission was denied; it activates
      // once notifications are enabled. (`usable` only affects messaging.)
      if (!usable && mounted) setState(() {});
    }

    await state.createTask(
      title: title,
      dueDate: dueDate,
      dueMinutes: dueDate != null ? parse?.dueMinutes : null,
      priority: _priority,
      reminders: reminders,
      tags: parse?.tags ?? const [],
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _openFullEditor() async {
    final navigator = Navigator.of(context);
    final draftTitle = (_activeParse?.title ?? _controller.text).trim();
    final draftDate = _effectiveDate;
    navigator.pop();
    await TaskEditorScreen.open(
      context,
      draftTitle: draftTitle,
      draftDate: draftDate,
      draftPriority: _priority,
    );
  }

  String _detectedLabel(ParsedQuickAdd parse) {
    final parts = <String>[];
    final date = _effectiveDate;
    if (date != null && parse.dueDate != null) {
      var label = Formats.relativeDate(date);
      if (parse.dueMinutes != null) {
        label = '$label at ${Formats.time(parse.dueMinutes!)}';
      }
      parts.add(label);
    }
    parts.addAll(parse.tags.map((t) => '#$t'));
    return parts.isEmpty ? '' : 'Detected: ${parts.join(' · ')}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveDate?.toDateTime() ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _dueDate = DateOnly.fromDateTime(picked));
    }
  }

  void _clearDate() {
    _dueDate = null;
    _ignoreParsed = true;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateOnly.today();
    final tomorrow = today.addDays(1);
    final parse = _activeParse;
    final effectiveDate = _effectiveDate;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onChanged: _onTextChanged,
            onSubmitted: (_) => _submit(),
            style: const TextStyle(fontSize: AppTypography.body),
            decoration: const InputDecoration(
              hintText: 'Add something you cannot forget…',
            ),
          ),
          if (parse != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 15,
                  color: context.colors.accent,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _detectedLabel(parse),
                    style: TextStyle(
                      fontSize: AppTypography.footnote,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Keep text as typed',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _ignoreParsed = true),
                  icon: Icon(
                    Icons.close,
                    size: 16,
                    color: context.colors.textMuted,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Today'),
                selected: effectiveDate == today,
                onSelected: (v) =>
                    setState(() => v ? _dueDate = today : _clearDate()),
              ),
              ChoiceChip(
                label: const Text('Tomorrow'),
                selected: effectiveDate == tomorrow,
                onSelected: (v) =>
                    setState(() => v ? _dueDate = tomorrow : _clearDate()),
              ),
              ActionChip(
                avatar: Icon(
                  Icons.calendar_month_outlined,
                  size: 16,
                  color: context.colors.textSecondary,
                ),
                label: Text(
                  effectiveDate != null &&
                          effectiveDate != today &&
                          effectiveDate != tomorrow
                      ? Formats.relativeDate(effectiveDate)
                      : 'Pick date',
                ),
                onPressed: _pickDate,
              ),
              ChoiceChip(
                avatar: _priority == TaskPriority.none
                    ? null
                    : Icon(
                        Icons.flag,
                        size: 16,
                        color: priorityColor(context, _priority),
                      ),
                label: Text(
                  _priority == TaskPriority.none ? 'Priority' : _priority.label,
                ),
                selected: _priority != TaskPriority.none,
                onSelected: (_) => setState(() {
                  final next =
                      (_priority.index + 1) % TaskPriority.values.length;
                  _priority = TaskPriority.values[next];
                }),
              ),
              ChoiceChip(
                avatar: Icon(
                  _reminder
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                  size: 16,
                  color: _reminder
                      ? context.colors.accent
                      : context.colors.textSecondary,
                ),
                label: const Text('Reminder'),
                selected: _reminder,
                onSelected: (v) => setState(() => _reminder = v),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              TextButton.icon(
                onPressed: _openFullEditor,
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('More options'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: const Text('Add task'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
