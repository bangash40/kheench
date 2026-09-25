import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EngineException implements Exception {
  const EngineException(this.message);

  final String message;

  @override
  String toString() => message;
}

enum EngineUpdateResult { updated, alreadyUpToDate }

/// Dart side of the native yt-dlp bridge (see EngineChannel.kt).
class Engine {
  static const _channel = MethodChannel('kheench/engine');

  /// Unpacks the engine if needed and returns the yt-dlp version.
  Future<String> prepare() => _call<String>('prepare');

  /// Raw `yt-dlp --dump-single-json` output for [url].
  Future<String> fetchInfoJson(String url) =>
      _call<String>('fetchInfo', {'url': url});

  Future<EngineUpdateResult> update() async {
    final status = await _call<String>('updateEngine');
    return status == 'DONE'
        ? EngineUpdateResult.updated
        : EngineUpdateResult.alreadyUpToDate;
  }

  Future<T> _call<T>(String method, [Map<String, Object?>? args]) async {
    try {
      final value = await _channel.invokeMethod<T>(method, args);
      if (value == null) throw const EngineException('Engine returned nothing');
      return value;
    } on PlatformException catch (e) {
      throw EngineException(e.message ?? e.code);
    } on MissingPluginException {
      throw const EngineException('Engine is only available on Android');
    }
  }
}

final engineProvider = Provider<Engine>((_) => Engine());

/// Installed yt-dlp version; also warms up the engine on first read.
final engineVersionProvider = FutureProvider<String>(
  (ref) => ref.watch(engineProvider).prepare(),
);
