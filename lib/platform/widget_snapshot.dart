import 'package:flutter/foundation.dart';

import '../domain/astronomy.dart';
import '../domain/zodiac.dart';

enum WidgetCapability {
  android,
  appleHome,
  macDesktop,
  windowsBoard,
  webDashboard,
  unavailable,
}

WidgetCapability get currentWidgetCapability => kIsWeb
    ? WidgetCapability.webDashboard
    : switch (defaultTargetPlatform) {
        TargetPlatform.android => WidgetCapability.android,
        TargetPlatform.iOS => WidgetCapability.appleHome,
        TargetPlatform.macOS => WidgetCapability.macDesktop,
        TargetPlatform.windows => WidgetCapability.windowsBoard,
        _ => WidgetCapability.unavailable,
      };

class WidgetSnapshot {
  const WidgetSnapshot({
    required this.generatedAt,
    required this.validUntil,
    required this.zone,
    required this.phase,
    required this.illumination,
    required this.moonSign,
    required this.dailyNumber,
    this.zodiac = Zodiac.tropical,
  });
  final DateTime generatedAt;
  final DateTime validUntil;
  final String zone;
  final String phase;
  final double illumination;
  final String moonSign;
  final int dailyNumber;
  final Zodiac zodiac;

  factory WidgetSnapshot.fromSky({
    required DateTime instant,
    required DateTime expiresAt,
    required String zone,
    required SkySnapshot sky,
    required int universalDay,
    Zodiac zodiac = Zodiac.tropical,
  }) => WidgetSnapshot(
    generatedAt: instant.toUtc(),
    validUntil: expiresAt.toUtc(),
    zone: zone,
    phase: sky.phase,
    illumination: sky.illumination,
    moonSign: sky.positions[Body.moon]!.sign(zodiac.offset(instant)),
    zodiac: zodiac,
    dailyNumber: universalDay,
  );

  Map<String, Object> toJson() => {
    'schema': 1,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'validUntil': validUntil.toUtc().toIso8601String(),
    'zone': zone,
    'zodiac': zodiac.name,
    'phase': phase,
    'illumination': illumination,
    'moonSign': moonSign,
    'universalDay': dailyNumber,
  };
}

abstract interface class WidgetPublisher {
  Future<void> publish(WidgetSnapshot snapshot);
}
