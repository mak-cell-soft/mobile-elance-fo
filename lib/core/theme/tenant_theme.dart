import 'package:flutter/material.dart';

/// Dynamic Material 3 [ThemeData] builder for WoodApp.
/// Implements both the **Arbor Industrial** Dark design system from Stitch
/// and a high-legibility companion Light mode, supporting tenant-specific brand overrides.
class TenantTheme {
  TenantTheme._();

  // --- ARBOR INDUSTRIAL DESIGN SYSTEM TOKENS (Dark Mode Source of Truth) ---
  static const Color _arborDarkPrimary = Color(0xFF1B4332); // Forest Green brand accent
  static const Color _arborDarkBackground = Color(0xFF041329); // Deep Nocturnal Navy
  static const Color _arborDarkSurfaceContainer = Color(0xFF112036); // Elevated card container
  static const Color _arborDarkSurfaceLow = Color(0xFF0D1C32); // Lower contrast container
  static const Color _arborDarkSurfaceHigh = Color(0xFF1C2A41); // Elevated modal container
  static const Color _arborDarkOnSurface = Color(0xFFD6E3FF); // High-contrast light cool grey text
  static const Color _arborDarkOnSurfaceVariant = Color(0xFFC1C8C2); // Muted secondary text
  static const Color _arborDarkOutline = Color(0xFF8B938D); // Border outline
  static const Color _arborDarkOutlineVariant = Color(0xFF414844); // Low-contrast card divider
  static const Color _arborDarkError = Color(0xFFFFB4AB); // Status error text
  static const Color _arborDarkErrorContainer = Color(0xFF93000A); // Error background badge

  // --- LIGHT MODE COMPANION TOKENS ---
  static const Color _arborLightPrimary = Color(0xFF1B4332);
  static const Color _arborLightBackground = Color(0xFFF8FAFC);
  static const Color _arborLightSurfaceContainer = Color(0xFFFFFFFF);
  static const Color _arborLightOnSurface = Color(0xFF0F172A);
  static const Color _arborLightOnSurfaceVariant = Color(0xFF475569);
  static const Color _arborLightOutline = Color(0xFFCBD5E1);

  /// Standard entry builder — defaults to Dark mode for Arbor Industrial branding.
  static ThemeData build({
    String? primaryColorHex,
    String? secondaryColorHex,
    Brightness brightness = Brightness.dark,
  }) {
    return brightness == Brightness.dark
        ? buildDark(primaryColorHex: primaryColorHex, secondaryColorHex: secondaryColorHex)
        : buildLight(primaryColorHex: primaryColorHex, secondaryColorHex: secondaryColorHex);
  }

  /// Builds the **Arbor Industrial Dark Theme** (Stitch UI Spec).
  static ThemeData buildDark({
    String? primaryColorHex,
    String? secondaryColorHex,
  }) {
    final customPrimary = _parseHexColor(primaryColorHex);
    final customSecondary = _parseHexColor(secondaryColorHex);
    final seed = customPrimary ?? _arborDarkPrimary;

    // Build base ColorScheme from seed
    var colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ).copyWith(
      surface: _arborDarkBackground,
      onSurface: _arborDarkOnSurface,
      onSurfaceVariant: _arborDarkOnSurfaceVariant,
      surfaceContainerLow: _arborDarkSurfaceLow,
      surfaceContainer: _arborDarkSurfaceContainer,
      surfaceContainerHigh: _arborDarkSurfaceHigh,
      outline: _arborDarkOutline,
      outlineVariant: _arborDarkOutlineVariant,
      error: _arborDarkError,
      errorContainer: _arborDarkErrorContainer,
    );

    if (customPrimary != null) {
      colorScheme = colorScheme.copyWith(primary: customPrimary);
    }
    if (customSecondary != null) {
      colorScheme = colorScheme.copyWith(secondary: customSecondary);
    }

    return _assembleThemeData(colorScheme: colorScheme);
  }

  /// Builds the **Arbor Industrial Companion Light Theme**.
  static ThemeData buildLight({
    String? primaryColorHex,
    String? secondaryColorHex,
  }) {
    final customPrimary = _parseHexColor(primaryColorHex);
    final customSecondary = _parseHexColor(secondaryColorHex);
    final seed = customPrimary ?? _arborLightPrimary;

    var colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ).copyWith(
      surface: _arborLightBackground,
      onSurface: _arborLightOnSurface,
      onSurfaceVariant: _arborLightOnSurfaceVariant,
      surfaceContainer: _arborLightSurfaceContainer,
      outline: _arborLightOutline,
    );

    if (customPrimary != null) {
      colorScheme = colorScheme.copyWith(primary: customPrimary);
    }
    if (customSecondary != null) {
      colorScheme = colorScheme.copyWith(secondary: customSecondary);
    }

    return _assembleThemeData(colorScheme: colorScheme);
  }

  /// Assembles a cohesive [ThemeData] from a defined [ColorScheme].
  static ThemeData _assembleThemeData({required ColorScheme colorScheme}) {
    final textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,

      // Modern zero-elevation AppBar with clean contrast
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),

      // Arbor Industrial Card Theme: 16px radius, subtle border outline, surface container tone
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        color: colorScheme.surfaceContainer,
        margin: EdgeInsets.zero,
      ),

      // Modern Input decoration with floating labels & rounded focus states
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
      ),

      // Primary Button styling (Forest Green / Brand Primary)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Filled button alternative styling
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined button styling
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Navigation Bar / Bottom Bar Styling
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.2),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12);
          }
          return TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12);
        }),
      ),
    );
  }

  /// Builds clean, readable typography with hierarchical scaling.
  static TextTheme _buildTextTheme(ColorScheme colors) {
    return TextTheme(
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: colors.onSurface,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: colors.onSurface,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: colors.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: colors.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: colors.onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colors.onSurface,
      ),
    );
  }

  /// Parses hex color strings safely (e.g., "#1B4332" or "1B4332").
  static Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var value = hex.trim().replaceFirst('#', '');
    if (value.length == 6) value = 'FF$value';
    if (value.length != 8) return null;
    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) return null;
    return Color(parsed);
  }
}
