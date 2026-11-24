import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../app/destination.dart';
import '../domain/astronomy.dart';
import '../domain/civil_time.dart';
import '../domain/numerology.dart';
import '../domain/zodiac.dart';
import '../infrastructure/lunar_editorial.dart';
import 'widget_snapshot.dart';

class NativeMoonWidget {
  static const _channel = MethodChannel('astro_worker/moon_widget');
  int _revision = 0;

  set onOpenMoon(ValueChanged<MoonSection>? callback) {
    _channel.setMethodCallHandler(
      callback == null
          ? null
          : (call) async {
              if (call.method == 'openMoon') callback(_section(call.arguments));
            },
    );
    if (callback != null) unawaited(_consumeInitialOpen(callback));
  }

  Future<void> _consumeInitialOpen(ValueChanged<MoonSection> callback) async {
    try {
      final target = await _channel.invokeMethod<String>('consumeOpenMoon');
      if (target != null) callback(_section(target));
    } on MissingPluginException {
      // The native widget channel is absent on unsupported OS versions.
    } on PlatformException catch (error) {
      debugPrint('Moon widget launch unavailable: ${error.code}');
    }
  }

  MoonSection _section(Object? target) =>
      MoonSection.values.asNameMap()[target] ?? MoonSection.phase;

  Future<void> refresh(
    AstronomyEngine engine,
    DateTime now,
    String zone,
    bool keepMasterNumbers, {
    required bool south,
    required bool showSpiritual,
    required Zodiac zodiac,
  }) async {
    final revision = ++_revision;
    final timeline = await compute(buildNativeMoonTimeline, (
      engine: engine,
      now: DateTime.fromMillisecondsSinceEpoch(
        now.millisecondsSinceEpoch,
        isUtc: true,
      ),
      zone: zone,
      keepMasterNumbers: keepMasterNumbers,
      south: south,
      showSpiritual: showSpiritual,
      zodiac: zodiac,
    ));
    if (revision != _revision) return;
    try {
      await _channel.invokeMethod<void>('publish', jsonEncode(timeline));
    } on MissingPluginException {
      // The native widget channel is absent on unsupported OS versions.
    } on PlatformException catch (error) {
      debugPrint('Moon widget update unavailable: ${error.code}');
    }
  }
}

@visibleForTesting
List<Map<String, Object>> buildNativeMoonTimeline(
  ({
    AstronomyEngine engine,
    DateTime now,
    String zone,
    bool keepMasterNumbers,
    bool south,
    bool showSpiritual,
    Zodiac zodiac,
  })
  request,
) {
  tz.initializeTimeZones();
  final (
    :engine,
    :now,
    :zone,
    :keepMasterNumbers,
    :south,
    :showSpiritual,
    :zodiac,
  ) = request;
  final numerology = Numerology(keepMasterNumbers: keepMasterNumbers);
  const step = Duration(hours: 1);
  final snapshots = <Map<String, Object>>[];
  if (now.isBefore(engine.start) || !now.isBefore(engine.end)) return snapshots;
  final phases = engine
      .events(now, now.add(const Duration(days: 14)))
      .where((event) => event.category == EventCategory.moonPhase)
      .iterator;
  var hasNextPhase = phases.moveNext();
  final horizon = now.add(const Duration(hours: 48));
  for (
    var start = now;
    start.isBefore(horizon) && start.isBefore(engine.end);
  ) {
    while (hasNextPhase && !phases.current.instant.isAfter(start)) {
      hasNextPhase = phases.moveNext();
    }
    final nextPhase = hasNextPhase ? phases.current : null;
    var end = start.add(step);
    if (nextPhase != null && nextPhase.instant.isBefore(end)) {
      end = nextPhase.instant;
    }
    if (engine.end.isBefore(end)) end = engine.end;
    if (horizon.isBefore(end)) end = horizon;

    final sky = engine.skyAt(start);
    final editorial = lunarEditorial(sky.phase);
    snapshots.add({
      ...WidgetSnapshot.fromSky(
        instant: start,
        expiresAt: end,
        zone: zone,
        sky: sky,
        zodiac: zodiac,
        universalDay: numerology.universalDay(inDisplayZone(start, zone)),
      ).toJson(),
      'waxing': sky.waxing,
      'south': south,
      if (showSpiritual) 'reflection': editorial.prompt,
      'colourName': editorial.colour,
      'colourBackground': editorial.background,
      'colourForeground': editorial.foreground,
      if (nextPhase != null) 'nextPhase': nextPhase.name,
    });
    start = end;
  }
  return snapshots;
}
