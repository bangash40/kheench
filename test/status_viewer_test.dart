import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kheench/app/theme.dart';
import 'package:kheench/engine/status_source.dart';
import 'package:kheench/features/status/status_viewer.dart';

void main() {
  testWidgets('close button and counter sit at the top of the screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    final items = [
      for (var i = 0; i < 3; i++)
        StatusItem(
          uri: 'file:///status/$i.jpg',
          name: '$i.jpg',
          type: StatusType.photo,
          modified: DateTime.now().subtract(const Duration(hours: 2)),
          size: 1,
        ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: StatusViewer(items: items, initialIndex: 1),
        ),
      ),
    );
    await tester.pump();

    final close = tester.getCenter(find.byTooltip('Close'));
    expect(close.dy, lessThan(120));
    expect(find.text('2 of 3'), findsOneWidget);
    expect(find.text('2h ago'), findsOneWidget);
  });
}
