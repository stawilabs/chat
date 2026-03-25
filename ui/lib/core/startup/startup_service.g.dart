// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'startup_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages phased app initialization for optimized startup time

@ProviderFor(StartupService)
final startupServiceProvider = StartupServiceProvider._();

/// Manages phased app initialization for optimized startup time
final class StartupServiceProvider
    extends $NotifierProvider<StartupService, StartupProgress> {
  /// Manages phased app initialization for optimized startup time
  StartupServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startupServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startupServiceHash();

  @$internal
  @override
  StartupService create() => StartupService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StartupProgress value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StartupProgress>(value),
    );
  }
}

String _$startupServiceHash() => r'05edfee145d96c032e731a0123dbee0cea0d7240';

/// Manages phased app initialization for optimized startup time

abstract class _$StartupService extends $Notifier<StartupProgress> {
  StartupProgress build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<StartupProgress, StartupProgress>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<StartupProgress, StartupProgress>,
              StartupProgress,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
