import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kheench/data/database.dart';
import 'package:kheench/features/link/clipboard_offer.dart';
import 'package:kheench/features/settings/settings_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late AppDatabase db;
  late ProviderContainer container;
  var mayHaveLink = true;
  var stamp = 1;
  var clipboard = 'look https://youtu.be/abc';
  var reads = 0;

  setUp(() {
    mayHaveLink = true;
    stamp = 1;
    clipboard = 'look https://youtu.be/abc';
    reads = 0;
    messenger.setMockMethodCallHandler(const MethodChannel('kheench/share'), (
      call,
    ) async {
      if (call.method == 'clipboardHint') {
        return {'mayHaveLink': mayHaveLink, 'stamp': stamp};
      }
      return null;
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') {
        reads++;
        return {'text': clipboard};
      }
      return null;
    });
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  ClipboardOffer offer() => container.read(clipboardOfferProvider.notifier);
  String? offered() => container.read(clipboardOfferProvider);

  test('offers the link found on the clipboard', () async {
    await offer().check();
    expect(offered(), 'https://youtu.be/abc');
  });

  test('reads each clip only once (no repeated clipboard toasts)', () async {
    await offer().check();
    await offer().check();
    expect(reads, 1);
  });

  test(
    "doesn't read the clipboard when Android says there's no link",
    () async {
      mayHaveLink = false;
      await offer().check();
      expect(reads, 0);
      expect(offered(), isNull);
    },
  );

  test('a dismissed link is never offered again', () async {
    await offer().check();
    await offer().done();
    expect(offered(), isNull);

    stamp = 2; // copied again
    await offer().check();
    expect(offered(), isNull);

    clipboard = 'https://vimeo.com/1';
    stamp = 3;
    await offer().check();
    expect(offered(), 'https://vimeo.com/1');
  });

  test('skips the link already in the text field', () async {
    await offer().check(currentText: 'https://youtu.be/abc');
    expect(offered(), isNull);
  });

  test('does nothing when the setting is off', () async {
    container.read(settingsProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await container
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(clipboardDetection: false));
    await offer().check();
    expect(reads, 0);
    expect(offered(), isNull);
  });
}
