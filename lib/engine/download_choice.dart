import 'media_info.dart';

enum DownloadKind { video, audio }

/// What the user picked in the quality sheet, as yt-dlp arguments.
class DownloadChoice {
  const DownloadChoice._({
    required this.id,
    required this.label,
    required this.kind,
    required this.selector,
    this.extraArgs = const [],
    this.sizeBytes,
    this.sizeIsEstimate = false,
  });

  /// Stable key so the sheet can tell which row is selected.
  final String id;

  /// e.g. `1080p60 MP4`, `MP3 audio`.
  final String label;
  final DownloadKind kind;
  final String selector;
  final List<String> extraArgs;
  final int? sizeBytes;
  final bool sizeIsEstimate;

  static const _merge = ['--merge-output-format', 'mp4/mkv'];

  factory DownloadChoice.best(MediaInfo info) {
    final top = info.bestVideo;
    return DownloadChoice._(
      id: 'best',
      label: top == null ? 'Best quality' : '${top.label} ${top.container}',
      kind: DownloadKind.video,
      selector: 'bv*+ba/b',
      extraArgs: _merge,
      sizeBytes: top?.sizeBytes,
      sizeIsEstimate: top?.sizeIsEstimate ?? false,
    );
  }

  factory DownloadChoice.mp3(MediaInfo info) => DownloadChoice._(
    id: 'mp3',
    label: 'MP3 audio',
    kind: DownloadKind.audio,
    selector: 'ba/b',
    extraArgs: const ['-x', '--audio-format', 'mp3', '--audio-quality', '0'],
    sizeBytes: info.bestAudio?.sizeBytes,
    sizeIsEstimate: true,
  );

  factory DownloadChoice.video(VideoOption v) => DownloadChoice._(
    id: 'v:${v.formatId}',
    label: '${v.label} ${v.container}',
    kind: DownloadKind.video,
    selector: v.selector,
    extraArgs: v.needsAudio ? _merge : const [],
    sizeBytes: v.sizeBytes,
    sizeIsEstimate: v.sizeIsEstimate,
  );

  factory DownloadChoice.audio(AudioOption a) => DownloadChoice._(
    id: 'a:${a.formatId}',
    label: '${a.kbps != null ? '${a.kbps} kbps ' : ''}${a.container}',
    kind: DownloadKind.audio,
    selector: a.selector,
    sizeBytes: a.sizeBytes,
    sizeIsEstimate: a.sizeIsEstimate,
  );

  /// e.g. `212 MB` or `~212 MB`, or null when unknown.
  String? get sizeText => sizeBytes == null
      ? null
      : '${sizeIsEstimate ? '~' : ''}${formatBytes(sizeBytes!)}';
}
