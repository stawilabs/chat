// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screenshot_prevention_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for ScreenshotPreventionService

@ProviderFor(screenshotPreventionService)
final screenshotPreventionServiceProvider =
    ScreenshotPreventionServiceProvider._();

/// Provider for ScreenshotPreventionService

final class ScreenshotPreventionServiceProvider
    extends
        $FunctionalProvider<
          ScreenshotPreventionService,
          ScreenshotPreventionService,
          ScreenshotPreventionService
        >
    with $Provider<ScreenshotPreventionService> {
  /// Provider for ScreenshotPreventionService
  ScreenshotPreventionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'screenshotPreventionServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$screenshotPreventionServiceHash();

  @$internal
  @override
  $ProviderElement<ScreenshotPreventionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ScreenshotPreventionService create(Ref ref) {
    return screenshotPreventionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScreenshotPreventionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScreenshotPreventionService>(value),
    );
  }
}

String _$screenshotPreventionServiceHash() =>
    r'f71407ea88aec05ef1b6367f23aa94cec2856d86';

/// Provider for screenshot prevention enabled state

@ProviderFor(ScreenshotPreventionEnabled)
final screenshotPreventionEnabledProvider =
    ScreenshotPreventionEnabledProvider._();

/// Provider for screenshot prevention enabled state
final class ScreenshotPreventionEnabledProvider
    extends $NotifierProvider<ScreenshotPreventionEnabled, bool> {
  /// Provider for screenshot prevention enabled state
  ScreenshotPreventionEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'screenshotPreventionEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$screenshotPreventionEnabledHash();

  @$internal
  @override
  ScreenshotPreventionEnabled create() => ScreenshotPreventionEnabled();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$screenshotPreventionEnabledHash() =>
    r'445bb7a205dc1156ace161e312ec5d1de127d628';

/// Provider for screenshot prevention enabled state

abstract class _$ScreenshotPreventionEnabled extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
