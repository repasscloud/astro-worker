import 'package:flutter/services.dart';

import '../domain/horizon.dart';

class DeviceObserverLocation {
  static const _channel = MethodChannel('astro_worker/observer_location');

  Future<Observer> locate() async {
    final coordinates = await _channel.invokeMapMethod<String, double>(
      'gpsFix',
    );
    if (coordinates case {
      'latitude': final double latitude,
      'longitude': final double longitude,
    }) {
      return Observer(latitude: latitude, longitude: longitude);
    }
    throw const FormatException('GPS coordinates were unavailable.');
  }

  Future<void> cancel() async {
    try {
      await _channel.invokeMethod<void>('cancel');
    } on PlatformException {
      // The dialog has already closed.
    } on MissingPluginException {
      // The platform does not provide a GPS channel.
    }
  }
}
