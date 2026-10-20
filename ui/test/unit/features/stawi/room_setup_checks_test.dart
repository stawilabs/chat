import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';
import 'package:stawi/features/stawi/domain/proposal_documents.dart';
import 'package:stawi/features/stawi/domain/room_setup.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

/// Vectors printed by stawi v0.2.5's own Go (pkg/rules LoanApprovalDocument,
/// LoanWriteOffDocument, LoanRestructureDocument, TemplateDocument;
/// pkg/evm/stawi GrantPayload, Call.TypedHash, AccountWrappedHash).
final Map<String, dynamic> go = jsonDecode(
  File('test/fixtures/stawi/go_proposal_documents.json').readAsStringSync(),
) as Map<String, dynamic>;

Uint8List hx(String key, [String? sub]) => hexToBytes(
  (sub == null ? go[key] : (go[key] as Map<String, dynamic>)[sub]) as String,
);

/// A vector's field.
String gv(String key, String sub) =>
    (go[key] as Map<String, dynamic>)[sub] as String;

typedef Kind = settlement.RoomSetupStepKind;

final custody = hx('custody');
final governance = hx('governance');
final member = hx('member');
final rulesEngine = hx('module');
final loanBook = hx('loan_book');
final rotationModule = Uint8List(20)..[19] = 0x77;
final chainId = BigInt.from(14601);
final now = DateTime.utc(2026, 10, 20);
final deadline = Int64(1900000000);

/// A setup digest as settlement renders one for [member] at [nonce].
settlement.RoomSetupDigest digestFor(
  Kind step,
  int nonce, {
  Uint8List? document,
  int? proposalKind,
  Uint8List? signer,
}) {
  final kind =
      proposalKind ??
      (step == Kind.ROOM_SETUP_STEP_KIND_RULES_TEMPLATE
          ? scheduleProposalKind
          : capabilityGrantProposalKind);
  final doc =
      document ??
      switch (step) {
        Kind.ROOM_SETUP_STEP_KIND_GRANT_RULES_ENGINE => engineGrantDocument(
          custody: custody,
          module: rulesEngine,
        ),
        Kind.ROOM_SETUP_STEP_KIND_GRANT_LOAN_ENGINE => engineGrantDocument(
          custody: custody,
          module: loanBook,
        ),
        Kind.ROOM_SETUP_STEP_KIND_GRANT_ROTATION => engineGrantDocument(
          custody: custody,
          module: rotationModule,
        ),
        _ => templateDocumentFor(custody, rulesEngine, loanBook),
      };
  final payload = payloadHashOf(doc);
  final typed = roomCallTypedHash(
    SignedCallKind.propose,
    verifier: governance,
    chainId: chainId,
    member: signer ?? member,
    nonce: BigInt.from(nonce),
    deadline: BigInt.from(deadline.toInt()),
    params: [...bigIntToBytes(BigInt.from(kind), 32), ...payload],
  );
  return settlement.RoomSetupDigest(
    step: step,
    typedHash: typed,
    digest: accountWrappedHash(signer ?? member, chainId, typed),
    nonce: Int64(nonce),
    deadline: Timestamp(seconds: deadline),
    proposalKind: kind,
    payloadHash: payload,
    payloadDocument: doc,
  );
}

/// The Go template vector, with its custody and engines swapped for others.
Uint8List templateDocumentFor(
  List<int> custody,
  List<int> rules,
  List<int> loans,
) {
  final doc = Uint8List.fromList(hx('template', 'document'));
  doc.setRange(32 + 12, 64, custody);
  doc.setRange(64 + 12, 96, rules);
  doc.setRange(128 + 12, 160, loans);
  return doc;
}

List<settlement.RoomSetupDigest> genesisDigests() => [
  digestFor(Kind.ROOM_SETUP_STEP_KIND_GRANT_RULES_ENGINE, 0),
  digestFor(Kind.ROOM_SETUP_STEP_KIND_GRANT_LOAN_ENGINE, 1),
  digestFor(Kind.ROOM_SETUP_STEP_KIND_RULES_TEMPLATE, 2),
];

List<Uint8List> check(
  List<settlement.RoomSetupDigest> digests, {
  int? firstNonce = 0,
  DateTime? at,
  List<int>? module,
  bool noModule = false,
}) => checkedSetupDigests(
  digests: digests,
  governance: governance,
  custody: custody,
  account: member,
  chainId: chainId,
  now: at ?? now,
  firstNonce: firstNonce,
  rotationModule: noModule ? null : (module ?? rotationModule),
);

void main() {
  group('proposal documents match stawi\'s Go', () {
    test('a loan approval', () {
      final doc = loanApprovalDocument(
        loanBook: loanBook,
        custody: custody,
        loanId: BigInt.from(7),
        borrower: hx('borrower'),
        amount: BigInt.from(250000000),
        instalments: 6,
      );
      expect(bytesToHex0x(doc), gv('loan_approval', 'document'));
      expect(
        bytesToHex0x(payloadHashOf(doc)),
        gv('loan_approval', 'payload_hash'),
      );
    });

    test('a write-off and a restructure', () {
      expect(
        bytesToHex0x(
          payloadHashOf(
            loanWriteOffDocument(
              loanBook: loanBook,
              custody: custody,
              loanId: BigInt.from(7),
            ),
          ),
        ),
        gv('write_off', 'payload_hash'),
      );
      final re = loanRestructureDocument(
        loanBook: loanBook,
        custody: custody,
        loanId: BigInt.from(7),
        instalments: 12,
        rateBps: 250,
      );
      expect(bytesToHex0x(re), gv('restructure', 'document'));
      expect(
        bytesToHex0x(payloadHashOf(re)),
        gv('restructure', 'payload_hash'),
      );
    });

    test('an engine grant, and the engine it grants', () {
      final doc = engineGrantDocument(custody: custody, module: rulesEngine);
      expect(bytesToHex0x(doc), gv('grant', 'document'));
      expect(bytesToHex0x(payloadHashOf(doc)), gv('grant', 'payload_hash'));
      expect(grantedEngine(doc, custody: custody), rulesEngine);
      expect(grantedEngine(doc, custody: hx('borrower')), isNull);
      // A limit or an expiry is not the setup's grant.
      final limited = Uint8List.fromList(doc)..[32 * 5 - 1] = 1;
      expect(grantedEngine(limited, custody: custody), isNull);
    });

    test('a template\'s header', () {
      final h = templateHeader(hx('template', 'document'))!;
      expect(h.custody, custody);
      expect(h.rulesEngine, hx('template', 'rules_engine'));
      expect(h.loanBook, hx('template', 'loan_book'));
      expect(templateHeader(hx('grant', 'document')), isNull);
    });

    test('a setup proposal\'s typed hash and digest', () {
      final v = go['setup_propose'] as Map<String, dynamic>;
      final typed = roomCallTypedHash(
        SignedCallKind.propose,
        verifier: governance,
        chainId: chainId,
        member: member,
        nonce: BigInt.one,
        deadline: BigInt.from(1900000000),
        params: [
          ...bigIntToBytes(BigInt.from(11), 32),
          ...hexToBytes(v['payload_hash'] as String),
        ],
      );
      expect(bytesToHex0x(typed), v['typed_hash']);
      expect(
        bytesToHex0x(accountWrappedHash(member, chainId, typed)),
        v['digest'],
      );
    });
  });

  group('checkedSetupDigests', () {
    test('signs the three genesis proposals at nonces 0, 1 and 2', () {
      final digests = genesisDigests();
      expect(check(digests), [for (final d in digests) d.digest]);
    });

    test('a merry-go-round grants the RotationModule in place of the loan '
        'book', () {
      final digests = [
        digestFor(Kind.ROOM_SETUP_STEP_KIND_GRANT_RULES_ENGINE, 0),
        digestFor(Kind.ROOM_SETUP_STEP_KIND_GRANT_ROTATION, 1),
        digestFor(Kind.ROOM_SETUP_STEP_KIND_RULES_TEMPLATE, 2),
      ];
      expect(check(digests), [for (final d in digests) d.digest]);
      expect(
        setupStepTitle(
          settlement.RoomSetupStep(
            step: Kind.ROOM_SETUP_STEP_KIND_GRANT_ROTATION,
          ),
        ),
        'Turn on the rotation payouts',
      );
    });

    test('refuses a setup granting both the loan book and the rotation, or '
        'the rules engine twice', () {
      expect(
        () => check([
          digestFor(Kind.ROOM_SETUP_STEP_KIND_GRANT_LOAN_ENGINE, 0),
          digestFor(Kind.ROOM_SETUP_STEP_KIND_GRANT_ROTATION, 1),
        ]),
        throwsA(isA<SigningRefused>()),
      );
      expect(
        () => check([
          digestFor(Kind.ROOM_SETUP_STEP_KIND_GRANT_RULES_ENGINE, 0),
          digestFor(
            Kind.ROOM_SETUP_STEP_KIND_GRANT_ROTATION,
            1,
            document: engineGrantDocument(
              custody: custody,
              module: rulesEngine,
            ),
          ),
        ], module: rulesEngine),
        throwsA(
          isA<SigningRefused>().having(
            (e) => e.reason,
            'reason',
            'both setup grants grant the same engine',
          ),
        ),
      );
    });

    test('a rotation grant grants exactly the protocol\'s RotationModule, '
        'and waits until finance names it', () {
      final digests = [
        digestFor(Kind.ROOM_SETUP_STEP_KIND_GRANT_RULES_ENGINE, 0),
        digestFor(Kind.ROOM_SETUP_STEP_KIND_GRANT_ROTATION, 1),
        digestFor(Kind.ROOM_SETUP_STEP_KIND_RULES_TEMPLATE, 2),
      ];
      expect(
        () => check(digests, noModule: true),
        throwsA(
          isA<SigningRefused>().having(
            (e) => e.reason,
            'reason',
            rotationModuleUnknownReason,
          ),
        ),
      );
      expect(
        () => check(digests, module: Uint8List(20)..[19] = 0x78),
        throwsA(
          isA<SigningRefused>().having(
            (e) => e.reason,
            'reason',
            contains('another module than the protocol\'s rotation module'),
          ),
        ),
      );
      // A setup with no rotation grant needs no module.
      expect(check(genesisDigests(), noModule: true), hasLength(3));
    });

    test('later, the steps still to propose from the current nonce', () {
      final later = [
        digestFor(Kind.ROOM_SETUP_STEP_KIND_GRANT_LOAN_ENGINE, 4),
        digestFor(Kind.ROOM_SETUP_STEP_KIND_RULES_TEMPLATE, 5),
      ];
      expect(check(later, firstNonce: null), hasLength(2));
    });

    void refuses(
      List<settlement.RoomSetupDigest> digests,
      String reason, {
      int? firstNonce = 0,
      DateTime? at,
    }) => expect(
      () => check(digests, firstNonce: firstNonce, at: at),
      throwsA(isA<SigningRefused>().having((e) => e.reason, 'reason', reason)),
    );

    test('refuses another member\'s proposal', () {
      final d = genesisDigests();
      d[1] = digestFor(
        Kind.ROOM_SETUP_STEP_KIND_GRANT_LOAN_ENGINE,
        1,
        signer: hx('borrower'),
      );
      refuses(d, 'a setup step is not the proposal it describes');
    });

    test('refuses a digest that is not the account\'s wrapping', () {
      final d = genesisDigests();
      d[0].digest = Uint8List(32);
      refuses(d, 'a setup digest is not your account wrapping of its proposal');
    });

    test('refuses a document that is not the one proposed', () {
      final d = genesisDigests();
      d[2].payloadHash = Uint8List(32);
      refuses(d, 'a setup step\'s document is not the one it proposes');
    });

    test('refuses a grant to another room or with limits', () {
      final d = genesisDigests();
      d[0] = digestFor(
        Kind.ROOM_SETUP_STEP_KIND_GRANT_RULES_ENGINE,
        0,
        document: engineGrantDocument(
          custody: hx('borrower'),
          module: rulesEngine,
        ),
      );
      refuses(d, 'a setup grant is not an engine grant to this room');
    });

    test('refuses rules for other engines than the grants', () {
      final d = genesisDigests();
      d[2] = digestFor(
        Kind.ROOM_SETUP_STEP_KIND_RULES_TEMPLATE,
        2,
        document: templateDocumentFor(custody, hx('borrower'), loanBook),
      );
      refuses(d, 'the setup\'s rules name other engines than its grants');
    });

    test('refuses a template for another room', () {
      final d = genesisDigests();
      d[2] = digestFor(
        Kind.ROOM_SETUP_STEP_KIND_RULES_TEMPLATE,
        2,
        document: templateDocumentFor(hx('borrower'), rulesEngine, loanBook),
      );
      refuses(d, 'the setup\'s rules are not a template for this room');
    });

    test('refuses a step of the wrong kind, or twice', () {
      final d = genesisDigests();
      d[0] = digestFor(
        Kind.ROOM_SETUP_STEP_KIND_GRANT_RULES_ENGINE,
        0,
        proposalKind: scheduleProposalKind,
      );
      refuses(d, 'a setup step proposes another kind of decision');
      final twice = genesisDigests()
        ..[1] = digestFor(Kind.ROOM_SETUP_STEP_KIND_GRANT_RULES_ENGINE, 1);
      refuses(twice, 'settlement asked for an unknown setup step');
    });

    test('refuses steps out of nonce order', () {
      final d = genesisDigests()
        ..[2] = digestFor(Kind.ROOM_SETUP_STEP_KIND_RULES_TEMPLATE, 3);
      refuses(d, 'the setup steps are not signed in order');
      refuses(
        genesisDigests().sublist(1),
        'the setup steps are not signed in order',
      );
    });

    test('refuses expired signatures', () {
      refuses(
        genesisDigests(),
        'the setup signatures have expired',
        at: DateTime.fromMillisecondsSinceEpoch(1900000000 * 1000, isUtc: true),
      );
    });
  });

  group('RoomSetupProgress', () {
    settlement.RoomSetupStep step(
      Kind kind,
      settlement.RoomSetupStepState state, {
      DateTime? closes,
    }) => settlement.RoomSetupStep(
      step: kind,
      state: state,
      onchainProposalId: Int64(kind.value + 10),
      votingClosesAt: closes == null ? null : Timestamp.fromDateTime(closes),
    );

    test('names the vote that is open and when it closes', () {
      final p = RoomSetupProgress(
        settlement.RoomSetup(
          state: settlement.RoomSetupState.ROOM_SETUP_STATE_VOTING,
          steps: [
            step(
              Kind.ROOM_SETUP_STEP_KIND_GRANT_RULES_ENGINE,
              settlement.RoomSetupStepState.ROOM_SETUP_STEP_STATE_QUEUED,
            ),
            step(
              Kind.ROOM_SETUP_STEP_KIND_GRANT_LOAN_ENGINE,
              settlement.RoomSetupStepState.ROOM_SETUP_STEP_STATE_VOTING,
              closes: now.add(const Duration(days: 3)),
            ),
            step(
              Kind.ROOM_SETUP_STEP_KIND_RULES_TEMPLATE,
              settlement.RoomSetupStepState.ROOM_SETUP_STEP_STATE_WAITING,
            ),
          ],
        ),
      );
      expect(
        p.headline(now),
        'Setting up lending: vote 2 of 3, closes in 3 days',
      );
      expect(p.voting.map((s) => s.step), [
        Kind.ROOM_SETUP_STEP_KIND_GRANT_LOAN_ENGINE,
      ]);
    });

    test('a merry-go-round\'s setup speaks of the rotation', () {
      final steps = [
        step(
          Kind.ROOM_SETUP_STEP_KIND_GRANT_ROTATION,
          settlement.RoomSetupStepState.ROOM_SETUP_STEP_STATE_VOTING,
          closes: now.add(const Duration(days: 3)),
        ),
      ];
      expect(
        RoomSetupProgress(
          settlement.RoomSetup(
            state: settlement.RoomSetupState.ROOM_SETUP_STATE_VOTING,
            steps: steps,
          ),
        ).headline(now),
        'Setting up the rotation: vote 1 of 1, closes in 3 days',
      );
      final ready = settlement.RoomSetup(
        state: settlement.RoomSetupState.ROOM_SETUP_STATE_READY,
        steps: steps,
      );
      expect(setupRunsRotation(ready), isTrue);
      expect(
        RoomSetupProgress(ready).headline(now),
        startsWith('The rotation is set up'),
      );
    });

    test('a step not open yet says when it opens', () {
      final p = RoomSetupProgress(
        settlement.RoomSetup(
          state: settlement.RoomSetupState.ROOM_SETUP_STATE_PROPOSING,
          votingPeriodSeconds: Int64(const Duration(days: 3).inSeconds),
          steps: [
            step(
              Kind.ROOM_SETUP_STEP_KIND_GRANT_RULES_ENGINE,
              settlement.RoomSetupStepState.ROOM_SETUP_STEP_STATE_PROPOSING,
              closes: now.add(const Duration(days: 5)),
            ),
          ],
        ),
      );
      expect(
        p.headline(now),
        'Setting up lending: vote 1 of 1, opens in 2 days',
      );
    });

    test('asks a founder to sign when settlement holds no signatures', () {
      final p = RoomSetupProgress(
        settlement.RoomSetup(
          state: settlement.RoomSetupState.ROOM_SETUP_STATE_AWAITING_SIGNATURE,
          needsSignatures: genesisDigests(),
        ),
      );
      expect(p.asksMe, isTrue);
      expect(
        p.headline(now),
        'Setting up lending: a founder needs to sign the setup',
      );
      expect(
        RoomSetupProgress(
          settlement.RoomSetup(
            state: settlement.RoomSetupState.ROOM_SETUP_STATE_NONE,
          ),
        ).shown,
        isFalse,
      );
    });
  });
}
