/// The RotationModule: the protocol module that pays a merry-go-round's turns
/// under the room's capability grant. The ProtocolRegistry keeps no role for
/// it, so the device checks it from finance's GetRoom engines.rotation_module
/// (stawi v0.2.8): the address the signed protocol manifest names, which the
/// protocol registered in the CapabilityRegistry (a timelocked act of its
/// upgrade authority; the chain refuses a grant to code that does not hash to
/// the registered code hash), and the room's own grant to it.
library;

import 'dart:typed_data';

import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import 'governance_requests.dart';
import 'proposal_documents.dart';
import 'signing_checks.dart';

/// The version a RotationModule grant names (RotationModule.VERSION).
const int rotationModuleVersion = 1;

/// The deployment's RotationModule as the device accepts it, and whether the
/// room's grant to it is ACTIVE.
final class CheckedRotationModule {
  const CheckedRotationModule._(this.address, this.grantActive);

  /// The module's 20-byte address.
  final Uint8List address;

  /// The room's newest grant names this room and this module and is ACTIVE
  /// now: a rotation proposed in the room is paid only while it is.
  final bool grantActive;
}

bool _nonZero(List<int> b, int length) =>
    b.length == length && b.any((x) => x != 0);

/// Checks finance's RotationModule binding before anything names it:
///   - finance read one (the deployment has a RotationModule);
///   - a 20-byte address;
///   - the version a grant names ([rotationModuleVersion]);
///   - registered in the CapabilityRegistry at that version, with its code
///     hash;
///   - named by a signed protocol manifest (version, key id and the SHA-256
///     of its payload).
/// A grant counts only when it names this module, is ACTIVE and has a
/// capability id. Anything else is refused: nothing is granted to, or
/// started on, an address the device cannot tie to the protocol.
CheckedRotationModule checkedRotationModule(finance.RoomModuleBinding? m) {
  if (m == null) {
    throw const SigningRefused(
      'this deployment names no rotation module, so a rotation cannot run',
    );
  }
  if (!_nonZero(m.address, 20)) {
    throw const SigningRefused('the rotation module has no address');
  }
  if (m.moduleVersion != rotationModuleVersion) {
    throw const SigningRefused(
      'the rotation module is not the version a rotation grant names',
    );
  }
  if (!m.registered || !_nonZero(m.codeHash, 32)) {
    throw const SigningRefused(
      'the rotation module is not registered with the protocol',
    );
  }
  if (m.manifestVersion.toInt() <= 0 ||
      m.manifestKeyId.trim().isEmpty ||
      !_nonZero(m.manifestPayloadHash, 32)) {
    throw const SigningRefused(
      'no signed protocol manifest names the rotation module',
    );
  }
  final active =
      m.grantActive &&
      m.capabilityState == finance.CapabilityState.CAPABILITY_STATE_ACTIVE &&
      _nonZero(m.capabilityId, 32);
  return CheckedRotationModule._(Uint8List.fromList(m.address), active);
}

/// The CAPABILITY_GRANT document that grants the room [custody] the
/// RotationModule [module]: version 1, no limits, no expiry (settlement
/// grantPropose for engine_grant ROOM_ENGINE_ROTATION; stawi GrantPayload).
Uint8List rotationGrantDocument({
  required List<int> custody,
  required List<int> module,
}) => engineGrantDocument(custody: custody, module: module);

/// The vote that adds a rotation to a group: the room grants the
/// RotationModule [module] (checked by [checkedRotationModule]) an unlimited,
/// unexpiring capability. The device rebuilds the grant document from the
/// room's custody and that module, so the proposal signed grants exactly it.
GovernanceRequest proposeRotationGrantRequest({
  required CheckedRotationModule module,
}) => GovernanceRequest(
  kind: settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE,
  params: settlement.RoomCallParams(
    propose: settlement.RoomProposeParams(
      engineGrant: settlement.RoomEngineGrant(
        engine: settlement.RoomEngine.ROOM_ENGINE_ROTATION,
      ),
    ),
  ),
  summary: 'Add a rotation to this group',
  expected: (room, prepared) {
    final custody =
        room.custody ??
        (throw const SigningRefused(roomContractsUnknownReason));
    final hash = payloadHashOf(
      rotationGrantDocument(custody: custody, module: module.address),
    );
    if (!bytesEqual(prepared.call.payloadHash, hash)) {
      throw const SigningRefused(
        'settlement proposes another grant than the rotation module\'s',
      );
    }
    return RoomCallExpected.propose(
      proposalKind: capabilityGrantProposalKind,
      payloadHash: hash,
    );
  },
  lines: [
    ('Turns on', 'Rotation payouts'),
    ('Module', shortAccount(module.address)),
    ('Limits', 'None; no expiry'),
  ],
);
