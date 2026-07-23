import 'package:flutter/material.dart';

/// Builds a Material 3 ThemeData from a tenant's branding colors so the
/// whole app re-skins itself per tenant without any hardcoded colors.
class TenantTheme {
  TenantTheme._();

  static const Color _fallbackSeed = Color(0xFF3B82F6);

  static ThemeData build({String? primaryColorHex, String? secondaryColorHex}) {
    final seed = _parseHexColor(primaryColorHex) ?? _fallbackSeed;
    final secondary = _parseHexColor(secondaryColorHex);

    var colorScheme = ColorScheme.fromSeed(seedColor: seed);
    if (secondary != null) {
      colorScheme = colorScheme.copyWith(secondary: secondary);
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

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
