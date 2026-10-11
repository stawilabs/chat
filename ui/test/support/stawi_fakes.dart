import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:connectrpc/connect.dart' as connect;
import 'package:fixnum/fixnum.dart';
import 'package:stawi/features/messages/domain/room_event.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';
import 'package:stawi/features/stawi/domain/stawi_money.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
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

/// One Go-produced account genesis (stawi_finance_sdk 0.2.0
/// test/vectors/go_genesis.json, pkg/evm/stawi): the device key, the identity
/// salt hash, the account, the initial policy, its hash, the genesis digest
/// and the device's signature over it.
class GoGenesisVector {
  GoGenesisVector(this.json);

  static List<GoGenesisVector> load() =>
      ((jsonDecode(
                    File(
                      'test/fixtures/stawi/go_genesis.json',
                    ).readAsStringSync(),
                  )
                  as Map<String, dynamic>)['genesis_device_digest']
              as List)
          .map((v) => GoGenesisVector(v as Map<String, dynamic>))
          .toList();

  final Map<String, dynamic> json;

  String get name => json['name'] as String;
  String get devicePrivateKey => json['device_private_key'] as String;
  Uint8List get device => hexToBytes(json['device'] as String);
  Uint8List get identitySaltHash =>
      hexToBytes(json['identity_salt_hash'] as String);
  Uint8List get account => hexToBytes(json['account'] as String);
  Uint8List get policyHash => hexToBytes(json['policy_hash'] as String);
  Uint8List get digest => hexToBytes(json['digest'] as String);
  String get signature => json['signature'] as String;

  finance.AccountPolicyParams get policy {
    final p = json['policy'] as Map<String, dynamic>;
    return finance.AccountPolicyParams(
      asset: hexToBytes(p['asset'] as String),
      periodLimit: p['period_limit'] as String,
      periodSeconds: _u64(p['period_seconds'] as String),
      epochStart: _u64(p['epoch_start'] as String),
      allowlist: [
        for (final a in p['allowlist'] as List) hexToBytes(a as String),
      ],
      guardians: [
        for (final g in p['guardians'] as List) hexToBytes(g as String),
      ],
      guardianThreshold: p['guardian_threshold'] as int,
      allowlistMode: finance.AccountDefaults_AllowlistMode.valueOf(
        p['allowlist_mode'] as int,
      ),
    );
  }

  /// What settlement's PrepareDeployAccount returns for this genesis.
  settlement.PrepareDeployAccountResponse get prepared =>
      settlement.PrepareDeployAccountResponse(
        genesisDigest: digest,
        initialPolicy: policy,
        initialPolicyHash: policyHash,
        device: device,
        chainId: _u64(json['chain_id'] as String),
      );

  /// The profile owning the account, with its identity salt hash.
  StawiIdentity identity(String profileId) => StawiIdentity(
    profileId: profileId,
    accounts: [
      StawiAccountRef(
        address: account,
        primary: true,
        identitySaltHash: identitySaltHash,
      ),
    ],
  );
}

/// A uint64 decimal (possibly above Int64's signed range) as Int64 bits.
Int64 _u64(String decimal) =>
    Int64.parseHex(BigInt.parse(decimal).toRadixString(16));

/// A session-proof source whose issuer refuses, as the authentication service
/// does without a live session on this device.
Future<Uint8List> refusingSessionProofs({
  required Uint8List deviceAddress,
}) async => throw connect.ConnectException(
  connect.Code.permissionDenied,
  'no live authenticated session for this profile on this device',
);

/// One Go-produced engine call (stawi_finance_sdk 0.3.0
/// test/vectors/go_engine_calls.json): the call, its ENGINE_CALL intent, the
/// intent digest and the device's signature over it.
class GoEngineCallVector {
  GoEngineCallVector(this.json, this.devicePrivateKey);

  static List<GoEngineCallVector> load() {
    final d =
        jsonDecode(
              File(
                'test/fixtures/stawi/go_engine_calls.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    return [
      for (final v in d['engine_calls'] as List)
        GoEngineCallVector(
          v as Map<String, dynamic>,
          d['device_private_key'] as String,
        ),
    ];
  }

  final Map<String, dynamic> json;
  final String devicePrivateKey;

  String get name => json['name'] as String;
  String get action => json['action'] as String;
  Uint8List get target => hexToBytes(json['target'] as String);
  Uint8List get room => hexToBytes(json['room'] as String);
  Uint8List get calldata => hexToBytes(json['calldata'] as String);
  Uint8List get digest => hexToBytes(json['digest'] as String);
  String get signature => json['signature'] as String;
  Map<String, dynamic> get _intent => json['intent'] as Map<String, dynamic>;
  Uint8List get account => hexToBytes(_intent['account'] as String);

  /// The vector's intent as finance.v1 carries it.
  finance.FinancialIntent get intent {
    final i = _intent;
    final d = i['domain'] as Map<String, dynamic>;
    finance.Principal principal(Object? p) {
      final m = p! as Map<String, dynamic>;
      return finance.Principal(
        type: finance.PrincipalType.valueOf(m['type'] as int),
        id: hexToBytes(m['id'] as String),
      );
    }

    finance.ValueLocation location(Object? l) {
      final m = l! as Map<String, dynamic>;
      return finance.ValueLocation(
        kind: finance.LocationKind.valueOf(m['kind'] as int),
        address: hexToBytes(m['address'] as String),
        bucket: m['bucket'] as String,
      );
    }

    Int64 n(Object? v) => _u64('$v');
    return finance.FinancialIntent(
      intentId: hexToBytes(i['intent_id'] as String),
      type: finance.IntentType.valueOf(i['type'] as int),
      domain: finance.IntentDomain(
        protocolVersion: d['protocol_version'] as int,
        chainId: n(d['chain_id']),
        verifyingContract: hexToBytes(d['verifying_contract'] as String),
        accountVersion: d['account_version'] as int,
        moduleVersion: d['module_version'] as int,
        environment: d['environment'] as String,
      ),
      requestedBy: principal(i['requested_by']),
      authorizedBy: principal(i['authorized_by']),
      account: hexToBytes(i['account'] as String),
      room: hexToBytes(i['room'] as String),
      source: location(i['source']),
      destination: location(i['destination']),
      asset: hexToBytes(i['asset'] as String),
      amount: i['amount'] as String,
      mode: finance.AuthorizationMode.valueOf(i['mode'] as int),
      authorizationId: hexToBytes(i['authorization_id'] as String),
      capabilityId: hexToBytes(i['capability_id'] as String),
      constitutionHash: hexToBytes(i['constitution_hash'] as String),
      securityPolicyHash: hexToBytes(i['security_policy_hash'] as String),
      policyEpoch: n(i['policy_epoch']),
      nonce: n(i['nonce']),
      credentialEpoch: n(i['credential_epoch']),
      recoveryEpoch: n(i['recovery_epoch']),
      validAfter: n(i['valid_after']),
      validUntil: n(i['valid_until']),
      countryPolicyVersion: hexToBytes(i['country_policy_version'] as String),
      complianceRequired: i['compliance_required'] as bool,
    );
  }

  /// The room's engines with this call's target as the engine its action runs
  /// on (the other engine elsewhere).
  RoomEngineTargets engines({bool callable = true}) {
    final onLoan = json['on_loan_engine'] as bool;
    final other = Uint8List.fromList(List.filled(20, 0xee));
    return RoomEngineTargets(
      rulesEngine: onLoan ? other : target,
      rulesCallable: callable,
      loanEngine: onLoan ? target : other,
      loanCallable: callable,
    );
  }

  /// What settlement's PrepareAccountCall returns for this call.
  settlement.PrepareAccountCallResponse prepared(
    settlement.AccountCallKind kind,
  ) => settlement.PrepareAccountCallResponse(
    callId: 'acct00000000000000e1',
    intentDigest: digest,
    financialIntent: intent,
    call: settlement.AccountCall(
      callId: 'acct00000000000000e1',
      address: account,
      kind: kind,
      intentDigest: digest,
      engineTarget: target,
      engineCalldata: calldata,
    ),
  );
}

/// The rooms' savings asset in tests, as finance describes it: USDC with 6
/// decimals.
final finance.AssetInfo usdcInfo = finance.AssetInfo(
  assetId: 'USDC.146',
  symbol: 'USDC',
  decimals: 6,
  chainId: Int64(146),
);

final StawiAsset usdc = StawiAsset.fromInfo(usdcInfo);

/// A room's assets in tests: its USDC.
final StawiAssets usdcAssets = StawiAssets([usdcInfo]);
