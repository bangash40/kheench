import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Text shared into Kheench from another app, waiting for Home to use it.
class SharedLink extends Notifier<String?> {
  static const _channel = MethodChannel('kheench/share');

  @override
  String? build() {
    // Shares while the app is open arrive as calls from MainActivity.
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'shared' && call.arguments is String) {
        receive(call.arguments as String);
      }
    });
    _takePending();
    return null;
  }

  /// A share that launched the app arrives before Flutter is listening.
  Future<void> _takePending() async {
    try {
      final text = await _channel.invokeMethod<String>('takePending');
      if (text != null && text.isNotEmpty) receive(text);
    } on MissingPluginException {
      // Not on Android (tests).
    }
  }

  void receive(String text) => state = text;

  /// Home took the link.
  void clear() => state = null;
}

final sharedLinkProvider = NotifierProvider<SharedLink, String?>(
  SharedLink.new,
);
