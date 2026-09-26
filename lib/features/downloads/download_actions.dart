import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/database.dart';
import '../../engine/files.dart';
import 'downloads_controller.dart';

void _snack(BuildContext context, String message, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), action: action, persist: false),
    );
}

/// Folder part of a saved path, e.g. `Movies/Kheench`.
String folderOf(Download d) {
  final path = d.filePath;
  if (path == null || !path.contains('/')) {
    return d.kind == 'audio' ? 'Music/Kheench' : 'Movies/Kheench';
  }
  return path.substring(0, path.lastIndexOf('/'));
}

Future<void> playDownload(
  BuildContext context,
  WidgetRef ref,
  Download d,
) async {
  final uri = d.uri;
  if (uri == null) return;
  final files = ref.read(fileActionsProvider);
  if (await files.open(uri, d.mime)) return;
  if (!context.mounted) return;
  await _explainFailure(context, ref, d);
}

Future<void> shareDownload(
  BuildContext context,
  WidgetRef ref,
  Download d,
) async {
  final uri = d.uri;
  if (uri == null) return;
  final files = ref.read(fileActionsProvider);
  if (await files.share(uri, d.mime)) return;
  if (!context.mounted) return;
  await _explainFailure(context, ref, d);
}

Future<void> _explainFailure(
  BuildContext context,
  WidgetRef ref,
  Download d,
) async {
  final exists = await ref.read(fileActionsProvider).exists(d.uri!);
  if (!context.mounted) return;
  if (exists) {
    _snack(context, 'No app on this phone can open this file');
    return;
  }
  _snack(
    context,
    'This file was deleted or moved',
    action: SnackBarAction(
      label: 'Remove',
      textColor: KColors.saffron,
      onPressed: () => ref.read(downloadsControllerProvider).forget(d.id),
    ),
  );
}

Future<void> openDownloadFolder(
  BuildContext context,
  WidgetRef ref,
  Download d,
) async {
  final folder = folderOf(d);
  if (await ref.read(fileActionsProvider).openFolder(folder)) return;
  if (context.mounted) _snack(context, 'Saved in $folder');
}

Future<void> deleteDownloadFile(
  BuildContext context,
  WidgetRef ref,
  Download d,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete file?'),
      content: Text('"${d.title}" will be removed from your phone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: KColors.error),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  final uri = d.uri;
  final result = uri == null
      ? DeleteResult.deleted
      : await ref.read(fileActionsProvider).delete(uri);
  if (!context.mounted) return;
  switch (result) {
    case DeleteResult.deleted:
      await ref.read(downloadsControllerProvider).forget(d.id);
      if (context.mounted) _snack(context, 'File deleted');
    case DeleteResult.cancelled:
      break;
    case DeleteResult.failed:
      _snack(context, "Couldn't delete this file");
  }
}

/// Bottom sheet with every action for a saved download.
Future<void> showDownloadActions(
  BuildContext context,
  WidgetRef ref,
  Download d,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) {
      Widget tile(
        IconData icon,
        String label,
        VoidCallback onTap, {
        Color? color,
      }) {
        return ListTile(
          minTileHeight: 52,
          leading: Icon(icon, color: color ?? sheet.k.teal),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color ?? sheet.k.text,
            ),
          ),
          onTap: () {
            Navigator.pop(sheet);
            onTap();
          },
        );
      }

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                d.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(sheet).textTheme.titleMedium,
              ),
            ),
            tile(
              Icons.play_arrow_rounded,
              'Play',
              () => playDownload(context, ref, d),
            ),
            tile(
              Icons.share_outlined,
              'Share',
              () => shareDownload(context, ref, d),
            ),
            tile(
              Icons.folder_open_rounded,
              'Open folder',
              () => openDownloadFolder(context, ref, d),
            ),
            tile(
              Icons.playlist_remove_rounded,
              'Remove from list',
              () => ref.read(downloadsControllerProvider).forget(d.id),
            ),
            tile(
              Icons.delete_outline_rounded,
              'Delete file',
              () => deleteDownloadFile(context, ref, d),
              color: KColors.error,
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
