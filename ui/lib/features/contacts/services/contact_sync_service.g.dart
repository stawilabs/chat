// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_sync_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for ContactSyncService

@ProviderFor(contactSyncService)
final contactSyncServiceProvider = ContactSyncServiceProvider._();

/// Provider for ContactSyncService

final class ContactSyncServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<ContactSyncService>,
          ContactSyncService,
          FutureOr<ContactSyncService>
        >
    with
        $FutureModifier<ContactSyncService>,
        $FutureProvider<ContactSyncService> {
  /// Provider for ContactSyncService
  ContactSyncServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactSyncServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactSyncServiceHash();

  @$internal
  @override
  $FutureProviderElement<ContactSyncService> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ContactSyncService> create(Ref ref) {
    return contactSyncService(ref);
  }
}

String _$contactSyncServiceHash() =>
    r'2f0d916bc8336577c6f3553ae60710d4c75686e6';

/// Provider for contact sync status

@ProviderFor(contactSyncStatus)
final contactSyncStatusProvider = ContactSyncStatusProvider._();

/// Provider for contact sync status

final class ContactSyncStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<ContactSyncStatus>,
          ContactSyncStatus,
          FutureOr<ContactSyncStatus>
        >
    with
        $FutureModifier<ContactSyncStatus>,
        $FutureProvider<ContactSyncStatus> {
  /// Provider for contact sync status
  ContactSyncStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactSyncStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactSyncStatusHash();

  @$internal
  @override
  $FutureProviderElement<ContactSyncStatus> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ContactSyncStatus> create(Ref ref) {
    return contactSyncStatus(ref);
  }
}

String _$contactSyncStatusHash() => r'5ec336d05251acfa5e7e421bf8e95da6680c4713';

/// Provider to check if auto sync is enabled

@ProviderFor(contactAutoSyncEnabled)
final contactAutoSyncEnabledProvider = ContactAutoSyncEnabledProvider._();

/// Provider to check if auto sync is enabled

final class ContactAutoSyncEnabledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Provider to check if auto sync is enabled
  ContactAutoSyncEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactAutoSyncEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactAutoSyncEnabledHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return contactAutoSyncEnabled(ref);
  }
}

String _$contactAutoSyncEnabledHash() =>
    r'158b3f6712a347beefceb6855ca28b6b15d5dc76';

/// Provider to check if sync is due

@ProviderFor(contactSyncDue)
final contactSyncDueProvider = ContactSyncDueProvider._();

/// Provider to check if sync is due

final class ContactSyncDueProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Provider to check if sync is due
  ContactSyncDueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactSyncDueProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactSyncDueHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return contactSyncDue(ref);
  }
}

String _$contactSyncDueHash() => r'3b402051360b5db6ddd48c7e724c1e812365db78';
