import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kheench/app/share_intake.dart';
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
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a link starting with https://'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('a shared link opens on Home with just the link filled in', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tools'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    container
        .read(sharedLinkProvider.notifier)
        .receive('Watch this! https://youtu.be/aqz-KE-bpKQ?si=abc');
    // The lookup starts right away; its loading animation never settles.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Paste a link to start'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'https://youtu.be/aqz-KE-bpKQ?si=abc');
    expect(container.read(sharedLinkProvider), isNull);
    await tearDownApp(tester);
  });

  testWidgets('See all opens the Saved tab, and tabs change by swiping', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing saved yet'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('No failed downloads'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
    await tester.pumpAndSettle();
    await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('No active downloads'), findsOneWidget);
    await tearDownApp(tester);
  });
}
