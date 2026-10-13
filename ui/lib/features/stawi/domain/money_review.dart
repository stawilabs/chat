import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' as sdk;

import 'account_engine_calls.dart';
import 'personal_calls.dart';
import 'stawi_money.dart';

/// What a person is shown before a money action is signed: a plain title
/// (also what the device lock shows), the lines of what will happen and the
/// notes they should read. Built from the call the SDK has already checked,
/// never from settlement's own description.
const String _sign = 'Confirm and sign';

final class MoneyReview {
  const MoneyReview({
    required this.title,
    required this.lines,
    required this.signLabel,
    required this.done,
    this.notes = const [],
  });

  /// A personal loan or savings call. [counterpartyName] names the other
  /// person, [pocketName] the pocket the money leaves or enters.
  factory MoneyReview.personal(
    PersonalRequest r,
    sdk.EngineCall call, {
    required StawiAsset asset,
    String? counterpartyName,
    String? pocketName,
  }) {
    String money(BigInt v) => formatUnits(v, asset);
    final other = counterpartyName ?? 'them';
    final pocket = pocketName ?? _pocketLabel(call.pocket);
    final amount = call.amount;
    switch (r.call) {
      case PersonalCall.borrowSelf:
        return MoneyReview(
          title: 'Borrow ${money(amount)} from my savings',
          lines: [
            ('From', pocket),
            ('Amount', money(amount)),
            ...personalTermLines(call.terms),
            ('You repay', money(expectedToRepay(amount, call.terms))),
          ],
          signLabel: _sign,
          done: 'Loan taken from your savings',
        );
      case PersonalCall.offer:
        return MoneyReview(
          title: 'Lend ${money(amount)} to $other',
          lines: [
            ('To', other),
            ('From', pocket),
            ('Amount', money(amount)),
            ...personalTermLines(call.terms),
            ('Offer open until', _date(call.expiresAt)),
          ],
          signLabel: _sign,
          done: 'Offer sent to $other',
        );
      case PersonalCall.ask:
        return MoneyReview(
          title: 'Ask $other to lend ${money(amount)}',
          lines: [
            ('From', other),
            ('Amount', money(amount)),
            ...personalTermLines(call.terms),
            ('Expected to repay', money(expectedToRepay(amount, call.terms))),
            ('At most you will repay', money(r.maxRepay ?? call.maxRepay)),
            ('Ask open until', _date(call.expiresAt)),
          ],
          notes: [
            _ceilingNote,
            'Asking shares your loan record with $other until they lend, decline, or the ask ends.',
          ],
          signLabel: _sign,
          done: 'Request sent to $other',
        );
      case PersonalCall.acceptOffer:
        final offer = r.offer;
        final shown = offer?.amount ?? amount;
        return MoneyReview(
          title: 'Accept a loan of ${money(shown)} from $other',
          lines: [
            ('From', other),
            ('Amount', money(shown)),
            if (offer != null) ...[
              ...personalTermLines(offer.terms),
              (
                'Expected to repay',
                money(expectedToRepay(offer.amount, offer.terms)),
              ),
            ],
            ('At most you will repay', money(r.maxRepay ?? call.maxRepay)),
          ],
          notes: const [_ceilingNote],
          signLabel: _sign,
          done: 'Loan accepted',
        );
      case PersonalCall.acceptAsk:
        return MoneyReview(
          title: 'Lend ${money(amount)} to $other',
          lines: [('To', other), ('Amount', money(amount)), ('From', pocket)],
          signLabel: _sign,
          done: 'Lent ${money(amount)} to $other',
        );
      case PersonalCall.pay:
        return MoneyReview(
          title: 'Pay an instalment',
          lines: [('Amount', money(amount))],
          signLabel: _sign,
          done: 'Payment sent',
        );
      case PersonalCall.cancel:
        return const MoneyReview(
          title: 'Cancel this request',
          lines: [],
          signLabel: _sign,
          done: 'Cancelled',
        );
      case PersonalCall.payoff:
        return MoneyReview(
          title: 'Pay off the loan',
          lines: [('Pays at most', money(amount))],
          notes: const ['Only what the loan takes is paid'],
          signLabel: _sign,
          done: 'Loan paid off',
        );
      case PersonalCall.withdraw:
        return MoneyReview(
          title: 'Withdraw my savings',
          lines: [('From', pocket), ('Amount', money(amount))],
          signLabel: _sign,
          done: 'Savings withdrawn',
        );
      case PersonalCall.createGoal:
        return MoneyReview(
          title: 'Start a savings goal',
          lines: [
            ('Target', money(call.goalTarget)),
            ('Unlocks', _date(call.goalUnlockAt)),
            ('Can be lent', call.goalLoanable ? 'Yes' : 'No'),
          ],
          signLabel: _sign,
          done: 'Savings goal started',
        );
      case PersonalCall.move:
        return MoneyReview(
          title: 'Move my savings',
          lines: [
            ('From', _pocketLabel(call.pocket)),
            ('To', _pocketLabel(call.toPocket)),
            ('Amount', money(amount)),
          ],
          signLabel: _sign,
          done: 'Savings moved',
        );
    }
  }

  /// A loan, withdrawal or amount choice on a room's engines.
  factory MoneyReview.engine(
    AccountEngineRequest r,
    sdk.EngineCall call, {
    String? feeLine,
  }) {
    final asset = r.asset;
    final amount = call.amount > BigInt.zero
        ? (asset == null
              ? call.amount.toString()
              : formatUnits(call.amount, asset))
        : null;
    return MoneyReview(
      title: r.summary,
      lines: [
        if (amount != null)
          (
            // A payoff asked without a ceiling shows the quoted ceiling that
            // was checked, never the request's empty amount.
            r.call == AccountEngineCall.loanPayoff && r.amount.isEmpty
                ? 'Pays at most'
                : 'Amount',
            amount,
          ),
        if (r.call.takesLoan) ('Loan', '#${r.loanId}'),
        if (call.instalments > 0) ('Instalments', '${call.instalments}'),
        if (feeLine != null) ('Stawi fee', feeLine),
      ],
      signLabel: _sign,
      done: 'Signed and submitted: ${r.summary}',
    );
  }

  /// Adding money to the person's own savings.
  factory MoneyReview.deposit({
    required BigInt amount,
    required String pocketName,
    required StawiAsset asset,
  }) => MoneyReview(
    title: 'Add ${formatUnits(amount, asset)} to $pocketName',
    lines: [('To', pocketName), ('Amount', formatUnits(amount, asset))],
    signLabel: _sign,
    done: 'Money added',
  );

  /// Turning a loan's automatic payment on or off.
  factory MoneyReview.standingOrder({
    required finance.Loan loan,
    required bool on,
    required StawiAsset asset,
    required BigInt perInstalment,
    String? title,
  }) => MoneyReview(
    title: title ?? (on ? 'Pay automatically' : 'Stop paying automatically'),
    lines: [
      ('Loan', '#${BigInt.parse(loan.onchainLoanId.toStringUnsigned())}'),
    ],
    notes: [
      if (on)
        'Pays up to ${formatUnits(perInstalment, asset)} each instalment from your wallet'
      else
        'Stops automatic payments; pay each instalment yourself',
    ],
    signLabel: _sign,
    done: on ? 'Automatic payment is on' : 'Automatic payment is off',
  );

  /// A payment into a room. Its title is built from the checked [amount],
  /// formatted the same way as its Amount line: [title] words it around that
  /// amount ("Contribute 77.50 USDC to Chama"); by default "Pay {amount} into
  /// {room}".
  factory MoneyReview.contribution({
    required BigInt amount,
    required String roomName,
    required StawiAsset asset,
    String? note,
    String Function(String amount)? title,
  }) {
    final shown = formatUnits(amount, asset);
    return MoneyReview(
      title: title?.call(shown) ?? 'Pay $shown into $roomName',
      lines: [('To', roomName), ('Amount', shown)],
      notes: [note ?? 'The room\'s rules apply it: dues and penalties first.'],
      signLabel: _sign,
      done: 'Payment sent to $roomName',
    );
  }

  /// Sending money to another Stawi account.
  factory MoneyReview.transferOut({
    required Uint8List to,
    required BigInt amount,
    required StawiAsset asset,
    String? name,
  }) => MoneyReview(
    title:
        'Send ${formatUnits(amount, asset)}${name == null ? '' : ' to $name'}',
    lines: [
      ('To', name ?? _short(sdk.bytesToHex0x(to))),
      ('Amount', formatUnits(amount, asset)),
    ],
    notes: const ['Money sent to another address cannot be taken back.'],
    signLabel: _sign,
    done: 'Money sent',
  );

  /// "Lend 300.00 USDC to Bob".
  final String title;

  /// ("Amount", "300.00 USDC").
  final List<(String, String)> lines;

  /// Plain warnings.
  final List<String> notes;
  final String signLabel;

  /// Shown after the call is submitted.
  final String done;
}

/// Why the signed ceiling is not the price.
const String _ceilingNote =
    'Expected to repay is what the loan costs when every instalment is paid '
    'on time. At most you will repay is the ceiling you sign: the difference '
    'covers late charges, owed only if an instalment is late.';

String _short(String hex) => hex.length <= 14
    ? hex
    : '${hex.substring(0, 6)}…${hex.substring(hex.length - 4)}';

String _pocketLabel(List<int> pocket) =>
    pocket.every((b) => b == 0) ? 'Free savings' : 'Savings goal';

String _date(BigInt seconds) => DateFormat.yMMMd().format(
  DateTime.fromMillisecondsSinceEpoch(seconds.toInt() * 1000, isUtc: true),
);

String _every(int days) => switch (days) {
  1 => 'day',
  7 => 'week',
  14 => 'two weeks',
  30 => 'month',
  _ => '$days days',
};

List<(String, String)> personalTermLines(sdk.PersonalTerms t) => [
  ('Instalments', '${t.n} every ${_every(t.everyDays)}'),
  ('Interest', '${formatBps(t.rateBps)} each instalment'),
];

/// Principal plus interest: half of [sdk.maxRepayable], which allows the
/// same again for late charges.
BigInt expectedToRepay(BigInt amount, sdk.PersonalTerms t) =>
    sdk.maxRepayable(amount, t) ~/ BigInt.two;
