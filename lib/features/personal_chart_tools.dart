import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../domain/astronomy.dart';
import '../domain/birth_chart.dart';
import '../domain/civil_time.dart';
import '../domain/personal_charts.dart';
import '../domain/zodiac.dart';
import 'observatory.dart' show formatMoment, titleCase;

class PersonalChartTools extends StatefulWidget {
  const PersonalChartTools({
    super.key,
    required this.engine,
    required this.zodiac,
    required this.profile,
    required this.chart,
    required this.profiles,
    required this.clock,
  });

  final AstronomyEngine engine;
  final Zodiac zodiac;
  final BirthProfile profile;
  final NatalChart chart;
  final List<BirthProfile> profiles;
  final DateTime Function() clock;

  @override
  State<PersonalChartTools> createState() => _PersonalChartToolsState();
}

class _PersonalChartToolsState extends State<PersonalChartTools> {
  Map<Body, double> get _natal =>
      chartLongitudes(widget.chart.sky!, widget.chart.instant!, widget.zodiac);

  Future<void> _showTransits() async {
    final now = widget.clock().toUtc();
    final first = widget.engine.start, end = widget.engine.end;
    final last = end.subtract(const Duration(days: 1));
    final day = await showDatePicker(
      context: context,
      helpText: 'Choose the transit date in UTC',
      firstDate: first,
      lastDate: last,
      initialDate: now.isBefore(first)
          ? first
          : now.isAfter(last)
          ? last
          : now,
      currentDate: now,
    );
    if (day == null || !mounted) return;
    final instant = DateTime.utc(
      day.year,
      day.month,
      day.day,
      now.hour,
      now.minute,
    );
    final sky = widget.engine.skyAt(instant);
    final aspects = compareLongitudes(
      chartLongitudes(sky, instant, widget.zodiac),
      _natal,
      4,
    );
    await _dialog('Transits', [
      Text(formatMoment(context, instant)),
      const Text('Transiting body · natal body'),
      ..._aspectRows(aspects),
    ]);
  }

  Future<void> _showReturn() async {
    final start = widget.engine.start.year;
    final birthYear = widget.chart.instant!.year;
    final firstYear = birthYear < start ? start : birthYear;
    final lastYear = widget.engine.end.subtract(const Duration(days: 1)).year;
    var year = widget.clock().year.clamp(firstYear, lastYear);
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solar return year'),
        content: DropdownButtonFormField<int>(
          initialValue: year,
          items: [
            for (var value = firstYear; value <= lastYear; value++)
              DropdownMenuItem(value: value, child: Text('$value')),
          ],
          onChanged: (selection) {
            if (selection != null) year = selection;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, year),
            child: const Text('Calculate'),
          ),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    final future = compute(_returnInstant, (
      widget.engine,
      _natal[Body.sun]!,
      widget.chart.instant!,
      selected,
      widget.zodiac,
    ));
    await _dialog('Solar return · $selected', [
      FutureBuilder(
        future: future,
        builder: (context, state) {
          if (state.connectionState != ConnectionState.done) {
            return const LinearProgressIndicator(
              semanticsLabel: 'Calculating solar return',
            );
          }
          final instant = state.data;
          return Text(
            instant == null
                ? 'The return falls outside the available ephemeris range.'
                : formatMoment(
                    context,
                    inDisplayZone(instant, widget.profile.zone),
                  ),
          );
        },
      ),
      const Text(
        'The instant the Sun returns to its natal longitude in the selected zodiac.',
      ),
    ]);
  }

  Iterable<BirthProfile> get _eligiblePeers => widget.profiles.where((profile) {
    if (profile.id == widget.profile.id) return false;
    final instant = profile.instant;
    return instant != null &&
        !instant.isBefore(widget.engine.start) &&
        instant.isBefore(widget.engine.end);
  });

  Future<void> _showComparison() async {
    final peers = _eligiblePeers.toList();
    if (peers.isEmpty) return;
    var peer = peers.first;
    final selected = await showDialog<BirthProfile>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compare birth profiles'),
        content: DropdownButtonFormField<BirthProfile>(
          isExpanded: true,
          initialValue: peer,
          items: [
            for (final candidate in peers)
              DropdownMenuItem(
                value: candidate,
                child: Text(candidate.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (selection) {
            if (selection != null) peer = selection;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, peer),
            child: const Text('Compare'),
          ),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    final instant = selected.instant!;
    final other = chartLongitudes(
      widget.engine.skyAt(instant),
      instant,
      widget.zodiac,
    );
    final natal = _natal;
    final synastry = compareLongitudes(other, natal, 4);
    final composite = compositeMidpoints(natal, other);
    await _dialog('Relationship charts', [
      Semantics(header: true, child: const Text('Synastry')),
      Text('${selected.name} · ${widget.profile.name}'),
      ..._aspectRows(synastry),
      const SizedBox(height: 12),
      Semantics(header: true, child: const Text('Composite midpoints')),
      for (final entry in composite.entries)
        Text(
          '${titleCase(entry.key.name)} · ${_describeLongitude(entry.value)}',
        ),
    ]);
  }

  String _describeLongitude(double? longitude) => longitude == null
      ? 'Opposition has two midpoints'
      : '${zodiacSigns[(longitude / 30).floor()]} ${(longitude % 30).toStringAsFixed(2)}°';

  Iterable<Widget> _aspectRows(List<ComparisonAspect> aspects) sync* {
    if (aspects.isEmpty) yield const Text('No major aspects within a 4° orb.');
    for (final item in aspects) {
      yield Text(
        '${titleCase(item.outer.name)} ${item.aspect.name} ${titleCase(item.natal.name)} · ${item.orb.toStringAsFixed(1)}°',
      );
    }
  }

  Future<void> _dialog(String title, List<Widget> children) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: Text(title),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: children,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      OutlinedButton(onPressed: _showTransits, child: const Text('Transits')),
      OutlinedButton(onPressed: _showReturn, child: const Text('Solar return')),
      if (_eligiblePeers.isNotEmpty)
        OutlinedButton(
          onPressed: _showComparison,
          child: const Text('Compare charts'),
        ),
    ],
  );
}

DateTime? _returnInstant(
  (AstronomyEngine, double, DateTime, int, Zodiac) request,
) {
  final (engine, longitude, birthday, year, zodiac) = request;
  return solarReturn(engine, longitude, birthday, year, zodiac);
}
