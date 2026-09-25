import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/kheench_mark.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  String? _error;

  static const _sites = [
    'YouTube',
    'Instagram',
    'TikTok',
    'Facebook',
    'X',
    'Snapchat',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!mounted) return;
    if (text.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Clipboard is empty')));
      return;
    }
    setState(() {
      _controller.text = text;
      _error = null;
    });
  }

  void _showQualities() {
    FocusScope.of(context).unfocus();
    final uri = Uri.tryParse(_controller.text.trim());
    final valid =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    setState(
      () => _error = valid ? null : 'Enter a link starting with https://',
    );
    if (valid) showComingSoon(context, 'The quality picker');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Row(
            children: [
              const KheenchMark(size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kheench',
                  style: text.headlineLarge?.copyWith(fontSize: 28),
                ),
              ),
              IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _HeroCard(
            controller: _controller,
            error: _error,
            onPaste: _paste,
            onSubmit: _showQualities,
            onChanged: () {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _sites) _SiteChip(label: s),
              _SiteChip(label: '+1,800 sites', highlighted: true),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(child: Text('Recent', style: text.headlineSmall)),
              TextButton(
                onPressed: () => context.go('/downloads'),
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          EmptyState(
            icon: Icons.download_rounded,
            title: 'Nothing downloaded yet',
            message: 'Paste a link above or share one to Kheench from any app.',
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.controller,
    required this.error,
    required this.onPaste,
    required this.onSubmit,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? error;
  final VoidCallback onPaste;
  final VoidCallback onSubmit;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: k.hero,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paste a link to start',
            style: TextStyle(
              fontFamily: KFonts.display,
              fontWeight: FontWeight.w800,
              fontSize: 26,
              letterSpacing: -0.5,
              color: KColors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Video, reel, story or post link',
            style: TextStyle(fontSize: 14, color: Color(0xFFB9C6C8)),
          ),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: context.ms(200),
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            decoration: BoxDecoration(
              color: k.heroField,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: error != null ? const Color(0xFFF97066) : k.heroField,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, color: Color(0xFF8FA3A6)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: (_) => onChanged(),
                    onSubmitted: (_) => onSubmit(),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.go,
                    autocorrect: false,
                    cursorColor: KColors.saffron,
                    style: const TextStyle(color: KColors.white, fontSize: 16),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'https://',
                      hintStyle: TextStyle(color: Color(0xFF8FA3A6)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: const Color(0xFF2E4A50),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onPaste,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.content_paste_rounded,
                            size: 18,
                            color: KColors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Paste',
                            style: TextStyle(
                              color: KColors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: context.ms(200),
            child: error == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      error!,
                      style: const TextStyle(
                        color: Color(0xFFFDA29B),
                        fontSize: 13,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.search_rounded),
              label: const Text('Show qualities'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SiteChip extends StatelessWidget {
  const _SiteChip({required this.label, this.highlighted = false});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted ? k.tealTint : k.surface,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: highlighted ? k.tealTint : k.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
          color: highlighted ? k.teal : k.text,
        ),
      ),
    );
  }
}
