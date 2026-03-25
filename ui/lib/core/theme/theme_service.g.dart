// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for theme mode

@ProviderFor(ThemeModeNotifier)
final themeModeProvider = ThemeModeNotifierProvider._();

/// Notifier for theme mode
final class ThemeModeNotifierProvider
    extends $NotifierProvider<ThemeModeNotifier, AppThemeMode> {
  /// Notifier for theme mode
  ThemeModeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeNotifierHash();

  @$internal
  @override
  ThemeModeNotifier create() => ThemeModeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppThemeMode>(value),
    );
  }
}

String _$themeModeNotifierHash() => r'eefa654a93313a6c9ea9b320566c41917448130d';

/// Notifier for theme mode

abstract class _$ThemeModeNotifier extends $Notifier<AppThemeMode> {
  AppThemeMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AppThemeMode, AppThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppThemeMode, AppThemeMode>,
              AppThemeMode,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Notifier for font size

@ProviderFor(FontSizeNotifier)
final fontSizeProvider = FontSizeNotifierProvider._();

/// Notifier for font size
final class FontSizeNotifierProvider
    extends $NotifierProvider<FontSizeNotifier, AppFontSize> {
  /// Notifier for font size
  FontSizeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fontSizeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fontSizeNotifierHash();

  @$internal
  @override
  FontSizeNotifier create() => FontSizeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppFontSize value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppFontSize>(value),
    );
  }
}

String _$fontSizeNotifierHash() => r'bd6f57f31ccb2c593d24f42aad30facbd3cebe1a';

/// Notifier for font size

abstract class _$FontSizeNotifier extends $Notifier<AppFontSize> {
  AppFontSize build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AppFontSize, AppFontSize>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppFontSize, AppFontSize>,
              AppFontSize,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Notifier for accent color

@ProviderFor(AccentColorNotifier)
final accentColorProvider = AccentColorNotifierProvider._();

/// Notifier for accent color
final class AccentColorNotifierProvider
    extends $NotifierProvider<AccentColorNotifier, Color> {
  /// Notifier for accent color
  AccentColorNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accentColorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accentColorNotifierHash();

  @$internal
  @override
  AccentColorNotifier create() => AccentColorNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Color value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Color>(value),
    );
  }
}

String _$accentColorNotifierHash() =>
    r'ff75dafa7b91426c804cc765bb922df216d4d603';

/// Notifier for accent color

abstract class _$AccentColorNotifier extends $Notifier<Color> {
  Color build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Color, Color>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Color, Color>,
              Color,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Notifier for chat wallpaper

@ProviderFor(ChatWallpaperNotifier)
final chatWallpaperProvider = ChatWallpaperNotifierProvider._();

/// Notifier for chat wallpaper
final class ChatWallpaperNotifierProvider
    extends $NotifierProvider<ChatWallpaperNotifier, String?> {
  /// Notifier for chat wallpaper
  ChatWallpaperNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatWallpaperProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatWallpaperNotifierHash();

  @$internal
  @override
  ChatWallpaperNotifier create() => ChatWallpaperNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$chatWallpaperNotifierHash() =>
    r'3204c3976f65a042c5434f8d54a09d068b35e169';

/// Notifier for chat wallpaper

abstract class _$ChatWallpaperNotifier extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider that builds the current ThemeData

@ProviderFor(appTheme)
final appThemeProvider = AppThemeProvider._();

/// Provider that builds the current ThemeData

final class AppThemeProvider
    extends $FunctionalProvider<ThemeData, ThemeData, ThemeData>
    with $Provider<ThemeData> {
  /// Provider that builds the current ThemeData
  AppThemeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appThemeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appThemeHash();

  @$internal
  @override
  $ProviderElement<ThemeData> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ThemeData create(Ref ref) {
    return appTheme(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeData>(value),
    );
  }
}

String _$appThemeHash() => r'7b36d453c8bf9a1c483e1a2a619e85f4db4f82b0';

/// Provider for the brightness (for widgets that need to know current brightness)

@ProviderFor(appBrightness)
final appBrightnessProvider = AppBrightnessProvider._();

/// Provider for the brightness (for widgets that need to know current brightness)

final class AppBrightnessProvider
    extends $FunctionalProvider<Brightness, Brightness, Brightness>
    with $Provider<Brightness> {
  /// Provider for the brightness (for widgets that need to know current brightness)
  AppBrightnessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appBrightnessProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appBrightnessHash();

  @$internal
  @override
  $ProviderElement<Brightness> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Brightness create(Ref ref) {
    return appBrightness(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Brightness value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Brightness>(value),
    );
  }
}

String _$appBrightnessHash() => r'5281ff7e2ed522fedcea5f3596a82c88634b14cd';
