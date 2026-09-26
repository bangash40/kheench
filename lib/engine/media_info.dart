import 'dart:convert';

/// What the user can pick in the quality sheet, parsed from yt-dlp JSON.
class MediaInfo {
  const MediaInfo({
    required this.id,
    required this.title,
    required this.url,
    required this.site,
    required this.videos,
    required this.audios,
    this.uploader,
    this.duration,
    this.thumbnail,
    this.isLive = false,
  });

  final String id;
  final String title;
  final String url;
  final String site;
  final String? uploader;
  final Duration? duration;
  final String? thumbnail;
  final bool isLive;

  /// One entry per resolution/frame rate, best first.
  final List<VideoOption> videos;

  /// One entry per audio container, best first.
  final List<AudioOption> audios;

  VideoOption? get bestVideo => videos.isEmpty ? null : videos.first;
  AudioOption? get bestAudio => audios.isEmpty ? null : audios.first;

  factory MediaInfo.fromJsonString(String source) =>
      MediaInfo.fromJson(jsonDecode(source) as Map<String, dynamic>);

  factory MediaInfo.fromJson(Map<String, dynamic> json) {
    final seconds = _num(json['duration']);
    final duration = seconds == null
        ? null
        : Duration(milliseconds: (seconds * 1000).round());

    var rawFormats =
        (json['formats'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(_RawFormat.new)
            .toList() ??
        const <_RawFormat>[];
    // Some extractors return a single stream on the top-level object.
    if (rawFormats.isEmpty && json['url'] != null) {
      rawFormats = [_RawFormat(json)];
    }

    final audios = _pickAudios(rawFormats, seconds);
    final videos = _pickVideos(rawFormats, seconds, audios);

    return MediaInfo(
      id: '${json['id'] ?? ''}',
      title: _str(json['title']) ?? _str(json['id']) ?? 'Untitled',
      url: _str(json['webpage_url']) ?? _str(json['original_url']) ?? '',
      site: siteName(
        _str(json['extractor_key']),
        _str(json['webpage_url_domain']),
      ),
      uploader: _str(json['uploader']) ?? _str(json['channel']),
      duration: duration,
      thumbnail: _str(json['thumbnail']),
      isLive: json['is_live'] == true,
      videos: videos,
      audios: audios,
    );
  }
}

class VideoOption {
  const VideoOption({
    required this.formatId,
    required this.label,
    required this.ext,
    required this.codec,
    required this.needsAudio,
    required this.height,
    this.fps,
    this.sizeBytes,
    this.sizeIsEstimate = false,
    this.mergeAudio,
    this.watermarked = false,
  });

  final String formatId;

  /// e.g. `1080p60`.
  final String label;
  final String ext;

  /// Friendly codec name, e.g. `H.264`, or null when unknown.
  final String? codec;

  /// True when the stream has no sound and audio gets merged in.
  final bool needsAudio;
  final int height;
  final int? fps;

  /// Total size including merged audio, when known.
  final int? sizeBytes;
  final bool sizeIsEstimate;

  /// Audio stream that will be merged in, when [needsAudio].
  final AudioOption? mergeAudio;

  /// TikTok's original with the logo burned in (offered as an extra option).
  final bool watermarked;

  String get container => ext.toUpperCase();

  /// yt-dlp `-f` value for this choice.
  String get selector {
    if (!needsAudio) return formatId;
    final preferred = ext == 'webm' ? 'webm' : 'm4a';
    return '$formatId+bestaudio[ext=$preferred]/$formatId+bestaudio';
  }
}

class AudioOption {
  const AudioOption({
    required this.formatId,
    required this.ext,
    this.codec,
    this.kbps,
    this.sizeBytes,
    this.sizeIsEstimate = false,
  });

  final String formatId;
  final String ext;
  final String? codec;
  final int? kbps;
  final int? sizeBytes;
  final bool sizeIsEstimate;

  String get container => ext.toUpperCase();
  String get selector => formatId;
}

/// Friendly site name from yt-dlp's extractor key or domain.
String siteName(String? extractorKey, String? domain) {
  const known = {
    'youtube': 'YouTube',
    'youtubetab': 'YouTube',
    'instagram': 'Instagram',
    'instagramstory': 'Instagram',
    'tiktok': 'TikTok',
    'facebook': 'Facebook',
    'facebookreel': 'Facebook',
    'twitter': 'X',
    'snapchatspotlight': 'Snapchat',
    'reddit': 'Reddit',
    'vimeo': 'Vimeo',
    'dailymotion': 'Dailymotion',
    'twitch': 'Twitch',
    'soundcloud': 'SoundCloud',
    'pinterest': 'Pinterest',
    'linkedin': 'LinkedIn',
  };
  final key = extractorKey?.toLowerCase();
  if (key != null && known.containsKey(key)) return known[key]!;
  if (domain != null && domain.isNotEmpty) return domain;
  return extractorKey ?? 'Web';
}

/// Size in MB/GB for display, e.g. `212 MB`, `1.21 GB`.
String formatBytes(int bytes) {
  const mb = 1024 * 1024;
  const gb = mb * 1024;
  if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(2)} GB';
  final m = bytes / mb;
  if (m >= 100) return '${m.round()} MB';
  return '${m.toStringAsFixed(1)} MB';
}

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}

// ---------------------------------------------------------------------------

class _RawFormat {
  _RawFormat(Map<String, dynamic> j)
    : id = '${j['format_id'] ?? j['id'] ?? 'best'}',
      ext = (_str(j['ext']) ?? 'mp4').toLowerCase(),
      vcodec = _str(j['vcodec']),
      acodec = _str(j['acodec']),
      height = _num(j['height'])?.round(),
      fps = _num(j['fps'])?.round(),
      filesize = _num(j['filesize'])?.round(),
      filesizeApprox = _num(j['filesize_approx'])?.round(),
      tbr = _num(j['tbr']),
      abr = _num(j['abr']),
      protocol = _str(j['protocol']) ?? 'https',
      note = _str(j['format_note']);

  final String id;
  final String ext;
  final String? vcodec;
  final String? acodec;
  final int? height;
  final int? fps;
  final int? filesize;
  final int? filesizeApprox;
  final double? tbr;
  final double? abr;
  final String protocol;
  final String? note;

  bool get isStoryboard => ext == 'mhtml' || note == 'storyboard';
  bool get hasVideo => vcodec != 'none';
  bool get hasAudio => acodec != 'none';
  bool get isDirect =>
      protocol.startsWith('http') && !protocol.contains('m3u8');
  bool get isDrc => id.endsWith('-drc');
  bool get isWatermarked => note?.toLowerCase() == 'watermarked';

  /// (bytes, isEstimate)
  (int?, bool) size(double? durationSeconds) {
    if (filesize != null) return (filesize, false);
    if (filesizeApprox != null) return (filesizeApprox, true);
    final rate = tbr ?? abr;
    if (rate != null && durationSeconds != null && rate > 0) {
      return ((rate * 1000 / 8 * durationSeconds).round(), true);
    }
    return (null, false);
  }
}

List<AudioOption> _pickAudios(List<_RawFormat> formats, double? seconds) {
  final best = <String, _RawFormat>{};
  bool isAudio(_RawFormat f) => !f.isStoryboard && !f.hasVideo && f.hasAudio;
  // Streamed-only (HLS) audio is a poor pick when direct files exist.
  final hasDirect = formats.any((f) => isAudio(f) && f.isDirect);
  for (final f in formats) {
    if (!isAudio(f) || (hasDirect && !f.isDirect)) continue;
    final current = best[f.ext];
    if (current == null || _audioScore(f) > _audioScore(current)) {
      best[f.ext] = f;
    }
  }
  final options = best.values.map((f) {
    final (bytes, estimate) = f.size(seconds);
    return AudioOption(
      formatId: f.id,
      ext: f.ext,
      codec: _codecName(f.acodec),
      kbps: (f.abr ?? f.tbr)?.round(),
      sizeBytes: bytes,
      sizeIsEstimate: estimate,
    );
  }).toList()..sort((a, b) => (b.kbps ?? 0).compareTo(a.kbps ?? 0));
  return options;
}

double _audioScore(_RawFormat f) =>
    (f.abr ?? f.tbr ?? 0) + (f.isDirect ? 100000 : 0) + (f.isDrc ? -50000 : 0);

List<VideoOption> _pickVideos(
  List<_RawFormat> formats,
  double? seconds,
  List<AudioOption> audios,
) {
  final best = <String, _RawFormat>{};
  for (final f in formats) {
    if (f.isStoryboard || !f.hasVideo) continue;
    // Streams with unknown codecs and no resolution are usually duplicates.
    if (f.vcodec == null && f.acodec == null && f.height == null) {
      if (formats.any((o) => o != f && o.hasVideo && o.height != null)) {
        continue;
      }
    }
    // Watermarked copies are kept as their own option, not merged away.
    final key =
        '${f.height ?? 0}@${_fpsBucket(f.fps)}${f.isWatermarked ? '-wm' : ''}';
    final current = best[key];
    if (current == null || _videoScore(f) > _videoScore(current)) {
      best[key] = f;
    }
  }

  AudioOption? audioFor(String ext) {
    final wanted = ext == 'webm' ? 'webm' : 'm4a';
    return audios.where((a) => a.ext == wanted).firstOrNull ??
        audios.firstOrNull;
  }

  final options =
      best.values.map((f) {
        final needsAudio = f.acodec == 'none';
        final merge = needsAudio ? audioFor(f.ext) : null;
        var (bytes, estimate) = f.size(seconds);
        if (bytes != null && merge?.sizeBytes != null) {
          bytes += merge!.sizeBytes!;
          estimate = estimate || merge.sizeIsEstimate;
        }
        final fps = _fpsBucket(f.fps);
        return VideoOption(
          formatId: f.id,
          label: f.height == null
              ? (f.note ?? 'Video')
              : '${f.height}p${fps > 30 ? fps : ''}',
          ext: f.ext,
          codec: _codecName(f.vcodec),
          needsAudio: needsAudio,
          height: f.height ?? 0,
          fps: f.fps,
          sizeBytes: bytes,
          sizeIsEstimate: estimate,
          mergeAudio: merge,
          watermarked: f.isWatermarked,
        );
      }).toList()..sort((a, b) {
        // Watermarked copies go last so they're never the default pick.
        if (a.watermarked != b.watermarked) return a.watermarked ? 1 : -1;
        final h = b.height.compareTo(a.height);
        return h != 0 ? h : (b.fps ?? 0).compareTo(a.fps ?? 0);
      });
  return options;
}

int _fpsBucket(int? fps) => fps == null || fps <= 30 ? 30 : fps;

/// Prefers direct downloads, then codecs the phone plays best, then bitrate.
double _videoScore(_RawFormat f) {
  final codec = f.vcodec ?? '';
  final codecRank = codec.startsWith('avc') || codec == 'h264'
      ? 3
      : codec.startsWith('vp9') || codec.startsWith('vp09')
      ? 2
      : codec.startsWith('av01')
      ? 1
      : 2;
  return (f.isDirect ? 1e9 : 0) +
      codecRank * 1e7 +
      (f.hasAudio ? 1e6 : 0) +
      (f.tbr ?? 0);
}

String? _codecName(String? codec) {
  if (codec == null || codec == 'none') return null;
  final c = codec.toLowerCase();
  if (c.startsWith('avc') || c == 'h264') return 'H.264';
  if (c.startsWith('hev') || c.startsWith('hvc') || c == 'h265') return 'HEVC';
  if (c.startsWith('vp09') || c.startsWith('vp9')) return 'VP9';
  if (c.startsWith('av01')) return 'AV1';
  if (c.startsWith('mp4a') || c == 'aac') return 'AAC';
  if (c.startsWith('opus')) return 'Opus';
  if (c.startsWith('vorbis')) return 'Vorbis';
  if (c.startsWith('mp3')) return 'MP3';
  return codec;
}

String? _str(Object? v) {
  if (v == null) return null;
  final s = '$v'.trim();
  return s.isEmpty ? null : s;
}

double? _num(Object? v) => switch (v) {
  num n => n.toDouble(),
  String s => double.tryParse(s),
  _ => null,
};
