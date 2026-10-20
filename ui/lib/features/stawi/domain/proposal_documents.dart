/// The documents a room's proposals carry, rebuilt on the device. Every vote
/// that changes a room's money names keccak256 of a document: the ABI
/// encoding of its tag, the engine, the room's custody and the change
/// (stawi pkg/rules money.go and pkg/evm/stawi payloads.go). The device
/// builds the document itself from what the person chose and the room's
/// contracts as finance knows them, so a proposal settlement prepared is
/// signed only when it proposes exactly that.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

/// GovernanceModule.ProposalKind numbers the SDK's ProposalKinds leaves out
/// (stawi pkg/evm/stawi payloads.go).
const int scheduleProposalKind = 5;
const int capabilityGrantProposalKind = 11;

/// The version every protocol engine registers (EngineBase VERSION), as a
/// setup grant names it.
const int engineModuleVersion = 1;

Uint8List _word(BigInt v) {
  if (v.isNegative || v.bitLength > 256) {
    throw ArgumentError.value(v, 'v', 'a uint256');
  }
  return bigIntToBytes(v, 32);
}

Uint8List _int(int v) => _word(BigInt.from(v));

Uint8List _address(List<int> a, String name) {
  if (a.length != 20) throw ArgumentError('$name: a 20-byte address');
  return Uint8List(32)..setRange(12, 32, a);
}

/// The tail of a dynamic `string`/`bytes`: its length, then the bytes padded
/// to a whole word.
Uint8List _dynamic(List<int> data) {
  final padded = (data.length + 31) ~/ 32 * 32;
  return Uint8List.fromList([
    ..._int(data.length),
    ...data,
    ...Uint8List(padded - data.length),
  ]);
}

/// abi.encode(string tag, ...static words): the tag's offset first, the
/// static words, then the tag.
Uint8List _tagged(String tag, List<Uint8List> words) => Uint8List.fromList([
  ..._int(32 * (words.length + 1)),
  for (final w in words) ...w,
  ..._dynamic(ascii.encode(tag)),
]);

/// LoanBook.approvalPayloadHash's document: a room vote approving pending
/// loan [loanId] of [borrower], for [amount] (minor units) over
/// [instalments] (rules.LoanApprovalDocument).
Uint8List loanApprovalDocument({
  required List<int> loanBook,
  required List<int> custody,
  required BigInt loanId,
  required List<int> borrower,
  required BigInt amount,
  required int instalments,
}) => _tagged('STAWI_LOAN_APPROVE_V1', [
  _address(loanBook, 'loanBook'),
  _address(custody, 'custody'),
  _word(loanId),
  _address(borrower, 'borrower'),
  _word(amount),
  _int(instalments),
]);

/// LoanBook.writeOffPayloadHash's document (rules.LoanWriteOffDocument).
Uint8List loanWriteOffDocument({
  required List<int> loanBook,
  required List<int> custody,
  required BigInt loanId,
}) => _tagged('STAWI_LOAN_WRITE_OFF_V1', [
  _address(loanBook, 'loanBook'),
  _address(custody, 'custody'),
  _word(loanId),
]);

/// LoanBook.restructurePayloadHash's document: the loan repaid over
/// [instalments] at [rateBps] from now (rules.LoanRestructureDocument).
Uint8List loanRestructureDocument({
  required List<int> loanBook,
  required List<int> custody,
  required BigInt loanId,
  required int instalments,
  required int rateBps,
}) => _tagged('STAWI_LOAN_RESTRUCTURE_V1', [
  _address(loanBook, 'loanBook'),
  _address(custody, 'custody'),
  _word(loanId),
  _int(instalments),
  _int(rateBps),
]);

/// GovernanceModule.grantPayloadHash's document for an engine grant with no
/// limits and no expiry, the grant a room's setup proposes (stawi
/// GrantPayload).
Uint8List engineGrantDocument({
  required List<int> custody,
  required List<int> module,
}) => _tagged('CAPABILITY_GRANT', [
  _address(custody, 'custody'),
  _address(module, 'module'),
  _int(engineModuleVersion),
  _int(0),
  _int(0),
  _int(0),
  _int(0),
]);

/// The payload hash a proposal of [document] carries.
Uint8List payloadHashOf(List<int> document) => keccak256(document);

/// The engine a setup grant document grants, when [document] is exactly an
/// unlimited, unexpiring grant to [custody] of a protocol engine; null
/// otherwise.
Uint8List? grantedEngine(List<int> document, {required List<int> custody}) {
  if (document.length < 32 * 9) return null;
  final module = Uint8List.fromList(document.sublist(64 + 12, 96));
  if (module.every((b) => b == 0)) return null;
  final Uint8List rebuilt;
  try {
    rebuilt = engineGrantDocument(custody: custody, module: module);
    // A malformed address is not a grant document.
    // ignore: avoid_catching_errors
  } on ArgumentError {
    return null;
  }
  return _same(rebuilt, document) ? module : null;
}

/// What a rules template document installs: the room's custody and the
/// rules and loan engines it names (rules.TemplateDocument: tag, custody,
/// rules engine, rules, loan engine, loans, gas tank, gas).
typedef TemplateHeader = ({
  Uint8List custody,
  Uint8List rulesEngine,
  Uint8List loanBook,
});

/// The header of a template document; null when [document] is not one.
TemplateHeader? templateHeader(List<int> document) {
  if (document.length < 32 * 9) return null;
  BigInt word(int i) => bytesToBigInt(document.sublist(32 * i, 32 * i + 32));
  Uint8List? address(int i) {
    final w = document.sublist(32 * i, 32 * i + 32);
    if (w.take(12).any((b) => b != 0)) return null;
    return Uint8List.fromList(w.sublist(12));
  }

  final offset = word(0);
  if (offset != BigInt.from(32 * 8)) return null;
  final tag = ascii.encode('STAWI_TEMPLATE_V1');
  const at = 32 * 8;
  if (word(8) != BigInt.from(tag.length) ||
      document.length < at + 64 ||
      !_same(document.sublist(at + 32, at + 32 + tag.length), tag)) {
    return null;
  }
  final custody = address(1);
  final rules = address(2);
  final loans = address(4);
  if (custody == null || rules == null || loans == null) return null;
  return (custody: custody, rulesEngine: rules, loanBook: loans);
}

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
