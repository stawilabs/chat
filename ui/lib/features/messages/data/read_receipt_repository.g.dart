// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'read_receipt_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for ReadReceiptRepository

@ProviderFor(readReceiptRepository)
final readReceiptRepositoryProvider = ReadReceiptRepositoryProvider._();

/// Provider for ReadReceiptRepository

final class ReadReceiptRepositoryProvider
    extends
        $FunctionalProvider<
          ReadReceiptRepository,
          ReadReceiptRepository,
          ReadReceiptRepository
        >
    with $Provider<ReadReceiptRepository> {
  /// Provider for ReadReceiptRepository
  ReadReceiptRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readReceiptRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readReceiptRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReadReceiptRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReadReceiptRepository create(Ref ref) {
    return readReceiptRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReadReceiptRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReadReceiptRepository>(value),
    );
  }
}

String _$readReceiptRepositoryHash() =>
    r'ce0658f4769a2599baf1cb9db3dda6a8a36203d9';

/// Provider for watching readers of a specific message

@ProviderFor(messageReaders)
final messageReadersProvider = MessageReadersFamily._();

/// Provider for watching readers of a specific message

final class MessageReadersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ReadReceiptInfo>>,
          List<ReadReceiptInfo>,
          Stream<List<ReadReceiptInfo>>
        >
    with
        $FutureModifier<List<ReadReceiptInfo>>,
        $StreamProvider<List<ReadReceiptInfo>> {
  /// Provider for watching readers of a specific message
  MessageReadersProvider._({
    required MessageReadersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'messageReadersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$messageReadersHash();

  @override
  String toString() {
    return r'messageReadersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ReadReceiptInfo>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ReadReceiptInfo>> create(Ref ref) {
    final argument = this.argument as String;
    return messageReaders(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MessageReadersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$messageReadersHash() => r'e43e02a9540fdb2c2b47dbee1fd1d927a705f0e0';

/// Provider for watching readers of a specific message

final class MessageReadersFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<ReadReceiptInfo>>, String> {
  MessageReadersFamily._()
    : super(
        retry: null,
        name: r'messageReadersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for watching readers of a specific message

  MessageReadersProvider call(String eventId) =>
      MessageReadersProvider._(argument: eventId, from: this);

  @override
  String toString() => r'messageReadersProvider';
}
