import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../data/device_key_store.dart';

/// GovernanceModule's secret-ballot commitment, Go stawi.Commitment:
/// keccak256(abi.encode(uint8 choice, bytes32 salt, uint256 proposalId,
/// address member)). All four are static ABI words, so the encoding is the
/// four 32-byte words in order. stawi_finance_sdk has no helper for it yet;
/// test/fixtures/stawi/go_vote_commitments.json holds Go-produced vectors.
///
/// It is computed here, on the device, so the choice never leaves it before
/// the reveal (settlement would compute it from a choice and salt, which
/// would show the choice to the platform at commit time).
Uint8List voteCommitment({
  required int choice,
  required List<int> salt,
  required BigInt proposalId,
  required List<int> member,
}) {
  if (choice < 0 || choice > 255) {
    throw ArgumentError.value(choice, 'choice', 'must be a uint8');
  }
  if (salt.length != 32) {
    throw ArgumentError.value(salt.length, 'salt', 'must be 32 bytes');
  }
  if (member.length != 20) {
    throw ArgumentError.value(member.length, 'member', 'must be 20 bytes');
  }
  if (proposalId.isNegative || proposalId.bitLength > 256) {
    throw ArgumentError.value(proposalId, 'proposalId', 'must be a uint256');
  }
  return keccak256([
    ...bigIntToBytes(BigInt.from(choice), 32),
    ...salt,
    ...bigIntToBytes(proposalId, 32),
    ...Uint8List(12),
    ...member,
  ]);
}

/// A committed vote kept on this device for its reveal.
class SealedVote {
  const SealedVote({
    required this.choice,
    required this.salt,
    required this.member,
  });

  factory SealedVote.fromJson(Map<String, dynamic> json) => SealedVote(
    choice: finance.VoteChoice.valueOf(json['choice'] as int)!,
    salt: hexToBytes(json['salt'] as String),
    member: hexToBytes(json['member'] as String),
  );

  final finance.VoteChoice choice;
  final Uint8List salt;

  /// The account the commitment was made for.
  final Uint8List member;

  Map<String, dynamic> toJson() => {
    'choice': choice.value,
    'salt': bytesToHex(salt),
    'member': bytesToHex(member),
  };

  Uint8List commitment(int proposalId) => voteCommitment(
    choice: choice.value,
    salt: salt,
    proposalId: BigInt.from(proposalId),
    member: member,
  );
}

/// Keeps each sealed vote's choice and salt in the device's secure storage
/// until it is revealed; lose them and the vote cannot be revealed.
class SecretBallotStore {
  SecretBallotStore(this._vault, {Random? random})
    : _random = random ?? Random.secure();

  final DeviceKeyVault _vault;
  final Random _random;

  static String _slot(String roomId, int proposalId) =>
      'stawi.ballot.v1.$roomId.$proposalId';

  /// Seals [choice] with a fresh salt for [member] and stores it before the
  /// commitment is sent, so a crash cannot lose the salt of a sent vote.
  Future<SealedVote> seal({
    required String roomId,
    required int proposalId,
    required finance.VoteChoice choice,
    required Uint8List member,
  }) async {
    final salt = Uint8List(32);
    for (var i = 0; i < salt.length; i++) {
      salt[i] = _random.nextInt(256);
    }
    final vote = SealedVote(choice: choice, salt: salt, member: member);
    await _vault.write(_slot(roomId, proposalId), jsonEncode(vote.toJson()));
    return vote;
  }

  Future<SealedVote?> load(String roomId, int proposalId) async {
    final stored = await _vault.read(_slot(roomId, proposalId));
    if (stored == null || stored.isEmpty) return null;
    return SealedVote.fromJson(jsonDecode(stored) as Map<String, dynamic>);
  }
}
