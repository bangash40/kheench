import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../engine/download_choice.dart';
import '../../engine/engine.dart';
import '../downloads/downloads_controller.dart';
import '../downloads/downloads_tab.dart';
import '../../widgets/kheench_mark.dart';
import '../../app/share_intake.dart';
import '../settings/settings_providers.dart';
import 'default_choice.dart';
import 'clipboard_banner.dart';
import 'clipboard_offer.dart';
import 'link_lookup.dart';
import 'link_text.dart';
import 'preview_card.dart';
import 'quality_sheet.dart';
import 'recent_list.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _updatingEngine = false;

  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Offer a copied link when Home appears and whenever the app comes back.
    _lifecycle = AppLifecycleListener(onResume: _checkClipboard);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkClipboard());
    // Links shared from other apps: fill them in and start reading.
    ref.listenManual(sharedLinkProvider, (_, text) {
      if (text != null) _useShared(text);
    }, fireImmediately: true);
  }

  void _useShared(String text) {
    // Defer so it never runs in the middle of a build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(sharedLinkProvider.notifier).clear();
      final url = extractUrl(text);
      if (url == null) {
        _snack('No link found in what was shared');
        return;
      }
      setState(() {
        _controller.text = url;
        _error = null;
      });
      ref.read(linkLookupProvider.notifier).fetch(url);
    });
  }

  Future<void> _checkClipboard() async {
    // Android only allows reading the clipboard once the window has focus.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    await ref
        .read(clipboardOfferProvider.notifier)
        .check(currentText: _controller.text);
  }

  void _openClipboardLink(String url) {
    ref.read(clipboardOfferProvider.notifier).done();
    setState(() {
      _controller.text = url;
      _error = null;
    });
    ref.read(linkLookupProvider.notifier).fetch(url);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!mounted) return;
    if (text.isEmpty) {
      _snack('Clipboard is empty');
      return;
    }
    setState(() {
      _controller.text = extractUrl(text) ?? text;
      _error = null;
    });
  }

  void _showQualities() {
    FocusScope.of(context).unfocus();
    final url = extractUrl(_controller.text.trim());
    setState(
      () => _error = url == null ? 'Enter a link starting with https://' : null,
    );
    if (url == null) return;
    if (_controller.text != url) _controller.text = url;
    ref.read(linkLookupProvider.notifier).fetch(url);
  }

  Future<void> _openSheet() async {
    final state = ref.read(linkLookupProvider);
    if (state is! LookupLoaded) return;
    final choice = await showQualitySheet(context, state.info);
    if (choice == null || !mounted) return;
    _startDownload(choice);
  }

  Future<void> _startDownload(DownloadChoice choice) async {
    final state = ref.read(linkLookupProvider);
    if (state is! LookupLoaded) return;
    await ref
        .read(downloadsControllerProvider)
        .start(
          info: state.info,
          url: state.info.url.isEmpty ? state.url : state.info.url,
          choice: choice,
        );
    if (!mounted) return;
    // Ready for the next link.
    _clear();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Downloading ${choice.label}'),
          // Snackbars with an action stay until tapped unless told otherwise.
          persist: false,
          action: SnackBarAction(
            label: 'View',
            textColor: KColors.saffron,
            onPressed: () {
              ref.read(downloadsTabProvider.notifier).show(DownloadsTab.active);
              context.go('/downloads');
            },
          ),
        ),
      );
  }

  Future<void> _updateEngineAndRetry() async {
    setState(() => _updatingEngine = true);
    try {
      await ref.read(engineProvider).update();
      ref.invalidate(engineVersionProvider);
    } on EngineException catch (e) {
      if (mounted) _snack('Update failed: ${e.message}');
    }
    if (!mounted) return;
    setState(() => _updatingEngine = false);
    _retry();
  }

  void _retry() {
    final state = ref.read(linkLookupProvider);
    final url = switch (state) {
      LookupFailed(:final url) || LookupLoaded(:final url) => url,
      _ => null,
    };
    if (url != null) ref.read(linkLookupProvider.notifier).fetch(url);
  }

  void _clear() {
    ref.read(linkLookupProvider.notifier).clear();
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final lookup = ref.watch(linkLookupProvider);

    // Open the quality sheet as soon as a link finishes loading.
    // When a link loads, start the default download or open the picker.
    ref.listen(linkLookupProvider, (previous, next) {
      if (next is! LookupLoaded || previous is! LookupLoading) return;
      final auto = choiceForDefault(next.info, ref.read(settingsProvider));
      if (auto == null) {
        _openSheet();
      } else {
        _startDownload(auto);
      }
    });

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
            loading: lookup is LookupLoading,
            onPaste: _paste,
            onSubmit: _showQualities,
            onChanged: () {
              if (_error != null) setState(() => _error = null);
            },
          ),
          ClipboardBanner(
            url: ref.watch(clipboardOfferProvider),
            onOpen: () {
              final url = ref.read(clipboardOfferProvider);
              if (url != null) _openClipboardLink(url);
            },
            onDismiss: () => ref.read(clipboardOfferProvider.notifier).done(),
          ),
          PreviewArea(
            state: lookup,
            onChooseQuality: _openSheet,
            askFirst:
                ref.watch(settingsProvider).defaultQuality ==
                DefaultQuality.ask,
            onRetry: _retry,
            onUpdateEngine: _updateEngineAndRetry,
            onClear: _clear,
            updatingEngine: _updatingEngine,
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(child: Text('Recent', style: text.headlineSmall)),
              TextButton(
                onPressed: () {
                  ref
                      .read(downloadsTabProvider.notifier)
                      .show(DownloadsTab.saved);
                  context.go('/downloads');
                },
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const RecentList(),
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
    this.loading = false,
  });

  final TextEditingController controller;
  final String? error;
  final bool loading;
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
              onPressed: loading ? null : onSubmit,
              style: FilledButton.styleFrom(
                disabledBackgroundColor: KColors.saffron.withValues(alpha: 0.6),
                disabledForegroundColor: KColors.ink,
              ),
              icon: loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: KColors.ink,
                      ),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(loading ? 'Downloading…' : 'Download'),
            ),
          ),
        ],
      ),
    );
  }
}
