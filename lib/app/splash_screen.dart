import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../widgets/kheench_mark.dart';
import 'motion.dart';
import 'theme.dart';

/// Mark scales in, arrow drops into the tray, wordmark letters stagger in,
/// then the app fades to Home. About 1.4 s in total.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _word = 'Kheench';

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  late final _markScale = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.40, curve: Curves.elasticOut),
  );
  late final _arrow = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.25, 0.55, curve: Curves.easeOutBack),
  );
  late final _tagline = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.70, 0.90, curve: Curves.easeOut),
  );
  late final _bar = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.1, 1, curve: Curves.easeInOut),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.isCompleted) return;
    if (context.reduceMotion) {
      _c.value = 1;
      Future.delayed(const Duration(milliseconds: 400), _finish);
    } else {
      _c.forward().whenComplete(_finish);
    }
  }

  void _finish() {
    if (mounted) context.go('/home');
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: KColors.ink,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: KColors.ink,
        body: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: _markScale.value,
                        child: KheenchMark(size: 92, arrowDrop: _arrow.value),
                      ),
                      const SizedBox(height: 28),
                      _wordmark(),
                      const SizedBox(height: 10),
                      Opacity(
                        opacity: _tagline.value,
                        child: const Text(
                          'Save anything you can watch',
                          style: TextStyle(
                            color: Color(0xFFB9C6C8),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 72,
                  child: Center(
                    child: Container(
                      width: 96 * _bar.value,
                      height: 3,
                      decoration: BoxDecoration(
                        color: KColors.saffron,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _wordmark() {
    final letters = <Widget>[];
    for (var i = 0; i < _word.length; i++) {
      final start = 0.40 + i * 0.04;
      final t = Interval(
        start,
        (start + 0.18).clamp(0, 1),
        curve: Curves.easeOutCubic,
      ).transform(_c.value);
      letters.add(
        Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - t)),
            child: Text(
              _word[i],
              style: const TextStyle(
                fontFamily: KFonts.display,
                fontWeight: FontWeight.w800,
                fontSize: 44,
                letterSpacing: -1,
                color: KColors.mist,
              ),
            ),
          ),
        ),
      );
    }
    return Semantics(
      label: _word,
      excludeSemantics: true,
      child: Row(mainAxisSize: MainAxisSize.min, children: letters),
    );
  }
}
