import 'package:flutter/material.dart';

import '../../core/app_tokens.dart';
import '../../core/app_colors.dart';
import '../../domain/models/date_only.dart';
import '../../domain/models/recurrence.dart';

/// Recurrence picker: presets first, custom rule builder behind "Custom".
/// Returns the chosen rule; `RecurrenceResult.none` clears recurrence.
class RecurrenceResult {
  final RecurrenceRule? rule;
  const RecurrenceResult(this.rule);
  static const none = RecurrenceResult(null);
}

Future<RecurrenceResult?> showRecurrenceSheet(
  BuildContext context, {
  RecurrenceRule? current,
  required DateOnly anchorDate,
  RecurrenceBehavior defaultBehavior = RecurrenceBehavior.fixedSchedule,
}) {
  return showModalBottomSheet<RecurrenceResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _RecurrenceSheet(
      current: current,
      anchorDate: anchorDate,
      defaultBehavior: defaultBehavior,
    ),
  );
}

class _RecurrenceSheet extends StatefulWidget {
  final RecurrenceRule? current;
  final DateOnly anchorDate;
  final RecurrenceBehavior defaultBehavior;

  const _RecurrenceSheet({
    required this.current,
    required this.anchorDate,
    required this.defaultBehavior,
  });

  @override
  State<_RecurrenceSheet> createState() => _RecurrenceSheetState();
}

class _RecurrenceSheetState extends State<_RecurrenceSheet> {
  bool _custom = false;
  late RecurrenceRule _rule;

  @override
  void initState() {
    super.initState();
    _rule =
        widget.current ??
        RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          behavior: widget.defaultBehavior,
        );
    _custom = widget.current != null && !_isPreset(widget.current!);
  }

  bool _isPreset(RecurrenceRule rule) {
    if (rule.interval != 1 ||
        rule.endDate != null ||
        rule.maxOccurrences != null ||
        rule.behavior != RecurrenceBehavior.fixedSchedule) {
      return false;
    }
    return switch (rule.frequency) {
      RecurrenceFrequency.daily => true,
      RecurrenceFrequency.weekly =>
        rule.weekdays.isEmpty || _isWeekdaySet(rule.weekdays),
      RecurrenceFrequency.monthly => rule.monthlyMode == MonthlyMode.dayOfMonth,
      RecurrenceFrequency.yearly => true,
    };
  }

  bool _isWeekdaySet(Set<int> days) =>
      days.length == 5 &&
      !days.contains(DateTime.saturday) &&
      !days.contains(DateTime.sunday);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: _custom ? 0.85 : 0.6,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 4, 4, 12),
            child: Text(
              'Repeat',
              style: TextStyle(
                fontSize: AppTypography.callout,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!_custom) ...[
            _preset('Does not repeat', null),
            _preset('Every day', RecurrenceRule.daily()),
            _preset('Every weekday', RecurrenceRule.everyWeekday()),
            _preset('Every week', RecurrenceRule.weekly()),
            _preset(
              'Every month',
              RecurrenceRule.monthly(dayOfMonth: widget.anchorDate.day),
            ),
            _preset('Every year', RecurrenceRule.yearly()),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Custom…'),
              onTap: () => setState(() => _custom = true),
            ),
          ] else
            ..._customBuilder(),
        ],
      ),
    );
  }

  Widget _preset(String label, RecurrenceRule? rule) {
    final selected = rule == null
        ? widget.current == null
        : widget.current != null &&
              _isPreset(widget.current!) &&
              widget.current!.frequency == rule.frequency &&
              _isWeekdaySet(widget.current!.weekdays) ==
                  _isWeekdaySet(rule.weekdays) &&
              widget.current!.weekdays.isEmpty == rule.weekdays.isEmpty;
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? context.colors.accent : context.colors.textMuted,
      ),
      title: Text(label),
      onTap: () => Navigator.pop(context, RecurrenceResult(rule)),
    );
  }

  List<Widget> _customBuilder() {
    const dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final monthDay = _rule.dayOfMonth ?? widget.anchorDate.day;
    return [
      Row(
        children: [
          const Text('Every', style: TextStyle(fontSize: AppTypography.body)),
          const SizedBox(width: 12),
          _stepper(
            value: _rule.interval,
            onChanged: (v) =>
                setState(() => _rule = _rule.copyWith(interval: v)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<RecurrenceFrequency>(
              initialValue: _rule.frequency,
              items: [
                for (final f in RecurrenceFrequency.values)
                  DropdownMenuItem(
                    value: f,
                    child: Text(switch (f) {
                      RecurrenceFrequency.daily =>
                        _rule.interval == 1 ? 'day' : 'days',
                      RecurrenceFrequency.weekly =>
                        _rule.interval == 1 ? 'week' : 'weeks',
                      RecurrenceFrequency.monthly =>
                        _rule.interval == 1 ? 'month' : 'months',
                      RecurrenceFrequency.yearly =>
                        _rule.interval == 1 ? 'year' : 'years',
                    }),
                  ),
              ],
              onChanged: (f) {
                if (f != null) {
                  setState(() => _rule = _rule.copyWith(frequency: f));
                }
              },
            ),
          ),
        ],
      ),
      if (_rule.frequency == RecurrenceFrequency.weekly) ...[
        const SizedBox(height: 14),
        Text('On days', style: TextStyle(color: context.colors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: [
            for (var d = DateTime.monday; d <= DateTime.sunday; d++)
              FilterChip(
                label: Text(dayNames[d - 1]),
                selected: _rule.weekdays.contains(d),
                showCheckmark: false,
                onSelected: (v) {
                  final days = Set<int>.of(_rule.weekdays);
                  v ? days.add(d) : days.remove(d);
                  setState(() => _rule = _rule.copyWith(weekdays: days));
                },
              ),
          ],
        ),
      ],
      if (_rule.frequency == RecurrenceFrequency.monthly) ...[
        const SizedBox(height: 14),
        RadioGroup<MonthlyMode>(
          groupValue: _rule.monthlyMode,
          onChanged: (m) {
            if (m != null) {
              setState(() => _rule = _rule.copyWith(monthlyMode: m));
            }
          },
          child: Column(
            children: [
              RadioListTile<MonthlyMode>(
                value: MonthlyMode.dayOfMonth,
                title: Text('On day $monthDay'),
                subtitle: monthDay > 28
                    ? Text(
                        'Months without this day use their last day',
                        style: TextStyle(
                          fontSize: AppTypography.footnote,
                          color: context.colors.textMuted,
                        ),
                      )
                    : null,
              ),
              const RadioListTile<MonthlyMode>(
                value: MonthlyMode.lastDay,
                title: Text('On the last day of the month'),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 14),
      Text('Scheduling', style: TextStyle(color: context.colors.textSecondary)),
      RadioGroup<RecurrenceBehavior>(
        groupValue: _rule.behavior,
        onChanged: (b) {
          if (b != null) setState(() => _rule = _rule.copyWith(behavior: b));
        },
        child: Column(
          children: [
            RadioListTile<RecurrenceBehavior>(
              value: RecurrenceBehavior.fixedSchedule,
              title: Text('Fixed schedule'),
              subtitle: Text(
                'Stays on its calendar dates',
                style: TextStyle(
                  fontSize: AppTypography.footnote,
                  color: context.colors.textMuted,
                ),
              ),
            ),
            RadioListTile<RecurrenceBehavior>(
              value: RecurrenceBehavior.afterCompletion,
              title: Text('Repeat after completion'),
              subtitle: Text(
                'Next date counts from when you complete it',
                style: TextStyle(
                  fontSize: AppTypography.footnote,
                  color: context.colors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Text('Ends', style: TextStyle(color: context.colors.textSecondary)),
      RadioGroup<int>(
        groupValue: _rule.endDate != null
            ? 1
            : _rule.maxOccurrences != null
            ? 2
            : 0,
        onChanged: (v) async {
          if (v == 0) {
            setState(
              () => _rule = _rule.copyWith(
                clearEndDate: true,
                clearMaxOccurrences: true,
              ),
            );
          } else if (v == 1) {
            final picked = await showDatePicker(
              context: context,
              initialDate: (_rule.endDate ?? widget.anchorDate.addDays(30))
                  .toDateTime(),
              firstDate: widget.anchorDate.toDateTime(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
            );
            if (picked != null) {
              setState(
                () => _rule = _rule.copyWith(
                  endDate: DateOnly.fromDateTime(picked),
                  clearMaxOccurrences: true,
                ),
              );
            }
          } else if (v == 2) {
            setState(
              () => _rule = _rule.copyWith(
                maxOccurrences: _rule.maxOccurrences ?? 10,
                clearEndDate: true,
              ),
            );
          }
        },
        child: Column(
          children: [
            const RadioListTile<int>(value: 0, title: Text('Never')),
            RadioListTile<int>(
              value: 1,
              title: Text(
                _rule.endDate != null ? 'On ${_rule.endDate}' : 'On a date…',
              ),
            ),
            RadioListTile<int>(
              value: 2,
              title: Row(
                children: [
                  const Text('After'),
                  const SizedBox(width: 10),
                  if (_rule.maxOccurrences != null)
                    _stepper(
                      value: _rule.maxOccurrences!,
                      onChanged: (v) => setState(
                        () => _rule = _rule.copyWith(maxOccurrences: v),
                      ),
                    )
                  else
                    const Text('N'),
                  const SizedBox(width: 10),
                  const Text('times'),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: () {
          var rule = _rule;
          if (rule.frequency == RecurrenceFrequency.monthly &&
              rule.monthlyMode == MonthlyMode.dayOfMonth) {
            rule = rule.copyWith(dayOfMonth: monthDay);
          }
          if (rule.frequency == RecurrenceFrequency.weekly &&
              rule.weekdays.isEmpty) {
            rule = rule.copyWith(weekdays: {widget.anchorDate.weekday});
          }
          Navigator.pop(context, RecurrenceResult(rule));
        },
        child: const Text('Set recurrence'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, RecurrenceResult.none),
        child: const Text('Remove recurrence'),
      ),
    ];
  }

  Widget _stepper({required int value, required ValueChanged<int> onChanged}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.borderStrong),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove, size: 18),
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value < 365 ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add, size: 18),
          ),
        ],
      ),
    );
  }
}
