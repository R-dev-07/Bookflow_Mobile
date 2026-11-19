import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'widgets/motion.dart';

/// The selectable colour themes. Every theme ships a light AND a dark palette.
enum BFThemeId { crimson, champagne, ocean, amethyst, emerald }

/// One resolved set of colours (a theme in a specific brightness).
class BFPalette {
  const BFPalette({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.text,
    required this.muted,
    required this.accent,
    required this.accentDeep,
    required this.onAccent,
    required this.navBg,
  });

  final Color bg; // scaffold background
  final Color surface; // cards, sheets, dialogs
  final Color surfaceAlt; // inputs, chips, subtle fills
  final Color border;
  final Color text; // primary text
  final Color muted; // secondary text / icons
  final Color accent; // brand highlight, primary buttons
  final Color accentDeep; // pressed / gradient end
  final Color onAccent; // text or icons drawn on top of [accent]
  final Color navBg;

  static BFPalette of(BFThemeId id, Brightness b) =>
      b == Brightness.dark ? _dark[id]! : _light[id]!;

  static const _dark = <BFThemeId, BFPalette>{
    BFThemeId.crimson: BFPalette(
      bg: Color(0xFF0E0B0B),
      surface: Color(0xFF1A1413),
      surfaceAlt: Color(0xFF231A19),
      border: Color(0xFF332624),
      text: Color(0xFFF6EEDC),
      muted: Color(0xFFA99A91),
      accent: Color(0xFFD63C41),
      accentDeep: Color(0xFF9E1B20),
      onAccent: Color(0xFFFFFFFF),
      navBg: Color(0xFF161010),
    ),
    BFThemeId.champagne: BFPalette(
      bg: Color(0xFF101713),
      surface: Color(0xFF202923),
      surfaceAlt: Color(0xFF18211B),
      border: Color(0xFF29342D),
      text: Color(0xFFF4F0E6),
      muted: Color(0xFF8D9B91),
      accent: Color(0xFFD9AE68),
      accentDeep: Color(0xFFC79D57),
      onAccent: Color(0xFF101713),
      navBg: Color(0xFF151D18),
    ),
    BFThemeId.ocean: BFPalette(
      bg: Color(0xFF0A1420),
      surface: Color(0xFF122434),
      surfaceAlt: Color(0xFF0F1D2B),
      border: Color(0xFF1F3549),
      text: Color(0xFFEAF3FA),
      muted: Color(0xFF8CA3B6),
      accent: Color(0xFF4DB2F5),
      accentDeep: Color(0xFF2B8AD0),
      onAccent: Color(0xFF04121D),
      navBg: Color(0xFF0E1C2A),
    ),
    BFThemeId.amethyst: BFPalette(
      bg: Color(0xFF110D1B),
      surface: Color(0xFF1E1830),
      surfaceAlt: Color(0xFF181226),
      border: Color(0xFF30284A),
      text: Color(0xFFF1ECFA),
      muted: Color(0xFF9B91B6),
      accent: Color(0xFFB48CFF),
      accentDeep: Color(0xFF8F63E6),
      onAccent: Color(0xFF150B26),
      navBg: Color(0xFF171127),
    ),
    BFThemeId.emerald: BFPalette(
      bg: Color(0xFF07140E),
      surface: Color(0xFF10241A),
      surfaceAlt: Color(0xFF0C1C14),
      border: Color(0xFF1B3A2B),
      text: Color(0xFFEAF6EF),
      muted: Color(0xFF86A596),
      accent: Color(0xFF34D399),
      accentDeep: Color(0xFF1FA877),
      onAccent: Color(0xFF03150C),
      navBg: Color(0xFF0C1D14),
    ),
  };

  static const _light = <BFThemeId, BFPalette>{
    BFThemeId.crimson: BFPalette(
      bg: Color(0xFFFAF5EC),
      surface: Color(0xFFFFFFFF),
      surfaceAlt: Color(0xFFF4ECDF),
      border: Color(0xFFE8DDCB),
      text: Color(0xFF1E1412),
      muted: Color(0xFF6F615A),
      accent: Color(0xFF9B1C1C),
      accentDeep: Color(0xFF7A1010),
      onAccent: Color(0xFFFFFFFF),
      navBg: Color(0xFFFFFFFF),
    ),
    BFThemeId.champagne: BFPalette(
      bg: Color(0xFFF8F6F0),
      surface: Color(0xFFFFFFFF),
      surfaceAlt: Color(0xFFF1EEE4),
      border: Color(0xFFE5E0D5),
      text: Color(0xFF111813),
      muted: Color(0xFF5A655D),
      accent: Color(0xFF9A6C16),
      accentDeep: Color(0xFF7D5610),
      onAccent: Color(0xFFFFFFFF),
      navBg: Color(0xFFFFFFFF),
    ),
    BFThemeId.ocean: BFPalette(
      bg: Color(0xFFF3F8FC),
      surface: Color(0xFFFFFFFF),
      surfaceAlt: Color(0xFFE9F1F8),
      border: Color(0xFFDCE7F0),
      text: Color(0xFF0E1B26),
      muted: Color(0xFF53677A),
      accent: Color(0xFF0B6BCB),
      accentDeep: Color(0xFF08529E),
      onAccent: Color(0xFFFFFFFF),
      navBg: Color(0xFFFFFFFF),
    ),
    BFThemeId.amethyst: BFPalette(
      bg: Color(0xFFF7F4FC),
      surface: Color(0xFFFFFFFF),
      surfaceAlt: Color(0xFFEFE9F8),
      border: Color(0xFFE6DFF3),
      text: Color(0xFF1A1228),
      muted: Color(0xFF625878),
      accent: Color(0xFF6A38C2),
      accentDeep: Color(0xFF52289F),
      onAccent: Color(0xFFFFFFFF),
      navBg: Color(0xFFFFFFFF),
    ),
    BFThemeId.emerald: BFPalette(
      bg: Color(0xFFF2F8F4),
      surface: Color(0xFFFFFFFF),
      surfaceAlt: Color(0xFFE6F1EA),
      border: Color(0xFFDAEBE0),
      text: Color(0xFF0C1A12),
      muted: Color(0xFF516459),
      accent: Color(0xFF0E7A4F),
      accentDeep: Color(0xFF095C3B),
      onAccent: Color(0xFFFFFFFF),
      navBg: Color(0xFFFFFFFF),
    ),
  };
}

extension BFThemeIdX on BFThemeId {
  String get label => switch (this) {
    BFThemeId.crimson => 'Crimson',
    BFThemeId.champagne => 'Champagne',
    BFThemeId.ocean => 'Ocean',
    BFThemeId.amethyst => 'Amethyst',
    BFThemeId.emerald => 'Emerald',
  };

  /// Swatch shown in the theme picker (always the dark-mode accent so it reads on any surface).
  Color get swatch => BFPalette.of(this, Brightness.dark).accent;
}

/// The colours the whole app draws with.
///
/// The names `midnightForest`, `warmIvory`, `champagneGold`, ... are kept from the original
/// design system so every screen keeps compiling, but they are now *live getters* that return
/// the active theme's colour (light or dark). Nothing here is hardcoded to the dark look anymore.
/// [PaletteScope] (see widgets/palette_scope.dart) calls [apply] whenever the theme or
/// brightness changes and rebuilds the tree so every screen picks the new colours up at once.
class AppColors {
  AppColors._();

  static BFThemeId themeId = BFThemeId.crimson;
  static Brightness brightness = Brightness.dark;
  static BFPalette _p = BFPalette.of(BFThemeId.crimson, Brightness.dark);

  /// Returns true when something actually changed.
  static bool apply(BFThemeId id, Brightness b) {
    if (id == themeId && b == brightness) return false;
    themeId = id;
    brightness = b;
    _p = BFPalette.of(id, b);
    return true;
  }

  static BFPalette get palette => _p;
  static bool get isDark => brightness == Brightness.dark;

  // Semantic names (prefer these in new code).
  static Color get bg => _p.bg;
  static Color get surface => _p.surface;
  static Color get surfaceAlt => _p.surfaceAlt;
  static Color get border => _p.border;
  static Color get text => _p.text;
  static Color get muted => _p.muted;
  static Color get accent => _p.accent;
  static Color get accentDeep => _p.accentDeep;
  static Color get onAccent => _p.onAccent;
  static Color get navBg => _p.navBg;

  // Status colours are the same in every theme.
  static const statusActive = Color(0xFF22C55E); // Approved / Active
  static const statusPending = Color(0xFFEAB308); // Pending review / booking
  static const statusRejected = Color(0xFFEF4444); // Rejected / Cancelled
  static const statusCompleted = Color(0xFF3B82F6); // Completed

  // Brand colours sampled from the splash animation (fixed, theme independent).
  static const brandCrimson = Color(0xFF7E0000);
  static const brandCream = Color(0xFFFDF4D7);
}

/// Short fade + slight upward slide (iOS keeps its native swipe-back transition).
class _FadeSlideTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeSlideTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return FadeTransition(opacity: animation, child: child);
    }
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.outStrong,
      reverseCurve: AppMotion.outStrong.flipped,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}


ThemeData buildTheme(Brightness brightness, [BFThemeId id = BFThemeId.crimson]) {
  final isDark = brightness == Brightness.dark;
  final p = BFPalette.of(id, brightness);

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: p.accent,
    onPrimary: p.onAccent,
    primaryContainer: p.accent.withValues(alpha: isDark ? 0.18 : 0.12),
    onPrimaryContainer: p.accent,
    secondary: p.accent,
    onSecondary: p.onAccent,
    surface: p.bg,
    onSurface: p.text,
    surfaceContainerLowest: p.bg,
    surfaceContainerLow: p.surface,
    surfaceContainer: p.surface,
    surfaceContainerHigh: p.surface,
    surfaceContainerHighest: p.surface,
    onSurfaceVariant: p.muted,
    outline: p.border,
    outlineVariant: p.border.withValues(alpha: 0.7),
    error: AppColors.statusRejected,
    onError: Colors.white,
    inverseSurface: p.text,
    onInverseSurface: p.bg,
    shadow: Colors.black,
  );

  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: p.border),
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: p.bg,
    canvasColor: p.bg,
    dividerColor: p.border,
    splashFactory: NoSplash.splashFactory,
    fontFamily: '.SF Pro Text',
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final t in TargetPlatform.values)
          t: (t == TargetPlatform.iOS || t == TargetPlatform.macOS)
              ? const CupertinoPageTransitionsBuilder()
              : const _FadeSlideTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: p.bg,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      iconTheme: IconThemeData(color: p.text),
      actionsIconTheme: IconThemeData(color: p.text),
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: p.text,
        letterSpacing: -0.4,
      ),
    ),
    cardTheme: CardThemeData(color: p.surface, surfaceTintColor: Colors.transparent, elevation: 0),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: p.border),
      ),
      titleTextStyle: TextStyle(color: p.text, fontSize: 19, fontWeight: FontWeight.w800),
      contentTextStyle: TextStyle(color: p.muted, fontSize: 15, height: 1.4),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
    iconTheme: IconThemeData(color: p.muted),
    listTileTheme: ListTileThemeData(
      iconColor: p.muted,
      textColor: p.text,
      titleTextStyle: TextStyle(color: p.text, fontSize: 15, fontWeight: FontWeight.w700),
      subtitleTextStyle: TextStyle(color: p.muted, fontSize: 12),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.accent,
      contentTextStyle: TextStyle(color: p.onAccent, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent, circularTrackColor: p.border),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.onAccent : p.muted),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.accent : p.surfaceAlt),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.transparent : p.border,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.accent : Colors.transparent),
      checkColor: WidgetStatePropertyAll(p.onAccent),
      side: BorderSide(color: p.muted, width: 1.5),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: p.surface,
        foregroundColor: p.muted,
        selectedBackgroundColor: p.accent,
        selectedForegroundColor: p.onAccent,
        side: BorderSide(color: p.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        disabledBackgroundColor: p.surfaceAlt,
        disabledForegroundColor: p.muted.withValues(alpha: 0.6),
        minimumSize: const Size(64, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.text,
        minimumSize: const Size(64, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        side: BorderSide(color: p.border, width: 1.2),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.accent,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: p.text)),
    chipTheme: ChipThemeData(
      backgroundColor: p.surface,
      selectedColor: p.accent,
      secondarySelectedColor: p.accent,
      checkmarkColor: p.onAccent,
      labelStyle: TextStyle(color: p.muted, fontWeight: FontWeight.w600, fontSize: 13),
      secondaryLabelStyle: TextStyle(color: p.onAccent, fontWeight: FontWeight.w700, fontSize: 13),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: p.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      hintStyle: TextStyle(color: p.muted.withValues(alpha: 0.8), fontSize: 14),
      labelStyle: TextStyle(color: p.muted, fontSize: 14),
      floatingLabelStyle: TextStyle(color: p.accent, fontSize: 14, fontWeight: FontWeight.w600),
      prefixIconColor: p.muted,
      suffixIconColor: p.muted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: inputBorder,
      enabledBorder: inputBorder,
      errorBorder: inputBorder.copyWith(borderSide: const BorderSide(color: AppColors.statusRejected)),
      focusedErrorBorder: inputBorder.copyWith(borderSide: const BorderSide(color: AppColors.statusRejected, width: 1.5)),
      focusedBorder: inputBorder.copyWith(borderSide: BorderSide(color: p.accent, width: 1.5)),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: p.surfaceAlt,
      headerForegroundColor: p.text,
      dayForegroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.onAccent : p.text,
      ),
      todayForegroundColor: WidgetStatePropertyAll(p.accent),
      todayBorder: BorderSide(color: p.accent),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );

  // Text colours are set explicitly so nothing falls back to a default that clashes with the theme.
  final themed = base.textTheme.apply(bodyColor: p.text, displayColor: p.text);
  return base.copyWith(textTheme: _tightenType(themed));
}

TextTheme _tightenType(TextTheme t) => t.copyWith(
  headlineLarge: t.headlineLarge?.copyWith(letterSpacing: -0.7, height: 1.15, fontWeight: FontWeight.w800),
  headlineMedium: t.headlineMedium?.copyWith(letterSpacing: -0.6, height: 1.18, fontWeight: FontWeight.w800),
  headlineSmall: t.headlineSmall?.copyWith(letterSpacing: -0.4, height: 1.2, fontWeight: FontWeight.w700),
  titleLarge: t.titleLarge?.copyWith(letterSpacing: -0.3, height: 1.25, fontWeight: FontWeight.w700),
  titleMedium: t.titleMedium?.copyWith(letterSpacing: -0.1, height: 1.3, fontWeight: FontWeight.w600),
  bodyLarge: t.bodyLarge?.copyWith(letterSpacing: 0, height: 1.45),
  bodyMedium: t.bodyMedium?.copyWith(letterSpacing: 0.1, height: 1.4),
  bodySmall: t.bodySmall?.copyWith(letterSpacing: 0.2, height: 1.35),
  labelMedium: t.labelMedium?.copyWith(letterSpacing: 0.3),
  labelSmall: t.labelSmall?.copyWith(letterSpacing: 0.4),
);

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const BouncingScrollPhysics();

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
}
