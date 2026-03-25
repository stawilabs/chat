// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'typing_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Typing)
final typingProvider = TypingFamily._();

final class TypingProvider extends $NotifierProvider<Typing, Set<TypingUser>> {
  TypingProvider._({
    required TypingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'typingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$typingHash();

  @override
  String toString() {
    return r'typingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  Typing create() => Typing();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<TypingUser> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<TypingUser>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TypingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$typingHash() => r'36dcdb79d4ae23957cce27417faf511835a66ac2';

final class TypingFamily extends $Family
    with
        $ClassFamilyOverride<
          Typing,
          Set<TypingUser>,
          Set<TypingUser>,
          Set<TypingUser>,
          String
        > {
  TypingFamily._()
    : super(
        retry: null,
        name: r'typingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TypingProvider call(String roomId) =>
      TypingProvider._(argument: roomId, from: this);

  @override
  String toString() => r'typingProvider';
}

abstract class _$Typing extends $Notifier<Set<TypingUser>> {
  late final _$args = ref.$arg as String;
  String get roomId => _$args;

  Set<TypingUser> build(String roomId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<TypingUser>, Set<TypingUser>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<TypingUser>, Set<TypingUser>>,
              Set<TypingUser>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
