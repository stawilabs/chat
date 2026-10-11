import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:connectrpc/connect.dart' as connect;
import 'package:stawi/features/messages/domain/room_event.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

/// A Connect transport that answers unary calls from handlers registered per
/// procedure, so the generated stawi_api clients run unchanged in tests.
class FakeConnectTransport implements connect.Transport {
  final Map<String, FutureOr<Object> Function(Object input)> _handlers = {};

  /// Every call made, in order: (procedure, request).
  final List<(String, Object)> calls = [];

  void on<I extends Object, O extends Object>(
    connect.Spec<I, O> spec,
    FutureOr<O> Function(I input) handler,
  ) {
    _handlers[spec.procedure] = (input) => handler(input as I);
  }

  List<I> requestsTo<I extends Object, O extends Object>(
    connect.Spec<I, O> spec,
  ) => [
    for (final (procedure, input) in calls)
      if (procedure == spec.procedure) input as I,
  ];

  @override
  Future<connect.UnaryResponse<I, O>> unary<I extends Object, O extends Object>(
    connect.Spec<I, O> spec,
    I input, [
    connect.CallOptions? options,
  ]) async {
    calls.add((spec.procedure, input));
    final handler = _handlers[spec.procedure];
    if (handler == null) {
      throw connect.ConnectException(
        connect.Code.unimplemented,
        'no fake for ${spec.procedure}',
      );
    }
    final output = await handler(input) as O;
    return connect.UnaryResponse(
      spec,
      connect.Headers(),
      output,
      connect.Headers(),
    );
  }

  @override
  Future<connect.StreamResponse<I, O>>
  stream<I extends Object, O extends Object>(
    connect.Spec<I, O> spec,
    Stream<I> input, [
    connect.CallOptions? options,
  ]) => throw UnimplementedError('streams are not faked');
}

/// An in-memory [DeviceKeyVault].
class MemoryDeviceKeyVault implements DeviceKeyVault {
  final Map<String, String> entries = {};
  int writes = 0;

  @override
  Future<String?> read(String key) async => entries[key];

  @override
  Future<void> write(String key, String value) async {
    writes++;
    entries[key] = value;
  }
}

/// A sent Stawi act, as the fake sender records it.
class SentAct {
  SentAct(this.roomId, this.type, this.content, this.parentId);

  final String roomId;
  final RoomEventType type;
  final Map<String, dynamic> content;
  final String? parentId;
}

/// Records acts instead of queueing them for chat.
class RecordingActSender {
  final List<SentAct> sent = [];

  Future<RoomEvent> call({
    required String roomId,
    required RoomEventType type,
    required Map<String, dynamic> content,
    String? parentId,
  }) async {
    sent.add(SentAct(roomId, type, content, parentId));
    return RoomEvent(
      id: 'evt${sent.length}',
      roomId: roomId,
      senderId: 'sub-me',
      type: type,
      content: content,
      parentId: parentId,
      createdAt: 0,
    );
  }
}

/// The Go-produced signing vectors shipped with stawi_finance_sdk 0.1.0
/// (pkg/evm/stawi TestDartSignedCallVectors), copied to test/fixtures.
class GoSignedCallVectors {
  GoSignedCallVectors._(this._json);

  factory GoSignedCallVectors.load() => GoSignedCallVectors._(
    jsonDecode(
          File('test/fixtures/stawi/go_signed_calls.json').readAsStringSync(),
        )
        as Map<String, dynamic>,
  );

  final Map<String, dynamic> _json;

  List<Map<String, dynamic>> section(String name) =>
      (_json[name] as List).cast<Map<String, dynamic>>();

  List<Map<String, dynamic>> get preparedCallSignatures =>
      section('prepared_call_signatures');

  List<Map<String, dynamic>> get accountWrappedHashes =>
      section('account_wrapped_hash');
}

/// The anvil account-0 key the Go vectors sign with.
const String anvilKey =
    '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';

/// A vault already holding [privateKeyHex] for [profileId].
MemoryDeviceKeyVault vaultWith(String profileId, String privateKeyHex) {
  final vault = MemoryDeviceKeyVault();
  vault.entries['stawi.device_key.v1.$profileId'] = bytesToHex(
    hexToBytes(privateKeyHex),
  );
  return vault;
}

/// A signed-in member owning [account].
StawiIdentity identityWith(String profileId, Uint8List account) =>
    StawiIdentity(
      profileId: profileId,
      accounts: [StawiAccountRef(address: account, primary: true)],
    );
