import 'dart:convert';

import 'package:astro_worker/app/astro_app.dart';
import 'package:astro_worker/app/build_identity.dart';
import 'package:astro_worker/infrastructure/content.dart';
import 'package:astro_worker/infrastructure/meeus_engine.dart';
import 'package:astro_worker/infrastructure/preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'narrow navigation opens Moon and persists spiritual preference',
    (tester) async {
      tester.view.physicalSize = const Size(430, 950);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({'astro.v1.zone': 'UTC'});
      final preferences = await Preferences.open();
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMessageHandler('flutter/assets', (message) async {
        expect(
          utf8.decode(message!.buffer.asUint8List()),
          'assets/content/en.v1.json',
        );
        return ByteData.sublistView(
          utf8.encode(
            '{"schema":1,"numbers":{"5":["Teal","428F92","Change","Stay curious."]},'
            '"prompts":["What changed today?"]}',
          ),
        );
      });
      final EditorialContent content;
      try {
        content = await EditorialContent.load();
      } finally {
        messenger.setMockMessageHandler('flutter/assets', null);
      }
      await tester.pumpWidget(
        AstroApp(
          engine: MeeusEngine(),
          preferences: preferences,
          content: content,
          clock: () => DateTime.utc(2025, 1, 13, 22, 27),
        ),
      );

      expect(find.text('Full Moon'), findsWidgets);
      await tester.tap(find.byTooltip('Open navigation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Moon').first);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Northern Hemisphere convention'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Open navigation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show spiritual content'));
      await tester.pumpAndSettle();
      expect(preferences.flag('spiritual'), isFalse);

      final about = find.text('About and licences');
      await tester.ensureVisible(about);
      await tester.tap(about);
      await tester.pumpAndSettle();
      expect(find.text(BuildIdentity.label), findsOneWidget);
      expect(find.text('© 2026 RePass Cloud · AGPL-3.0-only'), findsOneWidget);
    },
  );
}
