import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:connectrpc/connect.dart' as connect;
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';
import 'package:stawi/features/messages/domain/room_event.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/signing_gate.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';
import 'package:stawi/features/stawi/domain/intent_bridge.dart';
import 'package:stawi/features/stawi/domain/proposal_documents.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi/features/stawi/domain/stawi_money.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

/// A Connect transport that answers unary calls from handlers registered per
/// procedure, so the generated stawi_api clients run unchanged in tests.
class FakeConnectTransport implements connect.Transport {
  /// Settlement lists no open account calls unless a test says otherwise, as
  /// for an account with nothing on its way.
  FakeConnectTransport() {
    on(
      settlement.AccountService.listAccountCalls,
      (_) => settlement.ListAccountCallsResponse(),
    );
  }

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

/// A [SigningGate] that records what it was asked to confirm, and confirms
/// unless [refuse] is set.
class RecordingSigningGate implements SigningGate {
  RecordingSigningGate({this.refuse = false});

  bool refuse;
  final List<String> reasons = [];

  @override
  Future<void> confirm(String reason) async {
    reasons.add(reason);
    if (refuse) throw const SigningRefused(notConfirmedReason);
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
    ) as Map<String, dynamic>,
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

/// The EVM address of the device key [privateKeyHex].
Future<Uint8List> deviceAddressOf(String privateKeyHex) async =>
    (await DeviceKeyStore(
      vaultWith('p', privateKeyHex),
      gate: SigningGate.open,
    ).load('p'))!.address;

/// Answers GetAccount with a deployed account whose active key is the device
/// key [privateKeyHex] (what ensureReady looks for),
/// with the given wallet [balance] ("" unknown), [policyAsset] and
/// [authorizationIds].
Future<void> serveDeployedAccount(
  FakeConnectTransport transport,
  String privateKeyHex, {
  String balance = '',
  List<int>? policyAsset,
  List<List<int>> authorizationIds = const [],
}) async {
  final device = await deviceAddressOf(privateKeyHex);
  transport.on(
    settlement.AccountService.getAccount,
    (req) => settlement.GetAccountResponse(
      account: settlement.AccountState(
        address: req.address,
        deployed: true,
        keys: [settlement.AccountKey(key: device, active: true)],
        balance: balance,
        policy: settlement.AccountPolicy(asset: policyAsset),
        authorizationIds: authorizationIds,
      ),
    ),
  );
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
                File('test/fixtures/stawi/go_genesis.json').readAsStringSync(),
              ) as Map<String, dynamic>)['genesis_device_digest']
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

/// Go-produced PersonalVault vectors (stawi_finance_sdk 0.6.0
/// test/vectors/go_vault.json): deposits, standing-order grants and standing
/// order ids.
class GoVaultVectors {
  GoVaultVectors(this.json);

  factory GoVaultVectors.load() => GoVaultVectors(
    jsonDecode(File('test/fixtures/stawi/go_vault.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  final Map<String, dynamic> json;

  List<Map<String, dynamic>> _section(String name) => [
    for (final v in json[name] as List) v as Map<String, dynamic>,
  ];

  List<GoDepositVector> get deposits => [
    for (final d in _section('deposits')) GoDepositVector(d),
  ];
  List<GoStandingGrantVector> get standingGrants => [
    for (final g in _section('standing_grants')) GoStandingGrantVector(g),
  ];
  List<GoStandingRevokeVector> get standingRevokes => [
    for (final r in _section('standing_revokes')) GoStandingRevokeVector(r),
  ];
  List<Map<String, dynamic>> get standingOrders => _section('standing_orders');
  List<GoAddKeyVector> get addKeys => [
    for (final k in _section('add_keys')) GoAddKeyVector(k),
  ];
}

/// What settlement's PrepareAccountCall returns for a CONTRIBUTE from
/// [account] of [amount] into [custody]: a whole intent (the Go deposit
/// vector's, retyped) whose digest is its own, as the device checks it.
settlement.PrepareAccountCallResponse preparedContribution({
  required List<int> account,
  required List<int> custody,
  required String amount,
  String callId = 'acct000000000000000c',
}) {
  final intent = GoVaultVectors.load().deposits.first.intent
    ..type = finance.IntentType.INTENT_TYPE_CONTRIBUTION
    ..account = account
    ..destination = finance.ValueLocation(
      kind: finance.LocationKind.LOCATION_KIND_ROOM_CUSTODY,
      address: custody,
      bucket: 'SAVINGS',
    )
    ..amount = amount;
  final digest = sdkIntentOf(intent).digest();
  return settlement.PrepareAccountCallResponse(
    callId: callId,
    intentDigest: digest,
    financialIntent: intent,
    call: settlement.AccountCall(
      callId: callId,
      address: account,
      kind: settlement.AccountCallKind.ACCOUNT_CALL_KIND_CONTRIBUTE,
      intentDigest: digest,
    ),
  );
}

/// One Go-produced ADD_KEY: the op adding [key] to [account] and the
/// KEY_CHANGE intent binding it (pkg/evm/stawi ManagementOpHash).
class GoAddKeyVector {
  GoAddKeyVector(this.json);

  final Map<String, dynamic> json;

  String get name => json['name'] as String;
  int get kind => json['kind'] as int;
  bool get p256 => json['p256'] as bool;
  Uint8List get key => hexToBytes(json['key'] as String);
  Uint8List get account => hexToBytes(json['account'] as String);
  Uint8List get opHash => hexToBytes(json['op_hash'] as String);
  Uint8List get digest => hexToBytes(json['digest'] as String);
  finance.FinancialIntent get intent =>
      financeIntentOf(json['intent'] as Map<String, dynamic>);

  /// What settlement's PrepareAccountCall returns for this add; [opKey] and
  /// [opKind] replace the op's, [intent] the intent (its digest recomputed
  /// unless [digestOverride] is given).
  settlement.PrepareAccountCallResponse prepared({
    List<int>? opKey,
    int? opKind,
    finance.FinancialIntent? intent,
    List<int>? digestOverride,
    bool withOp = true,
  }) {
    final i = intent ?? this.intent;
    final d = digestOverride ?? sdkIntentOf(i).digest();
    return settlement.PrepareAccountCallResponse(
      callId: 'acct000000000000000a',
      intentDigest: d,
      financialIntent: i,
      managementOp: withOp
          ? finance.AccountManagementOp(kind: opKind ?? kind, key: opKey ?? key)
          : null,
      call: settlement.AccountCall(
        callId: 'acct000000000000000a',
        address: account,
        kind: settlement.AccountCallKind.ACCOUNT_CALL_KIND_ADD_KEY,
        intentDigest: d,
      ),
    );
  }
}

/// One Go-produced REVOKE_STANDING of a personal loan's standing order.
class GoStandingRevokeVector {
  GoStandingRevokeVector(this.json);

  final Map<String, dynamic> json;

  String get name => json['name'] as String;
  Uint8List get book => hexToBytes(json['book'] as String);
  Uint8List get pool => hexToBytes(json['pool'] as String);
  BigInt get loanId => BigInt.parse(json['loan_id'] as String);
  Uint8List get asset => hexToBytes(json['asset'] as String);
  Uint8List get authorizationId =>
      hexToBytes(json['authorization_id'] as String);
  Uint8List get opHash => hexToBytes(json['op_hash'] as String);
  Uint8List get digest => hexToBytes(json['digest'] as String);
  finance.FinancialIntent get intent =>
      financeIntentOf(json['intent'] as Map<String, dynamic>);
  Uint8List get account => Uint8List.fromList(intent.account);

  /// The active loan whose order is revoked, as its borrower sees it.
  finance.Loan get loan => finance.Loan(
    loanBook: book,
    pool: pool,
    lender: pool,
    borrowerAccount: account,
    onchainLoanId: _u64(loanId.toString()),
    kind: bytesEqual(pool, account)
        ? finance.LoanKind.LOAN_KIND_SELF
        : finance.LoanKind.LOAN_KIND_PERSON_TO_PERSON,
    state: finance.LoanState.LOAN_STATE_FUNDED,
  );

  /// What settlement's PrepareAccountCall returns for this revoke; [opId]
  /// replaces the op's authorization id, and [intentAuthorizationId] the
  /// intent's (its digest recomputed, so only the revoke check can refuse).
  settlement.PrepareAccountCallResponse prepared({
    List<int>? opId,
    List<int>? intentAuthorizationId,
  }) {
    final i = intent;
    var d = digest;
    if (intentAuthorizationId != null) {
      i.authorizationId = intentAuthorizationId;
      d = sdkIntentOf(i).digest();
    }
    return settlement.PrepareAccountCallResponse(
      callId: 'acct00000000000000r1',
      intentDigest: d,
      financialIntent: i,
      call: settlement.AccountCall(
        callId: 'acct00000000000000r1',
        address: account,
        kind: settlement.AccountCallKind.ACCOUNT_CALL_KIND_REVOKE_STANDING,
        intentDigest: d,
      ),
      managementOp: finance.AccountManagementOp(
        kind: opRevokeStanding,
        authorizationId: opId ?? authorizationId,
      ),
    );
  }
}

/// One Go-produced deposit into a vault pocket.
class GoDepositVector {
  GoDepositVector(this.json);

  final Map<String, dynamic> json;

  String get name => json['name'] as String;
  Uint8List get vault => hexToBytes(json['vault'] as String);
  Uint8List get pocket {
    final p = json['pocket'] as String;
    return p.isEmpty ? Uint8List(32) : hexToBytes(p);
  }

  BigInt get amount => BigInt.parse(json['amount'] as String);
  finance.FinancialIntent get intent =>
      financeIntentOf(json['intent'] as Map<String, dynamic>);
  Uint8List get account => Uint8List.fromList(intent.account);
  Uint8List get digest => hexToBytes(json['digest'] as String);

  /// The vault and, as its one loan book, an address that is not it.
  PersonalTargets get targets => PersonalTargets.fromResponse(
    vault: vault,
    loanBooks: [Uint8List.fromList(List.filled(20, 0x10))],
  );

  /// What settlement's PrepareAccountCall returns for this deposit.
  settlement.PrepareAccountCallResponse get prepared =>
      settlement.PrepareAccountCallResponse(
        callId: 'acct00000000000000d1',
        intentDigest: digest,
        financialIntent: intent,
        call: settlement.AccountCall(
          callId: 'acct00000000000000d1',
          address: account,
          kind: settlement.AccountCallKind.ACCOUNT_CALL_KIND_VAULT_DEPOSIT,
          intentDigest: digest,
        ),
      );
}

/// One Go-produced standing order for a personal loan: the loan, the grant
/// settlement chooses for it and the GRANT_STANDING intent that binds it.
class GoStandingGrantVector {
  GoStandingGrantVector(this.json);

  final Map<String, dynamic> json;

  String get name => json['name'] as String;
  Uint8List get book => hexToBytes(json['book'] as String);
  Uint8List get pool => hexToBytes(json['pool'] as String);
  BigInt get loanId => BigInt.parse(json['loan_id'] as String);
  Uint8List get vault => hexToBytes(json['vault'] as String);
  Uint8List get asset => hexToBytes(json['asset'] as String);
  BigInt get amount => BigInt.parse(json['amount'] as String);
  BigInt get largestInstalment =>
      BigInt.parse(json['largest_instalment'] as String);
  Uint8List get opHash => hexToBytes(json['op_hash'] as String);
  Uint8List get digest => hexToBytes(json['digest'] as String);
  finance.FinancialIntent get intent =>
      financeIntentOf(json['intent'] as Map<String, dynamic>);
  Uint8List get account => Uint8List.fromList(intent.account);

  PersonalTerms get terms {
    final t = json['terms'] as Map<String, dynamic>;
    return PersonalTerms(
      n: t['n'] as int,
      everyDays: t['every_days'] as int,
      method: t['method'] as int,
      rateBps: t['rate_bps'] as int,
      lateMethod: t['late_method'] as int,
      lateBps: t['late_bps'] as int,
      lateFlat: BigInt.parse(t['late_flat'] as String),
      defaultAfterDays: t['default_after_days'] as int,
    );
  }

  /// The grant as finance.v1 AccountStandingParams carries it.
  finance.AccountStandingParams get standing {
    final g = json['grant'] as Map<String, dynamic>;
    return finance.AccountStandingParams(
      authorizationId: hexToBytes(g['authorization_id'] as String),
      target: hexToBytes(g['target'] as String),
      selector: hexToBytes(g['selector'] as String),
      asset: hexToBytes(g['asset'] as String),
      maxPerPeriod: g['max_per_period'] as String,
      periodSeconds: _u64('${g['period_seconds']}'),
      epochStart: _u64('${g['epoch_start']}'),
      validAfter: _u64('${g['valid_after']}'),
      validUntil: _u64('${g['valid_until']}'),
    );
  }

  /// The loan as finance shows it to its borrower: active.
  finance.Loan get loan => finance.Loan(
    loanBook: book,
    pool: pool,
    lender: pool,
    borrowerAccount: account,
    onchainLoanId: _u64(loanId.toString()),
    requested: finance.Money(amount: amount.toString()),
    terms: finance.PersonalLoanTerms()
      ..mergeFromProto3Json(terms.toProtoJson()),
    kind: bytesEqual(pool, account)
        ? finance.LoanKind.LOAN_KIND_SELF
        : finance.LoanKind.LOAN_KIND_PERSON_TO_PERSON,
    state: finance.LoanState.LOAN_STATE_FUNDED,
  );

  PersonalTargets get targets =>
      PersonalTargets.fromResponse(vault: vault, loanBooks: [book]);

  /// What settlement's PrepareAccountCall returns for this grant.
  settlement.PrepareAccountCallResponse get prepared =>
      _prepare(intent, digest, standing);

  /// The grant with fields changed, as a self-consistent prepared call: the
  /// intent's authorization_id is the changed op's hash and the digest that
  /// intent's, so only the grant's own check can refuse it.
  settlement.PrepareAccountCallResponse preparedWith({
    BigInt? maxPerPeriod,
    BigInt? periodSeconds,
    List<int>? target,
    List<int>? authorizationId,
  }) {
    final s = standing;
    if (maxPerPeriod != null) s.maxPerPeriod = maxPerPeriod.toString();
    if (periodSeconds != null) s.periodSeconds = _u64('$periodSeconds');
    if (target != null) s.target = target;
    if (authorizationId != null) s.authorizationId = authorizationId;
    final grant = StandingGrant(
      authorizationId: s.authorizationId,
      target: s.target,
      selector: s.selector,
      asset: s.asset,
      maxPerPeriod: BigInt.parse(s.maxPerPeriod),
      periodSeconds: BigInt.parse(s.periodSeconds.toStringUnsigned()),
      epochStart: BigInt.parse(s.epochStart.toStringUnsigned()),
      validAfter: BigInt.parse(s.validAfter.toStringUnsigned()),
      validUntil: BigInt.parse(s.validUntil.toStringUnsigned()),
    );
    final i = intent..authorizationId = grant.opHash;
    return _prepare(i, sdkIntentOf(i).digest(), s);
  }

  settlement.PrepareAccountCallResponse _prepare(
    finance.FinancialIntent i,
    Uint8List digest,
    finance.AccountStandingParams s,
  ) => settlement.PrepareAccountCallResponse(
    callId: 'acct00000000000000g1',
    intentDigest: digest,
    financialIntent: i,
    call: settlement.AccountCall(
      callId: 'acct00000000000000g1',
      address: account,
      kind: settlement.AccountCallKind.ACCOUNT_CALL_KIND_GRANT_STANDING,
      intentDigest: digest,
    ),
    managementOp: finance.AccountManagementOp(kind: opGrantStanding, auth: s),
  );
}

/// One Go-produced RoomFactory.genesisHash case (stawi_finance_sdk 0.6.0
/// test/vectors/go_room_genesis.json).
class GoRoomGenesisVectors {
  GoRoomGenesisVectors(this.json);

  static List<GoRoomGenesisVectors> load() =>
      ((jsonDecode(
                File('test/fixtures/stawi/go_room_genesis.json')
                    .readAsStringSync(),
              ) as Map<String, dynamic>)['cases']
              as List)
          .map((v) => GoRoomGenesisVectors(v as Map<String, dynamic>))
          .toList();

  final Map<String, dynamic> json;

  String get name => json['name'] as String;
  Uint8List get genesisHash => hexToBytes(json['genesis_hash'] as String);

  /// The case named [name].
  static GoRoomGenesisVectors named(String name) =>
      load().firstWhere((v) => v.name == name);

  Uint8List _hex(String key) => hexToBytes(json[key] as String);

  /// Settlement's pending RoomGenesis for this case, founded by
  /// [founderProfileIds] (p1, p2, … by default) holding the case's initial
  /// members in order, each with their own account wrapping of the hash.
  /// With [accounts], the founders hold those instead and the hash is
  /// recomputed with stawi_finance_sdk roomGenesisHash, which the SDK checks
  /// against these same Go vectors; likewise with [agentAccount] in place of
  /// the case's agent. A non-zero agent is shown as [agentProfileId].
  settlement.RoomGenesis roomGenesis({
    String genesisId = 'gen00000000000000001',
    List<String>? founderProfileIds,
    List<Uint8List>? accounts,
    Uint8List? agentAccount,
    String agentProfileId = 'p-agent',
  }) {
    final members =
        accounts ??
        [
          for (final m in (json['initial_members'] as List).cast<String>())
            hexToBytes(m),
        ];
    final chainId = BigInt.from(json['chain_id'] as int);
    final agent = agentAccount ?? _hex('agent');
    final hasAgent = agent.any((b) => b != 0);
    final joinPolicy = json['join_policy'] as int;
    final hash = accounts == null && agentAccount == null
        ? genesisHash
        : roomGenesisHash(
            chainId: chainId,
            factory: _hex('factory'),
            constitutionHash: _hex('constitution_hash'),
            financePolicyHash: _hex('finance_policy_hash'),
            securityPolicyHash: _hex('security_policy_hash'),
            asset: _hex('asset'),
            initialMembers: members,
            manifestVersion: json['manifest_version'] as int,
            paramsHash: _hex('params_hash'),
            roomBinding: _hex('room_binding'),
            joinPolicy: joinPolicy,
            agent: hasAgent ? agent : null,
          );
    final profiles =
        founderProfileIds ??
        [for (var i = 0; i < members.length; i++) 'p${i + 1}'];
    return settlement.RoomGenesis(
      genesisId: genesisId,
      state: settlement.RoomGenesisState.ROOM_GENESIS_STATE_PENDING,
      chainId: Int64(json['chain_id'] as int),
      factory: _hex('factory'),
      genesisHash: hash,
      constitutionHash: _hex('constitution_hash'),
      financePolicyHash: _hex('finance_policy_hash'),
      securityPolicyHash: _hex('security_policy_hash'),
      compiledSecurityParamsHash: _hex('params_hash'),
      joinPolicy: joinPolicy == 1
          ? finance.RoomJoinPolicy.ROOM_JOIN_POLICY_PUBLIC
          : finance.RoomJoinPolicy.ROOM_JOIN_POLICY_PRIVATE,
      founders: [
        for (var i = 0; i < members.length; i++)
          settlement.RoomFounder(
            profileId: profiles[i],
            account: members[i],
            signingDigest: accountWrappedHash(members[i], chainId, hash),
          ),
      ],
      agent: hasAgent ? agent : null,
      agentProfileId: hasAgent ? agentProfileId : null,
      asset: _hex('asset'),
      manifestVersion: json['manifest_version'] as int,
      roomBinding: _hex('room_binding'),
    );
  }
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

/// One Go-produced engine call (stawi_finance_sdk 0.6.0
/// test/vectors/go_engine_calls.json): the call, its ENGINE_CALL intent, the
/// intent digest and the device's signature over it.
class GoEngineCallVector {
  GoEngineCallVector(this.json, this.devicePrivateKey);

  static List<GoEngineCallVector> load() {
    final d = jsonDecode(
      File('test/fixtures/stawi/go_engine_calls.json').readAsStringSync(),
    ) as Map<String, dynamic>;
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

  /// Whether the call runs on the personal path (the vault), not a room's.
  bool get personal => json['path'] == 'personal';

  /// The contract the call goes to: rules_engine, loan_book or vault.
  String get targetName => json['target_name'] as String;
  Uint8List get target => hexToBytes(json['target'] as String);
  Uint8List get room => hexToBytes(json['room'] as String);
  Uint8List get calldata => hexToBytes(json['calldata'] as String);
  Uint8List get digest => hexToBytes(json['digest'] as String);
  String get signature => json['signature'] as String;
  Map<String, dynamic> get _intent => json['intent'] as Map<String, dynamic>;
  Uint8List get account => hexToBytes(_intent['account'] as String);

  /// The vector's intent as finance.v1 carries it.
  finance.FinancialIntent get intent => financeIntentOf(_intent);

  /// The room's engines with this call's target as the engine its action runs
  /// on (the other engine elsewhere).
  RoomEngineTargets engines({bool callable = true}) {
    final onLoan = targetName == 'loan_book';
    final other = Uint8List.fromList(List.filled(20, 0xee));
    return RoomEngineTargets(
      rulesEngine: onLoan ? other : target,
      rulesCallable: callable,
      loanBook: onLoan ? target : other,
      loanCallable: callable,
    );
  }

  /// This vector's prepared call with [call] in place of its own: the
  /// calldata, the intent's amount and authorization id, and the digest made
  /// to match, so only the device's own checks can refuse it.
  settlement.PrepareAccountCallResponse preparedFor(
    EngineCall call,
    settlement.AccountCallKind kind,
  ) {
    final calldata = call.calldata;
    final i = intent
      ..amount = call.committed.toString()
      ..authorizationId = engineCallHash(target, calldata);
    final d = sdkIntentOf(i).digest();
    return prepared(kind)
      ..intentDigest = d
      ..financialIntent = i
      ..call.intentDigest = d
      ..call.engineCalldata = calldata;
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

/// The token the Go vectors' money intents move (the deposit vector's
/// asset): the deployment's and every room's asset in tests.
final Uint8List testAssetToken = hexToBytes(
  '0x707172737475767778797a7b7c7d7e7f80818283',
);

/// The rooms' savings asset in tests, as finance describes it: USDC with 6
/// decimals.
final finance.AssetInfo usdcInfo = finance.AssetInfo(
  assetId: 'USDC.146',
  symbol: 'USDC',
  decimals: 6,
  chainId: Int64(146),
  tokenAddress: testAssetToken,
);

/// Finance's Room.assets token addresses for any room in tests.
Future<List<Uint8List>> testRoomAssets(String roomId) async => [testAssetToken];

final StawiAsset usdc = StawiAsset.fromInfo(usdcInfo);

/// A room's assets in tests: its USDC.
final StawiAssets usdcAssets = StawiAssets([usdcInfo]);

/// A Go vector's intent (snake_case JSON) as finance.v1 carries it.
finance.FinancialIntent financeIntentOf(Map<String, dynamic> i) {
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

// ---- room calls ----------------------------------------------------------

Uint8List _w(BigInt v) => bigIntToBytes(v, 32);
Uint8List _wi(int v) => _w(BigInt.from(v));
Uint8List _wa(List<int> a) => Uint8List(32)..setRange(12, 32, a);
Uint8List _wb(bool b) => _wi(b ? 1 : 0);

/// The room's contracts as finance names them, for tests.
RoomContracts roomContractsOf({
  required List<int> governance,
  required List<int> custody,
  required BigInt chainId,
}) => RoomContracts(
  governance: Uint8List.fromList(governance),
  custody: Uint8List.fromList(custody),
  chainId: chainId,
);

/// Settlement as it should behave (apps/settlement room_calls.go): the call
/// for [req], signed by [signer] on [room], with its params encoded from the
/// request, its SignedCalls typed hash and the account-wrapped digest.
/// [exitIntent] is the exit a PROPOSE_PRINCIPAL_EXIT spend builds;
/// [inviteHash] what an ACCEPT_INVITATION reads off the chain.
settlement.PrepareRoomCallResponse honestRoomCall(
  settlement.PrepareRoomCallRequest req, {
  required RoomContracts room,
  required Uint8List signer,
  required String chatRoomId,
  DateTime? now,
  int nonce = 3,
  int deadline = 4102444800, // 2100-01-01
  finance.FinancialIntent? exitIntent,
  List<int>? inviteHash,
  List<int>? loanBook,
  ({List<int> borrower, BigInt amount, int instalments})? pendingLoan,
  settlement.RoomPolicyChange? policyChange,
  List<int>? policyPayloadHash,
  settlement.RoomRotation? rotation,
}) {
  final p = req.params;
  final at = BigInt.from(
    (now ?? DateTime.now()).toUtc().millisecondsSinceEpoch ~/ 1000,
  );
  Uint8List acct(settlement.RoomMemberRef r) => Uint8List.fromList(r.account);
  Uint8List propose(int kind, List<int> payload) =>
      Uint8List.fromList([..._wi(kind), ...payload]);
  final (SignedCallKind kind, Uint8List params) = switch (req.kind) {
    settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE
        when p.propose.hasLoanApproval() =>
      (
        SignedCallKind.propose,
        propose(
          ProposalKinds.loan,
          payloadHashOf(
            loanApprovalDocument(
              loanBook: loanBook!,
              custody: room.custody!,
              loanId: BigInt.parse(p.propose.loanApproval.toStringUnsigned()),
              borrower: pendingLoan!.borrower,
              amount: pendingLoan.amount,
              instalments: pendingLoan.instalments,
            ),
          ),
        ),
      ),
    settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE
        when p.propose.hasLoanWriteOff() =>
      (
        SignedCallKind.propose,
        propose(
          ProposalKinds.writeOff,
          payloadHashOf(
            loanWriteOffDocument(
              loanBook: loanBook!,
              custody: room.custody!,
              loanId: BigInt.parse(p.propose.loanWriteOff.toStringUnsigned()),
            ),
          ),
        ),
      ),
    settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE
        when p.propose.hasLoanRestructure() =>
      (
        SignedCallKind.propose,
        propose(
          ProposalKinds.restructure,
          payloadHashOf(
            loanRestructureDocument(
              loanBook: loanBook!,
              custody: room.custody!,
              loanId: BigInt.parse(
                p.propose.loanRestructure.loanId.toStringUnsigned(),
              ),
              instalments: p.propose.loanRestructure.instalments,
              rateBps: p.propose.loanRestructure.rateBps,
            ),
          ),
        ),
      ),
    settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE
        when p.propose.hasRotation() =>
      (
        SignedCallKind.propose,
        propose(
          ProposalKinds.distribution,
          openCyclePayloadHash(
            custody: room.custody!,
            cycleId: rotation!.cycleId,
            order: rotation.order,
            pot: BigInt.parse(rotation.pot),
            firstPeriod: rotation.firstPeriod,
          ),
        ),
      ),
    settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE
        when p.propose.hasRuleChanges() =>
      (
        SignedCallKind.propose,
        propose(ProposalKinds.policyChange, policyPayloadHash!),
      ),
    settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE => (
      SignedCallKind.propose,
      propose(
        p.propose.memberAction.action ==
                finance.RoomMemberAction.ROOM_MEMBER_ACTION_REMOVE
            ? ProposalKinds.memberRemove
            : ProposalKinds.memberAdd,
        memberActionPayloadHash(
          custody: room.custody!,
          action: p.propose.memberAction.action.value,
          subject: acct(p.propose.memberAction.subject),
          arg: BigInt.parse(p.propose.memberAction.arg.toStringUnsigned()),
        ),
      ),
    ),
    settlement.RoomCallKind.ROOM_CALL_KIND_ASSIGN_ROLE ||
    settlement.RoomCallKind.ROOM_CALL_KIND_REVOKE_ROLE => (
      SignedCallKind.propose,
      propose(
        ProposalKinds.role,
        rolePayloadHash(
          custody: room.custody!,
          assign:
              req.kind == settlement.RoomCallKind.ROOM_CALL_KIND_ASSIGN_ROLE,
          member: acct(p.role.member),
          roleId: roomRoleId(p.role.roleId),
          capabilities:
              req.kind == settlement.RoomCallKind.ROOM_CALL_KIND_ASSIGN_ROLE
              ? p.role.capabilities
              : 0,
          validUntil:
              req.kind == settlement.RoomCallKind.ROOM_CALL_KIND_ASSIGN_ROLE
              ? BigInt.parse(p.role.validUntil.toStringUnsigned())
              : BigInt.zero,
        ),
      ),
    ),
    settlement.RoomCallKind.ROOM_CALL_KIND_CAST_VOTE => (
      SignedCallKind.castVote,
      Uint8List.fromList([
        ..._w(BigInt.parse(p.vote.onchainProposalId.toStringUnsigned())),
        ..._wi(p.vote.choice.value),
      ]),
    ),
    settlement.RoomCallKind.ROOM_CALL_KIND_COMMIT_VOTE => (
      SignedCallKind.commitVote,
      Uint8List.fromList([
        ..._w(BigInt.parse(p.vote.onchainProposalId.toStringUnsigned())),
        ...p.vote.commitment,
      ]),
    ),
    settlement.RoomCallKind.ROOM_CALL_KIND_REVEAL_VOTE => (
      SignedCallKind.revealVote,
      Uint8List.fromList([
        ..._w(BigInt.parse(p.vote.onchainProposalId.toStringUnsigned())),
        ..._wi(p.vote.choice.value),
        ...p.vote.salt,
      ]),
    ),
    settlement.RoomCallKind.ROOM_CALL_KIND_DELEGATE => (
      SignedCallKind.delegate,
      Uint8List.fromList([
        ..._wa(p.delegate.to.account),
        ..._w(BigInt.parse(p.delegate.scope.toStringUnsigned())),
        ..._w(BigInt.parse(p.delegate.until.toStringUnsigned())),
      ]),
    ),
    settlement.RoomCallKind.ROOM_CALL_KIND_REVOKE_DELEGATION => (
      SignedCallKind.revokeDelegation,
      Uint8List(0),
    ),
    settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE_PRINCIPAL_EXIT => (
      SignedCallKind.proposePrincipalExit,
      p.principalExit.hasSpend()
          ? Uint8List.fromList([
              ...intentDigestOf(sdkIntentOf(exitIntent!)),
              ...Uint8List(32),
            ])
          : Uint8List.fromList([
              ...cancelPrincipalExitPayloadHash(
                chainId: room.chainId,
                custody: room.custody!,
                target: BigInt.parse(
                  p.principalExit.cancelTarget.toStringUnsigned(),
                ),
              ),
              ..._w(
                BigInt.parse(p.principalExit.cancelTarget.toStringUnsigned()),
              ),
            ]),
    ),
    settlement.RoomCallKind.ROOM_CALL_KIND_VOTE_PRINCIPAL_EXIT => (
      SignedCallKind.votePrincipalExit,
      Uint8List.fromList([
        ..._w(BigInt.parse(p.principalExit.ballotId.toStringUnsigned())),
        ..._wb(p.principalExit.approve),
      ]),
    ),
    settlement.RoomCallKind.ROOM_CALL_KIND_ACCEPT_INVITATION => (
      SignedCallKind.acceptInvitation,
      Uint8List.fromList([
        ..._w(BigInt.parse(p.inviteId.toStringUnsigned())),
        ...(inviteHash ?? List<int>.filled(32, 0xc1)),
      ]),
    ),
    settlement.RoomCallKind.ROOM_CALL_KIND_LEAVE => (
      SignedCallKind.leave,
      Uint8List(0),
    ),
    settlement.RoomCallKind.ROOM_CALL_KIND_JOIN => (
      SignedCallKind.join,
      Uint8List(0),
    ),
    settlement.RoomCallKind.ROOM_CALL_KIND_FREEZE => (
      SignedCallKind.freeze,
      freezeReasonHash(p.freeze_7.reason),
    ),
    settlement.RoomCallKind.ROOM_CALL_KIND_INVITE => (
      SignedCallKind.officerAction,
      Uint8List.fromList([
        ..._wi(MemberActions.invite),
        ..._wa(p.officer.subject.account),
        ..._w(at + BigInt.from(p.officer.inviteValidSeconds)),
      ]),
    ),
    settlement.RoomCallKind.ROOM_CALL_KIND_ADMIT => (
      SignedCallKind.officerAction,
      Uint8List.fromList([
        ..._wi(MemberActions.admit),
        ..._wa(p.officer.subject.account),
        ..._wi(0),
      ]),
    ),
    final k => throw StateError('honestRoomCall: no $k'),
  };
  final verifier = room.of(kind.contract)!;
  final typed = roomCallTypedHash(
    kind,
    verifier: verifier,
    chainId: room.chainId,
    member: signer,
    nonce: BigInt.from(nonce),
    deadline: BigInt.from(deadline),
    params: params,
  );
  final digest = accountWrappedHash(signer, room.chainId, typed);
  return settlement.PrepareRoomCallResponse(
    callId: 'call0000000000000001',
    digest: digest,
    signer: signer,
    call: settlement.RoomCall(
      callId: 'call0000000000000001',
      chainId: Int64.parseInt(room.chainId.toString()),
      chatRoomId: chatRoomId,
      kind: req.kind,
      verifier: verifier,
      signer: signer,
      nonce: Int64(nonce),
      deadline: Int64(deadline),
      params: params,
      typedHash: typed,
      digest: digest,
      requiresSignature: true,
      exitIntent: exitIntent,
      policyChange: policyChange,
      rotation: rotation,
      payloadHash: exitIntent == null
          ? null
          : intentDigestOf(sdkIntentOf(exitIntent)),
    ),
  );
}

/// One Go-produced room call (pkg/evm/stawi TestDartRoomCallVectors):
/// test/fixtures/stawi/go_room_calls.json, a copy of the SDK's oracle.
class GoRoomCallVector {
  GoRoomCallVector(this.json);

  static List<GoRoomCallVector> load() => [
    for (final v
        in (jsonDecode(
              File('test/fixtures/stawi/go_room_calls.json').readAsStringSync(),
            ) as Map<String, dynamic>)['room_calls']
            as List)
      GoRoomCallVector(v as Map<String, dynamic>),
  ];

  static GoRoomCallVector named(String name) =>
      load().firstWhere((v) => v.name == name);

  final Map<String, dynamic> json;

  String get name => json['name'] as String;
  String get builder => json['builder'] as String;
  Map<String, dynamic> get inputs => json['inputs'] as Map<String, dynamic>;
  String input(String k) => inputs[k] as String;
  Uint8List inputBytes(String k) => hexToBytes(input(k));
  BigInt get chainId => BigInt.parse(json['chain_id'] as String);
  Uint8List get member => hexToBytes(json['member'] as String);
  Uint8List get verifier => hexToBytes(json['verifier'] as String);
  Uint8List get custody => hexToBytes(json['custody'] as String);
  Uint8List get params => hexToBytes(json['params'] as String);
  Uint8List get typedHash => hexToBytes(json['typed_hash'] as String);
  Uint8List get digest => hexToBytes(json['digest'] as String);
  BigInt get deadline => BigInt.parse(json['deadline'] as String);

  /// The room as finance would name it: the vector's verifier for its own
  /// contract, and the environment's other contract.
  RoomContracts room(Uint8List governance) =>
      RoomContracts(governance: governance, custody: custody, chainId: chainId);

  /// Settlement's answer carrying this call; any field may be replaced.
  settlement.PrepareRoomCallResponse prepared(
    String chatRoomId, {
    List<int>? params,
    List<int>? typedHash,
    List<int>? digest,
    List<int>? verifier,
    int? kind,
  }) => settlement.PrepareRoomCallResponse(
    callId: 'call0000000000000001',
    digest: digest ?? this.digest,
    signer: member,
    call: settlement.RoomCall(
      callId: 'call0000000000000001',
      chainId: Int64.parseInt(chainId.toString()),
      chatRoomId: chatRoomId,
      kind: settlement.RoomCallKind.valueOf(
        kind ?? json['room_call_kind'] as int,
      ),
      verifier: verifier ?? this.verifier,
      signer: member,
      nonce: Int64.parseInt(json['nonce'] as String),
      deadline: Int64.parseInt(json['deadline'] as String),
      params: params ?? this.params,
      typedHash: typedHash ?? this.typedHash,
      digest: digest ?? this.digest,
      requiresSignature: true,
    ),
  );
}

/// A rules template document (rules.TemplateDocument) for [custody] on the
/// engines [rulesEngine] and [loanBook], with empty parts.
Uint8List templateDocument({
  required List<int> custody,
  required List<int> rulesEngine,
  required List<int> loanBook,
}) {
  Uint8List word(int v) => bigIntToBytes(BigInt.from(v), 32);
  Uint8List addr(List<int> a) => Uint8List(32)..setRange(12, 32, a);
  final tag = ascii.encode('STAWI_TEMPLATE_V1');
  return Uint8List.fromList([
    ...word(0x100),
    ...addr(custody),
    ...addr(rulesEngine),
    ...word(0x140),
    ...addr(loanBook),
    ...word(0x160),
    ...addr(Uint8List(20)..[19] = 0xee),
    ...word(0x180),
    ...word(tag.length),
    ...tag,
    ...Uint8List(32 - tag.length),
    ...word(0),
    ...word(0),
    ...word(0),
  ]);
}

/// A room's three setup proposals as settlement renders them for [account]:
/// the two engine grants and the template, proposeBySig on [governance] at
/// nonces from [firstNonce], until [deadline].
List<settlement.RoomSetupDigest> setupDigestsFor({
  required Uint8List account,
  required List<int> governance,
  required List<int> custody,
  required BigInt chainId,
  required DateTime deadline,
  int firstNonce = 0,
  List<settlement.RoomSetupStepKind> steps = const [
    settlement.RoomSetupStepKind.ROOM_SETUP_STEP_KIND_GRANT_RULES_ENGINE,
    settlement.RoomSetupStepKind.ROOM_SETUP_STEP_KIND_GRANT_LOAN_ENGINE,
    settlement.RoomSetupStepKind.ROOM_SETUP_STEP_KIND_RULES_TEMPLATE,
  ],
}) {
  final rules = Uint8List(20)..[19] = 0xa1;
  final loans = Uint8List(20)..[19] = 0xa2;
  final seconds = deadline.toUtc().millisecondsSinceEpoch ~/ 1000;
  return [
    for (var i = 0; i < steps.length; i++)
      () {
        final step = steps[i];
        final template =
            step ==
            settlement.RoomSetupStepKind.ROOM_SETUP_STEP_KIND_RULES_TEMPLATE;
        final kind = template ? 5 : 11;
        final document = template
            ? templateDocument(
                custody: custody,
                rulesEngine: rules,
                loanBook: loans,
              )
            : engineGrantDocument(
                custody: custody,
                module:
                    step ==
                        settlement
                            .RoomSetupStepKind
                            .ROOM_SETUP_STEP_KIND_GRANT_RULES_ENGINE
                    ? rules
                    : loans,
              );
        final payload = keccak256(document);
        final typed = roomCallTypedHash(
          SignedCallKind.propose,
          verifier: governance,
          chainId: chainId,
          member: account,
          nonce: BigInt.from(firstNonce + i),
          deadline: BigInt.from(seconds),
          params: [...bigIntToBytes(BigInt.from(kind), 32), ...payload],
        );
        return settlement.RoomSetupDigest(
          step: step,
          typedHash: typed,
          digest: accountWrappedHash(account, chainId, typed),
          nonce: Int64(firstNonce + i),
          deadline: Timestamp(seconds: Int64(seconds)),
          proposalKind: kind,
          payloadHash: payload,
          payloadDocument: document,
        );
      }(),
  ];
}

// ---- guardians and recovery ---------------------------------------------

/// One Go-produced account-protection call (stawi v0.2.5 ManagementOpHash,
/// RequiredIntentType and Intent.Digest): a guardian change's proposed
/// policy, a recovery contest or a pending policy's cancel.
class GoGuardianCallVector {
  GoGuardianCallVector(this.json);

  final Map<String, dynamic> json;

  static List<GoGuardianCallVector> load() => [
    for (final c
        in (jsonDecode(
              File('test/fixtures/stawi/go_guardian_calls.json')
                  .readAsStringSync(),
            ) as Map<String, dynamic>)['calls']
            as List<dynamic>)
      GoGuardianCallVector(c as Map<String, dynamic>),
  ];

  static GoGuardianCallVector named(String name) =>
      load().firstWhere((v) => v.name == name);

  String get name => json['name'] as String;
  int get kind => json['kind'] as int;
  Uint8List get opHash => hexToBytes(json['op_hash'] as String);
  Uint8List get digest => hexToBytes(json['digest'] as String);
  finance.FinancialIntent get intent =>
      financeIntentOf(json['intent'] as Map<String, dynamic>);
  Uint8List get account => Uint8List.fromList(intent.account);
  BigInt get chainId => BigInt.parse(intent.domain.chainId.toStringUnsigned());

  Map<String, dynamic>? get _policy => json['policy'] as Map<String, dynamic>?;

  List<Uint8List> _addresses(String key) => [
    for (final a in _policy![key] as List<dynamic>) hexToBytes(a as String),
  ];

  /// The policy the op proposes, as settlement sends it (management_op).
  finance.AccountPolicyParams? get policy => _policy == null
      ? null
      : finance.AccountPolicyParams(
          asset: hexToBytes(_policy!['asset'] as String),
          periodLimit: _policy!['period_limit'] as String,
          periodSeconds: Int64(_policy!['period_seconds'] as int),
          epochStart: Int64(_policy!['epoch_start'] as int),
          allowlist: _addresses('allowlist'),
          guardians: _addresses('guardians'),
          guardianThreshold: _policy!['guardian_threshold'] as int,
          allowlistMode: finance.AccountDefaults_AllowlistMode.valueOf(
            _policy!['allowlist_mode'] as int,
          ),
        );

  /// The account as the chain reads it with [guardians] and [threshold] (the
  /// rest of the policy the vector's), before the change.
  settlement.AccountState stateWith({
    List<Uint8List> guardians = const [],
    int threshold = 0,
    settlement.AccountRecovery? recovery,
    bool guardianFrozen = false,
  }) {
    final p =
        policy ?? GoGuardianCallVector.named('add_first_guardian').policy!;
    return settlement.AccountState(
      address: account,
      deployed: true,
      guardians: guardians,
      guardianThreshold: threshold,
      guardianFrozen: guardianFrozen,
      recovery: recovery,
      policy: settlement.AccountPolicy(
        asset: p.asset,
        periodLimit: p.periodLimit,
        periodSeconds: p.periodSeconds,
        epochStart: p.epochStart,
        allowlistMode: p.allowlistMode,
        allowlist: p.allowlist,
      ),
    );
  }

  /// What settlement's PrepareAccountCall returns for this call of [kind];
  /// [opPolicy] replaces the proposed policy and [opKind] the op's kind.
  settlement.PrepareAccountCallResponse prepared(
    settlement.AccountCallKind kind, {
    finance.AccountPolicyParams? opPolicy,
    int? opKind,
    finance.FinancialIntent? intent,
  }) {
    final i = intent ?? this.intent;
    final d = sdkIntentOf(i).digest();
    final p = opPolicy ?? policy;
    return settlement.PrepareAccountCallResponse(
      callId: 'acct00000000000000g1',
      intentDigest: d,
      financialIntent: i,
      managementOp: finance.AccountManagementOp(
        kind: opKind ?? this.kind,
        policy: p,
      ),
      call: settlement.AccountCall(
        callId: 'acct00000000000000g1',
        address: account,
        kind: kind,
        intentDigest: d,
      ),
    );
  }
}

/// One rule change stawi v0.2.6's Go compiled (test/fixtures/stawi/
/// go_governance.json, rule_changes): templates.ApplyRuleValues on the
/// savings-and-credit template, policy.Compile, policy.ChainSecurityParams,
/// ParamsHash and PolicyChangePayloadHash.
class GoRuleChange {
  GoRuleChange(this.json);

  final Map<String, dynamic> json;

  static List<GoRuleChange> load() => [
    for (final c
        in (jsonDecode(
              File('test/fixtures/stawi/go_governance.json').readAsStringSync(),
            ) as Map<String, dynamic>)['rule_changes']
            as List<dynamic>)
      GoRuleChange(c as Map<String, dynamic>),
  ];

  static GoRuleChange named(String name) =>
      load().firstWhere((v) => v.name == name);

  String get name => json['name'] as String;
  Map<String, String> get values =>
      (json['rule_values'] as Map<String, dynamic>).cast<String, String>();
  Uint8List hex(String k) => hexToBytes(json[k] as String);
  Uint8List get custody => hex('custody');
  List<Uint8List> get documents => [
    for (final d in json['documents'] as List<dynamic>) hexToBytes(d as String),
  ];
  List<Uint8List> get capabilityIds => [
    for (final d in json['capability_ids'] as List<dynamic>)
      hexToBytes(d as String),
  ];
  finance.RoomSecurityParams _params(String k) =>
      finance.RoomSecurityParams()..mergeFromProto3Json(json[k]);
  finance.RoomSecurityParams get params => _params('security_params');
  finance.RoomSecurityParams get previousParams =>
      _params('previous_security_params');
  finance.RoomPolicy get previousConstitution => finance.RoomPolicy()
    ..mergeFromProto3Json(
      jsonDecode(utf8.decode(hex('previous_constitution'))),
    );

  /// What finance's GetPolicy holds in force before the change.
  finance.PolicyVersion get inForce => finance.PolicyVersion(
    constitution: previousConstitution,
    constitutionHash: hex('previous_constitution_hash'),
    policyEpoch: Int64.ONE,
  );

  settlement.RoomPolicyChange get change => settlement.RoomPolicyChange(
    ruleValues: values.entries,
    constitutionHash: hex('constitution_hash'),
    financePolicyHash: hex('finance_policy_hash'),
    securityPolicyHash: hex('security_policy_hash'),
    securityParams: params,
    capabilityIds: capabilityIds,
    documents: documents,
    policyEpoch: Int64.ONE,
    previousConstitutionHash: hex('previous_constitution_hash'),
    previousSecurityParams: previousParams,
  );

  settlement.PrepareRoomCallResponse prepared([
    settlement.RoomPolicyChange? c,
  ]) => settlement.PrepareRoomCallResponse(
    call: settlement.RoomCall(policyChange: c ?? change),
  );
}

/// stawi v0.2.6's Go vectors for this round (test/fixtures/stawi/
/// go_governance.json): SET_GUARDIANS, guardian acts and the guardian key
/// proof. The rule changes are [GoRuleChange].
abstract final class GoGovernanceVectors {
  static Map<String, dynamic> get _json => jsonDecode(
    File('test/fixtures/stawi/go_governance.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  static List<GoSetGuardiansVector> setGuardians() => [
    for (final v in _json['set_guardians'] as List<dynamic>)
      GoSetGuardiansVector(v as Map<String, dynamic>),
  ];

  static List<GoGuardianActVector> guardianActs() => [
    for (final v in _json['guardian_acts'] as List<dynamic>)
      GoGuardianActVector(v as Map<String, dynamic>),
  ];

  static GoGuardianActVector guardianAct(String name) =>
      guardianActs().firstWhere((v) => v.name == name);

  static Map<String, dynamic> get guardianKeyProof =>
      _json['guardian_key_proof'] as Map<String, dynamic>;
}

/// A SET_GUARDIANS vector: the guardians [before] and [after] the change.
class GoSetGuardiansVector extends GoGuardianCallVector {
  GoSetGuardiansVector(super.json);

  ({List<Uint8List> guardians, int threshold}) _set(String key) {
    final p = this.json[key] as Map<String, dynamic>;
    return (
      guardians: [
        for (final g in p['guardians'] as List<dynamic>)
          hexToBytes(g as String),
      ],
      threshold: p['guardian_threshold'] as int,
    );
  }

  ({List<Uint8List> guardians, int threshold}) get before => _set('before');
  ({List<Uint8List> guardians, int threshold}) get after => _set('policy');
}

/// A guardian act on account 0xa0… by anvil's first key as guardian.
class GoGuardianActVector {
  GoGuardianActVector(this.json);

  final Map<String, dynamic> json;

  String get name => json['name'] as String;
  Map<String, dynamic> get _op => json['op'] as Map<String, dynamic>;
  int get opKind => _op['kind'] as int;
  Uint8List get newKey => hexToBytes(_op['new_key'] as String);
  int get round => _op['round'] as int;
  int get algorithm => _op['algorithm'] as int;
  Uint8List get guardian => hexToBytes(json['guardian'] as String);
  Uint8List get opHash => hexToBytes(json['op_hash'] as String);
  Uint8List get digest => hexToBytes(json['digest'] as String);
  finance.FinancialIntent get intent =>
      financeIntentOf(json['intent'] as Map<String, dynamic>);
  Uint8List get account => Uint8List.fromList(intent.account);
  BigInt get chainId => BigInt.parse(intent.domain.chainId.toStringUnsigned());

  /// The account as GetGuardedAccount reads it for this guardian, with a
  /// pending recovery to [newKey] in [round] when [pending].
  settlement.GuardedAccount guarded({
    bool pending = false,
    int approvals = 1,
    int required = 2,
  }) => settlement.GuardedAccount(
    address: account,
    ownerProfileId: 'owner0000000000000p9',
    guardian: guardian,
    guardians: [guardian, Uint8List(20)..[19] = 0x77],
    guardianThreshold: 2,
    guardianNonce: intent.nonce,
    recovery: settlement.AccountRecovery(
      round: Int64(round),
      state: pending
          ? settlement.AccountRecoveryState.ACCOUNT_RECOVERY_STATE_PENDING
          : settlement.AccountRecoveryState.ACCOUNT_RECOVERY_STATE_NONE,
      newKey: pending ? newKey : null,
      newKeyAlgorithm: pending
          ? settlement.DeviceKeyAlgorithm.DEVICE_KEY_ALGORITHM_SECP256K1
          : null,
      approvals: Int64(pending ? approvals : 0),
      approvalsRequired: Int64(pending ? required : 0),
      executableAfter: Int64(pending ? 1760090000 : 0),
      expiresAt: Int64(pending ? 1760600000 : 0),
    ),
  );

  /// What settlement's PrepareAccountCall returns for this act of [kind].
  settlement.PrepareAccountCallResponse prepared(
    settlement.AccountCallKind kind, {
    finance.FinancialIntent? intent,
    Uint8List? signer,
  }) {
    final i = intent ?? this.intent;
    final d = sdkIntentOf(i).digest();
    return settlement.PrepareAccountCallResponse(
      callId: 'acct00000000000000ga',
      intentDigest: d,
      financialIntent: i,
      call: settlement.AccountCall(
        callId: 'acct00000000000000ga',
        address: account,
        kind: kind,
        intentDigest: d,
        signer: signer ?? guardian,
        guardianOp: settlement.AccountGuardianOp(
          kind: opKind,
          newKey: newKey,
          round: Int64(round),
          algorithm: algorithm,
        ),
      ),
    );
  }
}

/// One Go-written rotation (stawi v0.2.7 stawi.OpenCyclePayload(Hash) and
/// stawi.RotationTurnID): test/fixtures/stawi/go_rotation.json, a copy of
/// the SDK's test/vectors/go_rotation.json.
class GoRotationVector {
  GoRotationVector(this.json);

  static List<GoRotationVector> load() => [
    for (final v
        in (jsonDecode(
              File('test/fixtures/stawi/go_rotation.json').readAsStringSync(),
            ) as Map<String, dynamic>)['rotations']
            as List)
      GoRotationVector(v as Map<String, dynamic>),
  ];

  static GoRotationVector named(String name) =>
      load().firstWhere((v) => v.name == name);

  final Map<String, dynamic> json;

  String get name => json['name'] as String;
  Uint8List get custody => hexToBytes(json['custody'] as String);
  Uint8List get cycleId => hexToBytes(json['cycle_id'] as String);
  List<Uint8List> get order => [
    for (final a in json['order'] as List) hexToBytes(a as String),
  ];
  BigInt get pot => BigInt.parse(json['pot'] as String);
  int get firstPeriod => json['first_period'] as int;
  Uint8List get payload => hexToBytes(json['payload'] as String);
  Uint8List get payloadHash => hexToBytes(json['payload_hash'] as String);
  List<Uint8List> get turnIds => [
    for (final t in json['turn_ids'] as List) hexToBytes(t as String),
  ];

  /// The cycle as settlement's RoomCall.rotation carries it, on the clock
  /// [epochStart] / [periodSeconds].
  settlement.RoomRotation rotation({
    required int epochStart,
    required int periodSeconds,
  }) => settlement.RoomRotation(
    cycleId: cycleId,
    order: order,
    pot: pot.toString(),
    firstPeriod: firstPeriod,
    periodEpochStart: Int64(epochStart),
    periodSeconds: Int64(periodSeconds),
  );
}
