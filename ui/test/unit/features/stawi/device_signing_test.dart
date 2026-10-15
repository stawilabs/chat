import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/signing_gate.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi/features/stawi/domain/stawi_payloads.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
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
          gate: SigningGate.open,
        );
        final key = await store.unlock('p1', reason: 'x');
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
      final store = DeviceKeyStore(
        vault,
        gate: SigningGate.open,
        random: Random(7),
      );

      expect(await store.load('p1'), isNull);
      final first = await store.loadOrCreate('p1');
      final again = await store.loadOrCreate('p1');
      final reopened = await DeviceKeyStore(
        vault,
        gate: SigningGate.open,
      ).load('p1');
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
      final store = DeviceKeyStore(vault, gate: SigningGate.open);
      final keys = await Future.wait([
        store.loadOrCreate('p1'),
        store.loadOrCreate('p1'),
        store.loadOrCreate('p1'),
      ]);
      expect(vault.writes, 1);
      expect(keys.map((k) => k.keyId).toSet(), hasLength(1));
    });

    test('signatures carry v as 27 or 28, never a raw recovery id', () async {
      final key = await DeviceKeyStore(
        vaultWith('p1', anvilKey),
        gate: SigningGate.open,
      ).unlock('p1', reason: 'x');
      final vs = <int>{};
      for (var i = 0; i < 32; i++) {
        final signature = key.sign(keccak256(Uint8List.fromList([i])));
        expect(signature, hasLength(65));
        vs.add(signature[64]);
      }
      // Both recovery ids occur over these digests, each sent as 27 + id.
      expect(vs, {27, 28});
    });

    test('the key read without the lock is the key that signs', () async {
      final store = DeviceKeyStore(
        MemoryDeviceKeyVault(),
        gate: SigningGate.open,
      );
      final public = await store.loadOrCreate('p');
      final signer = await store.unlock('p', reason: 'x');
      expect(public, isNot(isA<DeviceKeyHandle>()));
      expect(signer.address, public.address);
      expect(signer.publicKey, public.publicKey);
      expect((await store.load('p'))!.keyId, public.keyId);
    });

    test('a signature recovers to the device key', () async {
      final key = await DeviceKeyStore(
        MemoryDeviceKeyVault(),
        gate: SigningGate.open,
      ).unlock('p', reason: 'x');
      final digest = keccak256(Uint8List.fromList([1, 2, 3]));
      expect(recoverDeviceAddress(digest, key.sign(digest)), key.address);
    });
  });

  // Room calls are checked by checkedRoomCall: room_call_checks_test.dart.
  group('room call kinds', () {
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
    final rg = GoRoomGenesisVectors.named('agent');
    final account = hexToBytes(
      (rg.json['initial_members'] as List).first as String,
    );
    final genesisHash = rg.genesisHash;

    settlement.RoomGenesis genesis({
      List<int>? signingDigest,
      settlement.RoomGenesisState state =
          settlement.RoomGenesisState.ROOM_GENESIS_STATE_PENDING,
    }) {
      final g = rg.roomGenesis()..state = state;
      if (signingDigest != null) g.founders.first.signingDigest = signingDigest;
      return g;
    }

    final card = StawiGenesisView(
      genesisId: 'gen00000000000000001',
      genesisHash: genesisHash,
      constitutionHash: Uint8List(32),
      founderProfileIds: const ['p1'],
    );

    Matcher refusedWith(String reason) => throwsA(
      isA<SigningRefused>().having((e) => e.reason, 'reason', reason),
    );

    test('returns the founder digest when it wraps the posted hash', () {
      final checked = checkedGenesisDigest(
        genesis: genesis(),
        card: card,
        profileId: 'p1',
        ownAccounts: [account],
      );
      expect(
        checked.digest,
        accountWrappedHash(account, BigInt.from(146), genesisHash),
      );
      expect(checked.genesis.agentProfileId, 'p-agent');
    });

    test('every Go genesis case is recomputed on the device', () {
      for (final v in GoRoomGenesisVectors.load()) {
        final g = v.roomGenesis();
        final founder = g.founders.first;
        final checked = checkedGenesisDigest(
          genesis: g,
          card: StawiGenesisView(
            genesisId: g.genesisId,
            genesisHash: v.genesisHash,
            constitutionHash: Uint8List(32),
            founderProfileIds: [for (final f in g.founders) f.profileId],
          ),
          profileId: founder.profileId,
          ownAccounts: [Uint8List.fromList(founder.account)],
        );
        expect(checked.digest, founder.signingDigest, reason: v.name);
      }
    });

    test('refuses a genesis whose agent was swapped after hashing', () {
      final swapped = genesis();
      final agent = Uint8List.fromList(swapped.agent);
      agent[19] ^= 0x01;
      swapped.agent = agent;
      expect(
        () => checkedGenesisDigest(
          genesis: swapped,
          card: card,
          profileId: 'p1',
          ownAccounts: [account],
        ),
        refusedWith('the genesis hash does not match its contents'),
      );
    });

    test('refuses a genesis whose agent was removed after hashing', () {
      final removed = genesis()
        ..clearAgent()
        ..clearAgentProfileId();
      expect(
        () => checkedGenesisDigest(
          genesis: removed,
          card: card,
          profileId: 'p1',
          ownAccounts: [account],
        ),
        refusedWith('the genesis hash does not match its contents'),
      );
    });

    test('refuses other contents that differ from the hash', () {
      for (final change in <void Function(settlement.RoomGenesis)>[
        (g) => g.joinPolicy = finance.RoomJoinPolicy.ROOM_JOIN_POLICY_PUBLIC,
        (g) => g.compiledSecurityParamsHash = Uint8List(32),
        (g) => g.asset = Uint8List(20),
        (g) => g.manifestVersion = 2,
        (g) => g.roomBinding = Uint8List(32),
      ]) {
        final g = genesis();
        change(g);
        expect(
          () => checkedGenesisDigest(
            genesis: g,
            card: card,
            profileId: 'p1',
            ownAccounts: [account],
          ),
          refusedWith('the genesis hash does not match its contents'),
        );
      }
    });

    test('refuses an unspecified join policy and an unnamed agent', () {
      expect(
        () => checkedGenesisDigest(
          genesis: genesis()
            ..joinPolicy = finance.RoomJoinPolicy.ROOM_JOIN_POLICY_UNSPECIFIED,
          card: card,
          profileId: 'p1',
          ownAccounts: [account],
        ),
        throwsA(isA<SigningRefused>()),
      );
      expect(
        () => checkedGenesisDigest(
          genesis: genesis()..clearAgentProfileId(),
          card: card,
          profileId: 'p1',
          ownAccounts: [account],
        ),
        refusedWith('the genesis agent is not named'),
      );
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

  group('genesisAgentConfirmed', () {
    final v = GoRoomGenesisVectors.named('agent');
    final founder = Uint8List.fromList(List.filled(20, 0xf1));
    final carol = Uint8List.fromList(List.filled(20, 0xca));

    test('no agent needs no check', () {
      final g = GoRoomGenesisVectors.named('no_agent').roomGenesis();
      expect(genesisAgentConfirmed(g), isTrue);
    });

    test('a member agent matches their account in the genesis', () {
      final g = v.roomGenesis(
        founderProfileIds: const ['p1'],
        accounts: [founder],
        agentAccount: founder,
        agentProfileId: 'p1',
      );
      expect(genesisAgentConfirmed(g), isTrue);
      // A founder is never confirmed by a lookup in place of the genesis.
      final other = v.roomGenesis(
        founderProfileIds: const ['p1'],
        accounts: [founder],
        agentAccount: carol,
        agentProfileId: 'p1',
      );
      expect(
        genesisAgentConfirmed(other, resolvedAgentAccount: carol),
        isFalse,
      );
    });

    test('a DM partner agent matches the account chat answers', () {
      final g = v.roomGenesis(
        accounts: [founder],
        agentAccount: carol,
        agentProfileId: 'p-carol',
      );
      expect(genesisAgentConfirmed(g, resolvedAgentAccount: carol), isTrue);
    });

    test('a mismatched address is refused', () {
      final g = v.roomGenesis(
        accounts: [founder],
        agentAccount: Uint8List.fromList(List.filled(20, 0x66)),
        agentProfileId: 'p-carol',
      );
      expect(genesisAgentConfirmed(g, resolvedAgentAccount: carol), isFalse);
    });

    test('an agent that cannot be resolved is refused', () {
      final g = v.roomGenesis(
        accounts: [founder],
        agentAccount: carol,
        agentProfileId: 'p-carol',
      );
      expect(genesisAgentConfirmed(g), isFalse);
      expect(
        genesisAgentConfirmed(
          g..clearAgentProfileId(),
          resolvedAgentAccount: carol,
        ),
        isFalse,
      );
    });
  });
}
