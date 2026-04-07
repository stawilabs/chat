// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'form_message_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FormMessageController)
final formMessageControllerProvider = FormMessageControllerFamily._();

final class FormMessageControllerProvider
    extends $NotifierProvider<FormMessageController, FormMessageUiState> {
  FormMessageControllerProvider._({
    required FormMessageControllerFamily super.from,
    required domain.RoomEvent super.argument,
  }) : super(
         retry: null,
         name: r'formMessageControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$formMessageControllerHash();

  @override
  String toString() {
    return r'formMessageControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  FormMessageController create() => FormMessageController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FormMessageUiState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FormMessageUiState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FormMessageControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$formMessageControllerHash() =>
    r'2223a42e1fb9ead217159e5bba66b0a0614b8893';

final class FormMessageControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          FormMessageController,
          FormMessageUiState,
          FormMessageUiState,
          FormMessageUiState,
          domain.RoomEvent
        > {
  FormMessageControllerFamily._()
    : super(
        retry: null,
        name: r'formMessageControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FormMessageControllerProvider call(domain.RoomEvent message) =>
      FormMessageControllerProvider._(argument: message, from: this);

  @override
  String toString() => r'formMessageControllerProvider';
}

abstract class _$FormMessageController extends $Notifier<FormMessageUiState> {
  late final _$args = ref.$arg as domain.RoomEvent;
  domain.RoomEvent get message => _$args;

  FormMessageUiState build(domain.RoomEvent message);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FormMessageUiState, FormMessageUiState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FormMessageUiState, FormMessageUiState>,
              FormMessageUiState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
