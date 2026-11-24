import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/horizon.dart';
import '../platform/device_observer_location.dart';

class ObserverCoordinatesDialog extends StatefulWidget {
  const ObserverCoordinatesDialog({
    super.key,
    required this.observer,
    this.deviceLocation,
  });

  final Observer? observer;
  final DeviceObserverLocation? deviceLocation;

  @override
  State<ObserverCoordinatesDialog> createState() =>
      _ObserverCoordinatesDialogState();
}

class _ObserverCoordinatesDialogState extends State<ObserverCoordinatesDialog> {
  late final _latitude = TextEditingController(
    text: widget.observer?.latitude.toString(),
  );
  late final _longitude = TextEditingController(
    text: widget.observer?.longitude.toString(),
  );
  bool _locating = false;
  String? _feedback;

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _feedback = 'Looking for a GPS fix…';
    });
    try {
      final observer = await widget.deviceLocation!.locate();
      if (!mounted) return;
      _latitude.text = observer.latitude.toStringAsFixed(5);
      _longitude.text = observer.longitude.toStringAsFixed(5);
      setState(() => _feedback = 'GPS coordinates are ready to save.');
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => _feedback = switch (error.code) {
            'location_denied' =>
              'Enable precise location for GPS or enter coordinates manually.',
            'location_timeout' =>
              'No GPS fix. Try outside or enter coordinates manually.',
            _ =>
              'GPS is unavailable. You can still enter coordinates manually.',
          },
        );
      }
    } on Exception {
      if (mounted) setState(() => _feedback = 'Coordinates unavailable.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _save() {
    try {
      final observer = Observer(
        latitude: double.parse(_latitude.text.trim()),
        longitude: double.parse(_longitude.text.trim()),
      );
      Navigator.pop(context, (observer: observer));
    } on FormatException {
      setState(
        () => _feedback =
            'Enter latitude from −90 to 90 and longitude from −180 to 180.',
      );
    }
  }

  @override
  void dispose() {
    if (_locating) unawaited(widget.deviceLocation?.cancel());
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Observer coordinates'),
    scrollable: true,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _latitude,
          decoration: const InputDecoration(
            labelText: 'Latitude in degrees north',
          ),
          keyboardType: const TextInputType.numberWithOptions(
            signed: true,
            decimal: true,
          ),
        ),
        TextField(
          controller: _longitude,
          decoration: const InputDecoration(
            labelText: 'Longitude in degrees east',
          ),
          keyboardType: const TextInputType.numberWithOptions(
            signed: true,
            decimal: true,
          ),
        ),
        if (widget.deviceLocation != null)
          OutlinedButton.icon(
            onPressed: _locating ? null : _locate,
            icon: const Icon(Icons.my_location),
            label: const Text('Use device GPS'),
          ),
        if (_feedback case final feedback?)
          Semantics(liveRegion: true, child: Text(feedback)),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      if (widget.observer != null)
        TextButton(
          onPressed: () =>
              Navigator.pop<({Observer? observer})>(context, (observer: null)),
          child: const Text('Clear'),
        ),
      FilledButton(
        onPressed: _locating ? null : _save,
        child: const Text('Save'),
      ),
    ],
  );
}
