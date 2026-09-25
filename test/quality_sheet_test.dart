import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kheench/app/theme.dart';
import 'package:kheench/engine/media_info.dart';
import 'package:kheench/features/link/home_screen.dart';
import 'package:kheench/features/link/quality_sheet.dart';

void main() {
  group('extractUrl', () {
    test('finds a link inside shared text', () {
      expect(
        extractUrl('Watch this! https://youtu.be/aqz-KE-bpKQ?si=abc.'),
        'https://youtu.be/aqz-KE-bpKQ?si=abc',
      );
    });

    test('rejects text without a link', () {
      expect(extractUrl('not a link'), isNull);
      expect(extractUrl('https://localhost'), isNull);
    });
  });

  testWidgets('quality sheet lists options and updates the download button', (
    tester,
  ) async {
    final info = MediaInfo.fromJsonString(
      File('test/fixtures/youtube.json').readAsStringSync(),
    );
    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(body: QualitySheet(info: info)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Best quality'), findsOneWidget);
    expect(find.text('2160p60 + audio'), findsOneWidget);
    expect(find.text('Video · 8 options'), findsOneWidget);
    expect(find.textContaining('Download 2160p60 WEBM'), findsOneWidget);

    await tester.tap(find.text('1080p60'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Download 1080p60 MP4'), findsOneWidget);

    await tester.tap(find.text('MP3 audio'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Download MP3 audio'), findsOneWidget);
  });
}
