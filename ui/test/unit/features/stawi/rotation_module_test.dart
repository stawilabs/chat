import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/domain/proposal_documents.dart';
import 'package:stawi/features/stawi/domain/rotation_module.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

void main() {
  // stawi's Go grant vector (pkg/evm/stawi GrantPayload / GrantPayloadHash):
  // custody 0x4041…53 grants module 0xa0a1…b3 at version 1, no limits.
  final go = jsonDecode(
    File('test/fixtures/stawi/go_proposal_documents.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final grant = go['grant'] as Map<String, dynamic>;
  final custody = hexToBytes(go['custody'] as String);

  Matcher refusedWith(String text) => throwsA(
    isA<SigningRefused>().having((e) => e.reason, 'reason', contains(text)),
  );

  group('checkedRotationModule', () {
    test('accepts the manifest\'s registered module, and reads its grant', () {
      final m = checkedRotationModule(rotationModuleBinding());
      expect(m.address, goGrantModule);
      expect(m.grantActive, isFalse);
      expect(
        checkedRotationModule(rotationModuleBinding(grantActive: true))
            .grantActive,
        isTrue,
      );
    });

    test('a grant counts only when ACTIVE with a capability id', () {
      final suspended = rotationModuleBinding(grantActive: true)
        ..capabilityState = finance.CapabilityState.CAPABILITY_STATE_SUSPENDED;
      expect(checkedRotationModule(suspended).grantActive, isFalse);
      final noId = rotationModuleBinding(grantActive: true)
        ..capabilityId = Uint8List(32);
      expect(checkedRotationModule(noId).grantActive, isFalse);
    });

    test('refuses no module, no address, another version, an unregistered '
        'module and one no signed manifest names', () {
      expect(() => checkedRotationModule(null), refusedWith('names no'));
      expect(
        () => checkedRotationModule(
          rotationModuleBinding()..address = Uint8List(20),
        ),
        refusedWith('no address'),
      );
      expect(
        () => checkedRotationModule(rotationModuleBinding(moduleVersion: 2)),
        refusedWith('not the version'),
      );
      expect(
        () => checkedRotationModule(rotationModuleBinding(registered: false)),
        refusedWith('not registered'),
      );
      expect(
        () => checkedRotationModule(
          rotationModuleBinding()..codeHash = Uint8List(32),
        ),
        refusedWith('not registered'),
      );
      expect(
        () => checkedRotationModule(
          rotationModuleBinding()..manifestPayloadHash = Uint8List(0),
        ),
        refusedWith('no signed protocol manifest'),
      );
      expect(
        () => checkedRotationModule(
          rotationModuleBinding()..manifestVersion = Int64.ZERO,
        ),
        refusedWith('no signed protocol manifest'),
      );
    });
  });

  group('proposeRotationGrantRequest', () {
    final module = checkedRotationModule(rotationModuleBinding());
    final room = RoomContracts(
      governance: Uint8List(20)..[0] = 0x41,
      custody: custody,
      chainId: BigInt.from(146),
    );
    settlement.PrepareRoomCallResponse prepared(List<int> payloadHash) =>
        settlement.PrepareRoomCallResponse(
          call: settlement.RoomCall(payloadHash: payloadHash),
        );

    test('the grant document is Go\'s GrantPayload of the RotationModule', () {
      final doc = rotationGrantDocument(
        custody: custody,
        module: module.address,
      );
      expect(bytesToHex0x(doc), grant['document']);
      expect(bytesToHex0x(payloadHashOf(doc)), grant['payload_hash']);
    });

    test('asks settlement for engine_grant ROTATION and checks the grant it '
        'prepares is Go\'s', () {
      final r = proposeRotationGrantRequest(module: module);
      expect(r.kind, settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE);
      expect(
        r.params!.propose.engineGrant,
        settlement.RoomEngineGrant(
          engine: settlement.RoomEngine.ROOM_ENGINE_ROTATION,
        ),
      );
      expect(r.summary, 'Add a rotation to this group');
      final expected = r.expected(
        room,
        prepared(hexToBytes(grant['payload_hash'] as String)),
      );
      expect(expected.call, SignedCallKind.propose);
    });

    test('refuses a grant of anything else, or a room it cannot check', () {
      final r = proposeRotationGrantRequest(module: module);
      final other = payloadHashOf(
        engineGrantDocument(custody: custody, module: Uint8List(20)..[0] = 1),
      );
      expect(
        () => r.expected(room, prepared(other)),
        refusedWith('another grant'),
      );
      expect(
        () => r.expected(
          RoomContracts(chainId: BigInt.from(146)),
          prepared(hexToBytes(grant['payload_hash'] as String)),
        ),
        throwsA(isA<SigningRefused>()),
      );
    });
  });
}
