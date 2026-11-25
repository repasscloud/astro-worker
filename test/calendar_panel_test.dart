import 'package:astro_worker/domain/astronomy.dart';
import 'package:astro_worker/features/observatory.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _CalendarEngine implements AstronomyEngine {
  int queries = 0;

  @override
  DateTime get start => DateTime.utc(2000);

  @override
  DateTime get end => DateTime.utc(2051);

  @override
  SkySnapshot skyAt(DateTime instant) => throw UnimplementedError();

  @override
  List<SkyEvent> events(DateTime from, DateTime until) {
    queries++;
    return [
      SkyEvent(
        'Full Moon',
        DateTime.utc(2025, 1, 13),
        EventCategory.moonPhase,
        Body.moon,
      ),
      SkyEvent(
        'Lunar perigee',
        DateTime.utc(2025, 1, 14),
        EventCategory.apsis,
        Body.moon,
      ),
    ];
  }
}

void main() {
  testWidgets(
    'export follows filters and supports selection on a narrow layout',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final engine = _CalendarEngine();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: Scaffold(
            body: ListView(
              children: [
                CalendarPanel(
                  engine: engine,
                  day: DateTime.utc(2025, 1, 13),
                  zone: 'UTC',
                ),
              ],
            ),
          ),
        ),
      );
      expect(engine.queries, 1);
      await tester.tap(find.text('Lunar apsides'));
      await tester.pumpAndSettle();
      expect(engine.queries, 1);
      expect(find.text('Lunar perigee'), findsNothing);
      final event = find.text('Full Moon');
      await tester.ensureVisible(event);
      await tester.tap(event);
      await tester.pumpAndSettle();
      expect(find.textContaining(' UTC\nMoon'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      final openExport = find.text('Export events');
      await tester.ensureVisible(openExport);
      await tester.tap(openExport);
      await tester.pumpAndSettle();
      final dialog = find.byType(AlertDialog);
      final fullMoon = find.descendant(
        of: dialog,
        matching: find.text('Full Moon'),
      );
      expect(fullMoon, findsOneWidget);
      expect(
        find.descendant(of: dialog, matching: find.text('Lunar perigee')),
        findsNothing,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Export .ics'),
            )
            .onPressed,
        isNull,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Export .ics'),
            )
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
