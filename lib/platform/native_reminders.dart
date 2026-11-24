import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/astronomy.dart';
import '../domain/reminders.dart';

class NativeReminders {
  static const _channel = MethodChannel('astro_worker/reminders');
  Future<void> _pending = Future.value();
  int _revision = 0;

  Future<bool> requestPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestPermission') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> refresh(
    AstronomyEngine engine,
    DateTime now,
    ReminderSettings settings,
    String zone,
  ) {
    final revision = ++_revision;
    _pending = _pending.then((_) async {
      if (revision != _revision) return;
      final reminders = planReminders(
        engine,
        now,
        settings,
        zone,
        applyQuietHours: defaultTargetPlatform != TargetPlatform.android,
      );
      try {
        await _channel.invokeMethod<void>(
          'replace',
          jsonEncode({
            'zone': zone,
            'quietFrom': settings.quietFrom,
            'quietUntil': settings.quietUntil,
            'events': [
              for (final item in reminders)
                {
                  'id': item.id,
                  'title': item.title,
                  'event': item.event.millisecondsSinceEpoch,
                  'due': item.due.millisecondsSinceEpoch,
                },
            ],
          }),
        );
      } on PlatformException catch (error) {
        debugPrint('Reminders could not be replaced: ${error.code}');
      } on MissingPluginException {
        // The bundled platform does not expose a reminder scheduler.
      }
    });
    return _pending;
  }
}
