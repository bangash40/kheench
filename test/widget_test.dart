import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kheench/main.dart';

void main() {
  testWidgets('splash leads to Home and tabs switch', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: KheenchApp()));
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text('Paste a link to start'), findsOneWidget);

    await tester.tap(find.text('Tools'));
    await tester.pumpAndSettle();
    expect(find.text('Status splitter'), findsOneWidget);

    await tester.tap(find.text('Downloads').last);
    await tester.pumpAndSettle();
    expect(find.text('No active downloads'), findsOneWidget);
  });

  testWidgets('invalid link shows an error', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: KheenchApp()));
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'not a link');
    await tester.tap(find.text('Show qualities'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a link starting with https://'), findsOneWidget);
  });
}
