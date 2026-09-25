import 'package:flutter/material.dart';

/// Brand colors from the design sheet.
abstract final class KColors {
  static const ink = Color(0xFF12262B);
  static const saffron = Color(0xFFF2A93B);
  static const teal = Color(0xFF1F7A74);
  static const mist = Color(0xFFEEF3F1);
  static const saffronTint = Color(0xFFFCE9C8);
  static const tealTint = Color(0xFFD6EBE8);
  static const slate = Color(0xFF51646A);
  static const error = Color(0xFFB42318);
  static const white = Color(0xFFFFFFFF);
}

abstract final class KFonts {
  static const display = 'Bricolage Grotesque';
  static const body = 'DM Sans';
}

/// Semantic tokens that change between light and dark mode.
@immutable
class KTokens extends ThemeExtension<KTokens> {
  const KTokens({
    required this.background,
    required this.surface,
    required this.hero,
    required this.heroField,
    required this.text,
    required this.textMuted,
    required this.border,
    required this.saffronTint,
    required this.tealTint,
    required this.teal,
    required this.onSaffronTint,
  });

  final Color background;
  final Color surface;
  final Color hero;
  final Color heroField;
  final Color text;
  final Color textMuted;
  final Color border;
  final Color saffronTint;
  final Color tealTint;
  final Color teal;
  final Color onSaffronTint;

  static const light = KTokens(
    background: KColors.mist,
    surface: KColors.white,
    hero: KColors.ink,
    heroField: Color(0xFF1E363C),
    text: KColors.ink,
    textMuted: KColors.slate,
    border: Color(0xFFDCE4E1),
    saffronTint: KColors.saffronTint,
    tealTint: KColors.tealTint,
    teal: KColors.teal,
    onSaffronTint: KColors.ink,
  );

  static const dark = KTokens(
    background: Color(0xFF0C1A1E),
    surface: Color(0xFF16292E),
    hero: Color(0xFF1B3338),
    heroField: Color(0xFF244248),
    text: Color(0xFFEAF1EF),
    textMuted: Color(0xFF9DB0B4),
    border: Color(0xFF26403F),
    saffronTint: Color(0xFF3D3020),
    tealTint: Color(0xFF173B39),
    teal: Color(0xFF5CC3BA),
    onSaffronTint: Color(0xFFFCE9C8),
  );

  @override
  KTokens copyWith() => this;

  @override
  KTokens lerp(ThemeExtension<KTokens>? other, double t) {
    if (other is! KTokens) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return KTokens(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      hero: l(hero, other.hero),
      heroField: l(heroField, other.heroField),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      border: l(border, other.border),
      saffronTint: l(saffronTint, other.saffronTint),
      tealTint: l(tealTint, other.tealTint),
      teal: l(teal, other.teal),
      onSaffronTint: l(onSaffronTint, other.onSaffronTint),
    );
  }
}

extension KTokensX on BuildContext {
  KTokens get k => Theme.of(this).extension<KTokens>()!;
}

ThemeData buildTheme(Brightness brightness) {
  final k = brightness == Brightness.light ? KTokens.light : KTokens.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: KColors.saffron,
    onPrimary: KColors.ink,
    secondary: k.teal,
    onSecondary: KColors.white,
    error: KColors.error,
    onError: KColors.white,
    surface: k.surface,
    onSurface: k.text,
    onSurfaceVariant: k.textMuted,
    outline: k.border,
    outlineVariant: k.border,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: KFonts.body,
    scaffoldBackgroundColor: k.background,
    extensions: [k],
  );

  final text = base.textTheme.apply(bodyColor: k.text, displayColor: k.text);

  return base.copyWith(
    textTheme: text.copyWith(
      headlineLarge: const TextStyle(
        fontFamily: KFonts.display,
        fontWeight: FontWeight.w800,
        fontSize: 30,
        letterSpacing: -0.6,
        height: 1.1,
      ).apply(color: k.text),
      headlineSmall: const TextStyle(
        fontFamily: KFonts.display,
        fontWeight: FontWeight.w700,
        fontSize: 22,
        letterSpacing: -0.3,
      ).apply(color: k.text),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 16,
        color: k.text,
      ),
      titleSmall: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: k.text,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: k.text),
      bodyMedium: TextStyle(fontSize: 15, color: k.text),
      bodySmall: TextStyle(fontSize: 13, color: k.textMuted),
      labelLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: k.background,
      foregroundColor: k.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: KFonts.display,
        fontWeight: FontWeight.w700,
        fontSize: 22,
        color: k.text,
      ),
    ),
    cardTheme: CardThemeData(
      color: k.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: KColors.saffron,
        foregroundColor: KColors.ink,
        minimumSize: const Size(48, 52),
        textStyle: const TextStyle(
          fontFamily: KFonts.body,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: k.text,
        minimumSize: const Size(48, 40),
        side: BorderSide(color: k.text, width: 1.2),
        textStyle: const TextStyle(
          fontFamily: KFonts.body,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: k.teal,
        textStyle: const TextStyle(
          fontFamily: KFonts.body,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: k.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 72,
      indicatorColor: KColors.saffron,
      indicatorShape: const StadiumBorder(),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: KFonts.body,
          fontSize: 13,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? k.text : k.textMuted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected)
              ? KColors.ink
              : k.textMuted,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: KColors.ink,
      contentTextStyle: const TextStyle(
        fontFamily: KFonts.body,
        fontSize: 14,
        color: KColors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(color: k.border, thickness: 1, space: 1),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: k.background,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
  );
}
