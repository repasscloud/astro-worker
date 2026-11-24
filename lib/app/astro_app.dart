import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as tz;

import '../domain/astronomy.dart';
import '../domain/civil_time.dart';
import '../domain/numerology.dart';
import '../domain/reminders.dart';
import '../domain/zodiac.dart';
import '../domain/horizon.dart';
import '../features/observatory.dart';
import '../features/reminder_settings.dart';
import '../infrastructure/content.dart';
import '../infrastructure/preferences.dart';
import '../platform/native_moon_widget.dart';
import '../platform/native_reminders.dart';
import 'branding.dart';
import 'build_identity.dart';
import 'destination.dart';

class AstroApp extends StatefulWidget {
  const AstroApp({
    super.key,
    required this.engine,
    required this.preferences,
    required this.content,
    required this.clock,
    this.nativeMoonWidget,
    this.nativeReminders,
  });
  final AstronomyEngine engine;
  final Preferences preferences;
  final EditorialContent content;
  final DateTime Function() clock;
  final NativeMoonWidget? nativeMoonWidget;
  final NativeReminders? nativeReminders;

  @override
  State<AstroApp> createState() => _AstroAppState();
}

class _AstroAppState extends State<AstroApp> {
  final _scaffold = GlobalKey<ScaffoldState>();
  Destination _destination = Destination.today;
  MoonSection? _moonSection;
  int _widgetOpenCount = 0;
  DateTime? _selected;
  DateTime? _computed;
  SkySnapshot? _sky;
  late final Timer _timer;
  AppLifecycleListener? _lifecycle;
  late ThemeMode _themeMode;
  late String _zone;
  late bool _spiritual;
  late bool _masters;
  late bool _south;
  late Zodiac _zodiac;
  late double _orb;
  DateTime? _birth;
  Observer? _observer;

  Preferences get _preferences => widget.preferences;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    final publisher = widget.nativeMoonWidget;
    if (publisher != null) {
      publisher.onOpenMoon = (section) {
        if (!mounted) return;
        _scaffold.currentState?.closeDrawer();
        setState(() {
          _destination = Destination.moon;
          _moonSection = section;
          _widgetOpenCount++;
          _selected = null;
        });
      };
    }
    if (publisher != null || widget.nativeReminders != null) {
      _lifecycle = AppLifecycleListener(onResume: _refreshNative);
      _refreshNative();
    }
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_selected == null) setState(() {});
    });
  }

  void _loadPreferences() {
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
    _zodiac =
        Zodiac.values.asNameMap()[_preferences.text('zodiac')] ??
        Zodiac.tropical;
    _orb = (_preferences.decimal('orb') ?? 4).clamp(1, 10);
    _birth = Preferences.parseBirthDate(
      _preferences.text('birth'),
      widget.clock().toLocal(),
    );
    _observer = Preferences.parseObserver(_preferences.text('observer'));
  }

  @override
  void dispose() {
    _timer.cancel();
    _lifecycle?.dispose();
    widget.nativeMoonWidget?.onOpenMoon = null;
    super.dispose();
  }

  void _refreshNative() {
    _refreshMoonWidget();
    final reminders = widget.nativeReminders;
    if (reminders != null) {
      unawaited(
        reminders.refresh(
          widget.engine,
          widget.clock(),
          _reminderSettings,
          _zone,
        ),
      );
    }
  }

  ReminderSettings get _reminderSettings =>
      ReminderSettings.decode(_preferences.text('reminders')) ??
      const ReminderSettings();

  void _refreshMoonWidget() {
    final publisher = widget.nativeMoonWidget;
    if (publisher == null) return;
    unawaited(
      publisher.refresh(
        widget.engine,
        widget.clock(),
        _zone,
        _masters,
        south: _south,
        showSpiritual: _spiritual,
        zodiac: _zodiac,
      ),
    );
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
            body: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (wide) ...[
                    SizedBox(
                      width: 210,
                      child: ColoredBox(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerLow,
                        child: navigation,
                      ),
                    ),
                    const VerticalDivider(width: 1),
                  ],
                  Expanded(
                    child: ListView(
                      key: _moonSection == null
                          ? PageStorageKey(_destination)
                          : ValueKey(_widgetOpenCount),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            _destination.label,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
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
                            moonSection: _moonSection,
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
                            zodiac: _zodiac,
                            orb: _orb,
                            observer: _observer,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
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
            setState(() {
              _destination = destination;
              _moonSection = null;
            });
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
      key: ValueKey(_themeMode),
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
    ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Observer coordinates'),
      subtitle: Text(
        _observer == null
            ? 'Optional · used for Sun and Moon horizon events'
            : '${_observer!.latitude}°, ${_observer!.longitude}°',
      ),
      trailing: const Icon(Icons.edit_location_alt_outlined),
      onTap: () => _editObserver(context),
    ),
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Show spiritual content'),
      value: _spiritual,
      onChanged: (value) {
        setState(() => _spiritual = value);
        _refreshMoonWidget();
        unawaited(_save(context, _preferences.writeFlag('spiritual', value)));
      },
    ),
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Keep master numbers 11, 22 and 33'),
      value: _masters,
      onChanged: (value) {
        setState(() => _masters = value);
        _refreshMoonWidget();
        unawaited(_save(context, _preferences.writeFlag('masters', value)));
      },
    ),
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Southern Hemisphere Moon schematic'),
      value: _south,
      onChanged: (value) {
        setState(() => _south = value);
        _refreshMoonWidget();
        unawaited(_save(context, _preferences.writeFlag('south', value)));
      },
    ),
    DropdownButtonFormField<Zodiac>(
      key: ValueKey(_zodiac),
      initialValue: _zodiac,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Zodiac system'),
      items: [
        for (final zodiac in Zodiac.values)
          DropdownMenuItem(value: zodiac, child: Text(zodiac.label)),
      ],
      onChanged: (zodiac) {
        if (zodiac == null) return;
        setState(() => _zodiac = zodiac);
        _refreshMoonWidget();
        unawaited(
          _save(context, _preferences.writeText('zodiac', zodiac.name)),
        );
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
    if (widget.nativeReminders != null)
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.notifications_outlined),
        title: const Text('Astronomy reminders'),
        subtitle: Text(_reminderSettings.enabled ? 'On' : 'Off'),
        onTap: () => _editReminderSettings(context),
      ),
    ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.backup_outlined),
      title: const Text('Settings backup'),
      onTap: () => _exportSettings(context),
    ),
    ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.settings_backup_restore),
      title: const Text('Restore settings'),
      onTap: () => _restoreSettings(context),
    ),
    ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.delete_outline),
      title: const Text('Reset app settings'),
      onTap: () => _resetSettings(context),
    ),
    ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('About and licences'),
      subtitle: Text('Meeus / VSOP87 · 2000–2050 UTC · ${_zodiac.label}'),
      onTap: () => showAboutDialog(
        context: context,
        applicationName: Branding.name,
        applicationVersion: BuildIdentity.label,
        applicationLegalese: '© 2026 RePass Cloud · AGPL-3.0-only',
        children: const [
          SizedBox(height: 16),
          Text('Public repository'),
          SelectableText(BuildIdentity.repository),
          if (BuildIdentity.hasRevision) ...[
            SizedBox(height: 12),
            Text('Corresponding source'),
            SelectableText(BuildIdentity.source),
          ],
        ],
      ),
    ),
  ];

  Future<void> _editReminderSettings(BuildContext context) async {
    final scheduler = widget.nativeReminders!;
    final settings = await showDialog<ReminderSettings>(
      context: context,
      builder: (context) => ReminderSettingsDialog(initial: _reminderSettings),
    );
    if (settings == null || !context.mounted) return;
    if (settings.enabled && !await scheduler.requestPermission()) {
      if (context.mounted) {
        _settingsMessage(
          context,
          'Allow Astro Worker notifications in your system settings.',
        );
      }
      return;
    }
    if (!context.mounted) return;
    await _save(
      context,
      _preferences.writeText('reminders', settings.encode()),
    );
    if (!mounted) return;
    setState(() {});
    _refreshNative();
  }

  Future<void> _exportSettings(BuildContext context) async {
    var includePersonal = false;
    final backup = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Copy settings backup'),
          scrollable: true,
          content: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Include birth date and observer coordinates'),
            value: includePersonal,
            onChanged: (checked) =>
                setDialogState(() => includePersonal = checked ?? false),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                _preferences.exportBackup(includePersonal: includePersonal),
              ),
              child: const Text('Copy backup'),
            ),
          ],
        ),
      ),
    );
    if (backup == null || !context.mounted) return;
    try {
      await Clipboard.setData(ClipboardData(text: backup));
      if (context.mounted) _settingsMessage(context, 'Settings backup copied.');
    } on PlatformException {
      if (context.mounted) {
        _settingsMessage(context, 'Could not copy settings.');
      }
    }
  }

  Future<void> _restoreSettings(BuildContext context) async {
    var input = '';
    final backup = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore settings'),
        scrollable: true,
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Paste a settings backup',
          ),
          minLines: 3,
          maxLines: 7,
          maxLength: 8192,
          onChanged: (value) => input = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, input),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (backup == null || !context.mounted) return;
    try {
      final restored = await _preferences.restoreBackup(
        backup,
        now: widget.clock().toLocal(),
      );
      if (!context.mounted) return;
      if (restored) {
        setState(_loadPreferences);
        _refreshNative();
      }
      _settingsMessage(
        context,
        restored ? 'Settings restored.' : 'Could not save restored settings.',
      );
    } on FormatException {
      if (context.mounted) {
        _settingsMessage(context, 'This settings backup is invalid.');
      }
    } on Exception {
      if (context.mounted) {
        _settingsMessage(context, 'Could not save restored settings.');
      }
    }
  }

  Future<void> _resetSettings(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset app settings?'),
        content: const Text(
          'This clears preferences and removes the saved birth date and observer coordinates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final reset = await _preferences.reset();
      if (!context.mounted) return;
      if (reset) {
        setState(() {
          _loadPreferences();
          _selected = null;
        });
        _refreshNative();
      }
      _settingsMessage(
        context,
        reset ? 'App settings reset.' : 'Could not reset app settings.',
      );
    } on Exception {
      if (context.mounted) {
        _settingsMessage(context, 'Could not reset app settings.');
      }
    }
  }

  void _settingsMessage(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _editObserver(BuildContext context) async {
    var latitude = _observer?.latitude.toString() ?? '';
    var longitude = _observer?.longitude.toString() ?? '';
    final decision = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Observer coordinates'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: latitude,
                decoration: const InputDecoration(
                  labelText: 'Latitude in degrees north',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                onChanged: (value) => latitude = value.trim(),
              ),
              TextFormField(
                initialValue: longitude,
                decoration: const InputDecoration(
                  labelText: 'Longitude in degrees east',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                onChanged: (value) => longitude = value.trim(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (_observer != null)
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Clear'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (decision == null || !context.mounted) return;
    if (!decision) {
      final removed = await _preferences.remove('observer');
      if (!context.mounted) return;
      if (removed) {
        setState(() => _observer = null);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The saved coordinates could not be cleared.'),
          ),
        );
      }
      return;
    }
    try {
      final observer = Observer(
        latitude: double.parse(latitude),
        longitude: double.parse(longitude),
      );
      setState(() => _observer = observer);
      await _save(
        context,
        _preferences.writeText(
          'observer',
          '${observer.latitude},${observer.longitude}',
        ),
      );
    } on FormatException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Enter latitude from −90 to 90 and longitude from −180 to 180.',
            ),
          ),
        );
      }
    }
  }

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
    _refreshNative();
    await _save(context, _preferences.writeText('zone', proposed));
  }
}
