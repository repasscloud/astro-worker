import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../domain/astronomy.dart';
import '../domain/civil_time.dart';
import '../domain/numerology.dart';
import '../features/observatory.dart';
import '../infrastructure/content.dart';
import '../infrastructure/preferences.dart';
import 'branding.dart';
import 'destination.dart';

class AstroApp extends StatefulWidget {
  const AstroApp({
    super.key,
    required this.engine,
    required this.preferences,
    required this.content,
    required this.clock,
  });
  final AstronomyEngine engine;
  final Preferences preferences;
  final EditorialContent content;
  final DateTime Function() clock;

  @override
  State<AstroApp> createState() => _AstroAppState();
}

class _AstroAppState extends State<AstroApp> {
  final _scaffold = GlobalKey<ScaffoldState>();
  Destination _destination = Destination.today;
  DateTime? _selected;
  DateTime? _computed;
  SkySnapshot? _sky;
  late final Timer _timer;
  late ThemeMode _themeMode;
  late String _zone;
  late bool _spiritual;
  late bool _masters;
  late bool _south;
  late double _orb;
  DateTime? _birth;

  Preferences get _preferences => widget.preferences;

  @override
  void initState() {
    super.initState();
    _themeMode =
        ThemeMode.values.asNameMap()[_preferences.text('theme')] ??
        ThemeMode.system;
    final zone = _preferences.text('zone');
    _zone =
        zone == 'device' ||
            zone == 'UTC' ||
            tz.timeZoneDatabase.locations.containsKey(zone)
        ? zone!
        : 'device';
    _spiritual = _preferences.flag('spiritual') ?? true;
    _masters = _preferences.flag('masters') ?? true;
    _south = _preferences.flag('south') ?? false;
    _orb = (_preferences.decimal('orb') ?? 4).clamp(1, 10);
    _birth = DateTime.tryParse(_preferences.text('birth') ?? '');
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_selected == null) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  ThemeData _theme(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xff69558e),
      brightness: brightness,
      tertiary: brightness == Brightness.dark
          ? const Color(0xffebc986)
          : const Color(0xff76541e),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final instant = (_selected ?? widget.clock()).toUtc();
    final epochMinute = instant.millisecondsSinceEpoch ~/ 60000;
    final minute = DateTime.fromMillisecondsSinceEpoch(
      epochMinute * 60000,
      isUtc: true,
    );
    if (_computed != minute) {
      _computed = minute;
      _sky =
          minute.isBefore(widget.engine.start) ||
              !minute.isBefore(widget.engine.end)
          ? null
          : widget.engine.skyAt(minute);
    }
    final day = inDisplayZone(instant, _zone);
    final numerology = Numerology(keepMasterNumbers: _masters);
    final daily = widget.content.forDay(numerology.universalDay(day), day);
    return MaterialApp(
      title: Branding.name,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: _themeMode,
      home: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 870;
          final navigation = _navigation();
          return Scaffold(
            key: _scaffold,
            appBar: AppBar(
              title: const Text(Branding.name),
              leading: wide
                  ? null
                  : IconButton(
                      tooltip: 'Open navigation',
                      onPressed: () => _scaffold.currentState?.openDrawer(),
                      icon: const Icon(Icons.menu),
                    ),
            ),
            drawer: wide ? null : Drawer(child: SafeArea(child: navigation)),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide) ...[
                  SizedBox(
                    width: 210,
                    child: ColoredBox(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      child: navigation,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                ],
                Expanded(
                  child: ListView(
                    key: PageStorageKey(_destination),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      Text(
                        _destination.label,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 12),
                      if (_destination != Destination.settings) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.schedule),
                              onPressed: () => _pickInstant(context, day),
                              label: Text(formatMoment(context, day)),
                            ),
                            TextButton(
                              onPressed: _selected == null
                                  ? null
                                  : () => setState(() => _selected = null),
                              child: const Text('Return to now'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_destination == Destination.settings)
                        ..._settings(context)
                      else
                        Observatory(
                          destination: _destination,
                          instant: instant,
                          day: day,
                          zone: _zone,
                          engine: widget.engine,
                          sky: _sky,
                          numerology: numerology,
                          daily: daily,
                          birth: _birth,
                          showSpiritual: _spiritual,
                          south: _south,
                          orb: _orb,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _navigation() => ListView(
    padding: const EdgeInsets.all(8),
    children: [
      const ListTile(title: Text(Branding.publisher)),
      for (final destination in Destination.values)
        ListTile(
          selected: destination == _destination,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: Icon(destination.icon),
          title: Text(destination.label),
          onTap: () {
            _scaffold.currentState?.closeDrawer();
            setState(() => _destination = destination);
          },
        ),
    ],
  );

  Future<void> _pickInstant(BuildContext context, DateTime current) async {
    final first = inDisplayZone(widget.engine.start, _zone);
    final last = inDisplayZone(
      widget.engine.end.subtract(const Duration(milliseconds: 1)),
      _zone,
    );
    final initial = current.isBefore(first)
        ? first
        : current.isAfter(last)
        ? last
        : current;
    final day = await showDatePicker(
      context: context,
      firstDate: first,
      lastDate: last,
      initialDate: initial,
    );
    if (day == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !context.mounted) return;
    final wall = DateTime.utc(
      day.year,
      day.month,
      day.day,
      time.hour,
      time.minute,
    );
    final resolved = resolveWallTime(wall, _zone);
    if (resolved == null ||
        resolved.isBefore(widget.engine.start) ||
        !resolved.isBefore(widget.engine.end)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'That wall time is skipped or outside the supported UTC range.',
          ),
        ),
      );
      return;
    }
    setState(() => _selected = resolved);
  }

  Future<void> _save(BuildContext context, Future<bool> operation) async {
    var saved = false;
    try {
      saved = await operation;
    } on Exception {
      // The in-memory setting remains usable if storage is unavailable.
    }
    if (!saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This change could not be saved locally.'),
        ),
      );
    }
  }

  List<Widget> _settings(BuildContext context) => [
    DropdownButtonFormField<ThemeMode>(
      initialValue: _themeMode,
      decoration: const InputDecoration(labelText: 'Theme'),
      items: [
        for (final theme in ThemeMode.values)
          DropdownMenuItem(value: theme, child: Text(titleCase(theme.name))),
      ],
      onChanged: (theme) {
        if (theme == null) return;
        setState(() => _themeMode = theme);
        unawaited(_save(context, _preferences.writeText('theme', theme.name)));
      },
    ),
    ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Display timezone'),
      subtitle: Text(_zone == 'device' ? 'Device local time' : _zone),
      trailing: const Icon(Icons.edit_outlined),
      onTap: () => _editZone(context),
    ),
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Show spiritual content'),
      value: _spiritual,
      onChanged: (value) {
        setState(() => _spiritual = value);
        unawaited(_save(context, _preferences.writeFlag('spiritual', value)));
      },
    ),
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Keep master numbers 11, 22 and 33'),
      value: _masters,
      onChanged: (value) {
        setState(() => _masters = value);
        unawaited(_save(context, _preferences.writeFlag('masters', value)));
      },
    ),
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Southern Hemisphere Moon schematic'),
      value: _south,
      onChanged: (value) {
        setState(() => _south = value);
        unawaited(_save(context, _preferences.writeFlag('south', value)));
      },
    ),
    Text('Major aspect orb · ${_orb.round()}°'),
    Slider(
      value: _orb,
      min: 1,
      max: 10,
      divisions: 9,
      label: '${_orb.round()}°',
      onChanged: (value) => setState(() => _orb = value),
      onChangeEnd: (value) =>
          unawaited(_save(context, _preferences.writeDecimal('orb', value))),
    ),
    ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Optional birth date'),
      subtitle: Text(
        _birth == null
            ? 'Used for personal numerology'
            : MaterialLocalizations.of(context).formatMediumDate(_birth!),
      ),
      onTap: () async {
        final now = widget.clock();
        final date = await showDatePicker(
          context: context,
          firstDate: DateTime(1800),
          lastDate: now,
          initialDate: _birth ?? DateTime(now.year - 18),
        );
        if (date == null || !context.mounted) return;
        final civilDate = DateTime.utc(date.year, date.month, date.day);
        setState(() => _birth = civilDate);
        await _save(
          context,
          _preferences.writeText('birth', civilDate.toIso8601String()),
        );
      },
      trailing: _birth == null
          ? const Icon(Icons.edit_outlined)
          : IconButton(
              tooltip: 'Clear birth date',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (await _preferences.remove('birth') && mounted) {
                  setState(() => _birth = null);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'The saved birth date could not be cleared.',
                      ),
                    ),
                  );
                }
              },
            ),
    ),
    ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('About and licences'),
      subtitle: const Text('Meeus / VSOP87 · 2000–2050 UTC · Tropical zodiac'),
      onTap: () => showLicensePage(
        context: context,
        applicationName: Branding.name,
        applicationVersion: '0.1.0',
      ),
    ),
  ];

  Future<void> _editZone(BuildContext context) async {
    var input = _zone;
    final proposed = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Display timezone'),
        content: TextFormField(
          initialValue: _zone,
          decoration: const InputDecoration(
            helperText: 'device, UTC or an IANA identifier',
            hintText: 'Australia/Adelaide',
          ),
          onChanged: (value) => input = value.trim(),
          onFieldSubmitted: (_) => Navigator.pop(context, input),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, input),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (proposed == null || !context.mounted) return;
    if (proposed != 'device' &&
        proposed != 'UTC' &&
        !tz.timeZoneDatabase.locations.containsKey(proposed)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unknown timezone identifier.')),
      );
      return;
    }
    setState(() => _zone = proposed);
    await _save(context, _preferences.writeText('zone', proposed));
  }
}
