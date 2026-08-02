import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../storage/storage_service.dart';

/// Service managing the application's active [ThemeMode] (Light vs Dark).
/// Persists user preferences and dynamically updates GetMaterialApp via GetX.
class ThemeService {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  /// Reactive theme mode state (defaults to Dark for Arbor Industrial aesthetic)
  final Rx<ThemeMode> _themeMode = ThemeMode.dark.obs;

  ThemeMode get themeMode => _themeMode.value;
  bool get isDarkMode => _themeMode.value == ThemeMode.dark;

  /// Initializes theme mode from stored user preference.
  void init() {
    final savedMode = StorageService.instance.themeMode;
    if (savedMode == 'light') {
      _themeMode.value = ThemeMode.light;
    } else if (savedMode == 'system') {
      _themeMode.value = ThemeMode.system;
    } else {
      // Default to Arbor Industrial Dark Mode
      _themeMode.value = ThemeMode.dark;
    }
  }

  /// Toggles between Light and Dark mode dynamically.
  Future<void> toggleTheme() async {
    final nextMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }

  /// Explicitly sets the active theme mode and persists choice.
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode.value = mode;
    Get.changeThemeMode(mode);
    
    final modeString = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.system
            ? 'system'
            : 'dark';
    await StorageService.instance.saveThemeMode(modeString);
  }
}
