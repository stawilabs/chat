// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages download progress state for multiple concurrent downloads
///
/// Uses [ContentResolver] for downloading files via MXC or legacy URLs.
///
/// Example:
/// ```dart
/// // Watch a specific download's progress
/// final progress = ref.watch(downloadProgressProvider)['dl-123'];
///
/// // Start a download
/// ref.read(downloadProgressProvider.notifier).startDownload(
///   fileUrl: 'https://files.example.com/v1/content/media_id',
///   downloadId: 'dl-123',
/// );
/// ```

@ProviderFor(DownloadProgressNotifier)
final downloadProgressProvider = DownloadProgressNotifierProvider._();

/// Manages download progress state for multiple concurrent downloads
///
/// Uses [ContentResolver] for downloading files via MXC or legacy URLs.
///
/// Example:
/// ```dart
/// // Watch a specific download's progress
/// final progress = ref.watch(downloadProgressProvider)['dl-123'];
///
/// // Start a download
/// ref.read(downloadProgressProvider.notifier).startDownload(
///   fileUrl: 'https://files.example.com/v1/content/media_id',
///   downloadId: 'dl-123',
/// );
/// ```
final class DownloadProgressNotifierProvider
    extends
        $NotifierProvider<
          DownloadProgressNotifier,
          Map<String, DownloadProgress>
        > {
  /// Manages download progress state for multiple concurrent downloads
  ///
  /// Uses [ContentResolver] for downloading files via MXC or legacy URLs.
  ///
  /// Example:
  /// ```dart
  /// // Watch a specific download's progress
  /// final progress = ref.watch(downloadProgressProvider)['dl-123'];
  ///
  /// // Start a download
  /// ref.read(downloadProgressProvider.notifier).startDownload(
  ///   fileUrl: 'https://files.example.com/v1/content/media_id',
  ///   downloadId: 'dl-123',
  /// );
  /// ```
  DownloadProgressNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadProgressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadProgressNotifierHash();

  @$internal
  @override
  DownloadProgressNotifier create() => DownloadProgressNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, DownloadProgress> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, DownloadProgress>>(
        value,
      ),
    );
  }
}

String _$downloadProgressNotifierHash() =>
    r'4785c1cad39f0e4a66f14d36193d4b1ef6bd6025';

/// Manages download progress state for multiple concurrent downloads
///
/// Uses [ContentResolver] for downloading files via MXC or legacy URLs.
///
/// Example:
/// ```dart
/// // Watch a specific download's progress
/// final progress = ref.watch(downloadProgressProvider)['dl-123'];
///
/// // Start a download
/// ref.read(downloadProgressProvider.notifier).startDownload(
///   fileUrl: 'https://files.example.com/v1/content/media_id',
///   downloadId: 'dl-123',
/// );
/// ```

abstract class _$DownloadProgressNotifier
    extends $Notifier<Map<String, DownloadProgress>> {
  Map<String, DownloadProgress> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              Map<String, DownloadProgress>,
              Map<String, DownloadProgress>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, DownloadProgress>,
                Map<String, DownloadProgress>
              >,
              Map<String, DownloadProgress>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider for a specific download's progress

@ProviderFor(singleDownloadProgress)
final singleDownloadProgressProvider = SingleDownloadProgressFamily._();

/// Provider for a specific download's progress

final class SingleDownloadProgressProvider
    extends
        $FunctionalProvider<
          DownloadProgress?,
          DownloadProgress?,
          DownloadProgress?
        >
    with $Provider<DownloadProgress?> {
  /// Provider for a specific download's progress
  SingleDownloadProgressProvider._({
    required SingleDownloadProgressFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'singleDownloadProgressProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$singleDownloadProgressHash();

  @override
  String toString() {
    return r'singleDownloadProgressProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<DownloadProgress?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DownloadProgress? create(Ref ref) {
    final argument = this.argument as String;
    return singleDownloadProgress(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DownloadProgress? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DownloadProgress?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SingleDownloadProgressProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$singleDownloadProgressHash() =>
    r'93ce005de13bb6c7531e06acdbe2ddd2809d699a';

/// Provider for a specific download's progress

final class SingleDownloadProgressFamily extends $Family
    with $FunctionalFamilyOverride<DownloadProgress?, String> {
  SingleDownloadProgressFamily._()
    : super(
        retry: null,
        name: r'singleDownloadProgressProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for a specific download's progress

  SingleDownloadProgressProvider call(String downloadId) =>
      SingleDownloadProgressProvider._(argument: downloadId, from: this);

  @override
  String toString() => r'singleDownloadProgressProvider';
}

/// Provider for checking if a specific download is active

@ProviderFor(isDownloading)
final isDownloadingProvider = IsDownloadingFamily._();

/// Provider for checking if a specific download is active

final class IsDownloadingProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Provider for checking if a specific download is active
  IsDownloadingProvider._({
    required IsDownloadingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isDownloadingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isDownloadingHash();

  @override
  String toString() {
    return r'isDownloadingProvider'
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
    return isDownloading(ref, argument);
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
    return other is IsDownloadingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isDownloadingHash() => r'08cb53079a0f48fde6c184eecc4624613e905904';

/// Provider for checking if a specific download is active

final class IsDownloadingFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  IsDownloadingFamily._()
    : super(
        retry: null,
        name: r'isDownloadingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for checking if a specific download is active

  IsDownloadingProvider call(String downloadId) =>
      IsDownloadingProvider._(argument: downloadId, from: this);

  @override
  String toString() => r'isDownloadingProvider';
}

/// Provider for active download count

@ProviderFor(activeDownloadCount)
final activeDownloadCountProvider = ActiveDownloadCountProvider._();

/// Provider for active download count

final class ActiveDownloadCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Provider for active download count
  ActiveDownloadCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeDownloadCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeDownloadCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return activeDownloadCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$activeDownloadCountHash() =>
    r'64badcc5824b50e35efd97bf0001797f711f5797';

/// Provider for total download progress across all active downloads

@ProviderFor(totalDownloadProgress)
final totalDownloadProgressProvider = TotalDownloadProgressProvider._();

/// Provider for total download progress across all active downloads

final class TotalDownloadProgressProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  /// Provider for total download progress across all active downloads
  TotalDownloadProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalDownloadProgressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalDownloadProgressHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return totalDownloadProgress(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$totalDownloadProgressHash() =>
    r'c027c028cd0e825c2cf95e32433547a639d61d54';

/// Provider for TransferQueueService

@ProviderFor(transferQueueService)
final transferQueueServiceProvider = TransferQueueServiceProvider._();

/// Provider for TransferQueueService

final class TransferQueueServiceProvider
    extends
        $FunctionalProvider<
          TransferQueueService,
          TransferQueueService,
          TransferQueueService
        >
    with $Provider<TransferQueueService> {
  /// Provider for TransferQueueService
  TransferQueueServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transferQueueServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transferQueueServiceHash();

  @$internal
  @override
  $ProviderElement<TransferQueueService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TransferQueueService create(Ref ref) {
    return transferQueueService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransferQueueService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransferQueueService>(value),
    );
  }
}

String _$transferQueueServiceHash() =>
    r'9c6673fd23a71cff8a97f0074bb156bc635ce5fd';

/// Provider for pending upload count

@ProviderFor(pendingUploadCount)
final pendingUploadCountProvider = PendingUploadCountProvider._();

/// Provider for pending upload count

final class PendingUploadCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Provider for pending upload count
  PendingUploadCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingUploadCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingUploadCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return pendingUploadCount(ref);
  }
}

String _$pendingUploadCountHash() =>
    r'e63e11d7e657fa30a32f01536e5d30803b113c67';

/// Provider for pending download count

@ProviderFor(pendingDownloadCount)
final pendingDownloadCountProvider = PendingDownloadCountProvider._();

/// Provider for pending download count

final class PendingDownloadCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Provider for pending download count
  PendingDownloadCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingDownloadCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingDownloadCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return pendingDownloadCount(ref);
  }
}

String _$pendingDownloadCountHash() =>
    r'd2ceb1b9599df65493fada9507d63cea36492516';

/// Provider for total pending bytes

@ProviderFor(totalPendingBytes)
final totalPendingBytesProvider = TotalPendingBytesProvider._();

/// Provider for total pending bytes

final class TotalPendingBytesProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Provider for total pending bytes
  TotalPendingBytesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalPendingBytesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalPendingBytesHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return totalPendingBytes(ref);
  }
}

String _$totalPendingBytesHash() => r'697c600c6d2cb6a9d4d779ece531ddf0cb029acf';

/// Provider for total transferred bytes

@ProviderFor(totalTransferredBytes)
final totalTransferredBytesProvider = TotalTransferredBytesProvider._();

/// Provider for total transferred bytes

final class TotalTransferredBytesProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Provider for total transferred bytes
  TotalTransferredBytesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalTransferredBytesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalTransferredBytesHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return totalTransferredBytes(ref);
  }
}

String _$totalTransferredBytesHash() =>
    r'011d136415074f21b24e5739fa052a61b86a5471';

/// Provider for checking if there are any active transfers

@ProviderFor(hasActiveTransfers)
final hasActiveTransfersProvider = HasActiveTransfersProvider._();

/// Provider for checking if there are any active transfers

final class HasActiveTransfersProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Provider for checking if there are any active transfers
  HasActiveTransfersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasActiveTransfersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasActiveTransfersHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return hasActiveTransfers(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$hasActiveTransfersHash() =>
    r'54a0c67518a76b350daf251185da070585681a1b';

/// Provider for overall transfer progress (uploads + downloads)

@ProviderFor(overallTransferProgress)
final overallTransferProgressProvider = OverallTransferProgressProvider._();

/// Provider for overall transfer progress (uploads + downloads)

final class OverallTransferProgressProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  /// Provider for overall transfer progress (uploads + downloads)
  OverallTransferProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'overallTransferProgressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$overallTransferProgressHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return overallTransferProgress(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$overallTransferProgressHash() =>
    r'7715b1adb0a2b2994ed5c5aa6191493460dec87b';

/// Provider that automatically shows/updates transfer notifications
///
/// This provider watches upload and download progress state notifiers
/// and shows appropriate notifications.

@ProviderFor(TransferNotifications)
final transferNotificationsProvider = TransferNotificationsProvider._();

/// Provider that automatically shows/updates transfer notifications
///
/// This provider watches upload and download progress state notifiers
/// and shows appropriate notifications.
final class TransferNotificationsProvider
    extends $NotifierProvider<TransferNotifications, bool> {
  /// Provider that automatically shows/updates transfer notifications
  ///
  /// This provider watches upload and download progress state notifiers
  /// and shows appropriate notifications.
  TransferNotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transferNotificationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transferNotificationsHash();

  @$internal
  @override
  TransferNotifications create() => TransferNotifications();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$transferNotificationsHash() =>
    r'4543af100cb315660c9dc134fee349377e191025';

/// Provider that automatically shows/updates transfer notifications
///
/// This provider watches upload and download progress state notifiers
/// and shows appropriate notifications.

abstract class _$TransferNotifications extends $Notifier<bool> {
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

/// Provider to activate transfer notifications

@ProviderFor(transferNotificationsActive)
final transferNotificationsActiveProvider =
    TransferNotificationsActiveProvider._();

/// Provider to activate transfer notifications

final class TransferNotificationsActiveProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Provider to activate transfer notifications
  TransferNotificationsActiveProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transferNotificationsActiveProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transferNotificationsActiveHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return transferNotificationsActive(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$transferNotificationsActiveHash() =>
    r'b9f6781168cfa06cf29e6949422dbe0251963c94';
