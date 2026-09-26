import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'engine.dart';

class VideoProbe {
  const VideoProbe({
    required this.uri,
    required this.name,
    required this.duration,
    this.width,
    this.height,
    this.size,
  });

  final String uri;
  final String name;
  final Duration duration;
  final int? width;
  final int? height;
  final int? size;
}

class SplitPart {
  const SplitPart({required this.uri, required this.path, required this.name});

  final String uri;

  /// e.g. `Movies/Kheench/Split/Family dinner/part-01.mp4`.
  final String path;
  final String name;

  String get folder =>
      path.contains('/') ? path.substring(0, path.lastIndexOf('/')) : path;
}

class SplitProgress {
  const SplitProgress(this.part, this.parts, this.percent);

  final int part;
  final int parts;

  /// Overall 0–100.
  final double percent;
}

/// Time ranges for each part. A last sliver shorter than a second joins the
/// part before it (same rule as SplitChannel.kt).
List<(Duration, Duration)> splitRanges(
  Duration start,
  Duration end,
  Duration part,
) {
  final out = <(Duration, Duration)>[];
  if (part < const Duration(seconds: 1)) part = const Duration(seconds: 1);
  var s = start;
  while (s < end) {
    var e = s + part;
    if (e > end) e = end;
    if (e - s < const Duration(seconds: 1) && out.isNotEmpty) {
      out[out.length - 1] = (out.last.$1, e);
    } else {
      out.add((s, e));
    }
    s = e;
  }
  return out;
}

/// Dart side of SplitChannel.kt.
class Splitter {
  static const _channel = MethodChannel('kheench/split');
  static const _events = EventChannel('kheench/split_progress');

  late final Stream<SplitProgress> progress = _events
      .receiveBroadcastStream()
      .map((e) {
        final m = e as Map<Object?, Object?>;
        return SplitProgress(
          (m['part'] as num).toInt(),
          (m['parts'] as num).toInt(),
          (m['percent'] as num).toDouble(),
        );
      });

  /// Opens the system picker; the video's uri, or null if cancelled.
  Future<String?> pickVideo() => _channel.invokeMethod<String>('pickVideo');

  Future<VideoProbe?> probe(String uri) async {
    final m = await _channel.invokeMapMethod<String, Object?>('probe', {
      'uri': uri,
    });
    final ms = (m?['durationMs'] as num?)?.toInt();
    if (m == null || ms == null || ms <= 0) return null;
    return VideoProbe(
      uri: uri,
      name: m['name'] as String? ?? 'video.mp4',
      duration: Duration(milliseconds: ms),
      width: (m['width'] as num?)?.toInt(),
      height: (m['height'] as num?)?.toInt(),
      size: (m['size'] as num?)?.toInt(),
    );
  }

  Future<List<SplitPart>> split({
    required VideoProbe video,
    required Duration part,
    required Duration trimStart,
    required Duration trimEnd,
  }) async {
    try {
      final list =
          await _channel.invokeListMethod<Object?>('split', {
            'uri': video.uri,
            'name': video.name,
            'partSeconds': part.inSeconds,
            'trimStartMs': trimStart.inMilliseconds,
            'trimEndMs': trimEnd.inMilliseconds,
          }) ??
          [];
      return [
        for (final m in list.whereType<Map<Object?, Object?>>())
          SplitPart(
            uri: m['uri'] as String,
            path: m['path'] as String,
            name: m['name'] as String,
          ),
      ];
    } on PlatformException catch (e) {
      throw EngineException(
        e.code == 'CANCELLED' ? 'Cancelled' : e.message ?? e.code,
      );
    }
  }

  Future<void> cancel() => _channel.invokeMethod<bool>('cancel');

  /// Shares parts in order; straight to WhatsApp when [whatsapp] is true.
  Future<bool> share(List<SplitPart> parts, {bool whatsapp = true}) async =>
      await _channel.invokeMethod<bool>('share', {
        'uris': [for (final p in parts) p.uri],
        'whatsapp': whatsapp,
      }) ??
      false;
}

final splitterProvider = Provider<Splitter>((_) => Splitter());
