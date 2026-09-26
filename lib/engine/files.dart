import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DeleteResult { deleted, cancelled, failed }

/// Opens, shares and deletes saved files (see FileChannel.kt).
class FileActions {
  static const _channel = MethodChannel('kheench/files');

  /// False when no app can open it, or the file is gone.
  Future<bool> open(String uri, String? mime) =>
      _bool('open', {'uri': uri, 'mime': mime});

  Future<bool> share(String uri, String? mime) =>
      _bool('share', {'uri': uri, 'mime': mime});

  /// [folder] like `Movies/Kheench`.
  Future<bool> openFolder(String folder) =>
      _bool('openFolder', {'folder': folder});

  Future<bool> exists(String uri) => _bool('exists', {'uri': uri});

  Future<DeleteResult> delete(String uri) async {
    var status = await _channel.invokeMethod<String>('delete', {'uri': uri});
    // The user approved deleting a file from an earlier install; try again.
    if (status == 'confirm') {
      status = await _channel.invokeMethod<String>('delete', {'uri': uri});
    }
    return switch (status) {
      'deleted' => DeleteResult.deleted,
      'cancelled' => DeleteResult.cancelled,
      _ => DeleteResult.failed,
    };
  }

  Future<bool> _bool(String method, Map<String, Object?> args) async {
    try {
      return await _channel.invokeMethod<bool>(method, args) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

final fileActionsProvider = Provider<FileActions>((_) => FileActions());
