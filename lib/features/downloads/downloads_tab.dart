import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DownloadsTab { active, saved, failed }

/// A request to show a Downloads tab. Each request is a new object, so asking
/// for the same tab twice still switches back to it.
class DownloadsTabRequest {
  DownloadsTabRequest(this.tab);

  final DownloadsTab tab;
}

class DownloadsTabNotifier extends Notifier<DownloadsTabRequest> {
  @override
  DownloadsTabRequest build() => DownloadsTabRequest(DownloadsTab.active);

  void show(DownloadsTab tab) => state = DownloadsTabRequest(tab);
}

final downloadsTabProvider =
    NotifierProvider<DownloadsTabNotifier, DownloadsTabRequest>(
      DownloadsTabNotifier.new,
    );
