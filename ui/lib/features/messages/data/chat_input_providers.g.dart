// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_input_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EmojiPanelVisibility)
final emojiPanelVisibilityProvider = EmojiPanelVisibilityProvider._();

final class EmojiPanelVisibilityProvider
    extends $NotifierProvider<EmojiPanelVisibility, bool> {
  EmojiPanelVisibilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'emojiPanelVisibilityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$emojiPanelVisibilityHash();

  @$internal
  @override
  EmojiPanelVisibility create() => EmojiPanelVisibility();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$emojiPanelVisibilityHash() =>
    r'b3893117f05852a691b534a325a0427687ee413e';

abstract class _$EmojiPanelVisibility extends $Notifier<bool> {
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

@ProviderFor(typingState)
final typingStateProvider = TypingStateProvider._();

final class TypingStateProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  TypingStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'typingStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$typingStateHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return typingState(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$typingStateHash() => r'4c060f55d426cef7aa7f2e5511c35052858180b5';

@ProviderFor(TypingNotifier)
final typingProvider = TypingNotifierProvider._();

final class TypingNotifierProvider
    extends $NotifierProvider<TypingNotifier, bool> {
  TypingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'typingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$typingNotifierHash();

  @$internal
  @override
  TypingNotifier create() => TypingNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$typingNotifierHash() => r'ca15370a1e2b071b15be3cc5ac414b697c002f02';

abstract class _$TypingNotifier extends $Notifier<bool> {
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
