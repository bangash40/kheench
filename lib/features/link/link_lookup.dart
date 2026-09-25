import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/engine.dart';
import '../../engine/engine_error.dart';
import '../../engine/media_info.dart';

sealed class LookupState {
  const LookupState();
}

class LookupIdle extends LookupState {
  const LookupIdle();
}

class LookupLoading extends LookupState {
  const LookupLoading(this.url);
  final String url;
}

class LookupLoaded extends LookupState {
  const LookupLoaded(this.url, this.info);
  final String url;
  final MediaInfo info;
}

class LookupFailed extends LookupState {
  const LookupFailed(this.url, this.error);
  final String url;
  final EngineError error;
}

/// Fetches a link's details and formats for the Home preview.
class LinkLookup extends Notifier<LookupState> {
  int _request = 0;

  @override
  LookupState build() => const LookupIdle();

  Future<void> fetch(String url) async {
    final request = ++_request;
    state = LookupLoading(url);
    LookupState next;
    try {
      final json = await ref.read(engineProvider).fetchInfoJson(url);
      // YouTube JSON can be several hundred KB; parse off the UI thread.
      final info = await compute(MediaInfo.fromJsonString, json);
      next = LookupLoaded(url, info);
    } on EngineException catch (e) {
      next = LookupFailed(url, EngineError.from(e.message));
    } catch (e) {
      next = LookupFailed(url, EngineError(EngineErrorKind.unknown, '$e'));
    }
    if (request == _request) state = next;
  }

  void clear() {
    _request++;
    state = const LookupIdle();
  }
}

final linkLookupProvider = NotifierProvider<LinkLookup, LookupState>(
  LinkLookup.new,
);
