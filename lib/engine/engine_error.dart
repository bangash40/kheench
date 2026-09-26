/// User-facing categories for engine failures.
enum EngineErrorKind {
  unsupported,
  loginRequired,
  noInternet,
  unavailable,
  unknown,
}

class EngineError {
  const EngineError(this.kind, this.raw, {this.custom});

  /// Prefix native code uses for messages meant for the user as they are.
  static const userMessagePrefix = 'KHEENCH:';

  /// A ready-to-show message from Kheench itself.
  final String? custom;

  final EngineErrorKind kind;

  /// Original yt-dlp message, for "details".
  final String raw;

  factory EngineError.from(String message) {
    // Messages Kheench wrote for the user are shown as they are.
    final own = message.indexOf(userMessagePrefix);
    if (own >= 0) {
      return EngineError(
        EngineErrorKind.unknown,
        message,
        custom: message.substring(own + userMessagePrefix.length).trim(),
      );
    }
    final m = message.toLowerCase();
    bool has(List<String> words) => words.any(m.contains);

    final kind = has(['unsupported url', 'no suitable extractor'])
        ? EngineErrorKind.unsupported
        : has([
            'logged-in',
            'log in',
            'login',
            'cookies',
            'private',
            'sign in to confirm',
            'authentication',
          ])
        ? EngineErrorKind.loginRequired
        : has([
            'unable to download webpage',
            'getaddrinfo',
            'failed to resolve',
            'name or service not known',
            'network is unreachable',
            'timed out',
            'connection reset',
            'no address associated',
          ])
        ? EngineErrorKind.noInternet
        : has([
            'not found',
            'http error 404',
            'http error 410',
            'not available',
            'unavailable',
            'removed',
            'deleted',
            'expired',
            'does not exist',
          ])
        ? EngineErrorKind.unavailable
        : EngineErrorKind.unknown;
    return EngineError(kind, message);
  }

  String get title => custom != null
      ? "Couldn't load this link"
      : switch (kind) {
          EngineErrorKind.unsupported => 'This site isn\'t supported',
          EngineErrorKind.loginRequired => 'Login needed',
          EngineErrorKind.noInternet => 'No internet connection',
          EngineErrorKind.unavailable => 'Link expired or removed',
          EngineErrorKind.unknown => 'Couldn\'t load this link',
        };

  String get message =>
      custom ??
      switch (kind) {
        EngineErrorKind.unsupported => 'Kheench can\'t read videos from this link. Check it opens a video or post.',
        EngineErrorKind.loginRequired => 'Only visible when logged in. Log in under Tools → Accounts, then try again.',
        EngineErrorKind.noInternet => 'Check your connection and try again.',
        EngineErrorKind.unavailable =>
          'The post may be private, deleted, or the link has expired.',
        EngineErrorKind.unknown => 'The site may have changed. Updating the download engine often fixes this.',
      };

  /// Whether "Update engine" is a sensible next step.
  bool get suggestsUpdate => custom == null && kind == EngineErrorKind.unknown;
}
