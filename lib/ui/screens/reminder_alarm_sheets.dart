import 'package:flutter/material.dart';

import '../../core/app_tokens.dart';
import '../../core/app_colors.dart';
import '../../core/formats.dart';
import '../../domain/models/reminders.dart';

/// Picker for one reminder time. Returns null when dismissed.
Future<ReminderEntry?> showReminderPicker(BuildContext context) {
  return showModalBottomSheet<ReminderEntry>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              'Remind me',
              style: TextStyle(
                fontSize: AppTypography.callout,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final (label, minutes) in [
            ('At deadline', 0),
            ('5 minutes before', 5),
            ('15 minutes before', 15),
            ('30 minutes before', 30),
            ('1 hour before', 60),
            ('3 hours before', 180),
            ('1 day before', 1440),
          ])
            ListTile(
              leading: const Icon(Icons.notifications_none),
              title: Text(label),
              onTap: () =>
                  Navigator.pop(context, ReminderEntry.before(minutes)),
            ),
          ListTile(
            leading: const Icon(Icons.edit_calendar_outlined),
            title: const Text('Custom date and time…'),
            onTap: () async {
              final now = DateTime.now();
              final date = await showDatePicker(
                context: context,
                initialDate: now,
                firstDate: now,
                lastDate: now.add(const Duration(days: 365 * 5)),
              );
              if (date == null || !context.mounted) return;
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time == null || !context.mounted) return;
              Navigator.pop(
                context,
                ReminderEntry.custom(
                  DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

/// Full persistent-alarm configuration. Returns the new config, or null when
/// dismissed without changes.
Future<AlarmConfig?> showAlarmSheet(
  BuildContext context, {
  required AlarmConfig current,
  required int defaultCadenceMinutes,
}) {
  return showModalBottomSheet<AlarmConfig>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) =>
        _AlarmSheet(current: current, defaultCadence: defaultCadenceMinutes),
  );
}

class _AlarmSheet extends StatefulWidget {
  final AlarmConfig current;
  final int defaultCadence;

  const _AlarmSheet({required this.current, required this.defaultCadence});

  @override
  State<_AlarmSheet> createState() => _AlarmSheetState();
}

class _AlarmSheetState extends State<_AlarmSheet> {
  late AlarmConfig _config;

  static const _cadences = [
    ('Every 15 minutes', 15),
    ('Every 30 minutes', 30),
    ('Every hour', 60),
    ('Every 3 hours', 180),
  ];

  @override
  void initState() {
    super.initState();
    _config = widget.current.enabled
        ? widget.current
        : widget.current.copyWith(
            enabled: true,
            cadenceMinutes: widget.defaultCadence,
          );
  }

  Future<int?> _pickMinutesOfDay(int? initial) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial != null
          ? TimeOfDay(hour: initial ~/ 60, minute: initial % 60)
          : TimeOfDay.now(),
    );
    return picked == null ? null : picked.hour * 60 + picked.minute;
  }

  @override
  Widget build(BuildContext context) {
    final isPresetCadence = _cadences.any(
      (c) => c.$2 == _config.cadenceMinutes,
    );
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Text(
              'Persistent alarm',
              style: TextStyle(
                fontSize: AppTypography.callout,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(
              'Keeps reminding you on a schedule until the task is handled. '
              'You can stop it any time by completing, snoozing or editing '
              'the task.',
              style: TextStyle(
                fontSize: AppTypography.footnote,
                color: context.colors.textSecondary,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              'Remind me',
              style: TextStyle(
                fontSize: AppTypography.footnote,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
          ),
          RadioGroup<int>(
            groupValue: isPresetCadence ? _config.cadenceMinutes : -1,
            onChanged: (v) async {
              if (v == null) return;
              if (v == -1) {
                final custom = await _pickCustomCadence();
                if (custom != null) {
                  setState(
                    () => _config = _config.copyWith(cadenceMinutes: custom),
                  );
                }
              } else {
                setState(() => _config = _config.copyWith(cadenceMinutes: v));
              }
            },
            child: Column(
              children: [
                for (final (label, minutes) in _cadences)
                  RadioListTile<int>(value: minutes, title: Text(label)),
                RadioListTile<int>(
                  value: -1,
                  title: Text(
                    isPresetCadence
                        ? 'Custom…'
                        : 'Custom: ${_config.describeCadence()}',
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.play_arrow_outlined),
            title: const Text('Start time'),
            subtitle: Text(
              _config.startMinutesOfDay != null
                  ? 'From ${Formats.time(_config.startMinutesOfDay!)} each day'
                  : 'At the deadline',
              style: TextStyle(
                fontSize: AppTypography.footnote,
                color: context.colors.textMuted,
              ),
            ),
            trailing: _config.startMinutesOfDay != null
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Reset start time',
                    onPressed: () => setState(
                      () => _config = _config.copyWith(clearStart: true),
                    ),
                  )
                : null,
            onTap: () async {
              final minutes = await _pickMinutesOfDay(
                _config.startMinutesOfDay,
              );
              if (minutes != null) {
                setState(
                  () => _config = _config.copyWith(startMinutesOfDay: minutes),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.stop_outlined),
            title: const Text('Stop time'),
            subtitle: Text(
              _config.stopMinutesOfDay != null
                  ? 'Until ${Formats.time(_config.stopMinutesOfDay!)} each day'
                  : 'No stop time',
              style: TextStyle(
                fontSize: AppTypography.footnote,
                color: context.colors.textMuted,
              ),
            ),
            trailing: _config.stopMinutesOfDay != null
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Remove stop time',
                    onPressed: () => setState(
                      () => _config = _config.copyWith(clearStop: true),
                    ),
                  )
                : null,
            onTap: () async {
              final minutes = await _pickMinutesOfDay(_config.stopMinutesOfDay);
              if (minutes != null) {
                setState(
                  () => _config = _config.copyWith(stopMinutesOfDay: minutes),
                );
              }
            },
          ),
          SwitchListTile.adaptive(
            secondary: const Icon(Icons.bedtime_outlined),
            title: const Text('Ignore quiet hours'),
            subtitle: Text(
              'Keep alarming during quiet hours',
              style: TextStyle(
                fontSize: AppTypography.footnote,
                color: context.colors.textMuted,
              ),
            ),
            value: _config.allowInQuietHours,
            onChanged: (v) => setState(
              () => _config = _config.copyWith(allowInQuietHours: v),
            ),
          ),
          SwitchListTile.adaptive(
            secondary: const Icon(Icons.volume_up_outlined),
            title: const Text('Sound'),
            value: _config.soundEnabled,
            onChanged: (v) =>
                setState(() => _config = _config.copyWith(soundEnabled: v)),
          ),
          SwitchListTile.adaptive(
            secondary: const Icon(Icons.vibration),
            title: const Text('Vibration'),
            value: _config.vibrationEnabled,
            onChanged: (v) =>
                setState(() => _config = _config.copyWith(vibrationEnabled: v)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FilledButton(
              onPressed: () =>
                  Navigator.pop(context, _config.copyWith(enabled: true)),
              child: const Text('Enable alarm'),
            ),
          ),
          if (widget.current.enabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextButton(
                onPressed: () => Navigator.pop(
                  context,
                  widget.current.copyWith(enabled: false),
                ),
                child: Text(
                  'Turn off alarm',
                  style: TextStyle(color: context.colors.overdue),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<int?> _pickCustomCadence() async {
    final controller = TextEditingController(text: '${_config.cadenceMinutes}');
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom cadence'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Minutes between reminders',
            helperText: '5 to 1440 minutes',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null) {
                Navigator.pop(context, value.clamp(5, 1440));
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}
