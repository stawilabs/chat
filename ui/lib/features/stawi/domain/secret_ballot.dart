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
    this.revealClosesAt,
    this.revealed = false,
  });

  factory SealedVote.fromJson(Map<String, dynamic> json) => SealedVote(
    choice: finance.VoteChoice.valueOf(json['choice'] as int)!,
    salt: hexToBytes(json['salt'] as String),
    member: hexToBytes(json['member'] as String),
    revealClosesAt: json['reveal_closes_at'] is String
        ? DateTime.tryParse(json['reveal_closes_at'] as String)
        : null,
    revealed: json['revealed'] == true,
  );

  final finance.VoteChoice choice;
  final Uint8List salt;

  /// The account the commitment was made for.
  final Uint8List member;

  /// When the reveal window closes, when known at commit time.
  final DateTime? revealClosesAt;

  /// Whether this device has sent the reveal.
  final bool revealed;

  Map<String, dynamic> toJson() => {
    'choice': choice.value,
    'salt': bytesToHex(salt),
    'member': bytesToHex(member),
    if (revealClosesAt != null)
      'reveal_closes_at': revealClosesAt!.toUtc().toIso8601String(),
    'revealed': revealed,
  };

  SealedVote markRevealed() => SealedVote(
    choice: choice,
    salt: salt,
    member: member,
    revealClosesAt: revealClosesAt,
    revealed: true,
  );

  /// The commitment the COMMIT_VOTE carries (stawi_finance_sdk
  /// voteCommitment, Go stawi.Commitment).
  Uint8List commitment(int proposalId) => voteCommitment(
    choice: chainChoiceOf(choice),
    salt: salt,
    proposalId: BigInt.from(proposalId),
    member: member,
  );
}

/// A sealed vote this device still has to reveal.
typedef PendingReveal = ({int proposalId, SealedVote vote});

/// Keeps each sealed vote's choice and salt in this device's secure storage
/// until it is revealed. The salt never leaves the device (that is what keeps
/// the ballot secret), so only this device can reveal the vote; lose it and
/// the vote cannot be revealed.
class SecretBallotStore {
  SecretBallotStore(this._vault, {Random? random})
    : _random = random ?? Random.secure();

  final DeviceKeyVault _vault;
  final Random _random;

  static String _slot(String roomId, int proposalId) =>
      'stawi.ballot.v1.$roomId.$proposalId';
  static String _index(String roomId) => 'stawi.ballot.v1.index.$roomId';

  /// Seals [choice] with a fresh salt for [member] and stores it before the
  /// commitment is sent, so a crash cannot lose the salt of a sent vote.
  Future<SealedVote> seal({
    required String roomId,
    required int proposalId,
    required finance.VoteChoice choice,
    required Uint8List member,
    DateTime? revealClosesAt,
  }) async {
    final vote = SealedVote(
      choice: choice,
      salt: newVoteSalt(random: _random),
      member: member,
      revealClosesAt: revealClosesAt,
    );
    await _vault.write(_slot(roomId, proposalId), jsonEncode(vote.toJson()));
    final ids = await _ids(roomId);
    if (!ids.contains(proposalId)) {
      await _vault.write(_index(roomId), jsonEncode([...ids, proposalId]));
    }
    return vote;
  }

  Future<SealedVote?> load(String roomId, int proposalId) async {
    final stored = await _vault.read(_slot(roomId, proposalId));
    if (stored == null || stored.isEmpty) return null;
    return SealedVote.fromJson(jsonDecode(stored) as Map<String, dynamic>);
  }

  /// Records that the reveal was sent.
  Future<void> markRevealed(String roomId, int proposalId) async {
    final vote = await load(roomId, proposalId);
    if (vote == null) return;
    await _vault.write(
      _slot(roomId, proposalId),
      jsonEncode(vote.markRevealed().toJson()),
    );
  }

  /// The votes this device sealed in [roomId] and has not revealed, soonest
  /// deadline first (unknown deadlines last).
  Future<List<PendingReveal>> pending(String roomId) async {
    final out = <PendingReveal>[];
    for (final id in await _ids(roomId)) {
      final vote = await load(roomId, id);
      if (vote != null && !vote.revealed) {
        out.add((proposalId: id, vote: vote));
      }
    }
    out.sort((a, b) {
      final x = a.vote.revealClosesAt;
      final y = b.vote.revealClosesAt;
      if (x == null || y == null) return x == null ? (y == null ? 0 : 1) : -1;
      return x.compareTo(y);
    });
    return out;
  }

  Future<List<int>> _ids(String roomId) async {
    final stored = await _vault.read(_index(roomId));
    if (stored == null || stored.isEmpty) return [];
    return (jsonDecode(stored) as List).cast<int>();
  }
}

/// How urgent revealing is: the reveal window is open, closing within a day,
/// or already closed.
enum RevealUrgency { open, closingSoon, closed, unknown }

RevealUrgency revealUrgency(SealedVote vote, DateTime now) {
  final closes = vote.revealClosesAt;
  if (closes == null) return RevealUrgency.unknown;
  if (!now.isBefore(closes)) return RevealUrgency.closed;
  if (closes.difference(now) <= const Duration(hours: 24)) {
    return RevealUrgency.closingSoon;
  }
  return RevealUrgency.open;
}
