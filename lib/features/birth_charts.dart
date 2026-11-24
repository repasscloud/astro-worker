import 'package:flutter/material.dart';

import '../domain/astronomy.dart';
import '../domain/astrology.dart';
import '../domain/birth_chart.dart';
import '../domain/civil_time.dart';
import '../domain/zodiac.dart';
import '../infrastructure/preferences.dart';
import '../shared/zodiac_wheel.dart';
import 'observatory.dart' show formatMoment, titleCase;

class BirthCharts extends StatefulWidget {
  const BirthCharts({
    super.key,
    required this.engine,
    required this.zodiac,
    required this.profiles,
    required this.clock,
    required this.defaultZone,
    required this.onSave,
    this.defaultBirth,
  });

  final AstronomyEngine engine;
  final Zodiac zodiac;
  final List<BirthProfile> profiles;
  final DateTime Function() clock;
  final String defaultZone;
  final DateTime? defaultBirth;
  final Future<bool> Function(List<BirthProfile>) onSave;

  @override
  State<BirthCharts> createState() => _BirthChartsState();
}

class _BirthChartsState extends State<BirthCharts> {
  String? _active;
  HouseSystem _houses = HouseSystem.wholeSign;
  (AstronomyEngine, BirthProfile, Zodiac)? _calculatedFor;
  NatalChart? _chart;

  Future<void> _edit([BirthProfile? existing]) async {
    final seed = widget.clock().microsecondsSinceEpoch;
    var suffix = 0;
    while (widget.profiles.any((item) => item.id == '$seed-$suffix')) {
      suffix++;
    }
    final profile = await showDialog<BirthProfile>(
      context: context,
      builder: (context) => _BirthProfileEditor(
        existing: existing,
        defaultBirth: widget.defaultBirth,
        defaultZone: widget.defaultZone,
        now: widget.clock().toLocal(),
        id: existing?.id ?? '$seed-$suffix',
      ),
    );
    if (profile == null || !mounted) return;
    final profiles = [
      for (final item in widget.profiles)
        if (item.id == profile.id) profile else item,
      if (existing == null) profile,
    ];
    if (await widget.onSave(profiles) && mounted) {
      setState(() => _active = profile.id);
    }
  }

  Future<void> _delete(BirthProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete birth profile?'),
        content: Text('${profile.name} will be removed from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (await widget.onSave(
          widget.profiles.where((item) => item.id != profile.id).toList(),
        ) &&
        mounted) {
      setState(() => _active = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile =
        widget.profiles.where((item) => item.id == _active).firstOrNull ??
        widget.profiles.firstOrNull;
    if (profile != null) {
      final request = (widget.engine, profile, widget.zodiac);
      if (_calculatedFor != request) {
        _chart = calculateNatalChart(widget.engine, profile, widget.zodiac);
        _calculatedFor = request;
      }
    }
    final chart = _chart;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        const Text(
          'Traditional astrology · Birth profiles are stored on this device.',
        ),
        if (profile != null)
          DropdownButtonFormField<String>(
            key: ValueKey(profile.id),
            initialValue: profile.id,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Birth profile'),
            items: [
              for (final item in widget.profiles)
                DropdownMenuItem(
                  value: item.id,
                  child: Text(item.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (id) => setState(() => _active = id),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (widget.profiles.length < 24)
              OutlinedButton.icon(
                onPressed: () => _edit(),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Add birth profile'),
              ),
            if (profile != null) ...[
              TextButton(
                onPressed: () => _edit(profile),
                child: const Text('Edit profile'),
              ),
              TextButton(
                onPressed: () => _delete(profile),
                child: const Text('Delete profile'),
              ),
            ],
          ],
        ),
        if (profile != null && chart == null)
          const Text(
            'Chart calculations require a birth date within 2000–2050 UTC.',
          ),
        if (profile != null && chart != null) ...[
          Text(widget.zodiac.label),
          if (chart.instant case final instant?)
            Text(formatMoment(context, inDisplayZone(instant, profile.zone)))
          else
            const Text(
              'Birth time unknown. The list shows signs that agree across the sampled birth date. Degrees, angles, and houses require a birth time.',
            ),
          if (chart.sky case final sky?)
            ZodiacWheel(
              sky: sky,
              offset: widget.zodiac.offset(chart.instant!),
              aspects: activeAspects(sky, 4),
            ),
          for (final entry in chart.signs.entries)
            Text(
              '${titleCase(entry.key.name)} · ${entry.value ?? 'Varies during the day'}',
            ),
          if (chart.ascendant case final ascent?) ...[
            Semantics(
              header: true,
              child: Text(
                'Ascendant · ${zodiacSigns[(ascent / 30).floor()]} ${(ascent % 30).toStringAsFixed(2)}°',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            DropdownButtonFormField<HouseSystem>(
              initialValue: _houses,
              decoration: const InputDecoration(labelText: 'House system'),
              items: [
                for (final system in HouseSystem.values)
                  DropdownMenuItem(value: system, child: Text(system.label)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _houses = value);
              },
            ),
            for (final (index, cusp) in houseCusps(ascent, _houses).indexed)
              Text(
                'House ${index + 1} · ${zodiacSigns[(cusp / 30).floor()]} ${(cusp % 30).toStringAsFixed(2)}°',
              ),
          ] else if (chart.instant != null)
            const Text(
              'Rising sign and houses require a usable birth location.',
            ),
        ],
      ],
    );
  }
}

class _BirthProfileEditor extends StatefulWidget {
  const _BirthProfileEditor({
    required this.existing,
    required this.defaultBirth,
    required this.defaultZone,
    required this.now,
    required this.id,
  });

  final BirthProfile? existing;
  final DateTime? defaultBirth;
  final String defaultZone;
  final DateTime now;
  final String id;

  @override
  State<_BirthProfileEditor> createState() => _BirthProfileEditorState();
}

class _BirthProfileEditorState extends State<_BirthProfileEditor> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _zone = TextEditingController(
    text: widget.existing?.zone ?? widget.defaultZone,
  );
  late final _latitude = TextEditingController(
    text: widget.existing?.location?.latitude.toString(),
  );
  late final _longitude = TextEditingController(
    text: widget.existing?.location?.longitude.toString(),
  );
  late DateTime? _day = widget.existing?.day ?? widget.defaultBirth;
  late int? _minutes = widget.existing?.minutes;
  String? _error;

  Future<void> _pickDate() async {
    final today = widget.now;
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1800),
      lastDate: today,
      initialDate: _day ?? DateTime(today.year - 18, today.month, today.day),
    );
    if (picked != null && mounted) {
      setState(
        () => _day = DateTime.utc(picked.year, picked.month, picked.day),
      );
    }
  }

  Future<void> _pickTime() async {
    final minutes = _minutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: minutes == null
          ? const TimeOfDay(hour: 12, minute: 0)
          : TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked != null && mounted) {
      setState(() => _minutes = picked.hour * 60 + picked.minute);
    }
  }

  void _save() {
    final day = _day;
    final name = _name.text.trim();
    final zone = _zone.text.trim();
    final lat = _latitude.text.trim(), lon = _longitude.text.trim();
    if (day == null || name.isEmpty || !BirthProfile.validZone(zone)) {
      setState(
        () => _error =
            'Enter a name, birth date, and a valid IANA timezone or UTC.',
      );
      return;
    }
    final location = lat.isEmpty && lon.isEmpty
        ? null
        : Preferences.parseObserver('$lat,$lon');
    if (location == null && (lat.isNotEmpty || lon.isNotEmpty)) {
      setState(
        () => _error = 'Enter both coordinates within their valid ranges, or leave both blank.',
      );
      return;
    }
    final profile = BirthProfile(
      id: widget.id,
      name: name,
      day: day,
      zone: zone,
      minutes: _minutes,
      location: location,
    );
    if (_minutes != null && profile.instant == null) {
      setState(
        () => _error =
            'This local time was skipped. Check the time and timezone.',
      );
      return;
    }
    Navigator.pop(context, profile);
  }

  @override
  void dispose() {
    _name.dispose();
    _zone.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final date = _day;
    final minutes = _minutes;
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Add birth profile' : 'Edit birth profile',
      ),
      scrollable: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            maxLength: 60,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextButton(
            onPressed: _pickDate,
            child: Text(
              date == null
                  ? 'Choose birth date'
                  : MaterialLocalizations.of(context).formatMediumDate(date),
            ),
          ),
          TextButton(
            onPressed: _pickTime,
            child: Text(
              minutes == null
                  ? 'Birth time unknown · add time'
                  : TimeOfDay(
                      hour: minutes ~/ 60,
                      minute: minutes % 60,
                    ).format(context),
            ),
          ),
          if (minutes != null)
            TextButton(
              onPressed: () => setState(() => _minutes = null),
              child: const Text('Remove birth time'),
            ),
          TextField(
            controller: _zone,
            decoration: const InputDecoration(
              labelText: 'Birth timezone',
              hintText: 'Australia/Adelaide',
            ),
          ),
          TextField(
            controller: _latitude,
            decoration: const InputDecoration(
              labelText: 'Birth latitude · optional',
            ),
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
          ),
          TextField(
            controller: _longitude,
            decoration: const InputDecoration(
              labelText: 'Birth longitude · optional',
            ),
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
          ),
          if (_error case final error?)
            Semantics(liveRegion: true, child: Text(error)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
