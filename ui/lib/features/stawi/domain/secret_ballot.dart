import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../data/device_key_store.dart';

/// GovernanceModule.Choice for a vote: stawi_finance_sdk's voteChoice*
/// constants.
int chainChoiceOf(finance.VoteChoice choice) => switch (choice) {
  finance.VoteChoice.VOTE_CHOICE_APPROVE => voteChoiceFor,
  finance.VoteChoice.VOTE_CHOICE_REJECT => voteChoiceAgainst,
  finance.VoteChoice.VOTE_CHOICE_ABSTAIN => voteChoiceAbstain,
  _ => throw ArgumentError.value(choice, 'choice', 'choose a vote'),
};

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

  /// The commitment the COMMIT_VOTE carries (stawi_finance_sdk
  /// voteCommitment, Go stawi.Commitment).
  Uint8List commitment(int proposalId) => voteCommitment(
    choice: chainChoiceOf(choice),
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
    final salt = newVoteSalt(random: _random);
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
