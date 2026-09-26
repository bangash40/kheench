import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Platform {
  instagram('Instagram'),
  facebook('Facebook'),
  x('X'),
  tiktok('TikTok');

  const Platform(this.label);
  final String label;
}

/// Dart side of AccountsChannel.kt.
class Accounts {
  static const _channel = MethodChannel('kheench/accounts');

  /// When each platform was logged in, or null if it isn't.
  Future<Map<Platform, DateTime?>> status() async {
    final raw =
        await _channel.invokeMapMethod<String, Object?>('status') ?? const {};
    return {
      for (final p in Platform.values)
        p: switch (raw[p.name]) {
          final num ms => DateTime.fromMillisecondsSinceEpoch(ms.toInt()),
          _ => null,
        },
    };
  }

  /// Opens the platform's login page; true once a session was saved.
  Future<bool> login(Platform p) async =>
      await _channel.invokeMethod<bool>('login', {'platform': p.name}) ?? false;

  Future<void> logout(Platform p) =>
      _channel.invokeMethod<bool>('logout', {'platform': p.name});
}

final accountsProvider = Provider<Accounts>((_) => Accounts());

final accountStatusProvider = FutureProvider<Map<Platform, DateTime?>>(
  (ref) => ref.watch(accountsProvider).status(),
);
