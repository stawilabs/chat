// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pool_binding.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The pool binding of a room, null for a plain room.

@ProviderFor(poolBinding)
final poolBindingProvider = PoolBindingFamily._();

/// The pool binding of a room, null for a plain room.

final class PoolBindingProvider
    extends
        $FunctionalProvider<
          AsyncValue<PoolBinding?>,
          PoolBinding?,
          FutureOr<PoolBinding?>
        >
    with $FutureModifier<PoolBinding?>, $FutureProvider<PoolBinding?> {
  /// The pool binding of a room, null for a plain room.
  PoolBindingProvider._({
    required PoolBindingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'poolBindingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$poolBindingHash();

  @override
  String toString() {
    return r'poolBindingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PoolBinding?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PoolBinding?> create(Ref ref) {
    final argument = this.argument as String;
    return poolBinding(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PoolBindingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$poolBindingHash() => r'ebc669da928bbf3533cb14fb085a0bd3802bd4f0';

/// The pool binding of a room, null for a plain room.

final class PoolBindingFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PoolBinding?>, String> {
  PoolBindingFamily._()
    : super(
        retry: null,
        name: r'poolBindingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The pool binding of a room, null for a plain room.

  PoolBindingProvider call(String roomId) =>
      PoolBindingProvider._(argument: roomId, from: this);

  @override
  String toString() => r'poolBindingProvider';
}
