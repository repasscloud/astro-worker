import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../app/destination.dart';
import '../domain/astrology.dart';
import '../domain/astronomy.dart';
import '../domain/calendar_export.dart';
import '../domain/civil_time.dart';
import '../domain/numerology.dart';
import '../domain/planetary_events.dart';
import '../domain/horizon.dart';
import '../infrastructure/content.dart';
import '../infrastructure/lunar_editorial.dart';
import '../platform/widget_snapshot.dart';
import '../shared/moon_disc.dart';

String titleCase(String value) => value[0].toUpperCase() + value.substring(1);

String formatMoment(BuildContext context, DateTime value) {
  final localizations = MaterialLocalizations.of(context);
  final date = localizations.formatMediumDate(value);
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(value),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  return '$date · $time ${value.timeZoneName}';
}

class Observatory extends StatelessWidget {
  const Observatory({
    super.key,
    required this.destination,
    this.moonSection,
    required this.instant,
    required this.day,
    required this.zone,
    required this.engine,
    required this.sky,
    required this.numerology,
    required this.daily,
    required this.birth,
    required this.showSpiritual,
    required this.south,
    required this.orb,
    required this.observer,
  });

  final Destination destination;
  final MoonSection? moonSection;
  final DateTime instant;
  final DateTime day;
  final String zone;
  final AstronomyEngine engine;
  final SkySnapshot? sky;
  final Numerology numerology;
  final DailyContent daily;
  final DateTime? birth;
  final bool showSpiritual;
  final bool south;
  final double orb;
  final Observer? observer;

  @override
  Widget build(BuildContext context) {
    final snapshot = sky;
    final astronomy = snapshot == null
        ? const [Text('Astronomy is available from 2000 through 2050 UTC.')]
        : switch (destination) {
            Destination.today => _today(context, snapshot),
            Destination.moon => _moon(context, snapshot),
            Destination.planets => [
              const Text('Apparent geocentric positions · tropical zodiac'),
              for (final position in snapshot.positions.values)
                _positionCard(context, position),
              const Text(
                'Pluto, Chiron and lunar nodes are awaiting provider verification.',
              ),
            ],
            Destination.astrology => _astrology(snapshot),
            Destination.widgets => _widgets(snapshot),
            _ => <Widget>[],
          };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: switch (destination) {
        Destination.calendar => [
          CalendarPanel(engine: engine, day: day, zone: zone),
        ],
        Destination.numerology => _numbers(),
        Destination.spiritual =>
          showSpiritual
              ? [
                  _editorial(),
                  _Panel(title: 'Reflection', children: [Text(daily.prompt)]),
                ]
              : [
                  const Text(
                    'Spiritual content is disabled. Enable it in Settings.',
                  ),
                ],
        _ => astronomy,
      },
    );
  }

  List<Widget> _today(BuildContext context, SkySnapshot snapshot) {
    final moon = snapshot.positions[Body.moon]!;
    final sun = snapshot.positions[Body.sun]!;
    final retrogrades = snapshot.positions.values
        .where((position) => position.retrograde)
        .map((position) => titleCase(position.body.name));
    final aspects = activeAspects(snapshot, orb);
    final events = engine.events(
      instant,
      instant.add(const Duration(days: 31)),
    );
    return [
      _Panel(
        title: snapshot.phase,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: MoonDisc(
              illumination: snapshot.illumination,
              waxing: snapshot.waxing,
              south: south,
            ),
          ),
          Text(
            '${(snapshot.illumination * 100).toStringAsFixed(1)}% illuminated',
          ),
          Text(
            'Tropical zodiac · Moon in ${moon.sign()} · Sun in ${sun.sign()}',
          ),
        ],
      ),
      _Panel(
        title: 'Planetary motion and aspects',
        children: [
          Text(
            retrogrades.isEmpty
                ? 'No planets retrograde.'
                : 'Retrograde · ${retrogrades.join(', ')}',
          ),
          if (aspects.isEmpty)
            const Text('No major aspects within the selected orb.'),
          for (final aspect in aspects.take(3)) Text(_aspectText(aspect)),
        ],
      ),
      _horizon(context, lunar: false),
      _Panel(
        title: 'Upcoming events',
        children: [
          if (events.isEmpty)
            const Text(
              'No events in the next 31 days within the supported dates.',
            ),
          for (final event in events.take(4)) _eventTile(context, event, zone),
        ],
      ),
      _Panel(
        title: 'Universal day ${numerology.universalDay(day)}',
        children: [
          if (showSpiritual) Text('${daily.colour} · ${daily.theme}'),
          if (showSpiritual) Text(daily.affirmation),
          if (!showSpiritual) const Text('Traditional numerology'),
        ],
      ),
    ];
  }

  List<Widget> _moon(BuildContext context, SkySnapshot snapshot) {
    final moon = snapshot.positions[Body.moon]!;
    final editorial = lunarEditorial(snapshot.phase);
    final age = snapshot.lunarAgeDays;
    final nearby = engine
        .events(
          instant.subtract(const Duration(days: 31)),
          instant.add(const Duration(days: 31)),
        )
        .where((event) => event.category == EventCategory.moonPhase);
    final panels = <MoonSection, Widget>{
      MoonSection.phase: _Panel(
        title: snapshot.phase,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: MoonDisc(
              illumination: snapshot.illumination,
              waxing: snapshot.waxing,
              south: south,
            ),
          ),
          Text(
            '${(snapshot.illumination * 100).toStringAsFixed(1)}% illuminated · ${snapshot.waxing ? 'Waxing' : 'Waning'}',
          ),
          Text(
            'Lunar age · ${age == null ? 'Outside available phase history' : '${age.toStringAsFixed(2)} days'}',
          ),
          Text('Distance · ${moon.distanceKm!.round()} km'),
          Text('Tropical zodiac · ${moon.sign()} ${moon.zodiacPosition()}'),
          Text(
            'Schematic · ${south ? 'Southern' : 'Northern'} Hemisphere convention',
          ),
          const Text('Observer-dependent orientation is pending.'),
        ],
      ),
      if (showSpiritual || moonSection == MoonSection.reflection)
        MoonSection.reflection: _Panel(
          title: 'Lunar reflection',
          children: [
            Text(
              showSpiritual ? editorial.prompt : 'Enable spiritual content in Settings to see lunar reflections.',
            ),
          ],
        ),
      MoonSection.colour: _Panel(
        title: 'Lunar colour · ${editorial.colour}',
        children: [Text(editorial.association)],
      ),
      MoonSection.calendar: _Panel(
        title: 'Previous and upcoming lunar phases',
        children: [
          for (final event in nearby) _eventTile(context, event, zone),
        ],
      ),
    };
    final focused = panels.remove(moonSection);
    return [
      ?focused,
      for (final section in [
        MoonSection.phase,
        MoonSection.reflection,
        MoonSection.colour,
      ])
        ?panels[section],
      _horizon(context, lunar: true),
      ?panels[MoonSection.calendar],
    ];
  }

  Widget _horizon(BuildContext context, {required bool lunar}) {
    final location = observer;
    final provider = engine;
    final heading = lunar ? 'Moonrise and Moonset' : 'Sun and twilight';
    if (location == null || provider is! HorizonEngine) {
      return _Panel(
        title: heading,
        children: [
          const Text(
            'Set optional observer coordinates in Settings to see local horizon events.',
          ),
        ],
      );
    }
    final start = civilDayStart(day, zone);
    final end = civilDayStart(
      DateTime.utc(day.year, day.month, day.day + 1),
      zone,
    );
    if (start.isBefore(engine.start) || end.isAfter(engine.end)) {
      return _Panel(
        title: heading,
        children: [
          const Text(
            'This civil day lies outside the supported horizon range.',
          ),
        ],
      );
    }
    final horizon = (provider as HorizonEngine).horizon(start, end, location);
    final relevant = horizon.events.where(
      (event) =>
          (event.kind == HorizonKind.moonrise ||
              event.kind == HorizonKind.moonset) ==
          lunar,
    );
    return _Panel(
      title: heading,
      children: [
        if (!lunar)
          Text(
            'Daylight · ${horizon.daylight.inHours} h ${horizon.daylight.inMinutes % 60} min',
          ),
        if (relevant.isEmpty)
          const Text('No matching events on this civil date.'),
        if (lunar)
          for (final kind in [HorizonKind.moonrise, HorizonKind.moonset])
            if (!relevant.any((event) => event.kind == kind))
              Text('${kind.label} does not occur on this civil date.'),
        for (final event in relevant)
          Text(
            '${event.kind.label} · ${formatMoment(context, inDisplayZone(event.instant, zone))}',
          ),
        const Text('Approximate, for a level horizon at sea level.'),
      ],
    );
  }

  Widget _positionCard(
    BuildContext context,
    CelestialPosition position,
  ) => Card(
    child: ListTile(
      leading: const Icon(Icons.radio_button_checked),
      title: Text(titleCase(position.body.name)),
      subtitle: Text(
        '${position.sign()} ${position.zodiacPosition()} · ${position.motion}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showPosition(context, position),
    ),
  );

  Future<void> _showPosition(BuildContext context, CelestialPosition position) {
    final provider = engine;
    final body = position.body;
    final motionEvents =
        provider is PlanetaryEventEngine &&
            body != Body.sun &&
            body != Body.moon
        ? compute(_planetaryEvents, (
            provider as PlanetaryEventEngine,
            body,
            instant,
          ))
        : null;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titleCase(body.name)),
        scrollable: true,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [
                'Ecliptic longitude · ${position.longitude.toStringAsFixed(4)}°',
                'Ecliptic latitude · ${position.latitude.toStringAsFixed(4)}°',
                'Right ascension · ${(position.rightAscension / 15).toStringAsFixed(4)} h',
                'Declination · ${position.declination.toStringAsFixed(4)}°',
                'Longitude speed · ${position.speed.toStringAsFixed(4)}° per day',
                if (position.distanceKm case final distance?)
                  'Distance · ${distance.round()} km',
                'Geocentric equinox and ecliptic of date',
              ].join('\n'),
            ),
            if (motionEvents != null)
              FutureBuilder(
                future: motionEvents,
                builder: (context, state) {
                  if (state.hasError) {
                    return const Text('Planetary events unavailable.');
                  }
                  final events = state.data;
                  if (events == null) {
                    return const LinearProgressIndicator(
                      semanticsLabel: 'Calculating events',
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Semantics(
                        header: true,
                        child: const Text('Nearby planetary events'),
                      ),
                      for (final kind in PlanetaryEventKind.values) ...[
                        if (events
                                .where(
                                  (event) =>
                                      event.kind == kind &&
                                      event.instant.isBefore(instant),
                                )
                                .lastOrNull
                            case final previous?)
                          _motionEvent(context, previous),
                        if (events
                                .where(
                                  (event) =>
                                      event.kind == kind &&
                                      !event.instant.isBefore(instant),
                                )
                                .firstOrNull
                            case final next?)
                          _motionEvent(context, next),
                      ],
                      if (events.isEmpty)
                        const Text('No events within 183 days.'),
                    ],
                  );
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _motionEvent(BuildContext context, PlanetaryEvent event) {
    final label = switch (event.kind) {
      PlanetaryEventKind.ingress =>
        'Enters ${event.sign}${event.retrograde ? ' in retrograde' : ''}',
      PlanetaryEventKind.stationDirect => 'Stations direct',
      PlanetaryEventKind.stationRetrograde => 'Stations retrograde',
    };
    return Text(
      '$label · ${formatMoment(context, inDisplayZone(event.instant, zone))}',
    );
  }

  List<Widget> _astrology(SkySnapshot snapshot) {
    final aspects = activeAspects(snapshot, orb);
    return [
      const Text('Traditional astrology · Tropical zodiac'),
      _Panel(
        title: 'Active major aspects',
        children: [
          if (aspects.isEmpty)
            const Text('No major aspects within the selected orb.'),
          for (final aspect in aspects) Text(_aspectText(aspect)),
        ],
      ),
      _Panel(
        title: 'Zodiac positions',
        children: [
          for (final position in snapshot.positions.values)
            Text(
              '${titleCase(position.body.name)} · ${position.sign()} ${position.zodiacPosition()}',
            ),
        ],
      ),
    ];
  }

  String _aspectText(ActiveAspect aspect) =>
      '${titleCase(aspect.first.name)} ${aspect.aspect.name} ${titleCase(aspect.second.name)} · ${aspect.orb.toStringAsFixed(1)}° · ${aspect.motion}';

  List<Widget> _numbers() {
    final date = birth;
    return [
      _Panel(
        title: 'Universal numbers',
        children: [
          Text('Year · ${numerology.universalYear(day)}'),
          Text('Month · ${numerology.universalMonth(day)}'),
          Text('Day · ${numerology.universalDay(day)} · ${daily.theme}'),
          const Text(
            'Digits are summed iteratively. The reduced year feeds the month, which feeds the day.',
          ),
        ],
      ),
      _Panel(
        title: 'Personal numbers',
        children: [
          if (date == null)
            const Text(
              'Add an optional birth date in Settings to calculate personal numbers.',
            ),
          if (date != null) ...[
            Text('Life path · ${numerology.lifePath(date)}'),
            Text('Birthday · ${numerology.reduce(date.day)}'),
            Text('Personal year · ${numerology.personalYear(day, date)}'),
            Text('Personal month · ${numerology.personalMonth(day, date)}'),
            Text('Personal day · ${numerology.personalDay(day, date)}'),
          ],
        ],
      ),
      const Text('Numerology is a traditional interpretive practice.'),
    ];
  }

  Widget _editorial() => _Panel(
    title: 'Daily colour · ${daily.colour}',
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Color(0xff000000 | daily.rgb),
          ),
          child: const SizedBox(width: 84, height: 44),
        ),
      ),
      Text('Intention · ${daily.intention}'),
      Text(daily.interpretation),
      Text(daily.affirmation),
      const Text(
        'Original editorial content selected by universal day number.',
      ),
    ],
  );

  List<Widget> _widgets(SkySnapshot snapshot) {
    final capability = currentWidgetCapability;
    final platformName = switch (capability) {
      WidgetCapability.android => 'Android Home Screen',
      WidgetCapability.appleHome => 'iOS Home Screen and Lock Screen',
      WidgetCapability.macDesktop => 'macOS widgets',
      WidgetCapability.windowsBoard => 'Windows widget board',
      WidgetCapability.webDashboard => 'Web dashboard',
      WidgetCapability.unavailable => 'Current platform',
    };
    final preview = WidgetSnapshot.fromSky(
      instant: instant,
      expiresAt: instant.add(const Duration(minutes: 15)),
      zone: zone,
      sky: snapshot,
      universalDay: numerology.universalDay(day),
    );
    return [
      _Panel(
        title: platformName,
        children: [
          Text(
            capability == WidgetCapability.webDashboard
                ? 'The installable web dashboard supports offline access after caching.'
                : 'Native widget installation is pending on this platform.',
          ),
        ],
      ),
      _Panel(
        title: 'Moon Phase · Small preview',
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: MoonDisc(
              illumination: preview.illumination,
              waxing: snapshot.waxing,
              south: south,
            ),
          ),
          Text('${preview.phase} · ${(preview.illumination * 100).round()}%'),
        ],
      ),
      _Panel(
        title: 'Daily overview · Medium preview',
        children: [
          Text('Moon in ${preview.moonSign}'),
          Text('Universal day ${preview.dailyNumber}'),
        ],
      ),
    ];
  }
}

enum CalendarSpan { day, week, month, year }

class CalendarPanel extends StatefulWidget {
  const CalendarPanel({
    super.key,
    required this.engine,
    required this.day,
    required this.zone,
  });
  final AstronomyEngine engine;
  final DateTime day;
  final String zone;

  @override
  State<CalendarPanel> createState() => _CalendarPanelState();
}

class _CalendarPanelState extends State<CalendarPanel> {
  CalendarSpan _span = CalendarSpan.month;
  final _categories = EventCategory.values.toSet();
  bool _exporting = false;
  (AstronomyEngine, DateTime, DateTime, String)? _eventRange;
  List<SkyEvent> _rangeEvents = const [];

  List<SkyEvent> _eventsInRange(DateTime start, DateTime end) {
    final range = (widget.engine, start, end, widget.zone);
    if (_eventRange != range) {
      _rangeEvents = widget.engine
          .events(
            start.subtract(const Duration(days: 1)),
            end.add(const Duration(days: 1)),
          )
          .where((event) {
            final local = inDisplayZone(event.instant, widget.zone);
            final date = DateTime.utc(local.year, local.month, local.day);
            return !date.isBefore(start) && date.isBefore(end);
          })
          .toList();
      _eventRange = range;
    }
    return _rangeEvents
        .where((event) => _categories.contains(event.category))
        .toList();
  }

  Future<void> _export(
    BuildContext buttonContext,
    List<SkyEvent> events,
  ) async {
    if (_exporting) return;
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    setState(() => _exporting = true);
    try {
      final selected = await showDialog<List<SkyEvent>>(
        context: context,
        builder: (context) =>
            _ExportEventDialog(events: events, zone: widget.zone),
      );
      if (selected == null || !mounted) return;
      final calendar = exportCalendar(selected, createdAt: DateTime.now());
      await SharePlus.instance.share(
        ShareParams(
          title: 'Export Astro Worker events',
          files: [
            XFile.fromData(utf8.encode(calendar), mimeType: 'text/calendar'),
          ],
          fileNameOverrides: const ['astro-worker-events.ics'],
          sharePositionOrigin: origin,
        ),
      );
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not export the calendar file.')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final midnight = DateTime.utc(day.year, day.month, day.day);
    final (start, end) = switch (_span) {
      CalendarSpan.day => (midnight, midnight.add(const Duration(days: 1))),
      CalendarSpan.week => (
        midnight.subtract(Duration(days: midnight.weekday - 1)),
        midnight.add(Duration(days: 8 - midnight.weekday)),
      ),
      CalendarSpan.month => (
        DateTime.utc(day.year, day.month),
        DateTime.utc(day.year, day.month + 1),
      ),
      CalendarSpan.year => (DateTime.utc(day.year), DateTime.utc(day.year + 1)),
    };
    final events = _eventsInRange(start, end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final span in CalendarSpan.values)
              ChoiceChip(
                label: Text(titleCase(span.name)),
                selected: _span == span,
                onSelected: (_) => setState(() => _span = span),
              ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 6,
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
        if (events.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Builder(
              builder: (buttonContext) => OutlinedButton.icon(
                onPressed: _exporting
                    ? null
                    : () => _export(buttonContext, events),
                icon: const Icon(Icons.ios_share),
                label: const Text('Export events'),
              ),
            ),
          ),
        _Panel(
          title: 'Calculated events',
          children: [
            if (events.isEmpty)
              const Text('No matching events in this period.'),
            for (final event in events) _eventTile(context, event, widget.zone),
          ],
        ),
      ],
    );
  }
}

Widget _eventTile(BuildContext context, SkyEvent event, String zone) {
  final time = formatMoment(context, inDisplayZone(event.instant, zone));
  return ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(event.name),
    subtitle: Text(time),
    onTap: () => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.name),
        content: Text(
          '$time\n${formatMoment(context, event.instant)}\n${titleCase(event.body.name)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          ...children,
        ],
      ),
    ),
  );
}

class _ExportEventDialog extends StatefulWidget {
  const _ExportEventDialog({required this.events, required this.zone});

  final List<SkyEvent> events;
  final String zone;

  @override
  State<_ExportEventDialog> createState() => _ExportEventDialogState();
}

class _ExportEventDialogState extends State<_ExportEventDialog> {
  final _selected = <SkyEvent>{};

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Choose events to export'),
    semanticLabel: 'Choose events to export',
    content: SizedBox(
      width: 420,
      height: 340,
      child: ListView.builder(
        itemCount: widget.events.length,
        itemBuilder: (context, index) {
          final event = widget.events[index];
          return CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _selected.contains(event),
            title: Text(event.name),
            subtitle: Text(
              formatMoment(context, inDisplayZone(event.instant, widget.zone)),
            ),
            onChanged: (checked) => setState(() {
              if (checked == true) {
                _selected.add(event);
              } else {
                _selected.remove(event);
              }
            }),
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _selected.isEmpty
            ? null
            : () => Navigator.pop(context, _selected.toList()),
        child: const Text('Export .ics'),
      ),
    ],
  );
}

List<PlanetaryEvent> _planetaryEvents(
  (PlanetaryEventEngine, Body, DateTime) request,
) {
  final (engine, body, instant) = request;
  const radius = Duration(days: 183);
  return engine.planetaryEvents(
    body,
    instant.subtract(radius),
    instant.add(radius),
  );
}
