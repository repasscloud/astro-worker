import 'package:astro_worker/main.dart' as app;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'production bootstrap loads preferences, content and the observatory',
    (tester) async {
      await app.main();
      await tester.pumpAndSettle();
      expect(find.text('Astro Worker'), findsOneWidget);
      expect(find.text('Upcoming events'), findsOneWidget);
      expect(
        await rootBundle.loadString('LICENSE'),
        contains('GNU AFFERO GENERAL PUBLIC LICENSE'),
      );
      expect(
        await rootBundle.loadString('assets/legal/legacy-mit.txt'),
        contains('Copyright (c) 2026 RePass Cloud'),
      );
    },
  );
}
