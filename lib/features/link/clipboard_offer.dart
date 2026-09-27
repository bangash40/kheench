import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../settings/settings_providers.dart';
import 'link_text.dart';

/// "Link found on clipboard": the link on offer, or null.
///
/// Android 12+ shows a "pasted from your clipboard" toast whenever an app
/// reads it, so the clipboard is only read when Android says (without
/// reading) that it changed and may hold a link. A link the user opened or
/// dismissed is never offered again.
class ClipboardOffer extends Notifier<String?> {
  static const _channel = MethodChannel('kheench/share');
  static const _seenKey = 'clipboardSeen';

  int? _lastStamp;
  bool _checking = false;

  @override
  String? build() => null;

  Future<void> check({String? currentText}) async {
    if (_checking || !ref.read(settingsProvider).clipboardDetection) return;
    _checking = true;
    try {
      final hint = await _channel.invokeMapMethod<String, Object?>(
        'clipboardHint',
      );
      if (hint == null || hint['mayHaveLink'] != true) return;
      final stamp = (hint['stamp'] as num?)?.toInt();
      if (stamp != null && stamp == _lastStamp) return;
      _lastStamp = stamp;

      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final url = extractUrl(data?.text ?? '');
      if (url == null || url == currentText?.trim()) return;
      final seen = (await ref.read(databaseProvider).readSettings())[_seenKey];
      if (url == seen) return;
      state = url;
    } on MissingPluginException {
      // Not on Android (tests).
    } catch (_) {
      // The clipboard can be unavailable (e.g. not focused yet); try next time.
    } finally {
      _checking = false;
    }
  }

  /// The user opened or dismissed the offer; don't offer this link again.
  Future<void> done() async {
    final url = state;
    state = null;
    if (url != null) {
      await ref.read(databaseProvider).writeSetting(_seenKey, url);
    }
  }
}

final clipboardOfferProvider = NotifierProvider<ClipboardOffer, String?>(
  ClipboardOffer.new,
);
