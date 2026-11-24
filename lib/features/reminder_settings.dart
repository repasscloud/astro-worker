import 'package:flutter/material.dart';

import '../domain/astronomy.dart';
import '../domain/reminders.dart';

class ReminderSettingsDialog extends StatefulWidget {
  const ReminderSettingsDialog({super.key, required this.initial});

  final ReminderSettings initial;

  @override
  State<ReminderSettingsDialog> createState() => _ReminderSettingsDialogState();
}

class _ReminderSettingsDialogState extends State<ReminderSettingsDialog> {
  late bool _enabled = widget.initial.enabled;
  late final Set<EventCategory> _categories = widget.initial.categories.toSet();
  late int _lead = widget.initial.leadMinutes;
  late bool _quiet = widget.initial.quietFrom != null;
  late int _from = widget.initial.quietFrom ?? 22 * 60;
  late int _until = widget.initial.quietUntil ?? 8 * 60;

  TimeOfDay _time(int minutes) =>
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

  Future<void> _pickTime(bool starts) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time(starts ? _from : _until),
    );
    if (picked == null || !mounted) return;
    final minutes = picked.hour * 60 + picked.minute;
    setState(() {
      if (starts) {
        _from = minutes;
      } else {
        _until = minutes;
      }
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Astronomy reminders'),
    scrollable: true,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Enable local reminders'),
          value: _enabled,
          onChanged: (value) => setState(() => _enabled = value),
        ),
        if (_enabled) ...[
          Wrap(
            spacing: 8,
            children: [
              for (final category in EventCategory.values)
                FilterChip(
                  label: Text(switch (category) {
                    EventCategory.moonPhase => 'Moon phases',
                    EventCategory.apsis => 'Lunar apsides',
                    EventCategory.season => 'Seasons',
                    EventCategory.eclipse => 'Eclipses',
                  }),
                  selected: _categories.contains(category),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _categories.add(category);
                    } else {
                      _categories.remove(category);
                    }
                  }),
                ),
            ],
          ),
          DropdownButtonFormField<int>(
            initialValue: _lead,
            decoration: const InputDecoration(labelText: 'Notify'),
            items: [
              for (final lead in ReminderSettings.leadOptions)
                DropdownMenuItem(
                  value: lead,
                  child: Text(
                    lead == 0 ? 'At the event' : '$lead minutes before',
                  ),
                ),
            ],
            onChanged: (lead) {
              if (lead != null) setState(() => _lead = lead);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Quiet hours'),
            value: _quiet,
            onChanged: (value) => setState(() => _quiet = value),
          ),
          if (_quiet) ...[
            TextButton(
              onPressed: () => _pickTime(true),
              child: Text('Starts · ${_time(_from).format(context)}'),
            ),
            TextButton(
              onPressed: () => _pickTime(false),
              child: Text('Ends · ${_time(_until).format(context)}'),
            ),
            const Text(
              'Reminders during quiet hours are skipped in your display timezone.',
            ),
            if (_from == _until)
              const Text('Choose different start and end times.'),
          ],
        ],
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed:
            _enabled && (_categories.isEmpty || (_quiet && _from == _until))
            ? null
            : () => Navigator.pop(
                context,
                ReminderSettings(
                  enabled: _enabled,
                  categories: _categories.isEmpty
                      ? const {EventCategory.moonPhase}
                      : _categories,
                  leadMinutes: _lead,
                  quietFrom: _quiet ? _from : null,
                  quietUntil: _quiet ? _until : null,
                ),
              ),
        child: const Text('Save'),
      ),
    ],
  );
}
