import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kheench/data/database.dart';
import 'package:kheench/main.dart';

Widget app() => ProviderScope(
  overrides: [
    databaseProvider.overrideWith((ref) {
      final db = AppDatabase(NativeDatabase.memory());
      ref.onDispose(db.close);
      return db;
    }),
  ],
  child: const KheenchApp(),
);

/// Unmounts the app so drift closes its streams, then flushes their timers.
Future<void> tearDownApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

void main() {
  // Each test builds its own in-memory database on purpose.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('splash leads to Home and tabs switch', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text('Paste a link to start'), findsOneWidget);

    await tester.tap(find.text('Tools'));
    await tester.pumpAndSettle();
    expect(find.text('Status splitter'), findsOneWidget);

    await tester.tap(find.text('Downloads').last);
    await tester.pumpAndSettle();
    expect(find.text('No active downloads'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('invalid link shows an error', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'not a link');
    await tester.tap(find.text('Show qualities'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a link starting with https://'), findsOneWidget);
    await tearDownApp(tester);
  });
}
