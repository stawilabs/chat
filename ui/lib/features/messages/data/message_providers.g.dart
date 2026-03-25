// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(messageRepository)
final messageRepositoryProvider = MessageRepositoryProvider._();

final class MessageRepositoryProvider
    extends
        $FunctionalProvider<
          MessageRepository,
          MessageRepository,
          MessageRepository
        >
    with $Provider<MessageRepository> {
  MessageRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageRepositoryHash();

  @$internal
  @override
  $ProviderElement<MessageRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MessageRepository create(Ref ref) {
    return messageRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessageRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessageRepository>(value),
    );
  }
}

String _$messageRepositoryHash() => r'64ea5109260c212ce4e111fa20a9f04f8d03dab0';

@ProviderFor(MessageList)
final messageListProvider = MessageListFamily._();

final class MessageListProvider
    extends $AsyncNotifierProvider<MessageList, List<domain.RoomEvent>> {
  MessageListProvider._({
    required MessageListFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'messageListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$messageListHash();

  @override
  String toString() {
    return r'messageListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MessageList create() => MessageList();

  @override
  bool operator ==(Object other) {
    return other is MessageListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$messageListHash() => r'0f67c333486756c1f527d8fa39856b65aa2d62b3';

final class MessageListFamily extends $Family
    with
        $ClassFamilyOverride<
          MessageList,
          AsyncValue<List<domain.RoomEvent>>,
          List<domain.RoomEvent>,
          FutureOr<List<domain.RoomEvent>>,
          String
        > {
  MessageListFamily._()
    : super(
        retry: null,
        name: r'messageListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MessageListProvider call(String roomId) =>
      MessageListProvider._(argument: roomId, from: this);

  @override
  String toString() => r'messageListProvider';
}

abstract class _$MessageList extends $AsyncNotifier<List<domain.RoomEvent>> {
  late final _$args = ref.$arg as String;
  String get roomId => _$args;

  FutureOr<List<domain.RoomEvent>> build(String roomId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<domain.RoomEvent>>, List<domain.RoomEvent>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<domain.RoomEvent>>,
                List<domain.RoomEvent>
              >,
              AsyncValue<List<domain.RoomEvent>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
