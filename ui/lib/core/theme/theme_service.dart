import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../settings/settings_service.dart';
import 'app_theme.dart';

part 'theme_service.g.dart';

/// Available theme modes
enum AppThemeMode { light, dark, system }

/// Available font sizes
enum AppFontSize { small, medium, large, extraLarge }

/// Preset accent colors available for customization
class AccentColors {
  static const List<Color> presets = [
    Color(0xFF128C7E), // Teal (default)
    Color(0xFF1976D2), // Blue
    Color(0xFF7B1FA2), // Purple
    Color(0xFFD32F2F), // Red
    Color(0xFFF57C00), // Orange
    Color(0xFF388E3C), // Green
    Color(0xFF5D4037), // Brown
    Color(0xFF455A64), // Blue Grey
    Color(0xFFE91E63), // Pink
    Color(0xFF00BCD4), // Cyan
  ];

  static String colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  static Color hexToColor(String hex) {
    final hexCode = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}

/// Notifier for theme mode
@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  AppThemeMode build() {
    final settingsService = ref.watch(settingsServiceProvider);
    return _parseThemeMode(settingsService.themeMode);
  }

  static AppThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      default:
        return AppThemeMode.system;
    }
  }

  static String _themeModeToString(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.system:
        return 'system';
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    final settingsService = ref.read(settingsServiceProvider);
    await settingsService.setThemeMode(_themeModeToString(mode));
  }
}

/// Notifier for font size
@riverpod
class FontSizeNotifier extends _$FontSizeNotifier {
  @override
  AppFontSize build() {
    final settingsService = ref.watch(settingsServiceProvider);
    return _parseFontSize(settingsService.fontSize);
  }

  static AppFontSize _parseFontSize(String value) {
    switch (value.toLowerCase()) {
      case 'small':
        return AppFontSize.small;
      case 'large':
        return AppFontSize.large;
      case 'extra_large':
      case 'extralarge':
        return AppFontSize.extraLarge;
      default:
        return AppFontSize.medium;
    }
  }

  static String _fontSizeToString(AppFontSize size) {
    switch (size) {
      case AppFontSize.small:
        return 'small';
      case AppFontSize.medium:
        return 'medium';
      case AppFontSize.large:
        return 'large';
      case AppFontSize.extraLarge:
        return 'extra_large';
    }
  }

  Future<void> setFontSize(AppFontSize size) async {
    state = size;
    final settingsService = ref.read(settingsServiceProvider);
    await settingsService.setFontSize(_fontSizeToString(size));
  }
}

/// Notifier for accent color
@riverpod
class AccentColorNotifier extends _$AccentColorNotifier {
  @override
  Color build() {
    final settingsService = ref.watch(settingsServiceProvider);
    return _parseAccentColor(settingsService.accentColor);
  }

  static Color _parseAccentColor(String? value) {
    if (value == null || value.isEmpty) {
      return AppTheme.primaryGreen;
    }
    try {
      return AccentColors.hexToColor(value);
    } catch (_) {
      return AppTheme.primaryGreen;
    }
  }

  Future<void> setAccentColor(Color color) async {
    state = color;
    final settingsService = ref.read(settingsServiceProvider);
    await settingsService.setAccentColor(AccentColors.colorToHex(color));
  }

  Future<void> resetToDefault() async {
    state = AppTheme.primaryGreen;
    final settingsService = ref.read(settingsServiceProvider);
    await settingsService.setAccentColor(null);
  }
}

/// Notifier for chat wallpaper
@riverpod
class ChatWallpaperNotifier extends _$ChatWallpaperNotifier {
  @override
  String? build() {
    final settingsService = ref.watch(settingsServiceProvider);
    final value = settingsService.chatWallpaper;
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<void> setWallpaper(String? path) async {
    state = path;
    final settingsService = ref.read(settingsServiceProvider);
    await settingsService.setChatWallpaper(path);
  }

  Future<void> clearWallpaper() async {
    state = null;
    final settingsService = ref.read(settingsServiceProvider);
    await settingsService.setChatWallpaper(null);
  }
}

/// Provider that builds the current ThemeData
@riverpod
ThemeData appTheme(Ref ref) {
  final themeMode = ref.watch(themeModeProvider);
  final fontSize = ref.watch(fontSizeProvider);
  final accentColor = ref.watch(accentColorProvider);

  return _buildTheme(themeMode, fontSize, accentColor);
}

/// Provider for the brightness (for widgets that need to know current brightness)
@riverpod
Brightness appBrightness(Ref ref) {
  final themeMode = ref.watch(themeModeProvider);
  switch (themeMode) {
    case AppThemeMode.light:
      return Brightness.light;
    case AppThemeMode.dark:
      return Brightness.dark;
    case AppThemeMode.system:
      return SchedulerBinding.instance.platformDispatcher.platformBrightness;
  }
}

ThemeData _buildTheme(
  AppThemeMode mode,
  AppFontSize fontSize,
  Color accentColor,
) {
  final brightness = _getBrightness(mode);
  final textScale = _getTextScale(fontSize);

  final baseTheme = brightness == Brightness.dark
      ? AppTheme.darkTheme
      : AppTheme.lightTheme;

  // Create color scheme with custom accent color
  final colorScheme = ColorScheme.fromSeed(
    seedColor: accentColor,
    brightness: brightness,
  );

  return baseTheme.copyWith(
    colorScheme: colorScheme,
    textTheme: _scaleTextTheme(baseTheme.textTheme, textScale),
    appBarTheme: baseTheme.appBarTheme.copyWith(backgroundColor: accentColor),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}

Brightness _getBrightness(AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.light:
      return Brightness.light;
    case AppThemeMode.dark:
      return Brightness.dark;
    case AppThemeMode.system:
      return SchedulerBinding.instance.platformDispatcher.platformBrightness;
  }
}

double _getTextScale(AppFontSize fontSize) {
  switch (fontSize) {
    case AppFontSize.small:
      return 0.85;
    case AppFontSize.medium:
      return 1;
    case AppFontSize.large:
      return 1.15;
    case AppFontSize.extraLarge:
      return 1.3;
  }
}

TextTheme _scaleTextTheme(TextTheme base, double scale) {
  return TextTheme(
    displayLarge: base.displayLarge?.copyWith(
      fontSize: (base.displayLarge?.fontSize ?? 57) * scale,
    ),
    displayMedium: base.displayMedium?.copyWith(
      fontSize: (base.displayMedium?.fontSize ?? 45) * scale,
    ),
    displaySmall: base.displaySmall?.copyWith(
      fontSize: (base.displaySmall?.fontSize ?? 36) * scale,
    ),
    headlineLarge: base.headlineLarge?.copyWith(
      fontSize: (base.headlineLarge?.fontSize ?? 32) * scale,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontSize: (base.headlineMedium?.fontSize ?? 28) * scale,
    ),
    headlineSmall: base.headlineSmall?.copyWith(
      fontSize: (base.headlineSmall?.fontSize ?? 24) * scale,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontSize: (base.titleLarge?.fontSize ?? 22) * scale,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontSize: (base.titleMedium?.fontSize ?? 16) * scale,
    ),
    titleSmall: base.titleSmall?.copyWith(
      fontSize: (base.titleSmall?.fontSize ?? 14) * scale,
    ),
    bodyLarge: base.bodyLarge?.copyWith(
      fontSize: (base.bodyLarge?.fontSize ?? 16) * scale,
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      fontSize: (base.bodyMedium?.fontSize ?? 14) * scale,
    ),
    bodySmall: base.bodySmall?.copyWith(
      fontSize: (base.bodySmall?.fontSize ?? 12) * scale,
    ),
    labelLarge: base.labelLarge?.copyWith(
      fontSize: (base.labelLarge?.fontSize ?? 14) * scale,
    ),
    labelMedium: base.labelMedium?.copyWith(
      fontSize: (base.labelMedium?.fontSize ?? 12) * scale,
    ),
    labelSmall: base.labelSmall?.copyWith(
      fontSize: (base.labelSmall?.fontSize ?? 11) * scale,
    ),
  );
}

/// Extension methods for theme-related helpers
extension ThemeModeExtension on AppThemeMode {
  String get displayName {
    switch (this) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System default';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}

extension FontSizeExtension on AppFontSize {
  String get displayName {
    switch (this) {
      case AppFontSize.small:
        return 'Small';
      case AppFontSize.medium:
        return 'Medium';
      case AppFontSize.large:
        return 'Large';
      case AppFontSize.extraLarge:
        return 'Extra Large';
    }
  }
}
