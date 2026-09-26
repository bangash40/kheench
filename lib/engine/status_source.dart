import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum StatusApp {
  whatsapp('WhatsApp'),
  business('WhatsApp Business');

  const StatusApp(this.label);
  final String label;
}

enum StatusType { video, photo }

class StatusItem {
  const StatusItem({
    required this.uri,
    required this.name,
    required this.type,
    required this.modified,
    required this.size,
  });

  final String uri;
  final String name;
  final StatusType type;
  final DateTime modified;
  final int size;

  /// Identifies this status across refreshes, for the "Saved" badge.
  String hashFor(StatusApp app) => '${app.name}|$name|$size';

  factory StatusItem.fromMap(Map<Object?, Object?> m) => StatusItem(
    uri: m['uri'] as String,
    name: m['name'] as String,
    type: m['type'] == 'video' ? StatusType.video : StatusType.photo,
    modified: DateTime.fromMillisecondsSinceEpoch(
      (m['modified'] as num).toInt(),
    ),
    size: (m['size'] as num?)?.toInt() ?? 0,
  );
}

class StatusThumb {
  const StatusThumb(this.path, this.duration);

  final String path;
  final Duration? duration;
}

class StatusAccess {
  const StatusAccess({
    required this.granted,
    required this.installed,
    required this.usesFolderPicker,
    required this.needsFolderPicker,
    required this.folder,
  });

  final bool granted;
  final bool installed;

  /// True when access came through the system folder picker (Android 11+).
  final bool usesFolderPicker;

  /// True on Android 11+, where the folder picker is the only way in.
  final bool needsFolderPicker;

  /// e.g. `Android/media/com.whatsapp/WhatsApp/Media/.Statuses`.
  final String folder;
}

/// Dart side of StatusChannel.kt.
class StatusSource {
  static const _channel = MethodChannel('kheench/status');

  Future<StatusAccess> access(StatusApp app) async {
    final m = await _channel.invokeMapMethod<String, Object?>('access', {
      'app': app.name,
    });
    return StatusAccess(
      granted: m?['granted'] == true,
      installed: m?['installed'] == true,
      usesFolderPicker: m?['mode'] == 'saf',
      needsFolderPicker: m?['needsPicker'] == true,
      folder: m?['folder'] as String? ?? '',
    );
  }

  /// Asks for access the normal way for this Android version.
  Future<bool> request(StatusApp app) async =>
      await _channel.invokeMethod<bool>('request', {'app': app.name}) ?? false;

  /// Lets the user choose the status folder by hand.
  Future<bool> pickFolder(StatusApp app) async =>
      await _channel.invokeMethod<bool>('pickFolder', {'app': app.name}) ??
      false;

  Future<List<StatusItem>> list(StatusApp app) async {
    final list =
        await _channel.invokeListMethod<Object?>('list', {'app': app.name}) ??
        [];
    return [
      for (final m in list.whereType<Map<Object?, Object?>>())
        StatusItem.fromMap(m),
    ];
  }

  /// Small JPEG preview (and video length), or null if it couldn't be made.
  Future<StatusThumb?> thumbnail(String uri, StatusType type) async {
    final m = await _channel.invokeMapMethod<String, Object?>('thumbnail', {
      'uri': uri,
      'type': type.name,
    });
    if (m == null || m['path'] == null) return null;
    final ms = (m['durationMs'] as num?)?.toInt();
    return StatusThumb(
      m['path'] as String,
      ms == null ? null : Duration(milliseconds: ms),
    );
  }

  /// Copies [items] into Movies/Kheench/Status and Pictures/Kheench/Status.
  /// Returns the uris that were saved.
  Future<List<String>> save(List<StatusItem> items) async {
    final results =
        await _channel.invokeListMethod<Object?>('save', {
          'items': [
            for (final i in items)
              {
                'uri': i.uri,
                'name': i.name,
                'type': i.type.name,
                'size': i.size,
              },
          ],
        }) ??
        [];
    return [
      for (final r in results.whereType<Map<Object?, Object?>>())
        if (r['ok'] == true) r['uri'] as String,
    ];
  }

  /// A local file path for showing [uri] full screen.
  Future<String?> localCopy(String uri) =>
      _channel.invokeMethod<String>('localCopy', {'uri': uri});
}

final statusSourceProvider = Provider<StatusSource>((_) => StatusSource());

class SelectedStatusApp extends Notifier<StatusApp> {
  @override
  StatusApp build() => StatusApp.whatsapp;

  void set(StatusApp app) => state = app;
}

final statusAppProvider = NotifierProvider<SelectedStatusApp, StatusApp>(
  SelectedStatusApp.new,
);

final statusAccessProvider = FutureProvider.family<StatusAccess, StatusApp>(
  (ref, app) => ref.watch(statusSourceProvider).access(app),
);

final statusItemsProvider = FutureProvider.family<List<StatusItem>, StatusApp>((
  ref,
  app,
) async {
  final access = await ref.watch(statusAccessProvider(app).future);
  if (!access.granted) return const [];
  return ref.watch(statusSourceProvider).list(app);
});

final statusThumbProvider =
    FutureProvider.family<StatusThumb?, (String, StatusType)>(
      (ref, key) => ref.watch(statusSourceProvider).thumbnail(key.$1, key.$2),
    );
