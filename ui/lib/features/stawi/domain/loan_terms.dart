import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' as chain;

/// A personal loan's terms as finance.v1 PersonalLoanTerms carries them
/// (enums are the chain's plus one), and as the SDK signs them.
final class LoanTerms {
  const LoanTerms(this.proto);

  /// The finance.v1 form of the SDK's [chain.PersonalTerms]. Throws
  /// [FormatException] for terms a personal loan does not take.
  factory LoanTerms.fromSdk(chain.PersonalTerms t) {
    final Map<String, Object?> json;
    try {
      json = t.toProtoJson();
    } on chain.InvalidLoanTermsException {
      throw const FormatException(unsignableTerms);
    }
    return LoanTerms(finance.PersonalLoanTerms()..mergeFromProto3Json(json));
  }

  /// The terms of a preset schedule: flat interest of [rateBps] per
  /// instalment; no late charge on a loan to oneself, 5% of the shortfall
  /// between people; in default 30 days after a missed due date.
  factory LoanTerms.preset(
    LoanPreset p, {
    required int rateBps,
    required finance.LoanKind kind,
  }) {
    final (n, every) = switch (p) {
      LoanPreset.weekly4 => (4, 7),
      LoanPreset.fortnightly2 => (2, 14),
      LoanPreset.fortnightly4 => (4, 14),
      LoanPreset.monthly3 => (3, 30),
      LoanPreset.monthly6 => (6, 30),
      LoanPreset.monthly12 => (12, 30),
    };
    final self = kind == finance.LoanKind.LOAN_KIND_SELF;
    return LoanTerms(
      finance.PersonalLoanTerms(
        instalments: n,
        everyDays: every,
        method: finance.LoanInterestMethod.LOAN_INTEREST_METHOD_FLAT,
        rateBps: rateBps,
        latePenalty: self
            ? finance.PenaltyMethod.PENALTY_METHOD_NONE
            : finance.PenaltyMethod.PENALTY_METHOD_PERCENT_OF_SHORTFALL,
        lateBps: self ? 0 : 500,
        defaultAfterDays: 30,
      ),
    );
  }

  /// Why terms the LoanBook would refuse are not signed.
  static const String unsignableTerms = 'These loan terms cannot be signed';

  final finance.PersonalLoanTerms proto;

  /// The chain's PersonalTerms, exactly as the SDK reads finance's proto
  /// (personalTermsFromProtoJson). Throws [FormatException] for terms it
  /// refuses: a method a personal loan does not take, a late charge that is
  /// not one, interest beyond the principal.
  chain.PersonalTerms get sdk {
    try {
      return chain.personalTermsFromProtoJson(
        (proto.toProto3Json()! as Map).cast<String, Object?>(),
      );
    } on chain.InvalidLoanTermsException {
      throw const FormatException(unsignableTerms);
    }
  }

  int get instalments => proto.instalments;
  int get everyDays => proto.everyDays;

  /// Whether the terms carry a late charge.
  bool get hasLateCharge =>
      proto.latePenalty != finance.PenaltyMethod.PENALTY_METHOD_NONE &&
      proto.latePenalty != finance.PenaltyMethod.PENALTY_METHOD_UNSPECIFIED;

  /// What the LoanBook refuses, in words, or null: the shape the
  /// PersonalLoanTerms proto admits, and the checks of Go
  /// rules.ValidatePersonalTerms that depend on the amount and the kind.
  String? validate(BigInt amount, finance.LoanKind kind) {
    if (amount <= BigInt.zero) return 'Enter an amount';
    if (proto.instalments < 1 || proto.instalments > 104) {
      return 'A loan is repaid in 1 to 104 instalments';
    }
    if (!const [7, 14, 30].contains(proto.everyDays)) {
      return 'Instalments fall every week, two weeks or month';
    }
    if (proto.defaultAfterDays < 2 || proto.defaultAfterDays > 365) {
      return 'A loan can be in default 2 to 365 days after a missed instalment';
    }
    if (proto.rateBps * proto.instalments > 10000) {
      return 'Interest would be more than the amount';
    }
    if (kind == finance.LoanKind.LOAN_KIND_SELF && hasLateCharge) {
      return 'A loan to yourself carries no late charge';
    }
    final flat = BigInt.tryParse(proto.lateFlat.isEmpty ? '0' : proto.lateFlat);
    if (flat == null) return LoanTerms.unsignableTerms;
    if (flat > amount ~/ BigInt.from(proto.instalments)) {
      return 'The late charge is more than one instalment';
    }
    try {
      if (sdk.n != proto.instalments) return LoanTerms.unsignableTerms;
    } on FormatException catch (e) {
      return e.message;
    }
    return null;
  }

  /// When an instalment is late and what that costs, in plain words. The
  /// day after the due date is collection time, not a free day: an
  /// instalment unpaid by then is late, and a late charge counts from the
  /// due date itself.
  String get lateRule {
    const late = 'An instalment not paid within a day of its due date is late.';
    final charge = hasLateCharge
        ? ' Once it is late, the late charge counts from the due date.'
        : ' There is no late charge.';
    final days = proto.defaultAfterDays;
    return '$late$charge The loan can be declared in default $days days '
        'after a missed due date.';
  }
}

enum LoanPreset {
  weekly4('4 weekly'),
  fortnightly2('2 every two weeks'),
  fortnightly4('4 every two weeks'),
  monthly3('3 monthly'),
  monthly6('6 monthly'),
  monthly12('12 monthly');

  const LoanPreset(this.label);
  final String label;
}
