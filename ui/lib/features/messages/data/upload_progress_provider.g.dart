// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_progress_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages upload progress state for multiple concurrent uploads
///
/// Provides methods to start, cancel, retry, and track uploads
/// using [FilesUploadService] for proto-based streaming uploads.
///
/// Example:
/// ```dart
/// // Watch a specific upload's progress
/// final progress = ref.watch(uploadProgressProvider)['msg-123'];
///
/// // Start an upload
/// ref.read(uploadProgressProvider.notifier).startUpload(file, 'msg-123');
/// ```

@ProviderFor(UploadProgressNotifier)
final uploadProgressProvider = UploadProgressNotifierProvider._();

/// Manages upload progress state for multiple concurrent uploads
///
/// Provides methods to start, cancel, retry, and track uploads
/// using [FilesUploadService] for proto-based streaming uploads.
///
/// Example:
/// ```dart
/// // Watch a specific upload's progress
/// final progress = ref.watch(uploadProgressProvider)['msg-123'];
///
/// // Start an upload
/// ref.read(uploadProgressProvider.notifier).startUpload(file, 'msg-123');
/// ```
final class UploadProgressNotifierProvider
    extends
        $NotifierProvider<UploadProgressNotifier, Map<String, UploadProgress>> {
  /// Manages upload progress state for multiple concurrent uploads
  ///
  /// Provides methods to start, cancel, retry, and track uploads
  /// using [FilesUploadService] for proto-based streaming uploads.
  ///
  /// Example:
  /// ```dart
  /// // Watch a specific upload's progress
  /// final progress = ref.watch(uploadProgressProvider)['msg-123'];
  ///
  /// // Start an upload
  /// ref.read(uploadProgressProvider.notifier).startUpload(file, 'msg-123');
  /// ```
  UploadProgressNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uploadProgressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uploadProgressNotifierHash();

  @$internal
  @override
  UploadProgressNotifier create() => UploadProgressNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, UploadProgress> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, UploadProgress>>(value),
    );
  }
}

String _$uploadProgressNotifierHash() =>
    r'1a05fee8c2721a6441399e62f64d212aa639440f';

/// Manages upload progress state for multiple concurrent uploads
///
/// Provides methods to start, cancel, retry, and track uploads
/// using [FilesUploadService] for proto-based streaming uploads.
///
/// Example:
/// ```dart
/// // Watch a specific upload's progress
/// final progress = ref.watch(uploadProgressProvider)['msg-123'];
///
/// // Start an upload
/// ref.read(uploadProgressProvider.notifier).startUpload(file, 'msg-123');
/// ```

abstract class _$UploadProgressNotifier
    extends $Notifier<Map<String, UploadProgress>> {
  Map<String, UploadProgress> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<Map<String, UploadProgress>, Map<String, UploadProgress>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, UploadProgress>,
                Map<String, UploadProgress>
              >,
              Map<String, UploadProgress>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider for a specific upload's progress
///
/// Example:
/// ```dart
/// final progress = ref.watch(singleUploadProgressProvider('msg-123'));
/// if (progress != null && progress.isInProgress) {
///   // Show progress indicator
/// }
/// ```

@ProviderFor(singleUploadProgress)
final singleUploadProgressProvider = SingleUploadProgressFamily._();

/// Provider for a specific upload's progress
///
/// Example:
/// ```dart
/// final progress = ref.watch(singleUploadProgressProvider('msg-123'));
/// if (progress != null && progress.isInProgress) {
///   // Show progress indicator
/// }
/// ```

final class SingleUploadProgressProvider
    extends
        $FunctionalProvider<UploadProgress?, UploadProgress?, UploadProgress?>
    with $Provider<UploadProgress?> {
  /// Provider for a specific upload's progress
  ///
  /// Example:
  /// ```dart
  /// final progress = ref.watch(singleUploadProgressProvider('msg-123'));
  /// if (progress != null && progress.isInProgress) {
  ///   // Show progress indicator
  /// }
  /// ```
  SingleUploadProgressProvider._({
    required SingleUploadProgressFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'singleUploadProgressProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$singleUploadProgressHash();

  @override
  String toString() {
    return r'singleUploadProgressProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<UploadProgress?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UploadProgress? create(Ref ref) {
    final argument = this.argument as String;
    return singleUploadProgress(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UploadProgress? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UploadProgress?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SingleUploadProgressProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$singleUploadProgressHash() =>
    r'5dce156c0917b20174dfe7253e1c9b7c7d052d0a';

/// Provider for a specific upload's progress
///
/// Example:
/// ```dart
/// final progress = ref.watch(singleUploadProgressProvider('msg-123'));
/// if (progress != null && progress.isInProgress) {
///   // Show progress indicator
/// }
/// ```

final class SingleUploadProgressFamily extends $Family
    with $FunctionalFamilyOverride<UploadProgress?, String> {
  SingleUploadProgressFamily._()
    : super(
        retry: null,
        name: r'singleUploadProgressProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for a specific upload's progress
  ///
  /// Example:
  /// ```dart
  /// final progress = ref.watch(singleUploadProgressProvider('msg-123'));
  /// if (progress != null && progress.isInProgress) {
  ///   // Show progress indicator
  /// }
  /// ```

  SingleUploadProgressProvider call(String localId) =>
      SingleUploadProgressProvider._(argument: localId, from: this);

  @override
  String toString() => r'singleUploadProgressProvider';
}

/// Provider for checking if a specific upload is active

@ProviderFor(isUploading)
final isUploadingProvider = IsUploadingFamily._();

/// Provider for checking if a specific upload is active

final class IsUploadingProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Provider for checking if a specific upload is active
  IsUploadingProvider._({
    required IsUploadingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isUploadingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isUploadingHash();

  @override
  String toString() {
    return r'isUploadingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return isUploading(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IsUploadingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isUploadingHash() => r'4c40e92bf35e51947e35a4c98f70b4a05bf62458';

/// Provider for checking if a specific upload is active

final class IsUploadingFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  IsUploadingFamily._()
    : super(
        retry: null,
        name: r'isUploadingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for checking if a specific upload is active

  IsUploadingProvider call(String localId) =>
      IsUploadingProvider._(argument: localId, from: this);

  @override
  String toString() => r'isUploadingProvider';
}

/// Provider for active upload count

@ProviderFor(activeUploadCount)
final activeUploadCountProvider = ActiveUploadCountProvider._();

/// Provider for active upload count

final class ActiveUploadCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Provider for active upload count
  ActiveUploadCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeUploadCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeUploadCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return activeUploadCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$activeUploadCountHash() => r'1c9e681242e5a598c4f18c769ece64bcd3be0c12';

/// Provider for total upload progress across all active uploads

@ProviderFor(totalUploadProgress)
final totalUploadProgressProvider = TotalUploadProgressProvider._();

/// Provider for total upload progress across all active uploads

final class TotalUploadProgressProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  /// Provider for total upload progress across all active uploads
  TotalUploadProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalUploadProgressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalUploadProgressHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return totalUploadProgress(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$totalUploadProgressHash() =>
    r'80a99e838fda0c1a0e2f96d97cd8e8352c624d80';
