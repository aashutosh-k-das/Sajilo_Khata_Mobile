import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand: deep emerald (trust, money) with a marigold accent
  static const Color primaryColor = Color(0xFF0B7A5B);
  static const Color primaryDark = Color(0xFF064E3B);
  static const Color primaryLight = Color(0xFF14A37A);
  static const Color secondaryColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFE5484D);
  static const Color successColor = Color(0xFF12A150);
  static const Color infoColor = Color(0xFF3B82F6);
  static const Color violetColor = Color(0xFF8B5CF6);

  /// Hero gradient used by the app bar, login header and summary cards.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E9F75), primaryColor, primaryDark],
  );

  static const double radius = 18;

  static ThemeData get lightTheme => _build(
        brightness: Brightness.light,
        background: const Color(0xFFF2F6F4),
        surface: Colors.white,
        outline: const Color(0xFFE1E8E5),
        onSurface: const Color(0xFF102A22),
        muted: const Color(0xFF64748B),
      );

  static ThemeData get darkTheme => _build(
        brightness: Brightness.dark,
        background: const Color(0xFF0A1311),
        surface: const Color(0xFF13201C),
        outline: const Color(0xFF233430),
        onSurface: const Color(0xFFE7F0EC),
        muted: const Color(0xFF94A3B8),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color outline,
    required Color onSurface,
    required Color muted,
  }) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? primaryLight : primaryColor,
      onPrimary: Colors.white,
      secondary: secondaryColor,
      error: errorColor,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: muted,
      outline: outline,
      outlineVariant: outline,
    );
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final textTheme = GoogleFonts.muktaTextTheme(base.textTheme)
        .apply(bodyColor: onSurface, displayColor: onSurface);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: outline),
    );

    return base.copyWith(
      colorScheme: scheme,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      dividerColor: outline,
      dividerTheme: DividerThemeData(color: outline, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        // Base ThemeData text styles carry no sizes yet (Theme.of adds them),
        // so title sizes are set explicitly.
        titleTextStyle: GoogleFonts.mukta(
            fontSize: 21, fontWeight: FontWeight.w800, color: onSurface),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 5),
        shape: shape.copyWith(side: BorderSide(color: outline)),
      ),
      listTileTheme: ListTileThemeData(
        shape: shape,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        subtitleTextStyle: GoogleFonts.mukta(fontSize: 13, color: muted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF182824) : const Color(0xFFF7FAF9),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: muted),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          minimumSize: const Size(64, 50),
          side: BorderSide(color: outline, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        extendedTextStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: states.contains(WidgetState.selected)
                  ? scheme.primary
                  : muted,
            )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? scheme.primary
                  : muted,
            )),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.mukta(
            fontSize: 21, fontWeight: FontWeight.w800, color: onSurface),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: scheme.primary,
          selectedForegroundColor: Colors.white,
          side: BorderSide(color: outline),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
