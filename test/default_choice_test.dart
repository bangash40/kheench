import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kheench/engine/media_info.dart';
import 'package:kheench/features/link/default_choice.dart';
import 'package:kheench/features/settings/settings_providers.dart';

void main() {
  final youtube = MediaInfo.fromJsonString(
    File('test/fixtures/youtube.json').readAsStringSync(),
  );
  final tiktok = MediaInfo.fromJsonString(
    File('test/fixtures/combined.json').readAsStringSync(),
  );

  AppSettings with_(DefaultQuality q, [AudioFormat f = AudioFormat.m4a]) =>
      AppSettings(defaultQuality: q, audioFormat: f);

  test('ask means show the picker', () {
    expect(choiceForDefault(youtube, with_(DefaultQuality.ask)), isNull);
  });

  test('best uses the best-video selector', () {
    final c = choiceForDefault(youtube, with_(DefaultQuality.best))!;
    expect(c.selector, 'bv*+ba/b');
  });

  test('1080p and 720p pick that height', () {
    expect(
      choiceForDefault(youtube, with_(DefaultQuality.p1080))!.label,
      '1080p60 MP4',
    );
    expect(
      choiceForDefault(youtube, with_(DefaultQuality.p720))!.label,
      '720p60 MP4',
    );
  });

  test('falls back to the closest lower quality, or the lowest', () {
    // TikTok fixture has 1024p and 720p only.
    expect(
      choiceForDefault(tiktok, with_(DefaultQuality.p1080))!.label,
      '1024p MP4',
    );
    final lowOnly = MediaInfo.fromJson({
      'id': 'x',
      'title': 'x',
      'formats': [
        {
          'format_id': 'hd',
          'ext': 'mp4',
          'vcodec': 'h264',
          'acodec': 'aac',
          'height': 1440,
        },
      ],
    });
    expect(
      choiceForDefault(lowOnly, with_(DefaultQuality.p720))!.label,
      '1440p MP4',
    );
  });

  test('audio only follows the audio format setting', () {
    final m4a = choiceForDefault(youtube, with_(DefaultQuality.audio))!;
    expect(m4a.label, 'M4A audio');
    expect(m4a.extraArgs, contains('m4a'));

    final mp3 = choiceForDefault(
      youtube,
      with_(DefaultQuality.audio, AudioFormat.mp3),
    )!;
    expect(mp3.label, 'MP3 audio');
  });
}
