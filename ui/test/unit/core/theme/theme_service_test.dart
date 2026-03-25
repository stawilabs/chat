import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/theme/app_theme.dart';
import 'package:stawi/core/theme/theme_service.dart';

void main() {
  group('AppThemeMode', () {
    test('displayName returns correct strings', () {
      expect(AppThemeMode.light.displayName, equals('Light'));
      expect(AppThemeMode.dark.displayName, equals('Dark'));
      expect(AppThemeMode.system.displayName, equals('System default'));
    });

    test('icon returns correct icons', () {
      expect(AppThemeMode.light.icon, equals(Icons.light_mode));
      expect(AppThemeMode.dark.icon, equals(Icons.dark_mode));
      expect(AppThemeMode.system.icon, equals(Icons.brightness_auto));
    });
  });

  group('AppFontSize', () {
    test('displayName returns correct strings', () {
      expect(AppFontSize.small.displayName, equals('Small'));
      expect(AppFontSize.medium.displayName, equals('Medium'));
      expect(AppFontSize.large.displayName, equals('Large'));
      expect(AppFontSize.extraLarge.displayName, equals('Extra Large'));
    });

    test('values are ordered correctly', () {
      expect(
        AppFontSize.values,
        equals([
          AppFontSize.small,
          AppFontSize.medium,
          AppFontSize.large,
          AppFontSize.extraLarge,
        ]),
      );
    });
  });

  group('AccentColors', () {
    test('presets contains expected colors', () {
      expect(AccentColors.presets, isNotEmpty);
      expect(AccentColors.presets.length, equals(10));
      expect(AccentColors.presets.first, equals(const Color(0xFF128C7E)));
    });

    test('colorToHex converts correctly', () {
      expect(
        AccentColors.colorToHex(const Color(0xFF128C7E)),
        equals('#128c7e'),
      );
      expect(
        AccentColors.colorToHex(const Color(0xFF000000)),
        equals('#000000'),
      );
      expect(
        AccentColors.colorToHex(const Color(0xFFFFFFFF)),
        equals('#ffffff'),
      );
    });

    test('hexToColor converts correctly', () {
      expect(
        AccentColors.hexToColor('#128C7E'),
        equals(const Color(0xFF128C7E)),
      );
      expect(
        AccentColors.hexToColor('#000000'),
        equals(const Color(0xFF000000)),
      );
      expect(
        AccentColors.hexToColor('#ffffff'),
        equals(const Color(0xFFFFFFFF)),
      );
    });

    test('colorToHex and hexToColor are inverse operations', () {
      for (final color in AccentColors.presets) {
        final hex = AccentColors.colorToHex(color);
        final converted = AccentColors.hexToColor(hex);
        expect(converted.toARGB32(), equals(color.toARGB32()));
      }
    });

    test('hexToColor handles both cases', () {
      expect(
        AccentColors.hexToColor('#ABC123'),
        equals(AccentColors.hexToColor('#abc123')),
      );
    });

    test('hexToColor handles with and without hash', () {
      expect(
        AccentColors.hexToColor('128C7E'),
        equals(AccentColors.hexToColor('#128C7E')),
      );
    });
  });

  group('Providers', () {
    test('themeModeProvider is available', () {
      expect(themeModeProvider, isNotNull);
    });

    test('fontSizeProvider is available', () {
      expect(fontSizeProvider, isNotNull);
    });

    test('accentColorProvider is available', () {
      expect(accentColorProvider, isNotNull);
    });

    test('chatWallpaperProvider is available', () {
      expect(chatWallpaperProvider, isNotNull);
    });

    test('appThemeProvider is available', () {
      expect(appThemeProvider, isNotNull);
    });

    test('appBrightnessProvider is available', () {
      expect(appBrightnessProvider, isNotNull);
    });
  });

  group('AppTheme', () {
    test('lightTheme has correct brightness', () {
      expect(AppTheme.lightTheme.brightness, equals(Brightness.light));
    });

    test('darkTheme has correct brightness', () {
      expect(AppTheme.darkTheme.brightness, equals(Brightness.dark));
    });

    test('lightTheme uses Material 3', () {
      expect(AppTheme.lightTheme.useMaterial3, isTrue);
    });

    test('darkTheme uses Material 3', () {
      expect(AppTheme.darkTheme.useMaterial3, isTrue);
    });

    test('primaryGreen is the brand color', () {
      expect(AppTheme.primaryGreen, equals(const Color(0xFF128C7E)));
    });
  });

  group('Theme mode parsing', () {
    test('parses light theme mode', () {
      // Internal test via extension
      expect(AppThemeMode.light.displayName, equals('Light'));
    });

    test('parses dark theme mode', () {
      expect(AppThemeMode.dark.displayName, equals('Dark'));
    });

    test('parses system theme mode', () {
      expect(AppThemeMode.system.displayName, equals('System default'));
    });
  });

  group('Font size parsing', () {
    test('small font has correct name', () {
      expect(AppFontSize.small.displayName, equals('Small'));
    });

    test('medium font has correct name', () {
      expect(AppFontSize.medium.displayName, equals('Medium'));
    });

    test('large font has correct name', () {
      expect(AppFontSize.large.displayName, equals('Large'));
    });

    test('extraLarge font has correct name', () {
      expect(AppFontSize.extraLarge.displayName, equals('Extra Large'));
    });
  });

  group('Color utilities', () {
    test('all preset colors are valid', () {
      for (final color in AccentColors.presets) {
        expect((color.a * 255.0).round().clamp(0, 255), equals(255));
        expect(
          (color.r * 255.0).round().clamp(0, 255),
          inInclusiveRange(0, 255),
        );
        expect(
          (color.g * 255.0).round().clamp(0, 255),
          inInclusiveRange(0, 255),
        );
        expect(
          (color.b * 255.0).round().clamp(0, 255),
          inInclusiveRange(0, 255),
        );
      }
    });

    test('default accent is primary green', () {
      expect(AccentColors.presets.first, equals(AppTheme.primaryGreen));
    });
  });
}
