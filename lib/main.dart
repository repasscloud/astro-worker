import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'app/astro_app.dart';
import 'infrastructure/content.dart';
import 'infrastructure/meeus_engine.dart';
import 'infrastructure/preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  final preferences = await Preferences.open();
  final content = await EditorialContent.load();
  runApp(
    AstroApp(
      engine: MeeusEngine(),
      preferences: preferences,
      content: content,
      clock: DateTime.now,
    ),
  );
}
