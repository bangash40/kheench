import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
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

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
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
                  for (final (i, p) in const [
                    'Instagram',
                    'Facebook',
                    'X',
                    'TikTok',
                  ].indexed) ...[
                    if (i > 0) const Divider(indent: 16, endIndent: 16),
                    _AccountRow(platform: p),
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

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.platform});

  final String platform;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.key_rounded, color: k.teal, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              platform,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          OutlinedButton(
            onPressed: () => showComingSoon(context, 'Account login'),
            child: const Text('Log in'),
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
