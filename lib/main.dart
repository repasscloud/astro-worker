import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'app/astro_app.dart';
import 'infrastructure/content.dart';
import 'infrastructure/meeus_engine.dart';
import 'infrastructure/preferences.dart';
import 'platform/native_moon_widget.dart';
import 'platform/native_reminders.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Astro Worker',
    ], await rootBundle.loadString('LICENSE'));
    yield LicenseEntryWithLineBreaks([
      'Astro Worker (original MIT notice)',
    ], await rootBundle.loadString('assets/legal/legacy-mit.txt'));
  });
  tz.initializeTimeZones();
  final preferences = await Preferences.open();
  final content = await EditorialContent.load(
    locale: PlatformDispatcher.instance.locale,
  );
  runApp(
    AstroApp(
      engine: MeeusEngine(),
      preferences: preferences,
      content: content,
      clock: DateTime.now,
      nativeReminders:
          !kIsWeb &&
              (defaultTargetPlatform == TargetPlatform.android ||
                  defaultTargetPlatform == TargetPlatform.macOS)
          ? NativeReminders()
          : null,
      nativeMoonWidget:
          !kIsWeb &&
              (defaultTargetPlatform == TargetPlatform.android ||
                  defaultTargetPlatform == TargetPlatform.macOS)
          ? NativeMoonWidget()
          : null,
    ),
  );
}
