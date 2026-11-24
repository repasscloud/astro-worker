import 'package:astro_worker/app/astro_app.dart';
import 'package:astro_worker/app/build_identity.dart';
import 'package:astro_worker/infrastructure/content.dart';
import 'package:astro_worker/infrastructure/meeus_engine.dart';
import 'package:astro_worker/infrastructure/preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'narrow navigation opens Moon and persists spiritual preference',
    (tester) async {
      tester.view.physicalSize = const Size(430, 950);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(bottom: 48);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      SharedPreferences.setMockInitialValues({
        'astro.v1.zone': 'UTC',
        'astro.v1.zodiac': 'lahiri',
        'astro.v1.birth': '2000-02-29T00:00:00.000Z',
      });
      final preferences = await Preferences.open();
      final content = (await tester.runAsync(EditorialContent.load))!;
      await tester.pumpWidget(
        AstroApp(
          engine: MeeusEngine(),
          preferences: preferences,
          content: content,
          clock: () => DateTime.utc(2025, 1, 13, 22, 27),
        ),
      );

      expect(tester.getRect(find.byType(ListView)).bottom, 902);
      expect(find.text('Full Moon'), findsWidgets);
      await tester.tap(find.byTooltip('Open navigation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Moon').first);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Northern Hemisphere convention'),
        findsOneWidget,
      );

      expect(find.textContaining('Sidereal · Lahiri ·'), findsOneWidget);

      await tester.tap(find.byTooltip('Open navigation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show spiritual content'));
      await tester.pumpAndSettle();
      expect(preferences.flag('spiritual'), isFalse);

      await tester.tap(find.text('Keep master numbers 11, 22 and 33'));
      await tester.pumpAndSettle();
      expect((await Preferences.open()).flag('masters'), isFalse);

      final clearBirth = find.byTooltip('Clear birth date');
      await tester.ensureVisible(clearBirth);
      await tester.tap(clearBirth);
      await tester.pumpAndSettle();
      expect((await Preferences.open()).text('birth'), isNull);
      expect(find.byTooltip('Clear birth date'), findsNothing);

      final about = find.text('About and licences');
      await tester.ensureVisible(about);
      await tester.tap(about);
      await tester.pumpAndSettle();
      expect(find.text(BuildIdentity.label), findsOneWidget);
      expect(find.text('© 2026 RePass Cloud · AGPL-3.0-only'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open navigation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spiritual').first);
      await tester.pumpAndSettle();
      expect(
        find.text('Spiritual content is disabled. Enable it in Settings.'),
        findsOneWidget,
      );
      expect(find.textContaining('Daily colour'), findsNothing);
    },
  );
}
