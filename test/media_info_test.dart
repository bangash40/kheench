import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kheench/engine/engine_error.dart';
import 'package:kheench/engine/media_info.dart';

MediaInfo load(String name) =>
    MediaInfo.fromJsonString(File('test/fixtures/$name').readAsStringSync());

void main() {
  group('YouTube (separate video and audio streams)', () {
    final info = load('youtube.json');

    test('reads preview metadata', () {
      expect(info.title, startsWith('Big Buck Bunny'));
      expect(info.site, 'YouTube');
      expect(info.duration, const Duration(seconds: 635));
      expect(info.thumbnail, isNotNull);
    });

    test('lists one option per resolution, best first', () {
      expect(info.videos.map((v) => v.label), [
        '2160p60',
        '1440p60',
        '1080p60',
        '720p60',
        '480p',
        '360p',
        '240p',
        '144p',
      ]);
    });

    test('prefers direct H.264 over VP9 and AV1 at the same resolution', () {
      final p1080 = info.videos.firstWhere((v) => v.label == '1080p60');
      expect(p1080.formatId, '299');
      expect(p1080.codec, 'H.264');
      expect(p1080.container, 'MP4');
    });

    test('falls back to VP9 WEBM when there is no H.264', () {
      final p2160 = info.videos.first;
      expect(p2160.formatId, '315');
      expect(p2160.codec, 'VP9');
      expect(p2160.container, 'WEBM');
    });

    test('merges matching audio into silent video streams', () {
      final mp4 = info.videos.firstWhere((v) => v.label == '1080p60');
      expect(mp4.needsAudio, isTrue);
      expect(mp4.mergeAudio?.ext, 'm4a');
      expect(mp4.selector, '299+bestaudio[ext=m4a]/299+bestaudio');
      expect(mp4.sizeBytes, 257619653 + 10271496);

      final webm = info.videos.first;
      expect(webm.mergeAudio?.ext, 'webm');
      expect(webm.selector, '315+bestaudio[ext=webm]/315+bestaudio');
    });

    test('lists best audio per container, skipping DRC duplicates', () {
      expect(info.audios.map((a) => a.formatId), ['140', '251']);
      expect(info.audios.first.codec, 'AAC');
      expect(info.audios.first.kbps, 129);
      expect(info.audios.last.codec, 'Opus');
    });

    test('hides storyboards', () {
      expect(info.videos.any((v) => v.ext == 'mhtml'), isFalse);
    });
  });

  group('combined streams (TikTok-style)', () {
    final info = load('combined.json');

    test('keeps streams that already have sound', () {
      expect(info.site, 'TikTok');
      expect(info.videos, hasLength(2));
      expect(info.videos.first.needsAudio, isFalse);
      expect(info.videos.first.selector, info.videos.first.formatId);
      expect(info.audios, isEmpty);
    });

    test('picks the higher-bitrate stream at the same resolution', () {
      expect(info.videos.first.formatId, 'h264_540p_1');
      expect(info.videos.first.label, '1024p');
    });

    test('drops unknown duplicate streams', () {
      expect(info.videos.any((v) => v.formatId == 'unknown_0'), isFalse);
    });
  });

  test('single-stream JSON without a formats list', () {
    final info = MediaInfo.fromJson({
      'id': 'x',
      'title': 'Clip',
      'url': 'https://cdn.example.com/clip.mp4',
      'ext': 'mp4',
      'extractor_key': 'Generic',
      'webpage_url_domain': 'example.com',
    });
    expect(info.videos, hasLength(1));
    expect(info.site, 'example.com');
  });

  group('formatting', () {
    test('bytes', () {
      expect(formatBytes(1300000000), '1.21 GB');
      expect(formatBytes(222298112), '212 MB');
      expect(formatBytes(4087349), '3.9 MB');
    });

    test('duration', () {
      expect(formatDuration(const Duration(minutes: 12, seconds: 8)), '12:08');
      expect(formatDuration(const Duration(seconds: 58)), '0:58');
      expect(
        formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
    });
  });

  group('error classification', () {
    test('real yt-dlp messages', () {
      expect(
        EngineError.from(
          'ERROR: [vimeo] 22439234: The web client only works when logged-in. '
          'Use --cookies, --cookies-from-browser',
        ).kind,
        EngineErrorKind.loginRequired,
      );
      expect(
        EngineError.from('ERROR: [dailymotion] x8j7jkw: Not found.').kind,
        EngineErrorKind.unavailable,
      );
      expect(
        EngineError.from('ERROR: Unsupported URL: https://example.com/').kind,
        EngineErrorKind.unsupported,
      );
      expect(
        EngineError.from(
          'ERROR: [generic] Unable to download webpage: <urlopen error '
          '[Errno 7] No address associated with hostname>',
        ).kind,
        EngineErrorKind.noInternet,
      );
      expect(
        EngineError.from('ERROR: something odd happened').suggestsUpdate,
        isTrue,
      );
    });
  });
}
