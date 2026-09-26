import '../../engine/download_choice.dart';
import '../../engine/media_info.dart';
import '../settings/settings_providers.dart';

/// The download to start without asking, or null when the user wants to pick.
///
/// 1080p / 720p take that quality or the closest lower one; if a site only
/// has higher qualities, the lowest available is used.
DownloadChoice? choiceForDefault(MediaInfo info, AppSettings settings) {
  switch (settings.defaultQuality) {
    case DefaultQuality.ask:
      return null;
    case DefaultQuality.best:
      return DownloadChoice.best(info);
    case DefaultQuality.audio:
      return settings.audioFormat == AudioFormat.mp3
          ? DownloadChoice.mp3(info)
          : DownloadChoice.m4a(info);
    case DefaultQuality.p1080:
      return _atMost(info, 1080);
    case DefaultQuality.p720:
      return _atMost(info, 720);
  }
}

DownloadChoice _atMost(MediaInfo info, int height) {
  if (info.videos.isEmpty) return DownloadChoice.best(info);
  // Videos are sorted best first, so the first one that fits is the closest.
  final fit = info.videos.where((v) => v.height <= height).firstOrNull;
  return DownloadChoice.video(fit ?? info.videos.last);
}
