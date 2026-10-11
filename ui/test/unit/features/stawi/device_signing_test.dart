import 'dart:math';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi/features/stawi/domain/stawi_payloads.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

void main() {
  final vectors = GoSignedCallVectors.load();

  group('DeviceKeyStore', () {
    test('signs every Go vector byte for byte', () async {
      for (final v in vectors.preparedCallSignatures) {
        final store = DeviceKeyStore(
          vaultWith('p1', v['private_key'] as String),
        );
        final key = (await store.load('p1'))!;
        final digest = hexToBytes(v['digest'] as String);
        expect(
          bytesToHex0x(key.sign(digest)),
          v['signature'],
          reason: v['name'] as String,
        );
        expect(bytesToHex0x(key.address), v['signer']);
        expect(key.keyId, (v['signer'] as String).toLowerCase());
        expect(key.publicKey, hasLength(65));
      }
    });

    test('generates the key once and keeps it per profile', () async {
      final vault = MemoryDeviceKeyVault();
      final store = DeviceKeyStore(vault, random: Random(7));

      expect(await store.load('p1'), isNull);
      final first = await store.loadOrCreate('p1');
      final again = await store.loadOrCreate('p1');
      final reopened = await DeviceKeyStore(vault).load('p1');
      final other = await store.loadOrCreate('p2');

      expect(again.address, first.address);
      expect(reopened!.address, first.address);
      expect(other.address, isNot(first.address));
      expect(vault.writes, 2);
      expect(vault.entries.keys, {
        'stawi.device_key.v1.p1',
        'stawi.device_key.v1.p2',
      });
    });

    test('concurrent first use generates a single key', () async {
      final vault = MemoryDeviceKeyVault();
      final store = DeviceKeyStore(vault);
      final keys = await Future.wait([
        store.loadOrCreate('p1'),
        store.loadOrCreate('p1'),
        store.loadOrCreate('p1'),
      ]);
      expect(vault.writes, 1);
      expect(keys.map((k) => k.keyId).toSet(), hasLength(1));
    });

    test('signatures carry v as 27 or 28, never a raw recovery id', () async {
      final key = await DeviceKeyStore(vaultWith('p1', anvilKey)).load('p1');
      final vs = <int>{};
      for (var i = 0; i < 32; i++) {
        final signature = key!.sign(keccak256(Uint8List.fromList([i])));
        expect(signature, hasLength(65));
        vs.add(signature[64]);
      }
      // Both recovery ids occur over these digests, each sent as 27 + id.
      expect(vs, {27, 28});
    });

    test('a signature recovers to the device key', () async {
      final key = await DeviceKeyStore(
        MemoryDeviceKeyVault(),
      ).loadOrCreate('p');
      final digest = keccak256(Uint8List.fromList([1, 2, 3]));
      expect(recoverDeviceAddress(digest, key.sign(digest)), key.address);
    });
  });

  group('checkedRoomCallDigest', () {
    settlement.PrepareRoomCallResponse prepared(
      Map<String, dynamic> v, {
      settlement.RoomCallKind kind =
          settlement.RoomCallKind.ROOM_CALL_KIND_INVITE,
      String room = 'room00000000000000aa',
    }) {
      final signer = hexToBytes(v['account'] as String);
      final digest = hexToBytes(v['wrapped'] as String);
      return settlement.PrepareRoomCallResponse(
        callId: 'call0000000000000001',
        digest: digest,
        signer: signer,
        call: settlement.RoomCall(
          callId: 'call0000000000000001',
          chainId: Int64.parseInt(v['chain_id'] as String),
          chatRoomId: room,
          kind: kind,
          signer: signer,
          typedHash: hexToBytes(v['hash'] as String),
          digest: digest,
          requiresSignature: true,
        ),
      );
    }

    final wrapped = vectors.accountWrappedHashes
        .where((v) => v['chain_id'] != '18446744073709551615')
        .toList();

    test('accepts settlement digests matching Go AccountWrappedHash', () {
      for (final v in wrapped) {
        final digest = checkedRoomCallDigest(
          prepared: prepared(v),
          kind: settlement.RoomCallKind.ROOM_CALL_KIND_INVITE,
          chatRoomId: 'room00000000000000aa',
          ownAccounts: [hexToBytes(v['account'] as String)],
        );
        expect(bytesToHex0x(digest), v['wrapped'], reason: v['name'] as String);
      }
    });

    test('refuses a digest that is not the account wrapping', () {
      final v = wrapped.firstWhere((v) => v['name'] == 'seq/seq');
      final tampered = prepared(v);
      final bad = Uint8List.fromList(tampered.digest)..[0] ^= 1;
      tampered
        ..digest = bad
        ..call.digest = bad;
      expect(
        () => checkedRoomCallDigest(
          prepared: tampered,
          kind: settlement.RoomCallKind.ROOM_CALL_KIND_INVITE,
          chatRoomId: 'room00000000000000aa',
          ownAccounts: [hexToBytes(v['account'] as String)],
        ),
        throwsA(isA<SigningRefused>()),
      );
    });

    test('refuses another kind, room or signer', () {
      final v = wrapped.firstWhere((v) => v['name'] == 'seq/seq');
      final account = hexToBytes(v['account'] as String);
      expect(
        () => checkedRoomCallDigest(
          prepared: prepared(
            v,
            kind: settlement.RoomCallKind.ROOM_CALL_KIND_LEAVE,
          ),
          kind: settlement.RoomCallKind.ROOM_CALL_KIND_INVITE,
          chatRoomId: 'room00000000000000aa',
          ownAccounts: [account],
        ),
        throwsA(isA<SigningRefused>()),
      );
      expect(
        () => checkedRoomCallDigest(
          prepared: prepared(v, room: 'room00000000000000bb'),
          kind: settlement.RoomCallKind.ROOM_CALL_KIND_INVITE,
          chatRoomId: 'room00000000000000aa',
          ownAccounts: [account],
        ),
        throwsA(isA<SigningRefused>()),
      );
      expect(
        () => checkedRoomCallDigest(
          prepared: prepared(v),
          kind: settlement.RoomCallKind.ROOM_CALL_KIND_INVITE,
          chatRoomId: 'room00000000000000aa',
          ownAccounts: [Uint8List(20)],
        ),
        throwsA(isA<SigningRefused>()),
      );
    });

    test('kind names match what chat compares', () {
      expect(
        roomCallKindName(settlement.RoomCallKind.ROOM_CALL_KIND_CAST_VOTE),
        'CAST_VOTE',
      );
      expect(
        roomCallKindName(
          settlement.RoomCallKind.ROOM_CALL_KIND_ACCEPT_INVITATION,
        ),
        'ACCEPT_INVITATION',
      );
    });
  });

  group('checkedGenesisDigest', () {
    final v = vectors.accountWrappedHashes.firstWhere(
      (v) => v['name'] == 'anvil_0/seq' && v['chain_id'] == '146',
    );
    final account = hexToBytes(v['account'] as String);
    final genesisHash = hexToBytes(v['hash'] as String);

    settlement.RoomGenesis genesis({
      List<int>? signingDigest,
      settlement.RoomGenesisState state =
          settlement.RoomGenesisState.ROOM_GENESIS_STATE_PENDING,
    }) => settlement.RoomGenesis(
      genesisId: 'gen00000000000000001',
      state: state,
      chainId: Int64(146),
      genesisHash: genesisHash,
      founders: [
        settlement.RoomFounder(
          profileId: 'p1',
          account: account,
          signingDigest: signingDigest ?? hexToBytes(v['wrapped'] as String),
        ),
      ],
    );

    final card = StawiGenesisView(
      genesisId: 'gen00000000000000001',
      genesisHash: genesisHash,
      constitutionHash: Uint8List(32),
      founderProfileIds: const ['p1'],
    );

    test('returns the founder digest when it wraps the posted hash', () {
      final digest = checkedGenesisDigest(
        genesis: genesis(),
        card: card,
        profileId: 'p1',
        ownAccounts: [account],
      );
      expect(bytesToHex0x(digest), v['wrapped']);
    });

    test('refuses a hash other than the posted one', () {
      final other = StawiGenesisView(
        genesisId: card.genesisId,
        genesisHash: Uint8List(32),
        constitutionHash: Uint8List(32),
        founderProfileIds: const ['p1'],
      );
      expect(
        () => checkedGenesisDigest(
          genesis: genesis(),
          card: other,
          profileId: 'p1',
          ownAccounts: [account],
        ),
        throwsA(isA<SigningRefused>()),
      );
    });

    test('refuses a non-founder, a wrong digest and a closed genesis', () {
      expect(
        () => checkedGenesisDigest(
          genesis: genesis(),
          card: card,
          profileId: 'p2',
          ownAccounts: [account],
        ),
        throwsA(isA<SigningRefused>()),
      );
      expect(
        () => checkedGenesisDigest(
          genesis: genesis(signingDigest: Uint8List(32)),
          card: card,
          profileId: 'p1',
          ownAccounts: [account],
        ),
        throwsA(isA<SigningRefused>()),
      );
      expect(
        () => checkedGenesisDigest(
          genesis: genesis(
            state: settlement.RoomGenesisState.ROOM_GENESIS_STATE_ACTIVE,
          ),
          card: card,
          profileId: 'p1',
          ownAccounts: [account],
        ),
        throwsA(isA<SigningRefused>()),
      );
    });
  });
}
