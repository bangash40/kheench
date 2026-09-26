import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/database.dart';
import '../../engine/accounts.dart';
import '../../widgets/common.dart';

class _Tool {
  const _Tool(
    this.id,
    this.icon,
    this.title,
    this.subtitle, {
    this.warm = false,
  });

  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool warm;
}

const _tools = [
  _Tool(
    'splitter',
    Icons.content_cut_rounded,
    'Status splitter',
    'Cut long videos into status-length parts',
    warm: true,
  ),
  _Tool(
    'instagram-photos',
    Icons.photo_outlined,
    'Instagram photos',
    'Save every photo and video in a post',
  ),
  _Tool(
    'stories',
    Icons.play_circle_outline_rounded,
    'Stories and highlights',
    'Instagram, Facebook, Snapchat public stories',
  ),
  _Tool(
    'profile-picture',
    Icons.person_outline_rounded,
    'Profile picture',
    'Full-size DP from a username or profile link',
  ),
];

class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = context.k;
    final accounts =
        ref.watch(accountStatusProvider).value ?? const <Platform, DateTime?>{};
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const ScreenTitle('Tools'),
          for (final t in _tools)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _ToolCard(tool: t),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(
              'Accounts',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: k.textMuted),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              child: Column(
                children: [
                  for (final (i, p) in Platform.values.indexed) ...[
                    if (i > 0) const Divider(indent: 16, endIndent: 16),
                    _AccountRow(platform: p, loggedInAt: accounts[p]),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(
              'Logging in lets Kheench save what your own account can already see.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool});

  final _Tool tool;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/tools/${tool.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: tool.warm ? k.saffronTint : k.tealTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  tool.icon,
                  color: tool.warm ? const Color(0xFF9A5B0A) : k.teal,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.title,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tool.subtitle,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: k.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountRow extends ConsumerStatefulWidget {
  const _AccountRow({required this.platform, required this.loggedInAt});

  final Platform platform;
  final DateTime? loggedInAt;

  @override
  ConsumerState<_AccountRow> createState() => _AccountRowState();
}

class _AccountRowState extends ConsumerState<_AccountRow> {
  bool _busy = false;

  static const _warningKey = 'accountsWarningSeen';

  /// Shown once before the first login (rate-limit warning).
  Future<bool> _warnOnce() async {
    final db = ref.read(databaseProvider);
    if ((await db.readSettings())[_warningKey] == 'true') return true;
    if (!mounted) return false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Before you log in'),
        content: const Text(
          'You log in on the site\'s own page; Kheench never sees your password.\n\n'
          'Kheench can then save anything your account can already see. '
          'Downloading a lot in a short time can get an account temporarily '
          'limited by the site, so go easy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (ok == true) await db.writeSetting(_warningKey, 'true');
    return ok == true;
  }

  Future<void> _login() async {
    if (!await _warnOnce()) return;
    setState(() => _busy = true);
    final ok = await ref.read(accountsProvider).login(widget.platform);
    ref.invalidate(accountStatusProvider);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Logged in to ${widget.platform.label}'
                : 'Not logged in to ${widget.platform.label}',
          ),
        ),
      );
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log out of ${widget.platform.label}?'),
        content: const Text(
          'Kheench deletes the saved session from this phone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: KColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(accountsProvider).logout(widget.platform);
    ref.invalidate(accountStatusProvider);
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final loggedIn = widget.loggedInAt != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.key_rounded, color: k.teal, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.platform.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (loggedIn)
            TextButton(onPressed: _logout, child: const Text('Logged in'))
          else
            OutlinedButton(
              onPressed: _busy ? null : _login,
              child: Text(_busy ? 'Waiting…' : 'Log in'),
            ),
        ],
      ),
    );
  }
}

class ToolPlaceholderScreen extends StatelessWidget {
  const ToolPlaceholderScreen({super.key, required this.tool});

  final String tool;

  @override
  Widget build(BuildContext context) {
    final t = _tools.firstWhere(
      (t) => t.id == tool,
      orElse: () => _tools.first,
    );
    return Scaffold(
      appBar: AppBar(title: Text(t.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          EmptyState(
            icon: t.icon,
            title: t.title,
            message: '${t.subtitle}. This tool is coming in a later update.',
          ),
        ],
      ),
    );
  }
}
